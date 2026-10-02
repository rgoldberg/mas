//
// MASTests+NumberConventions.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			(NumberConventions.canonical, "1234567.25", "1,234,567.25"),
			(.canonical, "-1234", "-1,234"),
			(.canonical, "+1234", "+1,234"),
			(.canonical, "123", "123"),
			(.canonical, "1.5e+20", "1.5e+20"),
			(indianConventions, "12345678", "1,23,45,678"),
			(germanConventions, "1234.5", "1.234,5"),
			(anySizeConventions, "12345678", "12345678"),
			(fourDigitGroupConventions, "123456789", "1'2345'6789"),
		],
	)
	func `formats a canonical number per number conventions`(
		conventions: NumberConventions,
		number: String,
		expected: String,
	) {
		#expect(conventions.formatted(number) == expected)
	}

	@Test(
		arguments: [
			(NumberConventions.canonical, "1,234.5x", String?.some("1234.5"), "x"),
			(.canonical, "-1,234,567", "-1234567", ""),
			(.canonical, "1234,567", "1234", ",567"),
			(.canonical, "1,2345", "1", ",2345"),
			(.canonical, "1,234,5678", "1234", ",5678"),
			(.canonical, ".5e2!", "0.5e2", "!"),
			(.canonical, "+01.50e+3", "1.5e+3", ""),
			(.canonical, "5e", "5", "e"),
			(.canonical, "5.", "5", "."),
			(.canonical, "x5", nil, ""),
			(.canonical, "-", nil, ""),
			(indianConventions, "1,23,45,678", "12345678", ""),
			(indianConventions, "1,234,567", "1234", ",567"),
			(anySizeConventions, "1,23,4567", "1234567", ""),
			(germanConventions, "1.234,56", "1234.56", ""),
			(spaceConventions, "1 234 MB", "1234", " MB"),
		],
	)
	func `finds the longest number at the start of a string`(
		conventions: NumberConventions,
		string: String,
		number: String?,
		rest: String,
	) {
		let prefix = conventions.numberPrefix(of: string[...])
		#expect(prefix?.number == number)
		#expect(prefix.map { String(string[$0.end...]) } ?? "" == rest)
	}

	@Test(
		arguments: [
			(NumberConventions.canonical, "1,234 & 5", String?.some("1234"), " & 5"),
			(.canonical, "5,678.9x", "5678.9", "x"),
			(.canonical, "1,2345", "1", ",2345"),
			(.canonical, "0.123,456", "0.123", ",456"),
			(.canonical, "a,b", nil, "a,b"),
			(.canonical, "1,234.5e3x", "1234500", "x"),
			(.canonical, "2E-1!", "0.2", "!"),
			(.canonical, "3e+", "3", "e+"),
			(germanConventions, "1.234,5", "1234.5", ""),
		],
	)
	func `parses a grouped number's value, removing its digit group separators`(
		conventions: NumberConventions,
		string: String,
		number: String?,
		rest: String,
	) {
		let prefix = conventions.groupedNumberPrefix(of: string[...])
		#expect(prefix?.number == number.flatMap(DecimalNumber.init))
		#expect(prefix.map { String(string[$0.end...]) } ?? string == rest)
	}

	@Test
	func `a locale's number conventions come from its number formatting`() {
		#expect(NumberConventions(locale: .init(identifier: "de_DE")) == germanConventions)
		#expect(NumberConventions(locale: .init(identifier: "en_IN")).secondaryDigitGroupSize == 2)
	}

	@Test(
		arguments: [
			("a,b,c", [String?.some("a"), "b", "c"]),
			(" a , \\ b\\ ,c", ["a", " b ", "c"]),
			("a", ["a", nil, nil]),
			(",b", [nil, "b", nil]),
			(", ,c", [nil, nil, "c"]),
			("", [nil, nil, nil]),
			("a,b,c,d", ["a", "b", "c,d"]),
		],
	)
	func `parses an argument list`(arguments: String, expected: [String?]) throws {
		var input = "\(arguments):rest"[...]
		#expect(
			try parseArguments(
				&input,
				count: 3,
				terminator: ":",
				isLastArgumentSeparatorTerminated: false,
				invalidArgumentsError: .invalidNumberCoercionArguments,
			)
				== expected,
		)
		#expect(input == ":rest")
	}

	@Test
	func `reports too many arguments iff the last argument is separator-terminated`() {
		var input = "a,b,c,d:"[...]
		#expect(throws: ParsingError.invalidNumberCoercionArguments) {
			try parseArguments(
				&input,
				count: 3,
				terminator: ":",
				isLastArgumentSeparatorTerminated: true,
				invalidArgumentsError: .invalidNumberCoercionArguments,
			)
		}
	}

	@Test(
		arguments: [
			([String?.none, nil, nil, nil, nil], NumberConventions.canonical),
			(["de_DE", nil, nil, nil, nil], germanConventions),
			(["de_DE", nil, "4", nil, nil], .init(
				digitGroupSeparator: ".",
				digitGroupSize: 4,
				secondaryDigitGroupSize: 0,
				decimalSeparator: ",",
			)),
			([nil, " ", nil, nil, nil], spaceConventions),
			([nil, nil, nil, "2", nil], indianConventions),
			([nil, ".", nil, nil, ","], .init(
				digitGroupSeparator: ".",
				digitGroupSize: 3,
				secondaryDigitGroupSize: 0,
				decimalSeparator: ",",
			)),
			(["system", nil, nil, nil, nil], .init(locale: .current)),
			(["en-US", nil, nil, nil, nil], .init(locale: .init(identifier: "en_US"))),
		],
	)
	func `number-format-arguments default to the base conventions`(
		arguments: [String?],
		expected: NumberConventions,
	) throws {
		#expect(
			try numberConventions(
				from: arguments[...],
				defaultBaseConventions: .canonical,
				invalidArgumentsError: .invalidTransformArguments(name: "x"),
			)
				== expected,
		)
	}

	@Test(
		arguments: [
			([String?.some("nowhere"), nil, nil, nil, nil], ParsingError.invalidLocaleIdentifier("nowhere")),
			([nil, nil, "x", nil, nil], .invalidTransformArguments(name: "x")),
			([nil, nil, nil, "-1", nil], .invalidTransformArguments(name: "x")),
			([nil, ".", nil, nil, nil], .invalidTransformArguments(name: "x")),
		],
	)
	func `reports invalid number-format-arguments`(arguments: [String?], error: ParsingError) {
		#expect(throws: error) {
			try numberConventions(
				from: arguments[...],
				defaultBaseConventions: .canonical,
				invalidArgumentsError: .invalidTransformArguments(name: "x"),
			)
		}
	}
}

private let germanConventions =
	NumberConventions(digitGroupSeparator: ".", digitGroupSize: 3, secondaryDigitGroupSize: 0, decimalSeparator: ",")
private let indianConventions =
	NumberConventions(digitGroupSeparator: ",", digitGroupSize: 3, secondaryDigitGroupSize: 2, decimalSeparator: ".")
private let anySizeConventions =
	NumberConventions(digitGroupSeparator: ",", digitGroupSize: 0, secondaryDigitGroupSize: 0, decimalSeparator: ".")
private let spaceConventions =
	NumberConventions(digitGroupSeparator: " ", digitGroupSize: 3, secondaryDigitGroupSize: 0, decimalSeparator: ".")
private let fourDigitGroupConventions =
	NumberConventions(digitGroupSeparator: "'", digitGroupSize: 4, secondaryDigitGroupSize: 0, decimalSeparator: ".")
