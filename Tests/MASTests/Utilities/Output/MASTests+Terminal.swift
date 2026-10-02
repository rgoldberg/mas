//
// MASTests+Terminal.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: [("", 0), ("a", 1), ("é", 1), ("中", 2), ("a中é", 4), ("\t", 0)])
	func `a string's terminal width is its UTF-8 terminal column count, regardless of the environment's locale`(
		string: String,
		terminalWidth: Int,
	) {
		#expect(string.terminalWidth == terminalWidth)
	}
}
