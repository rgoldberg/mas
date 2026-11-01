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

	@Test(
		arguments: [
			(Alignment.start, "id", "1", "333"),
			(.centerStart, "id", " 1", "333"),
			(.centerEnd, " id", " 1", "333"),
			(.end, " id", "  1", "333"),
		],
	)
	func `a table's last column has no trailing spaces, regardless of its alignment`(
		alignment: Alignment,
		headerCell: String,
		dataCell1: String,
		dataCell2: String,
	) throws {
		#expect(
			try [
				JSON.Object([("name", .string("xy")), ("id", .number(1))]),
				.init([("name", .string("abc")), ("id", .number(333))]),
			]
				.table(
					fieldSpecs: [
						.init(name: "name", label: "name", format: .default(fieldName: "name"), sortSpec: nil),
						.init(name: "id", label: "id", format: .default(fieldName: "id"), sortSpec: nil, alignment: alignment),
					],
					tableConfig: .init(
						header: .init(styleSpecifier: ""),
						headerStyling: .terminalOnly,
						headerStyleSequences: .default,
						separator: nil,
						columnSpacing: "  ",
					),
				)
				== "name  \(headerCell)\nxy    \(dataCell1)\nabc   \(dataCell2)",
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
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrder: .positional(.init())).fields.map(\.key.rawValue)
				== ["b", "d", "f"],
		)
	}

	@Test
	func `a leader's width is measured from its item's rendered keys, excluding omitted pairs' keys`() throws {
		#expect(
			try JSON.Object([("a", .string("1")), ("b", .null), ("c", .string("2"))])
				.keyValueRows(
					fieldSpecs: [("a", "a\t"), ("b", "bbbb"), ("c", "c")]
						.map { .init(name: $0, label: $1, format: .default(fieldName: $0), sortSpec: nil) },
					fieldOrder: .positional(.init()),
					keyValueConfig: parseKeyValueConfig("F.:L:R:"),
				)
				.map(\.row)
				== ["a␉.1", "c..2"],
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
				fieldOrder: .positional(.init()),
				keyValueConfig: parseKeyValueConfig("fL=:R:"),
			)
			.map(\.row)
			== ["a=X", "a=Z", "b=y"],
		)
		#expect(
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrder: .positional(.init())).description
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

	@Test
	func `JSON outputs each field spec's key-value pair, even if its key repeats another's`() throws {
		let fieldSpecs = try resolvedFieldsConfig(
			from: "name=x,version=x",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs
		let object = JSON.Object([("name", .string("A")), ("version", .string("1"))])
		#expect(
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrder: .positional(.init()))
				.description == #"{"x":"A","x":"1"}"#,
		)
	}
}
