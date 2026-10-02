//
// MASTests+OutputConfigSetting.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
@testable private import mas
internal import Testing

private struct DanglingEscape: Equatable, Error {}

private extension MASTests {
	@Test(
		arguments: [
			("", "", ""),
			("ab", "ab", ""),
			("ab:", "ab", ""),
			("ab:cd", "ab", "cd"),
			(":cd", "", "cd"),
			("a::", "a", ":"),
			(" a b :c", " a b ", "c"),
			("a\\:b:c", "a:b", "c"),
			("a\\\\:b", "a\\", "b"),
			("\\ :", " ", ""),
		],
	)
	func `a text payload terminates at its 1st bare terminator, consuming whitespace & escape sequences`(
		value: String,
		payload: String,
		remainder: String,
	) throws {
		var input = value[...]
		#expect(
			try parseOutputConfigSettingPayload(&input, supportsEscapeSequences: true, danglingEscapeError: DanglingEscape())
				== payload,
		)
		#expect(input == remainder)
	}

	@Test(arguments: [("a\\b:c", "a\\b", "c"), ("a\\:b", "a\\", "b"), ("a\\", "a\\", "")])
	func `a non-text payload treats a backslash as an ordinary character`(
		value: String,
		payload: String,
		remainder: String,
	) throws {
		var input = value[...]
		#expect(
			try parseOutputConfigSettingPayload(&input, supportsEscapeSequences: false, danglingEscapeError: DanglingEscape())
				== payload,
		)
		#expect(input == remainder)
	}

	@Test(arguments: ["\\", "a\\", "a\\\\\\"])
	func `a text payload ending in an escape prefix throws the given dangling-escape error`(value: String) {
		var input = value[...]
		#expect(throws: DanglingEscape()) {
			try parseOutputConfigSettingPayload(&input, supportsEscapeSequences: true, danglingEscapeError: DanglingEscape())
		}
	}

	@Test(arguments: [("", ""), (" ", ""), ("1", "1"), ("1;4", "1;4"), (" 1 ; 4 ", "1;4"), ("38;5;208", "38;5;208")])
	func `valid SGR parameters normalize by removing outer whitespace around each parameter`(
		text: String,
		normalized: String,
	) {
		#expect(normalizedSGRParameters(text) == normalized)
	}

	@Test(arguments: [";", "1;", ";1", "1;;4", "x", "1;x", "-1", "1.5", "1 4"])
	func `invalid SGR parameters normalize to nil`(text: String) {
		#expect(normalizedSGRParameters(text) == nil)
	}

	@Test
	func `styling wraps a string in SGR escape sequences, for a non-terminal only if always styled`() {
		#expect(styled("x", sgrParameters: "1;4", isAlwaysStyled: true) == "\u{1B}[1;4mx\u{1B}[0m")
		#expect(
			styled("x", sgrParameters: "1", isAlwaysStyled: false)
				== (FileHandle.standardOutput.isTerminal ? "\u{1B}[1mx\u{1B}[0m" : "x"),
		)
	}

	@Test(arguments: [true, false])
	func `styling with empty SGR parameters leaves a string unstyled`(isAlwaysStyled: Bool) {
		#expect(styled("x", sgrParameters: "", isAlwaysStyled: isAlwaysStyled) == "x")
	}
}
