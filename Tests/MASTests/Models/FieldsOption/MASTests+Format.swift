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
		#expect(number.isNumber(42))
		#expect(try Format.default(fieldName: "n").rendered(value: nil, label: "L", name: "n").stringValue == nil)
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
		#expect(try format.rendered(value: .string("x"), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test(
		arguments: [
			(
				Format.nullaryPlaceholder(for: .init(type: .number, coercion: .default)),
				TypeDeterminant(type: .number, coercion: .default),
			),
			(.default(fieldName: "n"), .any),
			(.pipeline([.init(transform: .uppercase, coercion: nil)]), .init(type: .string, coercion: nil)),
			(.pipeline([.init(transform: .uppercase, coercion: .default)]), .any),
			(.pipeline([.init(transform: .round, coercion: .default)]), .init(type: .number, coercion: .default)),
			(
				.template(
					[
						.placeholder(.conditional(.init(predicate: .string, coercion: nil), .abortOnFailure(success: nil))),
						.placeholder(
							.match(
								[
									.conditional(.init(predicate: .number, coercion: nil), isNegated: false, block: nil),
									.conditional(.init(predicate: .chronologic, coercion: nil), isNegated: false, block: nil),
									.conditional(.init(predicate: .version, coercion: nil), isNegated: false, block: nil),
								],
								.abortOnNoMatch,
							),
						),
					],
				),
				.init(type: .chronologic, coercion: nil),
			),
		],
	)
	func `a format's type determinant is its 1st matcher or transform of the most specific type`(
		format: Format,
		typeDeterminant: TypeDeterminant,
	) {
		#expect(format.typeDeterminant == typeDeterminant)
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
			(.chronologic, nil, .string("XYZ"), false),
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
			.conditional(numberMatcher, .binary(success: abortingBlock, failure: nil)),
			.conditional(stringMatcher, .abortOnSuccess(failure: abortingBlock)),
			.conditional(stringMatcher, .binary(success: nil, failure: abortingBlock)),
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
		#expect(try format.rendered(value: .number(5), label: "L", name: "n").stringValue?.isEmpty == true)
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
