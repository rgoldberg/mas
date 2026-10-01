//
// MASTests+Transform.swift
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
			("abc def", "Abc def"),
			("\"hello\"", "\"Hello\""),
			("@home", "@Home"),
			("  élan", "  Élan"),
			("ǆemal", "ǅemal"),
			("ßa", "Ssa"),
			("1 x", "1 x"),
			("1st", "1st"),
			("$abc", "$abc"),
			("©apple", "©apple"),
			("", ""),
		],
	)
	func `initialTitlecase titlecases only the initial character`(input: String, expected: String) {
		#expect(Transform.initialTitlecase.applied(to: input) == expected)
	}

	@Test(
		arguments: [
			("-1.50", "1.50"),
			("+5", "5"),
			("-1.5e-3", "1.5e-3"),
			("5", "5"),
			("-0", "0"),
		],
	)
	func `absoluteValue removes only the leading sign`(input: String, expected: String) {
		#expect(Transform.absoluteValue.applied(to: input) == expected)
	}

	@Test(
		arguments: [
			// Positional
			("2.5", "3"),
			("-2.5", "-3"),
			("+2.4", "+2"),
			("-0.4", "0"),
			("2.50", "3"),
			(".5", "1"),
			("5.", "5"),
			("-999.5", "-1000"),
			("123456789012345678", "123456789012345678"),
			("123456789012345678.5", "123456789012345679"),
			// Scientific
			("1.5e3", "1.5e3"),
			("1.25e1", "1.3e1"),
			("1.25E1", "1.3E1"),
			("1.5e+3", "1.5e+3"),
			("9.96e+1", "1e+2"),
			("-1.5e3", "-1.5e3"),
			("1e+30", "1e+30"),
			("5e-1", "1e0"),
			("4e-1", "0e0"),
			("15e2", "1.5e3"),
			("1.23456789012345678901234567890123456789012e45", "1.23456789012345678901234567890123456789012e45"),
			// Not a finite decimal number
			("inf", "inf"),
			("0x10", "0x10"),
		],
	)
	func `round rounds exactly, retaining the value's notation`(input: String, expected: String) {
		#expect(Transform.round.applied(to: input) == expected)
	}

	@Test(
		arguments: [
			// Abbreviations take precedence over IANA Time Zone Database identifiers
			("EST", "America/New_York"),
			("est", "America/New_York"),
			("EDT", "America/New_York"),
			("CET", "Europe/Paris"),
			// IANA Time Zone Database identifiers, including ones absent from
			// `TimeZone.knownTimeZoneIdentifiers`
			("Asia/Tokyo", "Asia/Tokyo"),
			("asia/tokyo", "Asia/Tokyo"),
			("etc/gmt+5", "Etc/GMT+5"),
			("us/eastern", "US/Eastern"),
		],
	)
	func `resolves a named time zone code`(code: String, identifier: String) {
		#expect(timeZone(forCode: code)?.identifier == identifier)
	}

	@Test(
		arguments: [
			("Z", 0),
			("z", 0),
			("+05:30", 19800),
			("+5", 18000),
			("-05", -18000),
			("+18", 64800),
			("GMT+5", 18000),
			("utc+5", 18000),
			("UTC+5:30", 19800),
			("gmt-08:00", -28800),
		],
	)
	func `resolves a UTC offset time zone code`(code: String, secondsFromGMT: Int) {
		#expect(timeZone(forCode: code)?.secondsFromGMT() == secondsFromGMT)
	}

	@Test(arguments: ["system", "SYSTEM"])
	func `system identifies the system time zone`(code: String) throws {
		#expect(try inSystemTimeZone("Asia/Tokyo") { timeZone(forCode: code)?.identifier } == "Asia/Tokyo")
	}

	@Test(arguments: ["", "5", "+0530", "+05-30", "+05:60", "+19", "+18:30", "UTC+", "EST+5", "America", "Nowhere/Land"])
	func `rejects an invalid time zone code`(code: String) {
		#expect(timeZone(forCode: code) == nil)
	}
}
