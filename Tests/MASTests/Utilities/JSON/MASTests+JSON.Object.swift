//
// MASTests+JSON.Object.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			("-", false, "--------"),
			("-+", false, "-+-+-+-+"),
			("-", true, "----  --"),
			("-中", false, "-中-中- "),
			("-中", true, "-中-  - "),
			("\t", false, "\t"),
			("\t", true, "\t      \t"),
			("\u{301}", false, "\u{301}"),
		],
	)
	func `a table separator fills its width, except a 0-width separator, which is printed once`(
		pattern: String,
		broken: Bool,
		separatorLine: String,
	) throws {
		#expect(
			try [
				JSON.Object([("name", .string("xy")), ("id", .number(1))]),
				.init([("name", .string("abc")), ("id", .number(22))]),
			]
				.table(
					fieldSpecs: ["name", "id"].map { .init(name: $0, label: $0, format: .default(fieldName: $0), sortSpec: nil) },
					tableConfig: .init(
						header: .init(styleSpecifier: ""),
						headerStyling: .terminalOnly,
						headerStyleSequences: .default,
						separator: .init(pattern: pattern, broken: broken),
						columnSpacing: "  ",
					),
				)
				== "name  id\n\(separatorLine)\nxy    1\nabc   22",
		)
	}

	@Test
	func `key-value & JSON omit an absent formatted value, but not a fallback for an absent field`() throws {
		let fieldSpecs = try resolvedFieldsConfig(
			from: "a,b:%N%n+none+,c:%n,d,e:.round,f:..uppercase",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs
		let object = JSON.Object([("d", .null), ("f", .null)])
		#expect(
			try fieldSpecs.map { try $0.keyValueRow(for: object[nodeKey: .init(rawValue: $0.name)])?.value }
				== [nil, "none", nil, nil, nil, nil],
		)
		#expect(
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrder: .positional).fields.map(\.key.rawValue)
				== ["b", "d", "f"],
		)
	}

	@Test
	func `table & sorting use a field's last member, while key-value & JSON output each member`() throws {
		let object = JSON.Object([("a", .string("x")), ("b", .string("y")), ("a", .string("z"))])
		let fieldSpecs = try resolvedFieldsConfig(
			from: "a:..uppercase,b",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs
		#expect(try [object].table(fieldSpecs: fieldSpecs, tableConfig: .default) == "Z  y")
		#expect(
			try object.keyValueRows(
				fieldSpecs: fieldSpecs,
				fieldOrder: .positional,
				keyValueConfig: parseKeyValueConfig("fL=:R:"),
			)
			.map(\.row)
			== ["a=X", "a=Z", "b=y"],
		)
		#expect(
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrder: .positional).description
				== #"{"a":"X","a":"Z","b":"y"}"#,
		)
		#expect(object[lastNodeKey: "a"]?.stringValue == "z")
	}

	@Test(arguments: [("D", ["x", "y", "z"]), ("D-", ["z", "y", "x"])])
	func `document-order orders each member at its own position`(order: String, expected: [String]) throws {
		let object = JSON.Object([("a", .string("x")), ("b", .string("y")), ("a", .string("z"))])
		let fieldOrder = try resolvedFieldsConfig(
			from: "/" + order,
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldOrder
		#expect(
			fieldOrder.itemMembers(["a", "b"].map(FieldSpec.default(forName:)), for: object).map(\.value?.stringValue)
				== expected,
		)
	}
}
