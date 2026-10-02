//
// MASTests+KeyValueConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `an empty --key-value value parses to all defaults`() throws {
		#expect(try parseKeyValueConfig("") == .default)
	}

	@Test(arguments: [("K1", "1"), ("K1;4:", "1;4"), ("K 1 ; 4 :", "1;4"), ("K1:k", ""), ("kK1:", "1")])
	func `k unstyles keys; K styles them with required SGR parameters; last wins`(
		value: String,
		keySGRParameters: String,
	) throws {
		#expect(try parseKeyValueConfig(value).keySGRParameters == keySGRParameters)
	}

	@Test(
		arguments: [
			("K", KeyValueConfigParsingError.invalidKeyStyle("")),
			("K:", .invalidKeyStyle("")),
			("K1S", .invalidKeyStyle("1S")),
			("K\\1:", .invalidKeyStyle("\\1")),
			("z", .invalidSetting("z")),
			("L-\\", .danglingEscape),
		],
	)
	func `an invalid key style, unknown setting, or dangling escape is a parse error`(
		value: String,
		error: KeyValueConfigParsingError,
	) throws {
		#expect(throws: error) { try parseKeyValueConfig(value) }
	}

	@Test(arguments: [("K1:", KeyValueConfig.KeyStyling.terminalOnly), ("K1:a", .always), ("aK1:t", .terminalOnly)])
	func `t & a set key styling, last wins`(value: String, keyStyling: KeyValueConfig.KeyStyling) throws {
		#expect(try parseKeyValueConfig(value).keyStyling == keyStyling)
	}

	@Test(arguments: [
		("l", String?.none),
		("L", "▁"),
		("L:", "▁"),
		("L.-:", ".-"),
		("Ls", "s"),
		("lL.", "."),
		("L.:l", nil),
	])
	func `l removes the leader; L sets its pattern, ▁ by default`(value: String, leaderPattern: String?) throws {
		#expect(try parseKeyValueConfig(value).leaderPattern == leaderPattern)
	}

	@Test(arguments: [("c", " "), ("C", ""), ("C:", ""), ("C=", "="), ("C\\: :", ": "), ("C=:c", " ")])
	func `c resets key-value spacing to the built-in default; C sets a literal custom value, including empty`(
		value: String,
		keyValueSpacing: String,
	) throws {
		#expect(try parseKeyValueConfig(value).keyValueSpacing == keyValueSpacing)
	}

	@Test(arguments: [("s", String?.none), ("S", ""), ("S:", ""), ("S=", "="), ("S-+:s", nil)])
	func `s removes the item separator line; S sets its pattern, blank by default`(
		value: String,
		itemSeparatorPattern: String?,
	) throws {
		#expect(try parseKeyValueConfig(value).itemSeparatorPattern == itemSeparatorPattern)
	}

	@Test(arguments: [(" l s ", "ls"), ("K 1 : a", "K1:a"), ("L.: C=: s", "L.:C=:s"), ("L. :", "L.\\ :")])
	func `outer bare whitespace between settings is ignored, but a text payload consumes its own`(
		value: String,
		equivalent: String,
	) throws {
		#expect(try parseKeyValueConfig(value) == parseKeyValueConfig(equivalent))
	}

	@Test
	func `key-value aligns values per item via a leader, with spacing on each side, & a blank line between items`()
	throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("L.:"))
				== "Name .... Slack\nVersion . 4.0\n\nName .... X\nVersion . 1",
		)
	}

	@Test
	func `key-value truncates a leader pattern that doesn't evenly divide its leader's width`() throws {
		#expect(
			try keyValue(of: [twoItems[0]], keyValueConfig: try parseKeyValueConfig("L-+:C:"))
				== "Name-+-+-Slack\nVersion-+4.0",
		)
	}

	@Test(arguments: ["\t", "\u{301}"])
	func `key-value prints a 0-width leader pattern once per row`(pattern: String) throws {
		#expect(
			try keyValue(
				of: twoItems,
				keyValueConfig: .init(
					keySGRParameters: "",
					keyStyling: .terminalOnly,
					leaderPattern: pattern,
					keyValueSpacing: " ",
					itemSeparatorPattern: "",
				),
			)
				== "Name \(pattern) Slack\nVersion \(pattern) 4.0\n\nName \(pattern) X\nVersion \(pattern) 1",
		)
	}

	@Test
	func `key-value without a leader puts the spacing once between each key & its value`() throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("lC="))
				== "Name=Slack\nVersion=4.0\n\nName=X\nVersion=1",
		)
	}

	@Test
	func `key-value fills an item separator line to the width of the widest row of any item`() throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("lC=:S-+"))
				== "Name=Slack\nVersion=4.0\n-+-+-+-+-+-\nName=X\nVersion=1",
		)
	}

	@Test(arguments: ["\t", "\u{301}"])
	func `key-value prints a 0-width item separator pattern once`(pattern: String) throws {
		#expect(
			try keyValue(
				of: twoItems,
				keyValueConfig: .init(
					keySGRParameters: "",
					keyStyling: .terminalOnly,
					leaderPattern: nil,
					keyValueSpacing: "=",
					itemSeparatorPattern: pattern,
				),
			)
				== "Name=Slack\nVersion=4.0\n\(pattern)\nName=X\nVersion=1",
		)
	}

	@Test
	func `key-value without an item separator line puts adjacent items' rows on adjacent lines`() throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("lC=:s"))
				== "Name=Slack\nVersion=4.0\nName=X\nVersion=1",
		)
	}

	@Test
	func `key-value omits a field whose value is absent or null, aligning only the remaining keys`() throws {
		#expect(
			try keyValue(
				of: [JSON.Object([("name", .string("A")), ("version", .null)])],
				keyValueConfig: try parseKeyValueConfig("L.:"),
			)
				== "Name . A",
		)
	}

	@Test
	func `key-value styles only keys, for a non-terminal only with always-styling`() throws {
		let alwaysStyled = try keyValue(of: [twoItems[1]], keyValueConfig: try parseKeyValueConfig("K1:alC="))
		#expect(alwaysStyled == "\u{1B}[1mName\u{1B}[0m=X\n\u{1B}[1mVersion\u{1B}[0m=1")
		let terminalOnly = try keyValue(of: [twoItems[1]], keyValueConfig: try parseKeyValueConfig("K1:tlC="))
		#expect(terminalOnly == (FileHandle.standardOutput.isTerminal ? alwaysStyled : "Name=X\nVersion=1"))
	}
}

private let twoItems = [
	JSON.Object([("name", .string("Slack")), ("version", .string("4.0"))]),
	JSON.Object([("name", .string("X")), ("version", .string("1"))]),
]

private func keyValue(of objects: [JSON.Object], keyValueConfig: KeyValueConfig) throws -> String {
	try objects.keyValue(
		fieldSpecs: [
			.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
			.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
		],
		fieldOrder: .base(nil),
		keyValueConfig: keyValueConfig,
	)
}
