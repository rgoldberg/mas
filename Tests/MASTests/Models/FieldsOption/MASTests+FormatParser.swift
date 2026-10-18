//
// MASTests+FormatParser.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			"%S%s+no+",
			"%.N%n+no+",
			#"%.:,,,,,\\[,\\]:N%n+no+"#,
			"%.B%b+no+",
			"%.T%t+no+",
			"%.F%f+no+",
			"%.D%d+no+",
			"%V%v+no+",
		],
	)
	func `no predicate whose output type is not any matches a structured value`(format: String) throws {
		#expect(try rendered(format, structuredValue) == "no")
	}

	@Test
	func `a number coercion parses a string, but not a structured value, whose text is a number between trivia`()
	throws {
		let format = #"%.:,,,,,\\[,\\]:N%n+no+"#
		#expect(try rendered(format, .string("[1]")) == "[1]")
		#expect(try rendered(format, .array([.number(1)])) == "no")
	}

	@Test
	func `coerces a structured value to its compact JSON text`() throws {
		#expect(try rendered("(%i)", structuredValue) == #"(["é",{"a":null}])"#)
	}

	@Test(
		arguments: [
			// fields-format.md's examples
			("%.N%n (%i)++", JSON.Node.string("4.50"), String?.some("4.5 (4.50)")),
			("%mN.absoluteValue+bI..uppercase++", .number(-5), "5"),
			("%mN.absoluteValue+bI..uppercase++", .bool(true), "true"),
			("%mN.absoluteValue+bI..uppercase++", .string("abc"), "ABC"),
			("%MN.absoluteValue+b+Status Unknown+", .number(-5), "5"),
			("%MN.absoluteValue+b+Status Unknown+", .bool(false), "false"),
			("%MN.absoluteValue+b+Status Unknown+", .string("x"), "Status Unknown"),
			(".scale:10,6,,0:", .number(12_345_678), "12"),
		],
	)
	func `renders fields-format.md's examples`(format: String, value: JSON.Node, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			// Nullary: on failure, formatting aborts
			("%u", JSON.Node?.none, String?.none),
			("%u", .string("x"), nil),
			("x%ny", .string("a"), nil),
			// Nullary abort-on-success: on failure, the field value
			("%-u", .string("x"), "x"),
			("%-u", .null, nil),
			// Non-nullary abort-on-failure
			("%+N.round+", .number(5.6), "6"),
			("[%+N.round+]", .string("x"), nil),
			// Non-nullary abort-on-success
			("%-Nnot a number+", .string("x"), "not a number"),
			("[%-Nnot a number+]", .number(5), nil),
			// Binary
			("%N%n+fail+", .number(5), "5"),
			("%N%n+fail+", .string("x"), "fail"),
			("[%N++]", .string("x"), "[]"),
			("%S.uppercase++", .string("abc"), "ABC"),
			("%.T%t+no+", .string("true"), "true"),
			("%.T%t+no+", .string("false"), "no"),
			("%T+no+", .string("true"), "no"),
			("%E(empty)+%i+", .string(""), "(empty)"),
			("%W(blank)+%i+", .string(" \t"), "(blank)"),
			("%W(blank)+%i+", .string(" a "), " a "),
			// An absent block defaults to an empty string
			("[%N+fail+]", .number(5), "[]"),
			("[%N +fail+]", .number(5), "[]"),
			("[%V+%i+]", .string("1.2"), "[]"),
			("[%V+%i+]", .string("v1.2"), "[v1.2]"),
			("[%-N+]", .string("x"), "[]"),
			("[%w]", .string(" \t"), "[ \t]"),
			("[%e]", .null, "[]"),
		],
	)
	func `renders scalar conditional placeholders`(format: String, value: JSON.Node?, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%.:,,,,,.*,.*:n", JSON.Node.string("US$1,234.50"), String?.some("US$1234.5")),
			("%.:,,,,,.*,.*:N.round++", .string("US$1,234.50"), "US$1235"),
			("%.:,,,,,.*,.*:N.absoluteValue++", .string("-3 MB"), "3 MB"),
			("[%.n]", .string("US$5"), nil),
			("[%.:,,,,,.*,.*:n]", .string("none"), nil),
			("%.n", .string("4.50"), "4.5"),
			("[%.n]", .string("4.5a"), nil),
			("[%.n]", .string("nan"), nil),
			("[%.n]", .string("0x10"), nil),
			("%.n", .string("-1e3"), "-1e3"),
			("%.n", .string("12345678901234567890.123456789000"), "12345678901234567890.123456789"),
			("%.n", .string("+007.50"), "7.5"),
			("%.n", .string("-0.0"), "0"),
			("%n", .number(4.5), "4.5"),
			// fields-format.md's examples
			("%.:de:n", .string("1.234,56"), "1234.56"),
			("%.:,,,,,[A-Z]*[$]:n", .string("US$4.99"), "US$4.99"),
			("%.:,,,,,[A-Z]*[$]:n", .string("$4.99"), "$4.99"),
			("[%.:,,,,,[A-Z]*[$]:n]", .string("4.99"), nil),
			("%.:,,,,,,.*:n", .string("1,2345"), "1,2345"),
			// Number coercion's base conventions are canonical absent a locale
			("[%.:de:n]", .string("1,234.56"), nil),
			("%.::n", .string("1,234.5"), "1234.5"),
			("%.:,\\ ,,,\\,:n", .string("1 234,5"), "1234.5"),
			("%.:,,2:n", .string("12,34"), "1234"),
			("%.:,,0:n", .string("1,23,4567"), "1234567"),
			("%.:,,3,2:n", .string("12,34,567"), "1234567"),
			("[%.:,,3,2:n]", .string("1,234,567"), nil),
			// The trivia prefix is the shortest one that a number succeeds
			("%.:,,,,,\\\\d:n", .string("15"), "15"),
			("%.:,,,,,\\\\\\$:n", .string("$5"), "$5"),
			("%.:,,,,,.*,.*:N.absoluteValue++", .string("x-1.50 y"), "x1.5 y"),
			("[%.:,,,,,.*:n]", .string("5 MB"), nil),
			("%.:,,,,, [$] :n", .string("$5"), "$5"),
			// The trivia suffix regex is the last argument, so its `,` is unescaped
			("%.:,,,,,,,.*:n", .string("5,x"), "5,x"),
			("[%.:,,,,,,,.*:n]", .string("5x"), nil),
		],
	)
	func `renders coerced number placeholders`(format: String, value: JSON.Node, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%i", "v"),
			("%l", "L"),
			("%k", "n"),
			("%I..uppercase+", "V"),
			("%L.uppercase+", "L"),
			("%K.uppercase+", "N"),
		],
	)
	func `renders unconditional placeholders`(format: String, expected: String) throws {
		#expect(try rendered(format, .string("v")) == expected)
	}

	@Test(
		arguments: [
			("%i  x %l ", JSON.Node.string("v"), "v  x L"), // Consumed between placeholders; ignored at the end
			("  x%i", .string("v"), "xv"), // Ignored at the start
			("x  %i", .string("v"), "x  v"), // Consumed before a placeholder
			("\\ x%i", .string("v"), " xv"), // Escaped whitespace is always consumed
			("%N (%n) ++", .number(5), "(5)"), // A block's leading & pre-terminator whitespace is ignored
			("%N%n (%i)  ++", .number(5), "5 (5)"),
		],
	)
	func `treats template-text outer bare whitespace per the escaping appendix`(
		format: String,
		value: JSON.Node,
		expected: String,
	) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(arguments: [("\\.x%i", ".xv"), ("\\:x%i", ":xv"), ("a\\%%i", "a%v"), ("%S\\+%s++", "+v")])
	func `escapes a template-text's syntax characters`(format: String, expected: String) throws {
		#expect(try rendered(format, .string("v")) == expected)
	}

	@Test(
		arguments: [
			("%S<%s>++", JSON.Node.string("x"), "<x>"),
			("%S<%S.uppercase+>++", .string("x"), "<X>"),
			("%.N%n/%i++", .string("4.50"), "4.5/4.50"),
			("%.B%b!++", .string("true"), "true!"),
			("%D%D.dateOnly+++", .string("2020-03-18T17:39:23Z"), "2020-03-18"),
			("%V[%v]++", .string("1.2"), "[1.2]"),
			("%V.uppercase+-+", .string("1.2b"), "1.2B"),
			("%V%V.uppercase+++", .string("1.2b"), "1.2B"),
			("%U(%u)++", .null, "()"),
		],
	)
	func `evaluates a block-placeholder against the enclosing matcher's value`(
		format: String,
		value: JSON.Node,
		expected: String,
	) throws {
		#expect(try inSystemTimeZone("America/New_York") { try rendered(format, value) } == expected)
	}

	@Test(
		arguments: [
			("%mn-s+", JSON.Node.number(5), String?.some("5")),
			("[%mn-s+]", .string("x"), nil),
			("%mn-s+", .bool(true), "true"),
			("%mn-SnotString++", .bool(true), "notString"),
			("%mn.Bbool:%b+k+", .string("true"), "bool:true"),
			("%mnK.uppercase++", .string("x"), "N"),
			("%mnl+", .string("x"), "L"),
			("[%mnL++]", .string("x"), "[]"),
			("%mn-v+", .string("x"), "x"),
			("[%Mn-V+++]", .string("x"), "[]"),
			("%Mnb+none+", .string("x"), "none"),
			("%Mnb++", .string("x"), ""),
		],
	)
	func `evaluates match placeholders`(format: String, value: JSON.Node, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			(".uppercase", JSON.Node.string("abc"), String?.some("ABC")),
			("..uppercase", .number(5), "5"),
			(".round", .number(5.6), "6"),
			("..round", .string("5.6"), "6"),
			("..round", .string("x"), nil),
			(".round.numberFormat:,.,3,,,:", .number(1_234_567.8), "1.234.568"),
			(".numberFormat:en,\\,,2:", .number(123_456), "12,34,56"),
			(".numberFormat:en,\\ ,3:", .number(1234), "1 234"),
			(".numberFormat:de_DE:", .number(1_234_567), "1.234.567"),
			// fields-format.md's examples
			(".numberFormat:de:", .number(1234.5), "1.234,5"),
			(".numberFormat:de,,,,:", .number(1234.5), "1.234,5"),
			(".numberFormat:en,\\,,3,2:", .number(12_345_678), "1,23,45,678"),
			(".numberFormat:en,,0,2:", .number(12_345_678), "12345678"),
			(".numberFormat:en,,4:", .number(12_345_678), "1234,5678"),
			(".numberFormat:en,.,,,,:", .number(-1234.5), "-1.234,5"),
			(".numberFormat:system:", .number(1), "1"),
			// Scientific notation is retained, its exponent verbatim
			("..numberFormat:de:", .string("12345.6E3"), "12.345,6E3"),
			("..numberFormat:en:", .string("-1234e-2"), "-1,234e-2"),
			("..scale:10,0,,2:.numberFormat:de:", .string("1.5e3"), "1.500,00"),
			("..:,,,,,[$]:numberFormat:de:", .string("$1234.5"), "$1.234,5"),
			("..:de:round", .string("1.234,56"), "1235"),
			("..:,,,,,.*,.*:round", .string("about 2.5 MB"), "about 3 MB"),
			("..:,,,,,.*,.*:numberFormat:en:", .string("~1234567 B"), "~1,234,567 B"),
			(".scale:10,6, ,0:", .number(12_345_678), "12"),
			(".scale: 10 , 6 , 2 , 1 :", .number(12_345_678), "12.0"),
			("..dateOnly", .string("2020-03-18"), "2020-03-18"),
			(".initialTitlecase", .string("abc def"), "Abc def"),
			(".trimWhitespace", .string("  x  "), "x"),
			(".lowercase", .string("ABC"), "abc"),
			(".absoluteValue", .number(-5.5), "5.5"),
			(".round", .number(1e30), "1e+30"),
			(".absoluteValue", .number(-1e30), "1e+30"),
			(".scale:10,0,,0:", .number(1e30), "1000000000000000000000000000000"),
			("..scale:10,3,,2:", .string("123456789012345678901234567890"), "123456789012345678901234567.89"),
			("..scale:10,0,3,0:", .string("123456"), "123000"),
			("..scale:10,0,2,3:", .string("-0.0001234"), "0.000"),
			("..scale:2,0,,0:", .string("1e20"), "1010110101111000111010111100010110101100011000100000000000000000000"),
			("..scale:10,0,100,100:", .string("1"), "1." + String(repeating: "0", count: 100)),
			("..scale:10,99999999999999999999,,2:", .string("-5e30"), "0.00"),
			("..scale:2,40,,0:", .string("1e12"), "1"),
			("..scale:10,30,,0:", .string("5e29"), "1"),
			(".scale:10,0,,0:", .number(1e99), "1" + String(repeating: "0", count: 99)),
			("..scale:10,0,2,0:", .string("9.95e98"), "1" + String(repeating: "0", count: 99)),
			("..scale:2,0,,0:", .string("1e-999999999999"), "0"),
			("..scale:10,999999999999,,0:", .string("1e1000000000000"), "10"),
			("..scale:2,3321928094887,,3:", .string("1e1000000000000"), "1.010"),
			("..scale:2,3321928094887,2,3:", .string("1e1000000000000"), "1.100"),
			("..scale:10,0,1,0:", .string("25"), "30"),
			("..scale:2,1,,0:", .string("1"), "1"),
			("..scale:3,1,,0:", .string("1.5"), "1"),
			("..scale:16,0,2,0:", .string("4095.99"), "1000"),
			("..scale:2,0,1,0:", .string("8"), "1000"),
			("..scale:10,0,1,1:", .string("100"), "100.0"),
			("..scale:6,0,1,0:", .string("0.1e-1"), "0"),
			("..scale:10,0,,0:", .string("1e100"), nil),
			("..scale:10,0,2,0:", .string("9.995e99"), nil),
			("..scale:2,0,,0:", .string("1e999999999999"), nil),
			(".numberFormat:en,\\,,18446744073709551616:", .number(12_345_678), "12345678"),
			("..round", .string("12345678901234567890.5"), "12345678901234567891"),
		],
	)
	func `applies a format-block's value-transform-pipeline`(format: String, value: JSON.Node, expected: String?)
	throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			(".uppercase", JSON.Node.number(5)),
			(".round", .string("5.6")),
			(".dateOnly", .string("not a date")),
			(".dateOnly", .string("17:39:23")),
			(".scale:10,0,,0:", .number(1e100)),
		],
	)
	func `an uncoerced transform on an input not of its input type is an error`(format: String, value: JSON.Node)
	throws {
		let fieldSpec = try parsedFieldSpec(format)
		#expect(throws: FormattingError.self) { try fieldSpec.format.rendered(value: value, label: "L", name: "n") }
	}

	@Test(
		arguments: [
			("%u", String?.none),
			("%e", nil),
			("%w", nil),
			("%U+-+", ""),
			("%S+-+", "-"),
			("[%u]", "[]"),
			("x%iy", "xy"),
			("[%s]", nil),
		],
	)
	func `an absent value matches u, e & w as null does & coerces to the empty string`(format: String, expected: String?)
	throws {
		#expect(try rendered(format, nil) == expected)
	}

	@Test(
		arguments: [".round", ".uppercase", "..uppercase", ".dateOnly", "..:de:numberFormat", ".endJustify.round"],
		[JSON.Node?.none, .null],
	)
	func `a null or absent value remains unchanged through every transform`(format: String, value: JSON.Node?)
	throws {
		#expect(try parsedFieldSpec(format).format.rendered(value: value, label: "L", name: "n")?.description == value?
			.description)
	}

	@Test(
		arguments: [
			(".endJustify", Justification.end),
			(".startJustify.centerEndJustify", .centerEnd),
			(".centerStartJustify..uppercase", .centerStart),
			(".uppercase", .start),
		],
	)
	func `extracts a format-transform-pipeline's justification`(format: String, justification: Justification) throws {
		#expect(try parsedFieldSpec(format).justification == justification)
	}

	@Test
	func `a pipeline of only format transforms passes the value through`() throws {
		#expect(try parsedFieldSpec(".endJustify")
			.format
			.rendered(value: .number(5), label: "L", name: "n")?
			.isNumber(5) == true)
	}

	@Test(
		arguments: [
			("%i", JSON.Node.null, "null"),
			("(%i)", .null, #""()""#),
			("", .null, #""""#),
			("%N%n+%i+", .null, "null"),
			("%N%n+%i+", .number(42), "42"),
			("%.N%n+%i+", .string("42"), "42"),
			(".round", .number(5), "5"),
			("..round", .string("+2.4"), "2"),
			(".scale:16,0,,0:", .number(255), #""ff""#),
			(".numberFormat", .number(5), #""5""#),
			("%t", .bool(true), "true"),
			("%u", .null, "null"),
			("%e", .string(""), #""""#),
			("%w", .string(" \t"), #"" \t""#),
			("%d", .string("2020-03-18"), #""2020-03-18""#),
			("%i", structuredValue, #"["é",{"a":null}]"#),
			("(%i)", structuredValue, #""([\"é\",{\"a\":null}])""#),
		],
	)
	func `renders a format's value at its type iff JSON supports it`(format: String, value: JSON.Node, json: String)
	throws {
		#expect(try parsedFieldSpec(format).format.rendered(value: value, label: "L", name: "n")?.description == json)
	}

	@Test(
		arguments: [
			("%d", JSON.Node.string("2020-03-18"), String?.some("2020-03-18")),
			("%D.timeZone:UTC:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%D.timeZone:utc:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%D.timeZone:Asia/Tokyo:++", .string("2020-03-18T17:39:23Z"), "2020-03-19T02:39:23+09:00"),
			("%D.timeZone:Europe/London:++", .string("2020-01-15T12:00:00+01:00"), "2020-01-15T11:00:00Z"),
			("%D.timeZone:Europe/London:++", .string("2020-07-15T12:00:00Z"), "2020-07-15T13:00:00+01:00"),
			("%D.timeZone:asia/tokyo:++", .string("2020-03-18T17:39:23Z"), "2020-03-19T02:39:23+09:00"),
			("%D.timeZone:-05\\:30:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T12:09:23-05:30"),
			("%D.timeZone:UTC:++", .number(0), "1970-01-01T00:00:00Z"),
			("%D.timeZone:UTC:++", .string("2020-03-18T17:39:23.1234Z"), "2020-03-18T17:39:23.123Z"),
			("%D.timeZone:UTC:++", .string("2020-03-18T17:39:23.000Z"), "2020-03-18T17:39:23Z"),
			("%D.timeZone:UTC:++", .string("2020-03-18T17:39:23.0004Z"), "2020-03-18T17:39:23Z"),
			("%D.timeZone:UTC:++", .number(0.5), "1970-01-01T00:00:00.500Z"),
			// A year outside 0000 to 9999 renders as an ISO-8601 expanded year, and
			// every date is in the proleptic Gregorian calendar
			("%D.timeZone:UTC:++", .number(253_402_300_800), "+10000-01-01T00:00:00Z"),
			("%D.timeZone:UTC:++", .number(-62_135_596_801), "0000-12-31T23:59:59Z"),
			("%D.timeZone:UTC:++", .number(-62_167_219_201), "-00001-12-31T23:59:59Z"),
			("[%d]", .string("9223372036854775.807"), nil),
			("%.D.timeZone:UTC:++", .string("9223372036854775.807"), "+292278994-08-17T07:12:55.807Z"),
			("%.D.timeZone:UTC:++", .string("-9223372036854775.808"), "-292275055-05-16T16:47:04.192Z"),
			("[%.d]", .string("9223372036854775.808"), nil),
			("%D.timeZone:UTC:++", .string("+10000-01-01T00:00:00Z"), "+10000-01-01T00:00:00Z"),
			("%D.timeZone:UTC:++", .string("-00001-12-31T23:59:59Z"), "-00001-12-31T23:59:59Z"),
			("[%d]", .string("+292278994-08-17T07:12:55.808Z"), nil),
			("%D.timeZone:UTC:++", .string("+292278994-08-17T07:12:55.807Z"), "+292278994-08-17T07:12:55.807Z"),
			("[%d]", .string("10000-01-01"), nil),
			("[%d]", .string("+2020-03-18"), nil),
			("[%d]", .string("1500-02-29"), nil),
			("[%d]", .string("1900-02-29"), nil),
			("%D.timeZone:UTC:++", .string("2000-02-29T00:00:00Z"), "2000-02-29T00:00:00Z"),
			("%D.timeZone:UTC:++", .string("1500-02-28T12:00:00Z"), "1500-02-28T12:00:00Z"),
			("%D.dateOnly.timeZone:UTC:++", .string("2020-03-18T17:39:23.123Z"), "2020-03-18"),
			// A datetime's RFC 3339 variants & omitted seconds
			("%D.timeZone:UTC:++", .string("2020-03-18 17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%D.timeZone:UTC:++", .string("2020-03-18t17:39:23z"), "2020-03-18T17:39:23Z"),
			("%D.timeZone:UTC:++", .string("2020-03-18T17:39Z"), "2020-03-18T17:39:00Z"),
			("%D.timeZone:UTC:++", .string("2020-03-18 17:39+02:00"), "2020-03-18T15:39:00Z"),
			// Other ISO-8601 representations are not detected
			("[%d]", .string("2020-03-18T17:39.5Z"), nil),
			("[%d]", .string("2020-03-18T17Z"), nil),
			("[%d]", .string("2020-03-18_17:39:23Z"), nil),
			("[%d]", .string("20200318"), nil),
			("[%d]", .string("20200318T173923Z"), nil),
			("[%d]", .string("2020-03"), nil),
			("[%d]", .string("2020-078"), nil),
			("[%d]", .string("2020-W12-3"), nil),
			("[%d]", .string("not a date"), nil),
			// Only <coercion> allows a string as a Unix time
			("[%d]", .string("0"), nil),
			("%.D.timeZone:UTC:++", .string("0"), "1970-01-01T00:00:00Z"),
			("%.D.timeZone:UTC:++", .string("1.5e9"), "2017-07-14T02:40:00Z"),
			("..dateOnly.timeZone:UTC:", .string("0"), "1970-01-01"),
			("..dateOnly", .string("x"), nil),
			("%-d", .string("not a date"), "not a date"),
		],
	)
	func `renders chronologic placeholders`(format: String, value: JSON.Node, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%d", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%D.timeZone:system:++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%D.timeZone::++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%D.timeZone++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%D.timeZone:UTC:.timeZone++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%D.timeZone:GMT+5:++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-18T22:39:23+05:00"),
			("%D.dateOnly.timeZone:Asia/Tokyo:++", "America/New_York", "2020-03-18T17:39:23Z", "2020-03-19"),
			// A date-only value's date is independent of time zones
			("%D.timeZone:Pacific/Honolulu:++", "America/New_York", "2020-03-18", "2020-03-18"),
			("%D.timeZone:Pacific/Kiritimati:++", "Pacific/Honolulu", "2020-03-18", "2020-03-18"),
		],
	)
	func `renders chronologic values per the system & output time zones`(
		format: String,
		systemTimeZone: String,
		value: String,
		expected: String,
	) throws {
		#expect(try inSystemTimeZone(systemTimeZone) { try rendered(format, .string(value)) } == expected)
	}

	@Test(
		arguments: [
			// A time-only value is converted between time zones as if on the
			// reference date
			("%c", "17:39:23", String?.some("17:39:23-04:00")),
			("%c", "17:39:23.1234Z", "13:39:23.123-04:00"),
			("%C.timeZone:UTC:++", "17:39:23+02:00", "15:39:23Z"),
			("%C.timeZone:America/New_York,2020-01-15:++", "17:39:23Z", "12:39:23-05:00"),
			("%C.timeZone:America/New_York,2020-07-15:++", "17:39:23Z", "13:39:23-04:00"),
			("%C.timeZone:America/New_York:++", "17:39:23Z", "13:39:23-04:00"),
			("%C.timeZone:America/New_York,+10000-07-15:++", "17:39:23Z", "13:39:23-04:00"),
			("[%c]", "24:00:00", nil),
			("%C.timeZone:UTC:++", "17:39:23z", "17:39:23Z"),
			// Only a datetime's seconds can be omitted
			("[%c]", "17:39", nil),
			("[%c]", "17:39Z", nil),
			// A time-only value has no date, so `%d` & `%D` do not match it, while
			// `%c` & `%C` match only it
			("%D.dateOnly+-+", "17:39:23", "-"),
			("%D.dateOnly+-+", "2020-03-18T17:39:23Z", "2020-03-18"),
			("[%c]", "2020-03-18T17:39:23Z", nil),
			("%mdc+", "17:39:23", "17:39:23-04:00"),
			("%mdc+", "2020-03-18", "2020-03-18"),
			("..dateOnly", "17:39:23", nil),
		],
	)
	func `renders time-only chronologic values`(format: String, value: String, expected: String?) throws {
		#expect(
			try inSystemTimeZone("America/New_York", now: Date(timeIntervalSince1970: 1_594_771_200)) {
				try rendered(format, .string(value))
			}
				== expected,
		)
	}

	@Test(arguments: ["1", "1.0b", "10.2.3-beta"])
	func `%v matches a version`(version: String) throws {
		#expect(try rendered("%v", .string(version)) == version)
	}

	@Test(arguments: ["", "a1", "1..2", "1.", "٣.1", "½", "1.0 beta", "1.0_b", "1.0!"])
	func `%v does not match a non-version`(value: String) throws {
		#expect(try rendered("[%v]", .string(value)) == nil)
	}

	@Test(
		arguments: [
			("% i", ParsingError.forbiddenWhitespace(after: "%")),
			("%- n", .forbiddenWhitespace(after: "-")),
			("%. n", .forbiddenWhitespace(after: ".")),
			(". uppercase", .forbiddenWhitespace(after: ".")),
			(": name", .forbiddenWhitespace(after: ":")),
			("abc", .templateLacksPlaceholder),
			("%.s", .coercionNotSupported("s")),
			("%.:de:b", .numberCoercionArgumentsNotSupported("b")),
			("%.:de:T++", .numberCoercionArgumentsNotSupported("T")),
			("%.:de:s", .coercionNotSupported("s")),
			("%.:de:i", .invalidModifier("i")),
			("%m.:de:b+", .numberCoercionArgumentsNotSupported("b")),
			("..:de:uppercase", .numberCoercionArgumentsNotSupported("uppercase")),
			("..:de:dateOnly", .numberCoercionArgumentsNotSupported("dateOnly")),
			("%C.dateOnly++", .invalidPipeline("<time-only-pipeline>")),
			("%C%C.dateOnly++++", .invalidPipeline("<time-only-pipeline>")),
			("%.c", .coercionNotSupported("c")),
			("%I..:de:uppercase+", .numberCoercionArgumentsNotSupported("uppercase")),
			("%.:,,x:n", .invalidNumberCoercionArguments),
			("%.:,.:n", .invalidNumberCoercionArguments),
			("%.:,,,,", .invalidNumberCoercionArguments),
			("%.:nowhere:n", .invalidLocaleIdentifier("nowhere")),
			("%.:,,,,,(:n", .invalidTriviaRegex("(")),
			("%.:,,,,,,[:n", .invalidTriviaRegex("[")),
			("%_n", .invalidLetter("_")),
			("%.v", .coercionNotSupported("v")),
			("%.:de:d", .numberCoercionArgumentsNotSupported("d")),
			("%+n", .invalidModifier("n")),
			("%-i", .invalidModifier("i")),
			("%.m", .invalidModifier("m")),
			("%x", .invalidLetter("x")),
			("%", .missingPredicate),
			(":name", .unknownNamedFormat("name")),
			(".bogus", .unknownTransform("bogus")),
			(".initialUppercase", .unknownTransform("initialUppercase")),
			(".sentenceCase", .unknownTransform("sentenceCase")),
			(".numberFormat.round", .invalidPipeline("<value-transform-pipeline>")),
			(".uppercase.round", .invalidPipeline("<value-transform-pipeline>")),
			(".uppercase.endJustify", .invalidPipeline("<pipeline>")),
			("..endJustify", .coercionNotSupported(".")),
			(".uppercase%i", .unexpectedCharacter("%")),
			("%N.uppercase++", .invalidPipeline("<number-pipeline>")),
			("%S.round++", .invalidPipeline("<string-pipeline>")),
			("%I.uppercase+", .invalidPipeline("<unconditional-pipeline>")),
			("%Ix+", .invalidPipeline("<unconditional-pipeline>")),
			("%I+", .invalidPipeline("<unconditional-pipeline>")),
			("%L+", .invalidPipeline("<string-pipeline>")),
			("%S%S+++", .invalidPipeline("<string-pipeline>")),
			("%N", .missingBlockTerminator),
			("%N+", .missingBlockTerminator),
			("%S<%n>++", .invalidLetter("n")),
			("%N+%n+", .invalidLetter("n")),
			("%mn+", .singleBranch),
			("%mi n+", .unconditionalBranchNotLast),
			("%mn-i+", .invalidModifier("i")),
			("%mnm+", .invalidLetter("m")),
			(".numberFormat:en,x,y:", .invalidTransformArguments(name: "numberFormat")),
			(".numberFormat:en,.,3,,.:", .invalidTransformArguments(name: "numberFormat")),
			(".numberFormat:nowhere:", .invalidLocaleIdentifier("nowhere")),
			(".scale:1,0,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,0,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,,18446744073709551615:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,101,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,,101:", .invalidTransformArguments(name: "scale")),
			(".scale:,6,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,6,,0,1:", .invalidTransformArguments(name: "scale")),
			(".scale:10,x,,0:", .invalidTransformArguments(name: "scale")),
			(".numberFormat:en,,,,,:", .invalidTransformArguments(name: "numberFormat")),
			(".numberFormat:en,.,3,,.", .invalidTransformArguments(name: "numberFormat")),
			(".group", .unknownTransform("group")),
			(".timeZone:UTC,UTC:", .invalidTransformArguments(name: "timeZone")),
			(".timeZone:UTC,2020-02-30:", .invalidTransformArguments(name: "timeZone")),
			(".timeZone:UTC,2020-01-01,2020-01-02:", .invalidTransformArguments(name: "timeZone")),
			(".numberFormat:en,.,18446744073709551615:", .invalidTransformArguments(name: "numberFormat")),
			(".timeZone:Nowhere/Land:", .invalidTransformArguments(name: "timeZone")),
			(".timeZone:+530:", .invalidTransformArguments(name: "timeZone")),
			(".timeZone:EST+5:", .invalidTransformArguments(name: "timeZone")),
			("%S\\", .danglingEscape),
		],
	)
	func `reports a format-block syntax error`(format: String, error: ParsingError) {
		#expect(throws: error) { try parsedFieldSpec(format) }
	}

	@Test(arguments: ["", "  "])
	func `an absent format-block defaults to an empty string`(format: String) throws {
		#expect(try parsedFieldSpec(format).format == .empty)
		#expect(try rendered(format, .string("v"))?.isEmpty == true)
	}

	@Test
	func `an absent format-modifier does not default its format-block`() throws {
		let format = try resolvedFieldsConfig(
			from: "n",
			standard: SelectedFieldsConfig(),
			all: .init(),
			outputFormat: .json(.default),
		)
		.fieldSpecs[0]
		.format
		#expect(format == .default(fieldName: "n"))
	}
}

private func parsedFieldSpec(_ format: String) throws(ParsingError) -> FieldSpec {
	try resolvedFieldsConfig(
		from: "n:" + format,
		standard: SelectedFieldsConfig(),
		all: .init(),
		outputFormat: .json(.default),
	)
	.fieldSpecs[0]
}

private let structuredValue = JSON.Node.array([.string("é"), .object(["a": .null])])

private func rendered(_ format: String, _ value: JSON.Node?) throws -> String? {
	try parsedFieldSpec(format).format.rendered(value: value, label: "L", name: "n")?.stringValue
}
