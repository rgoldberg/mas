//
// MASTests+JSONConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `an empty --json value parses to all defaults`() throws {
		#expect(try parseJSONConfig("") == .default)
	}

	@Test(
		arguments: [
			("p", String?.none),
			("P", "  "),
			("P:", "  "),
			("P\t", "\t"),
			("P    :", "    "),
			("P\\ :", " "),
			("P:p", nil),
			("pP\t:", "\t"),
		],
	)
	func `p renders compactly; P pretty-prints with spaces & tabs indentation, 2 spaces by default`(
		value: String,
		indentation: String?,
	) throws {
		#expect(try parseJSONConfig(value).indentation == indentation)
	}

	@Test(
		arguments: [
			("Pa", JSONConfigParsingError.invalidIndentation("a")),
			("P  x:", .invalidIndentation("  x")),
			("P\\", .danglingEscape),
			("z", .invalidSetting("z")),
		],
	)
	func `invalid indentation, an unknown setting, or a dangling escape is a parse error`(
		value: String,
		error: JSONConfigParsingError,
	) throws {
		#expect(throws: error) { try parseJSONConfig(value) }
	}

	@Test(arguments: [("s", JSONConfig.TopLevelStructure.itemStream), ("a", .itemArray), ("as", .itemStream)])
	func `s & a set the top-level structure, last wins`(value: String, topLevelStructure: JSONConfig.TopLevelStructure)
	throws {
		#expect(try parseJSONConfig(value).topLevelStructure == topLevelStructure)
	}

	@Test(arguments: [("v", JSONConfig.NonASCIIRendering.verbatim), ("e", .escaped), ("ev", .verbatim)])
	func `v & e set non-ASCII rendering, last wins`(value: String, nonASCIIRendering: JSONConfig.NonASCIIRendering)
	throws {
		#expect(try parseJSONConfig(value).nonASCIIRendering == nonASCIIRendering)
	}

	@Test(arguments: [(" a e ", "ae"), ("P: a", "P:a"), ("P : a", "P\\ :a")])
	func `outer bare whitespace between settings is ignored, but a text payload consumes its own`(
		value: String,
		equivalent: String,
	) throws {
		#expect(try parseJSONConfig(value) == parseJSONConfig(equivalent))
	}

	@Test
	func `json renders each item as a compact top-level object on its own line by default`() throws {
		#expect(try json(of: twoItems, jsonConfig: .default) == #"{"name":"Slack","free":true}"# + "\n" +
			#"{"name":"X","free":false}"#)
	}

	@Test
	func `json renders every item in a single compact top-level array`() throws {
		#expect(
			try json(of: twoItems, jsonConfig: try parseJSONConfig("a"))
				== #"[{"name":"Slack","free":true},{"name":"X","free":false}]"#,
		)
	}

	@Test
	func `json pretty-prints each item with the given indentation per nesting level`() throws {
		#expect(
			try json(of: twoItems, jsonConfig: try parseJSONConfig("P\t"))
				== "{\n\t\"name\": \"Slack\",\n\t\"free\": true\n}\n{\n\t\"name\": \"X\",\n\t\"free\": false\n}",
		)
		#expect(
			try json(of: twoItems, jsonConfig: try parseJSONConfig("aP")) // editorconfig-checker-disable
				== """
					[
					  {
					    "name": "Slack",
					    "free": true
					  },
					  {
					    "name": "X",
					    "free": false
					  }
					]
					""", // editorconfig-checker-enable
		)
	}

	@Test
	func `json pretty-prints nested values, rendering empty arrays & objects compactly`() throws {
		let node = JSON.Node.object(
			.init([("a", .array([true, []])), ("o", .object(.init())), ("s", .string("x"))]),
		)
		#expect(
			node.rendered(jsonConfig: try parseJSONConfig("P")) // editorconfig-checker-disable
				== """
					{
					  "a": [
					    true,
					    []
					  ],
					  "o": {},
					  "s": "x"
					}
					""", // editorconfig-checker-enable
		)
	}

	@Test
	func `json escapes non-ASCII characters in keys & values as UTF-16 code units iff e`() throws {
		let node = JSON.Node.object(.init([("é", .string("ö😀\n"))]))
		#expect(node.rendered(jsonConfig: try parseJSONConfig("e")) == #"{"\u00e9":"\u00f6\ud83d\ude00\n"}"#)
		#expect(node.rendered(jsonConfig: try parseJSONConfig("v")) == #"{"é":"ö😀\n"}"#)
	}
}

private let twoItems = [
	JSON.Object([("name", .string("Slack")), ("free", true)]),
	JSON.Object([("name", .string("X")), ("free", false)]),
]

private func json(of objects: [JSON.Object], jsonConfig: JSONConfig) throws -> String {
	try objects.json(
		fieldSpecs: [
			.init(name: "name", label: "name", format: .default(fieldName: "name"), sortSpec: nil),
			.init(name: "free", label: "free", format: .default(fieldName: "free"), sortSpec: nil),
		],
		fieldOrder: .positional,
		jsonConfig: jsonConfig,
	)
}
