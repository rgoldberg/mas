//
// MASTests+OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: [("--json", "--json=\0"), ("--key-value=", "--key-value=\0"), ("--table=P", "--table=\0P")])
	func `normalizing gives an optional-value output option its value after = with a NUL prefix`(
		option: String,
		normalized: String,
	) {
		#expect(normalizingOutputOptions(in: [option, "1"]) == [normalized, "1"])
	}

	@Test
	func `normalizing retains other options`() {
		#expect(
			normalizingOutputOptions(in: ["--json", "1", "--fields", "name"]) == ["--json=\0", "1", "--fields", "name"],
		)
	}

	@Test
	func `normalizing removes every output option that a later one overrides`() {
		#expect(
			normalizingOutputOptions(in: ["--json=P", "1", "--table", "--json=a"]) == ["1", "--json=\0a"],
		)
	}

	@Test
	func `normalizing retains every argument after a -- terminator`() {
		#expect(normalizingOutputOptions(in: ["--json", "--", "--table"]) == ["--json=\0", "--", "--table"])
	}
}
