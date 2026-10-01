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
	@Test(
		arguments: [
			("formattedPrice", SortOptionSet.NonconformingComparison.least),
			("price", .allConforming),
			("name", .allConforming),
		],
	)
	func `only formattedPrice's nonconforming values compare as least by default`(
		fieldName: String,
		nonconformingComparison: SortOptionSet.NonconformingComparison,
	) {
		for outputFormat in [OutputFormat.json(.default), .keyValue(.default)] {
			#expect(
				defaultSortOptionSet(forFieldNamed: fieldName, outputFormat: outputFormat).nonconformingComparison
					== nonconformingComparison,
			)
		}
	}

	@Test(arguments: ["minimumOSVersion", "newVersion", "version"])
	func `a version field's default number segments are versions`(fieldName: String) {
		for outputFormat in [OutputFormat.json(.default), .keyValue(.default), .table(.default)] {
			#expect(defaultSortOptionSet(forFieldNamed: fieldName, outputFormat: outputFormat).numberSegments == .versions)
		}
	}

	@Test(arguments: ["name", "price", nil])
	func `a non-version, non-formattedPrice field's default number segments are grouped numbers`(fieldName: String?) {
		for outputFormat in [OutputFormat.json(.default), .keyValue(.default), .table(.default)] {
			#expect(
				defaultSortOptionSet(forFieldNamed: fieldName, outputFormat: outputFormat).numberSegments
					== .groupedNumeric(.default),
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
	func `formattedPrice sorts by its number segments, Free first`(
		lhs: JSON.Node,
		rhs: JSON.Node,
		result: ComparisonResult,
	) throws {
		let fieldSpec = try resolvedFieldsConfig(
			from: ".formattedPrice/1",
			standard: SelectedFieldsConfig(
				fieldSpecs: [
					.init(name: "formattedPrice", label: "Price", format: .default(fieldName: "formattedPrice"), sortSpec: nil),
				],
			),
			all: .init(),
			outputFormat: .keyValue(.default),
		)
		.fieldSpecs[0]
		#expect(
			try #require(fieldSpec.sortSpec).compare(.init(input: lhs, output: nil), .init(input: rhs, output: nil))
				== result,
		)
	}
}
