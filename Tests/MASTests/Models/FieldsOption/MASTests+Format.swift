//
// MASTests+Format.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `%i passes the value through at its original type`() throws {
		let number = try Format.default(fieldName: "n").rendered(value: .number(42), label: "L", name: "n")
		#expect(number?.isNumber(42) == true)
		#expect(try Format.default(fieldName: "n").rendered(value: nil, label: "L", name: "n") == nil)
	}

	@Test(
		arguments: [
			("-9223372036854775.808", true),
			("9223372036854775.807", true),
			("-9223372036854775.8081", false),
			("9223372036854775.808", false),
		],
	)
	func `a Unix time is chronologic iff its whole milliseconds fit in 64 bits`(
		unixTime: String,
		isChronologic: Bool,
	) {
		#expect((chronologic(from: .string(unixTime), isCoerced: true) != nil) == isChronologic)
	}

	@Test(
		arguments: [
			(JSON.Node.number(0), false, true),
			(.string("0"), false, false),
			(.string("0"), true, true),
			(.string(".5e3"), true, true),
			(.string("5."), true, false),
			(.string("1,000"), true, false),
			(.string("\u{0661}"), true, false),
		],
	)
	func `a string is a Unix time iff coerced`(value: JSON.Node, isCoerced: Bool, isChronologic: Bool) {
		#expect((chronologic(from: value, isCoerced: isCoerced) != nil) == isChronologic)
	}

	@Test
	func `formatting aborts the whole format, not just what precedes the failing placeholder`() throws {
		let format = Format.template(
			[
				.text("A"),
				.placeholder(.conditional(.init(predicate: .null, coercion: nil), .abortOnFailure(success: nil))),
				.text("B"),
			],
		)
		#expect(try format.rendered(value: .string("x"), label: "L", name: "n") == nil)
	}

	@Test(
		arguments: [
			(
				Predicate.number,
				Coercion?.some(.init(numberConventions: .canonical, triviaPrefixRegex: .any, triviaSuffixRegex: .empty)),
				JSON.Node?.some(.string("$5")),
				true,
			),
			(.number, nil, .string("5"), false),
			(.number, .default, .string("5"), true),
			(.string, nil, .null, false),
			(.date, nil, .string("XYZ"), false),
			(.timeOnly, nil, .string("2020-03-18"), false),
			(.boolean, .default, .string("true"), true),
		],
	)
	func `a value conforms to a matcher iff the matcher matches it`(
		predicate: Predicate,
		coercion: Coercion?,
		value: JSON.Node?,
		conforms: Bool,
	) {
		#expect(Matcher(predicate: predicate, coercion: coercion).conforms(value) == conforms)
	}

	@Test(
		arguments: [
			Placeholder.conditional(numberMatcher, .abortOnFailure(success: abortingBlock)),
			.conditional(numberMatcher, .binary(success: abortingBlock, failure: .empty)),
			.conditional(stringMatcher, .abortOnSuccess(failure: abortingBlock)),
			.conditional(stringMatcher, .binary(success: .empty, failure: abortingBlock)),
			.match(
				[.conditional(numberMatcher, isNegated: false, block: abortingBlock), .unconditional(.input, block: nil)],
				.abortOnNoMatch,
			),
			.match(
				[.conditional(stringMatcher, isNegated: true, block: abortingBlock), .unconditional(.input, block: nil)],
				.abortOnNoMatch,
			),
			.match(
				[.conditional(stringMatcher, isNegated: false, block: nil), .unconditional(.input, block: abortingBlock)],
				.abortOnNoMatch,
			),
			.match(
				[
					.conditional(stringMatcher, isNegated: false, block: nil),
					.conditional(.init(predicate: .boolean, coercion: nil), isNegated: false, block: nil),
				],
				.binary(failure: abortingBlock),
			),
		],
	)
	func `a block that aborts aborts the whole format`(placeholder: Placeholder) throws {
		let format = Format.template([.text("A"), .placeholder(placeholder), .text("B")])
		#expect(try format.rendered(value: .number(5), label: "L", name: "n") == nil)
	}
}

private let numberMatcher = Matcher(predicate: .number, coercion: nil)
private let stringMatcher = Matcher(predicate: .string, coercion: nil)

/// A block that aborts for any non-`null` value.
private let abortingBlock =
	Format.template([.placeholder(.conditional(.init(predicate: .null, coercion: nil), .abortOnFailure(success: nil)))])

extension JSON.Node {
	/// Whether this is the JSON number `number`.
	func isNumber(_ number: Int) -> Bool {
		if case let .number(value) = self {
			"\(value)" == "\(number)"
		} else {
			false
		}
	}
}
