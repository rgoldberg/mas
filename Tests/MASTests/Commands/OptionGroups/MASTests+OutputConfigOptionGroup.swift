//
// MASTests+OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `normalizing gives each optional-value output option its value after = with a NUL prefix`() {
		#expect(
			normalizingOutputOptions(in: ["--json", "1", "--key-value=", "--table=P", "--fields", "name"])
				== ["--json=\0", "1", "--key-value=\0", "--table=\0P", "--fields", "name"],
		)
	}

	@Test
	func `normalizing retains every argument after a -- terminator`() {
		#expect(normalizingOutputOptions(in: ["--json", "--", "--table"]) == ["--json=\0", "--", "--table"])
	}
}
