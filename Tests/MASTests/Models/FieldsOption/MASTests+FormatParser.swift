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
			"%.V%v+no+",
		],
	)
	func `no predicate whose output type is not any matches a structured value`(format: String) throws {
		#expect(try rendered(format, structuredValue) == "no")
	}

	@Test
	func `a call after a number run coerces the number as a Unix time without date-coercion-arguments`() throws {
		#expect(try inSystemTimeZone("UTC") { try rendered(".round..dateOnly", .number(0)) } == "1970-01-01")
	}

	@Test(
		arguments: [
			("%.C:standard.dateOnly+-+", "17:39:23Z", Transform.dateOnly),
			("%.D:standard.timeOnlyTimeZone:UTC:+-+", "2020-03-18", .timeOnlyTimeZone(.gmt, referenceDate: nil)),
		],
	)
	func `a chronologic value of another type is uncoercible, so its error suggests no coercion`(
		format: String,
		value: String,
		transform: Transform,
	) throws {
		let fieldSpec = try parsedFieldSpec(format)
		#expect(throws: FormattingError.uncoercibleTransformInput(transform: transform, input: value)) {
			try inSystemTimeZone("UTC") { try fieldSpec.format.rendered(value: .string(value), label: "L", name: "n") }
		}
	}

	@Test
	func `%v before %n renders a number as a string`() throws {
		let rendered = { (format: String) in
			try parsedFieldSpec(format).format.rendered(value: .number(1.2), label: "L", name: "n")?.description
		}
		#expect(try rendered("%mvn+") == #""1.2""#)
		#expect(try rendered("%mnv+") == "1.2")
	}

	@Test
	func `a number coercion parses a string, but not a structured value, whose text is a number between trivia`()
	throws {
		let format = #"%.:,,,,,\\[,\\]:N%n+no+"#
		#expect(try rendered(format, .string("[1]")) == "[1]")
		#expect(try rendered(format, .array([.number(1)])) == "no")
	}

	@Test
	func `a number transform's coercion parses a string, but not a structured value, whose text is a number`()
	throws {
		let format = #"..:,,,,,\\[,\\]:round"#
		#expect(try rendered(format, .string("[1.5]")) == "[2]")
		#expect(try rendered(format, .array([.number(1)])) == nil)
	}

	@Test(
		arguments: [
			(#".\round"#, .number(1.5), "2"),
			(#".ro\und"#, .number(1.5), "2"),
			(#"..up\percase"#, "a", "A"),
			(#"%.D.\timeZone:UTC:.\dateOnly++"#, "2020-03-18T17:39:23Z", "2020-03-18"),
		] as [(String, JSON.Node, String)],
	)
	func `a transform name evaluates its escape sequences`(format: String, value: JSON.Node, expected: String) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%.:iso,unix-time:D.timeZone:UTC:.dateOnly++", .number(0), "1970-01-01"),
			("%.:iso,unix-time:D.timeZone:UTC:.dateOnly++", "0", "1970-01-01"),
			("%.:iso,unix-time:D.timeZone:UTC:.dateOnly++", "2020-03-18", "2020-03-18"),
			("%.:unix-time,iso:D.timeZone:UTC:.dateOnly++", "2020-03-18", "2020-03-18"),
			("[%.:iso,unix-time:d]", "17:39:23", nil),
			("[%.:iso:d]", .number(0), nil),
			("[%.:iso:d]", "0", nil),
			("[%.:iso:d]", "17:39:23", nil),
			("%.:iso:D.dateOnly++", "2020-03-18", "2020-03-18"),
			("%.:iso-date:d", "2020-03-18", "2020-03-18"),
			("[%.:iso-date:d]", "2020-03-18T17:39:23Z", nil),
			("%.:iso-datetime:D.timeZone:UTC:++", "2020-03-18T17:39:23Z", "2020-03-18T17:39:23Z"),
			("[%.:iso-datetime:d]", "2020-03-18", nil),
			("%.: iso-date , iso-datetime :D.timeZone:UTC:.dateOnly++", "2020-03-18", "2020-03-18"),
			(#"%.:\unix-time:D.timeZone:UTC:.dateOnly++"#, .number(0), "1970-01-01"),
			(#"%.:unix\-time:D.timeZone:UTC:.dateOnly++"#, .number(0), "1970-01-01"),
			(".round..:iso,unix-time:timeZone:UTC:.dateOnly", .number(0), "1970-01-01"),
			("%.:iso-date:D%d+-+", "2020-03-18", "2020-03-18"),
			("%.:iso-date:D:default.dateOnly+-+", "2020-03-18", "2020-03-18"),
			("%.:iso-date:D..uppercase+-+", "2020-03-18", "2020-03-18"),
			("%.:iso-date,iso-datetime:D.timeZone:UTC:.dateOnly++", "2020-03-18", "2020-03-18"),
			("%.V..:iso-date:dateOnly+-+", "2020-03-18", "2020-03-18"),
			("%.V..:iso,iso-datetime:dateOnly+-+", "2020-03-18", "2020-03-18"),
			("%.V..:iso-datetime,iso-date:dateOnly+-+", "2020-03-18", "2020-03-18"),
			("%.V..:unix-time:timeZone:UTC:.dateOnly+-+", "0", "1970-01-01"),
			("%.V..:iso,unix-time:timeZone:UTC:.dateOnly+-+", "0", "1970-01-01"),
			("%.V..dateOnly+-+", "2020-03-18", "2020-03-18"),
			("..:iso-date:dateOnly", "2020-03-18", "2020-03-18"),
			("..:iso-date:dateOnly", "2020-03-18T17:39:23Z", nil),
			("..:iso-date:dateOnly.dateOnly", "2020-03-18", "2020-03-18"),
		] as [(String, JSON.Node, String?)],
	)
	func `a date coercion parses what any of its date formats matches`(
		format: String,
		value: JSON.Node,
		expected: String?,
	) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test
	func `a fallible unconditional placeholder coerces its label`() throws {
		#expect(
			try parsedFieldSpec("%L..:,,,,,.*:round+").format.rendered(value: nil, label: "Size 5.6", name: "n")?.description
				== #""Size 6""#,
		)
	}

	@Test
	func `coerces a structured value to its compact JSON text`() throws {
		#expect(try rendered("(%i)", structuredValue) == #"(["é",{"a":null}])"#)
	}

	@Test(
		arguments: [
			// fields-format.md's examples
			("%.:de:N%n (%i)++", JSON.Node.string("1.234,5"), String?.some("1234.5 (1.234,5)")),
			("%MN.absoluteValue+b+%I..uppercase++", .number(-5), "5"),
			("%MN.absoluteValue+b+%I..uppercase++", .bool(true), "true"),
			("%MN.absoluteValue+b+%I..uppercase++", .string("abc"), "ABC"),
			("%MN.absoluteValue+b+Status Unknown+", .number(-5), "5"),
			("%MN.absoluteValue+b+Status Unknown+", .bool(false), "false"),
			("%MN.absoluteValue+b+Status Unknown+", .string("x"), "Status Unknown"),
			(".scale:6,,0:", .number(12_345_678), "12"),
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
			("[%N%n++]", .string("x"), "[]"),
			("%S.uppercase++", .string("abc"), "ABC"),
			("%.T%t+no+", .string("true"), "true"),
			("%.T%t+no+", .string("false"), "no"),
			("%T+no+", .string("true"), "no"),
			("%E(empty)+%i+", .string(""), "(empty)"),
			("%W(blank)+%i+", .string(" \t"), "(blank)"),
			("%W(blank)+%i+", .string(" a "), " a "),
			// A directly absent block defaults to an empty string
			("[%N+fail+]", .number(5), "[]"),
			("[%N +fail+]", .number(5), "[]"),
			("[%.V+%i+]", .string("1.2"), "[]"),
			("[%.V+%i+]", .string("v1.2"), "[v1.2]"),
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
			(":standard", JSON.Node.string("abc"), String?.some("abc")),
			(":default", .string("abc"), "abc"),
			(":default.uppercase", .string("abc"), "ABC"),
			(":end.uppercase", .string("abc"), "ABC"), // A preset that sets no format
			(":standard..round", .string("4.6"), "5"),
			// A block's named format is evaluated against its matcher's value, which
			// is thus the format input that its `%i` inserts
			("%.:de:N:default+-+", .string("1.234,5"), "1234.5"),
			("%K:default.uppercase+", .string("abc"), "N"),
		],
	)
	func `renders the named format of a preset that sets no format as %i`(
		format: String,
		value: JSON.Node?,
		expected: String?,
	) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%.:,,,,,.*,.*:n", JSON.Node.string("US$1,234.50"), String?.some("US$1234.50")),
			("%.:,,,,,.*,.*:N.round++", .string("US$1,234.50"), "US$1235"),
			("%.:,,,,,.*,.*:N.absoluteValue++", .string("-3 MB"), "3 MB"),
			("[%.n]", .string("US$5"), nil),
			("[%.:,,,,,.*,.*:n]", .string("none"), nil),
			("%.n", .string("4.50"), "4.50"),
			("[%.n]", .string("4.5a"), nil),
			("[%.n]", .string("nan"), nil),
			("[%.n]", .string("0x10"), nil),
			("%.n", .string("-1e3"), "-1e3"),
			("%.n", .string("12345678901234567890.123456789000"), "12345678901234567890.123456789000"),
			("%.n", .string("+007.50"), "+007.50"),
			("%.n", .string("-0.0"), "-0.0"),
			("%n", .number(4.5), "4.5"),
			// fields-format.md's examples
			("%.:de:n", .string("1.234,56"), "1234.56"),
			("%.:de: n", .string("1.234,56"), "1234.56"),
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
			("%.:,,,,,\\\\$:n", .string("$5"), "$5"),
			("%.:,,,,,.*,.*:N.absoluteValue++", .string("x-1.50 y"), "x1.50 y"),
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
			("%I.uppercase+", "V"),
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
			("%.:de:N%n/%i++", .string("1.234,5"), "1234.5/1.234,5"),
			("%.B%b!++", .string("true"), "true!"),
			("%.D%D.dateOnly+++", .string("2020-03-18T17:39:23Z"), "2020-03-18"),
			("%.V[%v]++", .string("1.2"), "[1.2]"),
			("%.V..uppercase+-+", .string("1.2b"), "1.2B"),
			("%.V%V..uppercase+++", .string("1.2b"), "1.2B"),
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
			("%Mn.Bbool:%b++%k+", .string("true"), "bool:true"),
			("%Mn.Bbool:%b++%K.uppercase++", .string("x"), "N"),
			("%Mnb+%l+", .string("x"), "L"),
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
			(".numberFormat:en:.uppercase", .number(1234), "1,234"),
			("..round.numberFormat:en:.lowercase", .string("1234.5"), "1,235"),
			(".round..uppercase", .number(5), "5"),
			("..trimWhitespace..round", .string(" 5.6 "), "6"),
			("..numberFormat:de:..:de:round", .string("1234.5"), "1235"),
			("..numberFormat:de:..round", .string("1234.5"), nil),
			("..dateOnly..uppercase", .string("2020-03-18"), "2020-03-18"),
			(".round..:unix-time:timeZone:UTC:.dateOnly", .number(0), "1970-01-01"),
			("%N.numberFormat:en:.uppercase+none+", .number(1234), "1,234"),
			("%S.trimWhitespace..round+none+", .string(" 5.6 "), "6"),
			("%S..round+none+", .string("5.6"), "6"),
			("%S..round+none+", .number(5), "none"),
			("%S..round+none+", .string("x"), nil),
			("%N..uppercase+none+", .number(5), "5"),
			(":standard.uppercase", .string("x"), "X"),
			(":standard..uppercase", .number(5), "5"),
			("%S:standard..uppercase+none+", .string("x"), "X"),
			("%L.uppercase+", .string("x"), "L"),
			("[%v]", .string("1.2"), "[1.2]"),
			("[%v]", .number(1.2), "[1.2]"),
			("%V..uppercase+-+", .string("1.2b"), "1.2B"),
			("[%v]", .string("x"), nil),
			("[%b]", .string("true"), nil),
			("[%n]", .string("5"), nil),
			("%.v", .number(1.2), "1.2"),
			("[%.v]", .number(-1), nil),
			("%.:unix-time:D.timeZone:UTC:.dateOnly++", .number(0), "1970-01-01"),
			("%.D.dateOnly.dateOnly++", .string("2020-03-18"), "2020-03-18"),
			("[%.d]", .string("0"), nil),
			("[%.:unix-time:d]", .string("2020-03-18"), nil),
			("%m.D.timeZone:UTC:+n+", .number(5.6), "1970-01-01T00:00:05.600Z"),
			("%mn.d+", .number(5.6), "5.6"),
			("%m.ds+", .string("5.6"), "5.6"),
			("%mnv+", .number(1.2), "1.2"),
			("%m.:iso:d.n+", .number(5.6), "5.6"),
			("%N..:unix-time:timeZone:UTC:.dateOnly+-+", .number(0), "1970-01-01"),
			("..:,,,,,[$]:round..:unix-time:timeZone:UTC:.dateOnly", .string("$5"), nil),
			("%.:unix-time:D.timeZone:UTC:.dateOnly+-+", .string("x"), "-"),
			("%.V..round+-+", .string("1.2"), "1"),
			("%.D..uppercase..:,,,,,.*:round+-+", .string("2020-03-18"), "2020-03-18"),
			("%.V..round+-+", .string("x"), "-"),
			("%+.V..uppercase+", .string("1.2b"), "1.2B"),
			("%L:standard.uppercase+", .string("x"), "L"),
			("%L:standard..uppercase+", .string("x"), "L"),
			("%L..round+", .string("x"), nil),
			("%L..:,,,,,.*:round+", .string("x"), nil),
			("%I..trimWhitespace..round+", .string(" 5.6 "), "6"),
			("%I..round+ MB", .string("5.6"), "6 MB"),
			("%I..round+", .string("x"), nil),
			("%I.round+ MB", .number(5.6), "6 MB"),
			("%I:standard.uppercase+", .string("x"), "X"),
			("%S%I..round+++", .string("5.6"), "6"),
			("%S%I..round+++", .string("x"), nil),
			("%S.uppercase+%I..uppercase++", .number(5), "5"),
			("%S.uppercase+%L.lowercase++", .number(5), "l"),
			("%.D.timeZone:UTC:..lowercase+none+", .string("2020-03-18T17:39:23Z"), "2020-03-18t17:39:23z"),
			("%.C.timeOnlyTimeZone:UTC:..lowercase+none+", .string("17:39:23Z"), "17:39:23z"),
			("%.C..uppercase+none+", .string("x"), "none"),
			("%S:standard..round+none+", .string("5.6"), "6"),
			("%N:standard..uppercase+none+", .number(5), "5"),
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
			(".numberFormat:canonical,,3,2:", .number(12_345_678), "1,23,45,678"),
			(".numberFormat:en,,0,2:", .number(12_345_678), "12345678"),
			(".numberFormat:en,,4:", .number(12_345_678), "1234,5678"),
			(".numberFormat:en,.,,,,:", .number(-1234.5), "-1.234,5"),
			(".numberFormat:system:", .number(1), "1"),
			// Scientific notation is retained, its exponent verbatim
			("..numberFormat:de:", .string("12345.6E3"), "12.345,6E3"),
			("..numberFormat:en:", .string("-1234e-2"), "-1,234e-2"),
			("..scale:0,,2:.numberFormat:de:", .string("1.5e3"), "1.500,00"),
			("..:,,,,,[$]:numberFormat:de:", .string("$1234.5"), "$1.234,5"),
			("..numberFormat:de:", .string("+01234.50"), "+01.234,50"),
			("..numberFormat:de:", .string(".5"), ",5"),
			("..:de:round", .string("1.234,56"), "1235"),
			("..:de: round", .string("1.234,56"), "1235"),
			("..:,,,,,.*,.*:round", .string("about 2.5 MB"), "about 3 MB"),
			("..:,,,,,.*,.*:numberFormat:en:", .string("~1234567 B"), "~1,234,567 B"),
			(".scale:6, ,0:", .number(12_345_678), "12"),
			(".scale: 6 , 2 , 1 :", .number(12_345_678), "12.0"),
			("..dateOnly", .string("2020-03-18"), "2020-03-18"),
			(".initialTitlecase", .string("abc def"), "Abc def"),
			(".trimWhitespace", .string("  x  "), "x"),
			(".lowercase", .string("ABC"), "abc"),
			(".absoluteValue", .number(-5.5), "5.5"),
			(".round", .number(1e30), "1e+30"),
			(".absoluteValue", .number(-1e30), "1e+30"),
			(".scale:0,,0:", .number(1e30), "1000000000000000000000000000000"),
			("..scale:3,,2:", .string("123456789012345678901234567890"), "123456789012345678901234567.89"),
			("..scale:0,3,0:", .string("123456"), "123000"),
			("..scale:0,2,3:", .string("-0.0001234"), "0.000"),
			("..scale:0,100,100:", .string("1"), "1." + String(repeating: "0", count: 100)),
			("..scale:99999999999999999999,,2:", .string("-5e30"), "0.00"),
			("..scale:30,,0:", .string("5e29"), "1"),
			(".scale:0,,0:", .number(1e99), "1" + String(repeating: "0", count: 99)),
			("..scale:0,2,0:", .string("9.95e98"), "1" + String(repeating: "0", count: 99)),
			("..scale:0,,0:", .string("1e-999999999999"), "0"),
			("..scale:999999999999,,0:", .string("1e1000000000000"), "10"),
			("..scale:0,1,0:", .string("25"), "30"),
			("..scale:0,1,1:", .string("100"), "100.0"),
			("..scale:0,,0:", .string("1e100"), nil),
			(".scale:0,,0:", .number(1e100), nil),
			(".scale:0:", .number(1e-101), nil),
			("%N.scale:0,,0:+none+", .number(1e100), nil),
			(".round.scale:0,,0:", .number(1e100), nil),
			("..scale:0,2,0:", .string("9.995e99"), nil),
			("..scale:0,,0:", .string("1e999999999999"), nil),
			("..scale:-2,,0:", .string("0.25"), "25"),
			(".scale:-3,,1:", .number(1.5), "1500.0"),
			("..scale:+2,,0:", .string("1234"), "12"),
			("..scale:-0,,0:", .string("7"), "7"),
			("..scale:-99,,0:", .string("1"), "1" + String(repeating: "0", count: 99)),
			("..scale:-99999999999999999999,,2:", .string("0"), "0.00"),
			("..scale:-100,,0:", .string("1"), nil),
			("..scale:-99999999999999999999,,0:", .string("1"), nil),
			(".numberFormat:en,\\,,18446744073709551616:", .number(12_345_678), "12345678"),
			("..round", .string("12345678901234567890.5"), "12345678901234567891"),
			("..round", .string("007.5"), "8"),
			("..round", .string("007"), "7"),
			("..scale:0:", .string("01.50"), "1.5"),
			("..scale:0,,3:", .string("01.50"), "1.500"),
			("..round", .string("+01.50"), "+2"),
			("..round", .string(".5"), "1"),
			("..absoluteValue", .string("+01.50"), "01.50"),
			("..scale:0:", .string("+01.50"), "+1.5"),
			("..scale:0:", .string(".5"), "0.5"),
		],
	)
	func `applies a format-block's value-transform-pipeline`(format: String, value: JSON.Node, expected: String?)
	throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("..scale:3:", JSON.Node.string("1500"), String?.some("1.5")),
			("..scale:3,:", .string("1234"), "1.234"),
			("..scale:3,,:", .string("-1234"), "-1.234"),
			("..scale:-3:", .string("1.5"), "1500"),
			("..scale:6,3:", .string("1234567"), "1.23"),
			("..scale:6,3:", .string("123456789"), "123"),
			("..scale:0,2:", .string("9.96"), "10"),
			("..scale:0,2:", .string("-0.0001234"), "-0.00012"),
			("..scale:0:", .string("0"), "0"),
			("..scale:0:", .string("0.50"), "0.5"),
			("..scale:0:", .string("1e-100"), "0.\(String(repeating: "0", count: 99))1"),
			("..scale:0,3:", .string("1.00e-98"), "0.\(String(repeating: "0", count: 97))1"),
			("..scale:0:", .string("1e-101"), nil),
			("..scale:0,3:", .string("1.23e-99"), nil),
			("..scale:0,1:", .string("1e999999999999"), nil),
		],
	)
	func `scale renders as few fractional digits as are exact absent fractional-digits`(
		format: String,
		value: JSON.Node,
		expected: String?,
	) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			(
				".dateOnly",
				JSON.Node.string("x"),
				FormattingError.uncoercibleTransformInput(transform: .dateOnly, input: "x"),
				"Transform dateOnly requires an input of its input type: x",
			),
			(
				"%S:standard.dateOnly+-+",
				.string("x"),
				.uncoercibleTransformInput(transform: .dateOnly, input: "x"),
				"Transform dateOnly requires an input of its input type: x",
			),
			(
				"%S:standard.dateOnly+-+",
				.string("2020-03-18"),
				.transformInputTypeMismatch(transform: .dateOnly, input: "2020-03-18"),
				"Transform dateOnly requires an input of its input type (<coercion> '.' coerces it): 2020-03-18",
			),
			(
				".round",
				.string("x"),
				.uncoercibleTransformInput(transform: .round, input: "x"),
				"Transform round requires an input of its input type: x",
			),
			(
				".round",
				.string("5"),
				.transformInputTypeMismatch(transform: .round, input: "5"),
				"Transform round requires an input of its input type (<coercion> '.' coerces it): 5",
			),
			(
				".round",
				.bool(true),
				.uncoercibleTransformInput(transform: .round, input: "true"),
				"Transform round requires an input of its input type: true",
			),
			(
				".uppercase",
				.number(5),
				.transformInputTypeMismatch(transform: .uppercase, input: "5"),
				"Transform uppercase requires an input of its input type (<coercion> '.' coerces it): 5",
			),
		],
	)
	func `a transform's error suggests a coercion iff a default coercion would coerce its input`(
		format: String,
		value: JSON.Node,
		error: FormattingError,
		description: String,
	) throws {
		let fieldSpec = try parsedFieldSpec(format)
		#expect(throws: error) { try fieldSpec.format.rendered(value: value, label: "L", name: "n") }
		#expect(error.description == description)
	}

	@Test(
		arguments: [
			(".uppercase", JSON.Node.number(5)),
			(".round", .string("5.6")),
			(".dateOnly", .string("not a date")),
			(".dateOnly", .bool(true)),
			(".timeZone:UTC:", .string("0")),
			(".dateOnly", .string("0")),
			(".timeOnlyTimeZone:UTC:", .string("not a time")),
			(".dateOnly", .string("17:39:23")),
			(".timeZone:UTC:", .string("17:39:23")),
			(".timeOnlyTimeZone:UTC:", .string("2020-03-18")),
			("%S:standard.round+none+", .string("5")),
			("%L:standard.dateOnly+", .string("2020-03-18")),
			("%I.uppercase+", .number(5)),
			("%I.round+", .string("5")),
			("[%I.uppercase+]", .number(5)),
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
		arguments: [".round", ".uppercase", "..uppercase", ".dateOnly", "..:de:numberFormat", "%I.uppercase+"],
		[JSON.Node?.none, .null],
	)
	func `a null or absent value remains unmodified through every transform`(format: String, value: JSON.Node?)
	throws {
		#expect(try parsedFieldSpec(format).format.rendered(value: value, label: "L", name: "n")?.description == value?
			.description)
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
			("%.n", .string("+01.50"), "1.50"),
			("%.n", .string(".5"), "0.5"),
			("%.:,,,,,,[.]:n", .string("5."), #""5.""#),
			("..:,,,,,[$]:round", .string("$2.4"), #""$2""#),
			(".numberFormat", .number(5), #""5""#),
			("%t", .bool(true), "true"),
			("%u", .null, "null"),
			("%e", .string(""), #""""#),
			("%w", .string(" \t"), #"" \t""#),
			("%.d", .string("2020-03-18"), #""2020-03-18""#),
			("%i", structuredValue, #"["é",{"a":null}]"#),
			("(%i)", structuredValue, #""([\"é\",{\"a\":null}])""#),
		],
	)
	func `renders a format's value at its type iff JSON supports it`(format: String, value: JSON.Node, json: String)
	throws {
		#expect(
			try parsedFieldSpec(format).format.rendered(value: value, label: "L", name: "n")?.rendered(jsonConfig: .default)
				== json,
		)
	}

	@Test(
		arguments: [
			("%.d", JSON.Node.string("2020-03-18"), String?.some("2020-03-18")),
			("%.D.timeZone:UTC:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%.D.timeZone:utc:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%.D.timeZone:Asia/Tokyo:++", .string("2020-03-18T17:39:23Z"), "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone:Europe/London:++", .string("2020-01-15T12:00:00+01:00"), "2020-01-15T11:00:00Z"),
			("%.D.timeZone:Europe/London:++", .string("2020-07-15T12:00:00Z"), "2020-07-15T13:00:00+01:00"),
			("%.D.timeZone:asia/tokyo:++", .string("2020-03-18T17:39:23Z"), "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone:-05\\:30:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T12:09:23-05:30"),
			("%.:unix-time:D.timeZone:UTC:++", .number(0), "1970-01-01T00:00:00Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18T17:39:23.1234Z"), "2020-03-18T17:39:23.123Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18T17:39:23.000Z"), "2020-03-18T17:39:23Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18T17:39:23.0004Z"), "2020-03-18T17:39:23Z"),
			("%.:unix-time:D.timeZone:UTC:++", .number(0.5), "1970-01-01T00:00:00.500Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18T17:39:23.5Z"), "2020-03-18T17:39:23.500Z"),
			// A year outside 0000 to 9999 renders as an ISO-8601 expanded year, and
			// every date is in the proleptic Gregorian calendar
			("%.:unix-time:D.timeZone:UTC:++", .number(253_402_300_800), "+10000-01-01T00:00:00Z"),
			("%.:unix-time:D.timeZone:UTC:++", .number(-62_135_596_801), "0000-12-31T23:59:59Z"),
			("%.:unix-time:D.timeZone:UTC:++", .number(-62_167_219_201), "-00001-12-31T23:59:59Z"),
			("[%d]", .string("9223372036854775.807"), nil),
			("%.:unix-time:D.timeZone:UTC:++", .string("9223372036854775.807"), "+292278994-08-17T07:12:55.807Z"),
			("%.:unix-time:D.timeZone:UTC:++", .string("-9223372036854775.808"), "-292275055-05-16T16:47:04.192Z"),
			("[%.d]", .string("9223372036854775.808"), nil),
			("%.D.timeZone:UTC:++", .string("+10000-01-01T00:00:00Z"), "+10000-01-01T00:00:00Z"),
			("%.D.timeZone:UTC:++", .string("-00001-12-31T23:59:59Z"), "-00001-12-31T23:59:59Z"),
			("[%.d]", .string("+292278994-08-17T07:12:55.808Z"), nil),
			("[%.:iso-date:d]", .string("+999999999-01-01"), nil),
			("[%.:iso-datetime:d]", .string("+292278994-08-17T07:12:55.808Z"), nil),
			("%.D.timeZone:UTC:++", .string("+292278994-08-17T07:12:55.807Z"), "+292278994-08-17T07:12:55.807Z"),
			("[%.d]", .string("10000-01-01"), nil),
			("[%.d]", .string("+2020-03-18"), nil),
			("[%.d]", .string("1500-02-29"), nil),
			("[%.d]", .string("1900-02-29"), nil),
			("%.D.timeZone:UTC:++", .string("2000-02-29T00:00:00Z"), "2000-02-29T00:00:00Z"),
			("%.D.timeZone:UTC:++", .string("1500-02-28T12:00:00Z"), "1500-02-28T12:00:00Z"),
			("%.D.timeZone:UTC:.dateOnly++", .string("2020-03-18T17:39:23.123Z"), "2020-03-18"),
			// A datetime's RFC 3339 variants & omitted seconds
			("%.D.timeZone:UTC:++", .string("2020-03-18 17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18t17:39:23z"), "2020-03-18T17:39:23Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18T17:39Z"), "2020-03-18T17:39:00Z"),
			("%.D.timeZone:UTC:++", .string("2020-03-18 17:39+02:00"), "2020-03-18T15:39:00Z"),
			// Other ISO-8601 representations are not detected
			("[%.d]", .string("2020-03-18T17:39.5Z"), nil),
			("[%.d]", .string("2020-03-18T17Z"), nil),
			("[%.d]", .string("2020-03-18_17:39:23Z"), nil),
			("[%d]", .string("20200318"), nil),
			("[%.d]", .string("20200318T173923Z"), nil),
			("[%.d]", .string("2020-03"), nil),
			("[%.d]", .string("2020-078"), nil),
			("[%.d]", .string("2020-W12-3"), nil),
			("[%.d]", .string("not a date"), nil),
			// An implicit coercion gives a string a chronologic type wherever syntax
			// requires it, iff a default coercion would coerce it
			("%D.timeZone:UTC:+-+", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%D.dateOnly+-+", .string("2020-03-18"), "2020-03-18"),
			("[%d]", .string("2020-03-18"), "[2020-03-18]"),
			("%C.timeOnlyTimeZone:UTC:+-+", .string("17:39:23Z"), "17:39:23Z"),
			("[%c]", .string("not a time"), nil),
			("%D+-+", .string("not a date"), "-"),
			("%D.dateOnly+-+", .string("17:39:23"), "-"),
			("%C+-+", .string("2020-03-18"), "-"),
			("%mD.dateOnly+s+", .string("2020-03-18"), "2020-03-18"),
			("%mD.dateOnly+S.uppercase++", .string("abc"), "ABC"),
			(".dateOnly", .string("2020-03-18"), "2020-03-18"),
			(".timeZone:UTC:", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			(".timeZone:UTC:.dateOnly", .string("2020-03-18T17:39:23Z"), "2020-03-18"),
			(".timeOnlyTimeZone:UTC:", .string("17:39:23Z"), "17:39:23Z"),
			("%I.dateOnly+", .string("2020-03-18"), "2020-03-18"),
			(":standard.dateOnly", .string("2020-03-18"), "2020-03-18"),
			// A number is a Unix time for a default or an implicit coercion to a date
			("%D.timeZone:UTC:+-+", .number(0), "1970-01-01T00:00:00Z"),
			("%.D.timeZone:UTC:+-+", .number(1.5), "1970-01-01T00:00:01.500Z"),
			(".timeZone:UTC:", .number(0), "1970-01-01T00:00:00Z"),
			(".timeZone:UTC:.dateOnly", .number(0), "1970-01-01"),
			("..timeZone:UTC:.dateOnly", .number(0), "1970-01-01"),
			("%I.timeZone:UTC:+", .number(0), "1970-01-01T00:00:00Z"),
			(".round..timeZone:UTC:.dateOnly", .number(0), "1970-01-01"),
			("%N..timeZone:UTC:.dateOnly+-+", .number(0), "1970-01-01"),
			("..:,,,,,[$]:round..timeZone:UTC:", .string("$5"), nil),
			// A later branch that means to match a number needs one of these
			("%mN.round+D.timeZone:UTC:++", .number(1.5), "2"),
			("%m.:iso:D.timeZone:UTC:+N.round++", .number(1.5), "2"),
			// A coercion's arguments ignore the default
			("[%.:iso:d]", .number(0), nil),
			("[%.:iso-datetime:d]", .number(0), nil),
			// A number is never a time-only
			("[%c]", .number(0), nil),
			("[%.c]", .number(0), nil),
			// Only <unix-time> allows a decimal number
			("[%d]", .string("0"), nil),
			("[%.d]", .string("0"), nil),
			("..dateOnly", .string("0"), nil),
			("%.:unix-time:D.timeZone:UTC:++", .string("0"), "1970-01-01T00:00:00Z"),
			("%.:unix-time:D.timeZone:UTC:++", .string("1.5e9"), "2017-07-14T02:40:00Z"),
			("..:unix-time:timeZone:UTC:.dateOnly", .string("0"), "1970-01-01"),
			("..dateOnly", .string("x"), nil),
			("%-.d", .string("not a date"), "not a date"),
		],
	)
	func `renders chronologic placeholders`(format: String, value: JSON.Node, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%.d", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone:system:++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			(#"%.D.timeZone:s\ystem:++"#, "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone::++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone:UTC:.timeZone++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-19T02:39:23+09:00"),
			("%.D.timeZone:GMT+5:++", "Asia/Tokyo", "2020-03-18T17:39:23Z", "2020-03-18T22:39:23+05:00"),
			("%.D.timeZone:Asia/Tokyo:.dateOnly++", "America/New_York", "2020-03-18T17:39:23Z", "2020-03-19"),
			// A date-only value's date is independent of time zones
			("%.D.timeZone:Pacific/Honolulu:++", "America/New_York", "2020-03-18", "2020-03-18"),
			("%.D.timeZone:Pacific/Kiritimati:++", "Pacific/Honolulu", "2020-03-18", "2020-03-18"),
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
			("%.c", "17:39:23", String?.some("17:39:23-04:00")),
			("%.c", "17:39:23.1234Z", "13:39:23.123-04:00"),
			// A time-only value is converted between time zones as if on the
			// reference date
			("%.C.timeOnlyTimeZone:UTC:++", "17:39:23+02:00", "15:39:23Z"),
			("%.C.timeOnlyTimeZone:America/New_York,2020-01-15:++", "17:39:23Z", "12:39:23-05:00"),
			("%.C.timeOnlyTimeZone:America/New_York,2020-07-15:++", "17:39:23Z", "13:39:23-04:00"),
			("%.C.timeOnlyTimeZone:America/New_York:++", "17:39:23Z", "13:39:23-04:00"),
			("%.C.timeOnlyTimeZone:America/New_York,+10000-07-15:++", "17:39:23Z", "13:39:23-04:00"),
			("[%.c]", "24:00:00", nil),
			("[%.c]", "23:59:60", nil),
			("[%.c]", "17:39:23+19:00", nil),
			("%.C.timeOnlyTimeZone:UTC:++", "17:39:23+18:00", "23:39:23Z"),
			("%.C.timeOnlyTimeZone:UTC:++", "17:39:23z", "17:39:23Z"),
			// Only a datetime's seconds can be omitted
			("[%.c]", "17:39", nil),
			("[%.c]", "17:39Z", nil),
			// A time-only value has no date, so `%.d` & `%.D` do not match it, while
			// `%.c` & `%.C` match only it
			("%.D.dateOnly+-+", "17:39:23", "-"),
			("%.D.dateOnly+-+", "2020-03-18T17:39:23Z", "2020-03-18"),
			("[%.c]", "2020-03-18T17:39:23Z", nil),
			("%m.d.c+", "17:39:23", "17:39:23-04:00"),
			("%m.d.c+", "2020-03-18", "2020-03-18"),
			("..dateOnly", "17:39:23", nil),
			// A top-level pipeline applies `timeOnlyTimeZone` to a time-only value &
			// `timeZone` to a date
			("..timeOnlyTimeZone:UTC:", "17:39:23+02:00", "15:39:23Z"),
			("..timeZone:UTC:", "2020-03-18T17:39:23+02:00", "2020-03-18T15:39:23Z"),
			("..timeZone:UTC:", "17:39:23", nil),
			("..timeOnlyTimeZone:UTC:", "2020-03-18T17:39:23Z", nil),
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
	func `%.v matches a version`(version: String) throws {
		#expect(try rendered("%.v", .string(version)) == version)
	}

	@Test(arguments: ["", "a1", "1..2", "1.", "٣.1", "½", "1.0 beta", "1.0_b", "1.0!"])
	func `%.v does not match a non-version`(value: String) throws {
		#expect(try rendered("[%.v]", .string(value)) == nil)
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
			("%.C.dateOnly++", .invalidPipeline("<time-only-pipeline>")),
			("%.C.timeZone:UTC:++", .invalidPipeline("<time-only-pipeline>")),
			("%.D.timeOnlyTimeZone:UTC:++", .invalidPipeline("<date-pipeline>")),
			(".timeZone.timeOnlyTimeZone", .invalidPipeline("<value-transform-pipeline>")),
			("%.C%C.dateOnly++++", .invalidPipeline("<time-only-pipeline>")),
			("%I..:de:uppercase+", .numberCoercionArgumentsNotSupported("uppercase")),
			("%.:,,x:n", .invalidNumberCoercionArguments),
			("%.:,.:n", .invalidNumberCoercionArguments),
			("%.:,,,,", .invalidNumberCoercionArguments),
			("%.:nowhere:n", .invalidLocaleIdentifier("nowhere")),
			("%.:,,,,,(:n", .invalidTriviaRegex("(")),
			("%.:,,,,,,[:n", .invalidTriviaRegex("[")),
			("%_n", .invalidLetter("_")),
			("%.:de:d", .numberCoercionArgumentsNotSupported("d")),
			("%+n", .invalidModifier("n")),
			("%-i", .invalidModifier("i")),
			("%.m", .invalidModifier("m")),
			("%x", .invalidLetter("x")),
			("%", .missingPredicate),
			(":name", .unknownPreset("name")),
			(":default%i", .invalidPresetName("default%i")),
			(":my-name_2", .unknownPreset("my-name_2")),
			(":a b", .invalidPresetName("a b")),
			(":-end", .invalidPresetName("-end")),
			(":a\\.b", .invalidPresetName("a.b")),
			(":é", .invalidPresetName("é")),
			(".bogus", .unknownTransform("bogus")),
			(".initialUppercase", .unknownTransform("initialUppercase")),
			(".sentenceCase", .unknownTransform("sentenceCase")),
			(".numberFormat.round", .invalidPipeline("<value-transform-pipeline>")),
			(".uppercase.round", .invalidPipeline("<value-transform-pipeline>")),
			(".endJustify", .unknownTransform("endJustify")),
			(".uppercase%i", .unexpectedCharacter("%")),
			("%N.uppercase++", .invalidPipeline("<number-pipeline>")),
			("%S.round++", .invalidPipeline("<string-pipeline>")),
			("%Ix+", .invalidPipeline("<named-format-pipeline>")),
			("%I+", .invalidPipeline("<named-format-pipeline>")),
			("%L+", .invalidPipeline("<string-pipeline>")),
			("%L..uppercase+", .invalidPipeline("<string-pipeline>")),
			("%S.uppercase+%L..round++", .invalidPipeline("<unconditional-string-pipeline>")),
			("%S.uppercase+%L..uppercase++", .invalidPipeline("<unconditional-string-pipeline>")),
			("%S.uppercase+%I..trimWhitespace..round++", .invalidPipeline("<unconditional-pipeline>")),
			("%S.uppercase+%I..round++", .invalidPipeline("<unconditional-pipeline>")),
			("%S.uppercase+..round+", .invalidPipeline("<unconditional-pipeline>")),
			("%S..uppercase++", .invalidPipeline("<string-pipeline>")),
			("%N..round++", .invalidPipeline("<number-pipeline>")),
			("%N.numberFormat..uppercase++", .invalidPipeline("<number-pipeline>")),
			("%.D.dateOnly..timeZone:UTC:++", .invalidPipeline("<date-pipeline>")),
			("%.D..timeOnlyTimeZone:UTC:++", .invalidPipeline("<date-pipeline>")),
			("%.C..dateOnly++", .invalidPipeline("<time-only-pipeline>")),
			(#".\bogus"#, .unknownTransform("bogus")),
			(#".ro\xnd"#, .unknownTransform("roxnd")),
			(#".ro\"#, .danglingEscape),
			(#".\"#, .danglingEscape),
			("%I..uppercase..lowercase+", .invalidPipeline("<named-format-pipeline>")),
			(".round.uppercase", .invalidPipeline("<value-transform-pipeline>")),
			(".round..round", .invalidPipeline("<value-transform-pipeline>")),
			(".uppercase..uppercase", .invalidPipeline("<value-transform-pipeline>")),
			(".numberFormat..uppercase", .invalidPipeline("<value-transform-pipeline>")),
			(".dateOnly..timeOnlyTimeZone:UTC:", .invalidPipeline("<value-transform-pipeline>")),
			(".dateOnly.timeZone:UTC:", .invalidPipeline("<value-transform-pipeline>")),
			("%.:unix-time:c", .dateCoercionArgumentsNotSupported("c")),
			("%.:iso:c", .dateCoercionArgumentsNotSupported("c")),
			("%.:iso-time:C%c++", .invalidDateCoercionArguments),
			("%.:iso-time:D%d++", .invalidDateCoercionArguments),
			("%.:iso:n", .dateCoercionArgumentsNotSupported("n")),
			("%.:iso,unix-time:b", .dateCoercionArgumentsNotSupported("b")),
			("..:iso:timeOnlyTimeZone:UTC:", .dateCoercionArgumentsNotSupported("timeOnlyTimeZone")),
			("%.:unix-time,:d", .invalidDateCoercionArguments),
			("%.:unix-time,,,,,,:d", .invalidDateCoercionArguments),
			("..:unix-time,:dateOnly", .invalidDateCoercionArguments),
			("%.:iso-date:D.timeZone:UTC:+-+", .invalidPipeline("<date-only-pipeline>")),
			("%.:iso-date,iso-date:D.timeZone:UTC:+-+", .invalidPipeline("<date-only-pipeline>")),
			("%.:iso-date:D%D.timeZone:UTC:++-+", .invalidPipeline("<date-only-pipeline>")),
			("%.:iso-date:D.dateOnly+-+", .invalidPipeline("<date-only-pipeline>")),
			("%.:iso-date,iso-date:D.dateOnly+-+", .invalidPipeline("<date-only-pipeline>")),
			("%.:iso-date:D%D.dateOnly++-+", .invalidPipeline("<date-only-pipeline>")),
			("..:iso-date:timeZone:UTC:", .dateCoercionArgumentsNotSupported("timeZone")),
			("%.V..:iso-datetime:dateOnly+-+", .invalidPipeline("<version-pipeline>")),
			("%.V..:iso-datetime,iso-datetime:timeZone:UTC:+-+", .invalidPipeline("<version-pipeline>")),
			("%.V..timeZone:UTC:+-+", .invalidPipeline("<version-pipeline>")),
			("%.V..:iso:timeZone:UTC:+-+", .invalidPipeline("<version-pipeline>")),
			("%.V..:iso-date,iso-datetime:timeZone:UTC:+-+", .invalidPipeline("<version-pipeline>")),
			("%.:iso,:d", .invalidDateCoercionArguments),
			("%.:iso,de:d", .invalidDateCoercionArguments),
			("%N..:iso:dateOnly+-+", .invalidPipeline("<number-pipeline>")),
			("%N..:iso-date,iso-datetime:dateOnly+-+", .invalidPipeline("<number-pipeline>")),
			(".round..:iso:dateOnly", .invalidPipeline("<value-transform-pipeline>")),
			("%.:unix-time:n", .dateCoercionArgumentsNotSupported("n")),
			("..:unix-time:round", .dateCoercionArgumentsNotSupported("round")),
			("..:unix-time:uppercase", .dateCoercionArgumentsNotSupported("uppercase")),
			("%.D..round+-+", .invalidPipeline("<date-pipeline>")),
			("%.D..:,,,,,.*:round+-+", .invalidPipeline("<date-pipeline>")),
			("%.C..round+-+", .invalidPipeline("<time-only-pipeline>")),
			("%N..timeOnlyTimeZone:UTC:+-+", .invalidPipeline("<number-pipeline>")),
			("%.V..timeOnlyTimeZone:UTC:+-+", .invalidPipeline("<version-pipeline>")),
			(".dateOnly..round", .invalidPipeline("<value-transform-pipeline>")),
			(".round..timeOnlyTimeZone:UTC:", .invalidPipeline("<value-transform-pipeline>")),
			("%.D.dateOnly.timeZone:UTC:++", .invalidPipeline("<date-pipeline>")),
			("%.D..dateOnly++", .invalidPipeline("<date-pipeline>")),
			("%.V.uppercase+-+", .invalidPipeline("<version-pipeline>")),
			("%.V%V.uppercase+++", .invalidPipeline("<version-pipeline>")),
			(".timeOnlyTimeZone:UTC:..dateOnly", .invalidPipeline("<value-transform-pipeline>")),
			("%S%S+++", .invalidPipeline("<string-pipeline>")),
			("%N", .missingBlockTerminator),
			("%N+", .missingBlockTerminator),
			("%N++", .binaryPlaceholderLacksBlock),
			("%.N++", .binaryPlaceholderLacksBlock),
			("%U + +", .binaryPlaceholderLacksBlock),
			("%S<%n>++", .invalidLetter("n")),
			("%N+%n+", .invalidLetter("n")),
			("%mn+", .singleBranch),
			("%mi n+", .invalidLetter("i")),
			("%MbI++none+", .invalidLetter("I")),
			("%Mnk+none+", .invalidLetter("k")),
			("%mn-i+", .invalidLetter("i")),
			("%mnm+", .invalidLetter("m")),
			(".numberFormat:en,x,y:", .invalidTransformArguments(name: "numberFormat")),
			(".numberFormat:en,.,3,,.:", .invalidTransformArguments(name: "numberFormat")),
			(".numberFormat:nowhere:", .invalidLocaleIdentifier("nowhere")),
			(".scale:0,0,0:", .invalidTransformArguments(name: "scale")),
			(".scale:0,0:", .invalidTransformArguments(name: "scale")),
			(".scale:0,,18446744073709551615:", .invalidTransformArguments(name: "scale")),
			(".scale:0,101,0:", .invalidTransformArguments(name: "scale")),
			(".scale:0,,101:", .invalidTransformArguments(name: "scale")),
			(".scale:,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:6,,0,1:", .invalidTransformArguments(name: "scale")),
			(".scale:x,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:-,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:--1,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:+-1,,0:", .invalidTransformArguments(name: "scale")),
			(".numberFormat:en,,,,,:", .invalidTransformArguments(name: "numberFormat")),
			(".numberFormat:en,.,3,,.", .invalidTransformArguments(name: "numberFormat")),
			(".group", .unknownTransform("group")),
			(".timeZone:UTC,2020-01-01:", .invalidTransformArguments(name: "timeZone")),
			(".timeOnlyTimeZone:UTC,UTC:", .invalidTransformArguments(name: "timeOnlyTimeZone")),
			(".timeOnlyTimeZone:UTC,2020-02-30:", .invalidTransformArguments(name: "timeOnlyTimeZone")),
			(".timeOnlyTimeZone:UTC,2020-01-01,2020-01-02:", .invalidTransformArguments(name: "timeOnlyTimeZone")),
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
	func `a directly absent format-block defaults to an empty string`(format: String) throws {
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
