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
			("bundleID", "Bundle ID", Justification.start),
			("fileSizeBytes", "Size", .end),
			("adamID", "ADAM ID", .end),
			("trackName", "trackName", .start),
		],
	)
	func `a built-in field spec is labeled & justified per mas.md`(
		fieldName: String,
		label: String,
		justification: Justification,
	) {
		let fieldSpec = builtInFieldSpec(forFieldNamed: fieldName)
		#expect(fieldSpec.label == label)
		#expect(fieldSpec.justification == justification)
		#expect(fieldSpec.sortSpec == nil)
	}

	@Test
	func `an unlisted field's built-in field spec is formatted as %i`() {
		#expect(builtInFieldSpec(forFieldNamed: "trackName").format == .default(fieldName: "trackName"))
	}

	@Test
	func `only newVersion's built-in field spec is synthesized`() {
		#expect(builtInFieldSpec(forFieldNamed: "newVersion").isSynthesized)
		#expect(!builtInFieldSpec(forFieldNamed: "version").isSynthesized)
	}

	@Test
	func `a user-facing unlisted field's field spec is its built-in field spec`() {
		let unlistedFieldSpecs = BaseIncludesAllFieldsConfig()
			.unlistedFieldSpecs(in: [JSON.Object([("bundleID", .string("a.b")), ("trackName", .string("A"))])])
		#expect(unlistedFieldSpecs.map(\.label) == ["Bundle ID", "trackName"])
	}

	@Test
	func `a user-facing unlisted fileSizeBytes's field spec is end-justified`() {
		let unlistedFieldSpecs = BaseIncludesAllFieldsConfig()
			.unlistedFieldSpecs(in: [JSON.Object([("fileSizeBytes", .string("1")), ("trackName", .string("A"))])])
		#expect(unlistedFieldSpecs.map(\.justification) == [.end, .start])
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
