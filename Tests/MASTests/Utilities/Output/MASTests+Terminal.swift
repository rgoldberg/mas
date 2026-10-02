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

	@Test(
		arguments: [
			("e\u{301}", 1), // Combining acute accent
			("😀", 2),
			("👍🏽", 2), // Modifier sequence
			("🇺🇸", 2), // Flag sequence
			("❤", 1), // Text presentation by default
			("❤️", 2), // Emoji presentation sequence
			("1️⃣", 2), // Keycap sequence
			("👨‍👩‍👧", 2), // ZWJ sequence
			("🏳️‍🌈", 2), // ZWJ sequence starting with an emoji presentation sequence
			("a👨‍👩‍👧b", 4),
		],
	)
	func `a combined character's terminal width is that of the character as a whole, not the sum of its scalars'`(
		string: String,
		terminalWidth: Int,
	) {
		#expect(string.terminalWidth == terminalWidth)
	}
}
