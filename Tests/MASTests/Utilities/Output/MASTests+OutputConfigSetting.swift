//
// MASTests+OutputConfigSetting.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
@testable private import mas
internal import Testing

private enum PayloadError: Equatable, Error {
	case danglingEscape
	case invalidStyleSpecifier(String)
}

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
		#expect(try parseOutputConfigSettingPayload(&input, danglingEscapeError: PayloadError.danglingEscape) == payload)
		#expect(input == remainder)
	}

	@Test(arguments: ["\\", "a\\", "a\\\\\\"])
	func `a text payload ending in an escape prefix throws the given dangling-escape error`(value: String) {
		var input = value[...]
		#expect(throws: PayloadError.danglingEscape) {
			try parseOutputConfigSettingPayload(&input, danglingEscapeError: PayloadError.danglingEscape)
		}
	}

	@Test(
		arguments: [
			("", "", ""),
			(" 1;4 :c", "1;4", "c"),
			("1 ; 4", "1 ; 4", ""),
			("\\ 1\\ :", " 1 ", ""),
			("\\b:", "b", ""),
			("38;5;208", "38;5;208", ""),
		],
	)
	func `a style specifier ignores outer bare whitespace & allows escaped ASCII letters`(
		value: String,
		styleSpecifier: String,
		remainder: String,
	) throws {
		var input = value[...]
		#expect(
			try parseStyleSpecifier(
				&input,
				danglingEscapeError: PayloadError.danglingEscape,
				invalidStyleSpecifierError: PayloadError.invalidStyleSpecifier,
			)
				== styleSpecifier,
		)
		#expect(input == remainder)
	}

	@Test(arguments: ["b", "1b", " 1;4b "])
	func `a style specifier containing a bare ASCII letter throws the given style specifier error`(value: String) {
		var input = value[...]
		#expect(throws: PayloadError.invalidStyleSpecifier(value)) {
			try parseStyleSpecifier(
				&input,
				danglingEscapeError: PayloadError.danglingEscape,
				invalidStyleSpecifierError: PayloadError.invalidStyleSpecifier,
			)
		}
	}

	@Test
	func `styling wraps a string in style sequences, for a non-terminal only if always styled`() {
		#expect(
			styled("x", specifier: "1;4", sequences: .default, isAlwaysStyled: true) == "\u{1B}[1;4mx\u{1B}[0m",
		)
		#expect(
			styled("x", specifier: "1", sequences: .init(prefix: "<", suffix: ">", reset: "</>"), isAlwaysStyled: true)
				== "<1>x</>",
		)
		#expect(
			styled("x", specifier: "1", sequences: .default, isAlwaysStyled: false)
				== (FileHandle.standardOutput.isTerminal ? "\u{1B}[1mx\u{1B}[0m" : "x"),
		)
	}

	@Test(arguments: [true, false])
	func `styling with an empty style specifier leaves a string unstyled`(isAlwaysStyled: Bool) {
		#expect(styled("x", specifier: "", sequences: .default, isAlwaysStyled: isAlwaysStyled) == "x")
	}
}
