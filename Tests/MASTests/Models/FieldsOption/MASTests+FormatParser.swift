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
			("%u", JSON.Node?.none, String?.some("")),
			("%u", .string("x"), ""),
			("x%ny", .string("a"), ""),
			// Nullary abort-on-success: on failure, the field value
			("%-u", .string("x"), "x"),
			("%-u", .null, ""),
			// Non-nullary abort-on-failure
			("%+N.round+", .number(5.6), "6"),
			("[%+N.round+]", .string("x"), ""),
			// Non-nullary abort-on-success
			("%-Nnot a number+", .string("x"), "not a number"),
			("[%-Nnot a number+]", .number(5), ""),
			// Binary
			("%N+fail+", .number(5), "5"),
			("%N+fail+", .string("x"), "fail"),
			("[%N++]", .string("x"), "[]"),
			("%S.uppercase++", .string("abc"), "ABC"),
			("%.T+no+", .string("true"), "true"),
			("%.T+no+", .string("false"), "no"),
			("%T+no+", .string("true"), "no"),
			("%E(empty)+%i+", .string(""), "(empty)"),
			("%W(blank)+%i+", .string(" \t"), "(blank)"),
			("%W(blank)+%i+", .string(" a "), " a "),
		],
	)
	func `renders scalar conditional placeholders`(format: String, value: JSON.Node?, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%_n", JSON.Node.string("US$1,234.50"), "US$1,234.50"),
			("%_N.round++", .string("US$1,234.50"), "US$1235"),
			("%_N.absoluteValue++", .string("-3 MB"), "3 MB"),
			("[%_n]", .string("1 of 2"), ""),
			("[%_n]", .string("none"), ""),
			("%.n", .string("4.50"), "4.5"),
			("[%.n]", .string("4.5a"), ""),
			("[%.n]", .string("nan"), ""),
			("[%.n]", .string("0x10"), ""),
			("%.n", .string("-1e3"), "-1000"),
			("%n", .number(4.5), "4.5"),
		],
	)
	func `renders coerced number placeholders`(format: String, value: JSON.Node, expected: String) throws {
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
			("%I+", "v"),
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
			("%C%C.dateOnly+++", .string("2020-03-18T17:39:23Z"), "2020-03-18"),
			("%V[%v]++", .string("1.2"), "[1.2]"),
			("%U(%u)++", .null, "()"),
		],
	)
	func `evaluates a block-placeholder against the enclosing matcher's value`(
		format: String,
		value: JSON.Node,
		expected: String,
	) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			("%mn-s+", JSON.Node.number(5), String?.some("5")),
			("[%mn-s+]", .string("x"), ""),
			("%mn-s+", .bool(true), "true"),
			("%mn-SnotString++", .bool(true), "notString"),
			("%mn.Bbool:%b+k+", .string("true"), "bool:true"),
			("%mnK.uppercase++", .string("x"), "N"),
			("%mnL++", .string("x"), "L"),
			("%Mnb+none+", .string("x"), "none"),
			("%Mnb++", .string("x"), ""),
		],
	)
	func `evaluates match placeholders`(format: String, value: JSON.Node, expected: String?) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			(".uppercase", JSON.Node.string("abc"), "ABC"),
			("..uppercase", .number(5), "5"),
			(".round", .number(5.6), "6"),
			("..round", .string("5.6"), "6"),
			("..round", .string("x"), ""),
			(".round.group:.,3:", .number(1_234_567.8), "1.234.568"),
			(".group:\\,,2:", .number(123_456), "12,34,56"),
			(".group: ,3:", .number(1234), "1 234"),
			(".group:de_DE:", .number(1_234_567), "1.234.567"),
			("..dateOnly", .string("2020-03-18"), "2020-03-18"),
			(".initialTitlecase", .string("abc def"), "Abc def"),
			(".trimWhitespace", .string("  x  "), "x"),
			(".lowercase", .string("ABC"), "abc"),
			(".absoluteValue", .number(-5.5), "5.5"),
			(".round", .number(1e30), "1e+30"),
			(".absoluteValue", .number(-1e30), "1e+30"),
			(".scale:10,0,,0:", .number(1e30), "1e+30"),
		],
	)
	func `applies a format-block's value-transform-pipeline`(format: String, value: JSON.Node, expected: String)
	throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(
		arguments: [
			(".uppercase", JSON.Node.number(5)),
			(".round", .string("5.6")),
			(".dateOnly", .string("not a date")),
		],
	)
	func `an uncoerced transform on an input not of its input type is an error`(format: String, value: JSON.Node)
	throws {
		let fieldSpec = try parsedFieldSpec(format)
		#expect(throws: FormattingError.self) { try fieldSpec.format.rendered(value: value, label: "L", name: "n") }
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
		#expect(try parsedFieldSpec(".endJustify").format.rendered(value: .number(5), label: "L", name: "n").isNumber(5))
	}

	@Test(
		arguments: [
			("%c", JSON.Node.string("2020-03-18"), "2020-03-18"),
			("%C.timeZone:UTC:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%C.timeZone:utc:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T17:39:23Z"),
			("%C.timeZone:Asia/Tokyo:++", .string("2020-03-18T17:39:23Z"), "2020-03-19T02:39:23+09:00"),
			("%C.timeZone:asia/tokyo:++", .string("2020-03-18T17:39:23Z"), "2020-03-19T02:39:23+09:00"),
			("%C.timeZone:-05\\:30:++", .string("2020-03-18T17:39:23Z"), "2020-03-18T12:09:23-05:30"),
			("%C.timeZone:UTC:++", .number(0), "1970-01-01T00:00:00Z"),
			("[%c]", .string("not a date"), ""),
			("%-c", .string("not a date"), "not a date"),
		],
	)
	func `renders chronologic placeholders`(format: String, value: JSON.Node, expected: String) throws {
		#expect(try rendered(format, value) == expected)
	}

	@Test(arguments: ["1", "1.0b", "10.2.3-beta"])
	func `%v matches a version`(version: String) throws {
		#expect(try rendered("%v", .string(version)) == version)
	}

	@Test(arguments: ["", "a1", "1..2", "1.", "٣.1", "½"])
	func `%v does not match a non-version`(value: String) throws {
		#expect(try rendered("[%v]", .string(value))?.isEmpty == true)
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
			("%_b", .coercionNotSupported("b")),
			("%.v", .coercionNotSupported("v")),
			("%+n", .invalidModifier("n")),
			("%-i", .invalidModifier("i")),
			("%.m", .invalidModifier("m")),
			("%x", .invalidLetter("x")),
			("%", .missingPredicate),
			(":name", .unknownNamedFormat("name")),
			(".bogus", .unknownTransform("bogus")),
			(".group.round", .invalidPipeline("<value-transform-pipeline>")),
			(".uppercase.round", .invalidPipeline("<value-transform-pipeline>")),
			(".uppercase.endJustify", .invalidPipeline("<pipeline>")),
			("..endJustify", .coercionNotSupported(".")),
			(".uppercase%i", .unexpectedCharacter("%")),
			("%N.uppercase++", .invalidPipeline("<number-pipeline>")),
			("%S.round++", .invalidPipeline("<string-pipeline>")),
			("%I.uppercase+", .invalidPipeline("<unconditional-pipeline>")),
			("%Ix+", .invalidPipeline("<unconditional-pipeline>")),
			("%N", .missingBlockTerminator),
			("%N+", .missingBlockTerminator),
			("%S<%n>++", .invalidLetter("n")),
			("%N+%n+", .invalidLetter("n")),
			("%mn+", .singleBranch),
			("%mi n+", .unconditionalBranchNotLast),
			("%mn-i+", .invalidModifier("i")),
			("%mnm+", .invalidLetter("m")),
			(".group::", .invalidTransformArguments(name: "group")),
			(".group:x,0:", .invalidTransformArguments(name: "group")),
			(".group:nowhere:", .invalidTransformArguments(name: "group")),
			(".scale:1,0,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,0,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,99999999999999999999,,0:", .invalidTransformArguments(name: "scale")),
			(".scale:10,0,,18446744073709551615:", .invalidTransformArguments(name: "scale")),
			(".group:.,18446744073709551615:", .invalidTransformArguments(name: "group")),
			(".timeZone::", .invalidTransformArguments(name: "timeZone")),
			(".timeZone:Nowhere/Land:", .invalidTransformArguments(name: "timeZone")),
			("%S\\", .danglingEscape),
		],
	)
	func `reports a format-block syntax error`(format: String, error: ParsingError) {
		#expect(throws: error) { try parsedFieldSpec(format) }
	}

	@Test
	func `an absent format-block defaults to the nullary placeholder for the working format's type determinant`()
	throws {
		let config = try resolvedFieldsConfig(
			from: ".price:",
			standard: SelectedFieldsConfig(
				fieldSpecs: [
					.init(
						name: "price",
						label: "Price",
						format: .template(
							[
								.text("$"),
								.placeholder(.conditional(
									.init(predicate: .number, coercion: .lenient),
									.binary(success: nil, failure: nil),
								)),
							],
						),
						sortSpec: nil,
					),
				],
			),
			all: .init(),
			outputFormat: .keyValue,
		)
		#expect(
			config.fieldSpecs[0].format
				== .nullaryPlaceholder(for: .init(type: .number, coercion: .lenient)),
		)
	}
}

private func parsedFieldSpec(_ format: String) throws(ParsingError) -> FieldSpec {
	try resolvedFieldsConfig(from: "n:" + format, standard: SelectedFieldsConfig(), all: .init(), outputFormat: .json)
		.fieldSpecs[0]
}

private func rendered(_ format: String, _ value: JSON.Node?) throws -> String? {
	try parsedFieldSpec(format).format.rendered(value: value, label: "L", name: "n").stringValue
}
