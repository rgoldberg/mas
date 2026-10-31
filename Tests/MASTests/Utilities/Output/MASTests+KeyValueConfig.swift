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
	@Test(arguments: ["", " \t"])
	func `an empty or whitespace-only --key-value-config value parses to all defaults`(value: String) throws {
		#expect(try parseKeyValueConfig(value) == .default)
	}

	@Test(arguments: [("K1", "1"), ("K1;4:", "1;4"), ("K 1;4 :", "1;4"), ("K\\b", "b"), ("K1:k", ""), ("kK1:", "1")])
	func `k unstyles keys; K styles them with a required style specifier; last wins`(
		value: String,
		keyStyleSpecifier: String,
	) throws {
		#expect(try parseKeyValueConfig(value).keyStyleSpecifier == keyStyleSpecifier)
	}

	@Test(
		arguments: [
			("K", KeyValueConfigParsingError.invalidKeyStyleSpecifier("")),
			("K:", .invalidKeyStyleSpecifier("")),
			("K1S", .invalidKeyStyleSpecifier("1S")),
			("Kb:", .invalidKeyStyleSpecifier("b")),
			("K1\n2:", .invalidKeyStyleSpecifier("1\n2")),
			("P\n:", .invalidKeyStylePrefix("\n")),
			("X\u{85}:", .invalidKeyStyleSuffix("\u{85}")),
			("O\u{2029}:", .invalidKeyStyleReset("\u{2029}")),
			("z", .invalidSetting("z")),
			("F-\\", .danglingEscape),
			("F-\n", .invalidLeaderPattern("-\n")),
			("F\r:", .invalidLeaderPattern("\r")),
			("S=\n=", .invalidItemSeparatorLine("=\n=")),
			("S\u{2028}:", .invalidItemSeparatorLine("\u{2028}")),
			("L\r\n:", .invalidLeadingSpacing("\r\n")),
			("R\u{85}:", .invalidTrailingSpacing("\u{85}")),
		],
	)
	func `an invalid key style, pattern, or spacing, unknown setting, or dangling escape is a parse error`(
		value: String,
		error: KeyValueConfigParsingError,
	) throws {
		#expect(throws: error) { try parseKeyValueConfig(value) }
	}

	@Test(arguments: [("K1:", KeyValueConfig.KeyStyling.terminalOnly), ("K1:a", .always), ("aK1:t", .terminalOnly)])
	func `t & a set key styling, last wins`(value: String, keyStyling: KeyValueConfig.KeyStyling) throws {
		#expect(try parseKeyValueConfig(value).keyStyling == keyStyling)
	}

	@Test(
		arguments: [
			("", StyleSequences.default),
			("P<:X>:O</>:", .init(prefix: "<", suffix: ">", reset: "</>")),
			("P:X:O", .init(prefix: "", suffix: "", reset: "")),
			("P < :X\\::", .init(prefix: " < ", suffix: ":", reset: "\u{1B}[0m")),
			("P<:X>:O</>:pxo", .default),
			("pxoP<:X>:O</>:", .init(prefix: "<", suffix: ">", reset: "</>")),
		],
	)
	func `key style sequences: P, X & O set literal ones, including empty; p, x & o restore defaults; last wins`(
		value: String,
		keyStyleSequences: StyleSequences,
	) throws {
		#expect(try parseKeyValueConfig(value).keyStyleSequences == keyStyleSequences)
	}

	@Test(arguments: [
		("f", String?.none),
		("F", "▁"),
		("F:", "▁"),
		("F.-:", ".-"),
		("Fs", "s"),
		("fF.", "."),
		("F.:f", nil),
	])
	func `f removes the leader; F sets its pattern, ▁ by default`(value: String, leaderPattern: String?) throws {
		#expect(try parseKeyValueConfig(value).leaderPattern == leaderPattern)
	}

	@Test(arguments: [("l", " "), ("L", ""), ("L:", ""), ("L=", "="), ("L\\: :", ": "), ("L=:l", " ")])
	func `l resets leading spacing to the built-in default; L sets a literal custom value, including empty`(
		value: String,
		leadingSpacing: String,
	) throws {
		#expect(try parseKeyValueConfig(value).leadingSpacing == leadingSpacing)
	}

	@Test(arguments: [("f", ":"), ("lf", " "), ("fl", " "), ("L=:f", "="), ("fL:", ""), ("fF:", " ")])
	func `f implies a leading spacing of colon unless one is otherwise set`(value: String, leadingSpacing: String)
	throws {
		#expect(try parseKeyValueConfig(value).leadingSpacing == leadingSpacing)
	}

	@Test(arguments: [("r", " "), ("R", ""), ("R:", ""), ("R=", "="), ("R\\: :", ": "), ("R=:r", " ")])
	func `r resets trailing spacing to the built-in default; R sets a literal custom value, including empty`(
		value: String,
		trailingSpacing: String,
	) throws {
		#expect(try parseKeyValueConfig(value).trailingSpacing == trailingSpacing)
	}

	@Test(arguments: [("s", String?.none), ("S", ""), ("S:", ""), ("S=", "="), ("S-+:s", nil)])
	func `s removes the item separator line; S sets it, blank by default`(
		value: String,
		itemSeparatorLine: String?,
	) throws {
		#expect(try parseKeyValueConfig(value).itemSeparatorLine == itemSeparatorLine)
	}

	@Test(arguments: [(" f s ", "fs"), ("K 1 : a", "K1:a"), ("F.: L=: s", "F.:L=:s"), ("F. :", "F.\\ :")])
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
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("F.:"))
				== "Name .... Slack\nVersion . 4.0\n\nName .... X\nVersion . 1",
		)
	}

	@Test
	func `key-value truncates a leader pattern that does not evenly divide its leader's width`() throws {
		#expect(
			try keyValue(of: [twoItems[0]], keyValueConfig: try parseKeyValueConfig("F-+:L:R:"))
				== "Name-+-+-Slack\nVersion-+4.0",
		)
	}

	@Test
	func `key-value space-fills a leader's width that a wide leader pattern character would exceed`() throws {
		#expect(
			try keyValue(of: [twoItems[0]], keyValueConfig: try parseKeyValueConfig("F中:L:R:"))
				== "Name中中 Slack\nVersion中4.0",
		)
	}

	@Test(arguments: ["\t", "\u{301}"])
	func `key-value prints a 0-width leader pattern once per row`(pattern: String) throws {
		#expect(
			try keyValue(
				of: twoItems,
				keyValueConfig: .init(
					keyStyleSpecifier: "",
					keyStyling: .terminalOnly,
					keyStyleSequences: .default,
					leaderPattern: pattern,
					leadingSpacing: " ",
					trailingSpacing: " ",
					itemSeparatorLine: "",
				),
			)
				== "Name \(pattern) Slack\nVersion \(pattern) 4.0\n\nName \(pattern) X\nVersion \(pattern) 1",
		)
	}

	@Test
	func `key-value without a leader puts the leading & then the trailing spacing between each key & its value`()
	throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("fL=:R-"))
				== "Name=-Slack\nVersion=-4.0\n\nName=-X\nVersion=-1",
		)
	}

	@Test
	func `key-value without a leader defaults to colon-space between each key & its value`() throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("f"))
				== "Name: Slack\nVersion: 4.0\n\nName: X\nVersion: 1",
		)
	}

	@Test(arguments: ["-+", "中", "\t", "\u{301}"])
	func `key-value outputs an item separator line as is, regardless of any item's width`(line: String) throws {
		#expect(
			try keyValue(
				of: twoItems,
				keyValueConfig: .init(
					keyStyleSpecifier: "",
					keyStyling: .terminalOnly,
					keyStyleSequences: .default,
					leaderPattern: nil,
					leadingSpacing: "=",
					trailingSpacing: "",
					itemSeparatorLine: line,
				),
			)
				== "Name=Slack\nVersion=4.0\n\(line)\nName=X\nVersion=1",
		)
	}

	@Test
	func `key-value indents each non-empty later line of a value to its start`()
	throws {
		let items = [JSON.Object([("name", .string("Slack")), ("version", .string("4.0\r\n\u{2028}be\\nta"))]), twoItems[1]]
		#expect(
			try keyValue(of: items, keyValueConfig: try parseKeyValueConfig("fL=:R:S-"))
				== "Name=Slack\nVersion=4.0\n\n        be\\nta\n-\nName=X\nVersion=1",
		)
	}

	@Test
	func `key-value renders each line terminator in a key as a return symbol, aligning by its width`() throws {
		let keyValue = try [JSON.Object([("name", .string("Slack")), ("version", .string("4.0"))])]
			.keyValue(
				fieldSpecs: [
					.init(name: "name", label: "N\na", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "version", label: "Ver", format: .default(fieldName: "version"), sortSpec: nil),
				],
				fieldOrder: .positional(.init()),
				keyValueConfig: try parseKeyValueConfig("F.:"),
			)
		#expect(keyValue == "N⏎a . Slack\nVer . 4.0")
	}

	@Test
	func `key-value renders each other control character in a key as table cells do, aligning by its width`() throws {
		let keyValue = try [JSON.Object([("name", .string("Slack")), ("version", .string("4.0"))])]
			.keyValue(
				fieldSpecs: [
					.init(name: "name", label: "N\ta", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "version", label: "V\u{9B}r", format: .default(fieldName: "version"), sortSpec: nil),
				],
				fieldOrder: .positional(.init()),
				keyValueConfig: try parseKeyValueConfig("F.:"),
			)
		#expect(keyValue == "N␉a .. Slack\nV␛[r . 4.0")
	}

	@Test
	func `key-value renders each control character in a value except a tab or a line terminator as keys do`() throws {
		#expect(
			try keyValue(
				of: [JSON.Object([("name", .string("a\tb\u{1B}[1mc\u{8}\u{7F}d\ne\u{9B}2J"))])],
				keyValueConfig: try parseKeyValueConfig("fL=:R:"),
			)
				== "Name=a\tb␛[1mc␈␡d\n     e␛[2J",
		)
	}

	@Test
	func `key-value without an item separator line puts adjacent items' rows on adjacent lines`() throws {
		#expect(
			try keyValue(of: twoItems, keyValueConfig: try parseKeyValueConfig("fL=:R:s"))
				== "Name=Slack\nVersion=4.0\nName=X\nVersion=1",
		)
	}

	@Test(arguments: ["s", "S-"])
	func `key-value outputs nothing iff no item has a row`(value: String) throws {
		#expect(
			try keyValue(
				of: [.init([("other", .null)]), .init([("name", .null)])],
				keyValueConfig: parseKeyValueConfig(value),
			)
				== nil,
		)
	}

	@Test(
		arguments: [
			("fL=:R:s", "Name=Slack\nVersion=4.0\nName=X\nVersion=1"),
			("fL=:R:S-", "Name=Slack\nVersion=4.0\n-\n-\nName=X\nVersion=1"),
		],
	)
	func `key-value outputs no line for an item without rows, only its adjacent item separator lines`(
		value: String,
		expected: String,
	) throws {
		#expect(
			try keyValue(
				of: [twoItems[0], .init([("other", .null)]), twoItems[1]],
				keyValueConfig: parseKeyValueConfig(value),
			)
				== expected,
		)
	}

	@Test
	func `key-value omits a field whose value is absent or null, aligning only the remaining keys`() throws {
		#expect(
			try keyValue(
				of: [JSON.Object([("name", .string("A")), ("version", .null)])],
				keyValueConfig: try parseKeyValueConfig("F.:"),
			)
				== "Name . A",
		)
	}

	@Test
	func `key-value styles only keys, for a non-terminal only with key-always-styling`() throws {
		let alwaysStyled = try keyValue(of: [twoItems[1]], keyValueConfig: try parseKeyValueConfig("K1:afL=:R:"))
		#expect(alwaysStyled == "\u{1B}[1mName\u{1B}[0m=X\n\u{1B}[1mVersion\u{1B}[0m=1")
		let terminalOnly = try keyValue(of: [twoItems[1]], keyValueConfig: try parseKeyValueConfig("K1:tfL=:R:"))
		#expect(terminalOnly == (FileHandle.standardOutput.isTerminal ? alwaysStyled : "Name=X\nVersion=1"))
	}

	@Test
	func `key-value styles keys with custom style sequences`() throws {
		#expect(
			try keyValue(of: [twoItems[1]], keyValueConfig: try parseKeyValueConfig("K\\b:P<:X>:O</b>:afL=:R:"))
				== "<b>Name</b>=X\n<b>Version</b>=1",
		)
	}
}

private let twoItems = [
	JSON.Object([("name", .string("Slack")), ("version", .string("4.0"))]),
	JSON.Object([("name", .string("X")), ("version", .string("1"))]),
]

private func keyValue(of objects: [JSON.Object], keyValueConfig: KeyValueConfig) throws -> String? {
	try objects.keyValue(
		fieldSpecs: [
			.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
			.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
		],
		fieldOrder: .positional(.init()),
		keyValueConfig: keyValueConfig,
	)
}
