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
						header: .init(sgrCodes: ""),
						headerStyling: .terminalOnly,
						separator: .init(pattern: pattern, broken: broken),
						columnSpacing: "  ",
					),
				)
				== "name  id\n\(separatorLine)\nxy    1\nabc   22",
		)
	}
}
