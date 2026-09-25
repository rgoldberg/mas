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
				Format.nullaryPlaceholder(for: .init(type: .number, coercion: .lenient)),
				TypeDeterminant(type: .number, coercion: .lenient),
			),
			(.default(fieldName: "n"), .any),
			(.pipeline([.init(transform: .uppercase, isCoerced: false)]), .init(type: .string, coercion: nil)),
			(.pipeline([.init(transform: .uppercase, isCoerced: true)]), .any),
			(.pipeline([.init(transform: .round, isCoerced: true)]), .init(type: .number, coercion: .strict)),
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
			(Predicate.number, Coercion?.some(.lenient), JSON.Node?.some(.string("$5")), true),
			(.number, nil, .string("5"), false),
			(.number, .strict, .string("5"), true),
			(.string, nil, .null, false),
			(.chronologic, nil, .string("XYZ"), false),
			(.boolean, .strict, .string("true"), true),
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
}

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
