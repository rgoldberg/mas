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
			from: "a,b:%N%n+none+,c:%n,d",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs
		let object = JSON.Object([("d", .null)])
		#expect(try fieldSpecs.map { try object.keyValueRow(for: $0)?.value } == [nil, "none", nil, nil])
		#expect(try object.jsonObject(fieldSpecs: fieldSpecs).fields.map(\.key.rawValue) == ["b", "d"])
	}
}
