//
// MASTests+AppStoreFieldDefaults.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: [JSON.Node.string("$1,299.99"), .string("US$5"), .string("Free"), .string("5,00 €")])
	func `a price field's default format renders the value as is`(value: JSON.Node) throws {
		#expect(
			try defaultFieldFormat(forFieldNamed: "formattedPrice")
				.rendered(
					value: value,
					label: "Price",
					name: "formattedPrice",
				)
				.stringValue
				== value.stringValue,
		)
	}

	@Test(arguments: ["formattedPrice", "price"])
	func `a price field's default format is typed as a number coerced with any trivia`(fieldName: String) {
		let typeDeterminant = defaultFieldFormat(forFieldNamed: fieldName).typeDeterminant
		#expect(typeDeterminant.type == .number)
		#expect(typeDeterminant.coercion?.triviaPrefixRegex == .any)
		#expect(typeDeterminant.coercion?.triviaSuffixRegex == .any)
	}

	@Test(arguments: [("minimumOSVersion", FieldType.version), ("newVersion", .version), ("name", .any)])
	func `a field's default format is typed per its field name`(fieldName: String, type: FieldType) {
		#expect(defaultFieldFormat(forFieldNamed: fieldName).typeDeterminant.type == type)
	}

	@Test(
		arguments: [
			("formattedPrice", SortOptionSet.NonconformingComparison.least),
			("price", .greatest),
			("name", .greatest),
		],
	)
	func `only formattedPrice's nonconforming values compare as least by default`(
		fieldName: String,
		nonconformingComparison: SortOptionSet.NonconformingComparison,
	) {
		for outputFormat in [OutputFormat.json, .keyValue(.default)] {
			#expect(
				defaultSortOptionSet(forFieldNamed: fieldName, outputFormat: outputFormat).nonconformingComparison
					== nonconformingComparison,
			)
		}
	}

	@Test(
		arguments: [
			(JSON.Node.string("Free"), JSON.Node.string("$5"), ComparisonResult.orderedAscending),
			(.string("$10"), .string("$5"), .orderedDescending),
			(.string("US$1,299.99"), .string("US$999"), .orderedDescending),
		],
	)
	func `formattedPrice sorts by its coerced number, Free first`(
		lhs: JSON.Node,
		rhs: JSON.Node,
		result: ComparisonResult,
	) throws {
		let fieldSpec = try resolvedFieldsConfig(
			from: ".formattedPrice/1",
			standard: SelectedFieldsConfig(
				fieldSpecs: [
					.init(
						name: "formattedPrice",
						label: "Price",
						format: defaultFieldFormat(forFieldNamed: "formattedPrice"),
						sortSpec: nil,
					),
				],
			),
			all: .init(),
			outputFormat: .keyValue(.default),
		)
		.fieldSpecs[0]
		#expect(
			try #require(fieldSpec.sortSpec).compare(
				.init(input: lhs, output: nil),
				.init(input: rhs, output: nil),
				typeDeterminant: fieldSpec.format.typeDeterminant,
			)
				== result,
		)
	}
}
