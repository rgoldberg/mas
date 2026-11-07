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
	func `a table separator fills its width, except a 0-width separator, which is rendered once`(
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
						header: .init(stylingSpecifier: ""),
						styling: .supportedOnly,
						stylingSequences: .default,
						separator: .init(pattern: pattern, broken: broken),
						columnSpacing: "  ",
					),
				)
				== "name  id\n\(separatorLine)\nxy    1\nabc   22",
		)
	}

	@Test(arguments: [("\t", "----\t--"), (" \t ", "-----\t---"), ("\t\t", "----\t\t--")])
	func `an unbroken table separator retains each tab of each column spacing in place`(
		columnSpacing: String,
		separatorLine: String,
	) throws {
		#expect(
			try [JSON.Object([("name", .string("xy")), ("id", .number(1))])]
				.table(
					fieldSpecs: ["name", "id"].map { .init(name: $0, label: $0, format: .default(fieldName: $0), sortSpec: nil) },
					tableConfig: .init(
						header: .init(stylingSpecifier: ""),
						styling: .supportedOnly,
						stylingSequences: .default,
						separator: .init(pattern: "-", broken: false),
						columnSpacing: columnSpacing,
					),
				)?
				.split(separator: "\n")[1]
				== separatorLine[...],
		)
	}

	@Test(arguments: [
		("fL=:R:", "Notes=a\n      b"),
		("fL\t:R:", "Notes\ta\n     \tb"),
		("F.:L:R\t:", "Notes.\ta\n      \tb"),
		("fL\n:R  :", "Notes\n  a\n  b"),
		("fL=\r\n:R\t:", "Notes=\r\n\ta\n\tb"),
	])
	func `a value's later line is indented by its row's text before the value, retaining each tab`(
		keyValueConfig: String,
		row: String,
	) throws {
		#expect(
			try JSON.Object([("notes", .string("a\nb"))])
				.keyValueRows(
					fieldSpecs: [.init(name: "notes", label: "Notes", format: .default(fieldName: "notes"), sortSpec: nil)],
					fieldOrders: .init(),
					keyValueConfig: parseKeyValueConfig(keyValueConfig),
				)
				.map(\.row)
				== [row],
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
						header: .init(stylingSpecifier: ""),
						styling: .supportedOnly,
						stylingSequences: .default,
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
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrders: .init()).fields.map(\.key.rawValue)
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
					fieldOrders: .init(),
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
				fieldOrders: .init(),
				keyValueConfig: parseKeyValueConfig("fL=:R:"),
			)
			.map(\.row)
			== ["a=X", "a=Z", "b=y"],
		)
		#expect(
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrders: .init()).description
				== #"{"a":"X","a":"Z","b":"y"}"#,
		)
		#expect(object[lastNodeKey: "a"]?.stringValue == "z")
	}

	@Test(arguments: [("D", ["x", "y", "z"]), ("D-", ["z", "y", "x"])])
	func `document-order orders each member at its own position`(order: String, expected: [String]) throws {
		let object = JSON.Object([("a", .string("x")), ("b", .string("y")), ("a", .string("z"))])
		let fieldOrders = try resolvedFieldsConfig(
			from: "/" + order,
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldOrders
		#expect(
			fieldOrders.itemMembers(["a", "b"].map(FieldSpec.default(forName:)), for: object).map(\.value?.stringValue)
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
			try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrders: .init())
				.description == #"{"x":"A","x":"1"}"#,
		)
	}

	@Test(
		arguments: [
			("+01.50", "1.50"),
			(".5", "0.5"),
			("-.5", "-0.5"),
			("+.5e+03", "0.5e+03"),
			("000", "0"),
			("00.5", "0.5"),
			("-00.0", "-0.0"),
			("1.50", "1.50"),
			("0.50E+03", "0.50E+03"),
		],
	)
	func `only JSON output modifies a coerced number's text, only as JSON number syntax requires`(
		text: String,
		jsonText: String,
	) throws {
		let fieldSpecs = try resolvedFieldsConfig(
			from: "a:%.n",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs
		let objects = [JSON.Object([("a", .string(text))])]
		#expect(
			try objects.json(fieldSpecs: fieldSpecs, fieldOrders: .init(), jsonConfig: .default)
				== #"{"a":\#(jsonText)}"#,
		)
		#expect(try objects.table(fieldSpecs: fieldSpecs, tableConfig: .default) == text)
		#expect(try fieldSpecs[0].keyValueRow(for: .string(text))?.value == text)
	}

	@Test
	func `JSON output renders a number with trivia as a string, retaining its text`() throws {
		let fieldSpecs = try resolvedFieldsConfig(
			from: "a:%.:,,,,,[$]:n",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs
		#expect(
			try [JSON.Object([("a", .string("$+01.50"))])]
				.json(fieldSpecs: fieldSpecs, fieldOrders: .init(), jsonConfig: .default)
				== #"{"a":"$+01.50"}"#,
		)
	}
}
