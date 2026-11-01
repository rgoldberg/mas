//
// MASTests+FieldsConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import BigInt
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			("D", ["b", "a", "c"]),
			("D-", ["c", "a", "b"]),
			("aD", ["c", "b", "a"]),
			("aD-", ["a", "b", "c"]),
			("Dar", ["c", "b", "a"]),
			("Df-", ["a", "b", "c"]),
			("afD-", ["c", "a", "b"]),
			("fD", ["b", "a", "c"]),
		],
	)
	func `document-order orders each item's fields by its own key order`(order: String, expected: [String]) throws {
		let fieldSpecs = ["a", "b", "c"].map(FieldSpec.default(forName:))
		let object = JSON.Object([("b", .number(1)), ("a", .number(2))])
		let fieldOrder = try parseFieldsConfig("/" + order, outputFormat: .json(.default)).fieldOrder
		#expect(fieldOrder.itemMembers(fieldSpecs, for: object).map(\.fieldSpec.name) == expected)
	}

	@Test(
		arguments: [
			("P", ["adamID", "bundleID", "rating", "size"]),
			("P-", ["size", "rating", "bundleID", "adamID"]),
			("Pf-", ["bundleID", "adamID", "size", "rating"]),
			("aP", ["rating", "size", "adamID", "bundleID"]),
			("aP-", ["bundleID", "adamID", "size", "rating"]),
			("Paf-", ["size", "rating", "bundleID", "adamID"]),
		],
	)
	func `positional-order orders visible unlisted fields as unpositioned fields`(order: String, names: [String])
	throws {
		let config = try parseFieldsConfig("@all/" + order)
		let objects = [JSON.Object([("adamID", .number(1)), ("rating", .number(2))]), .init([("size", .number(3))])]
		#expect(
			config.fieldOrder.applied(to: config.fieldSpecs, unlisted: config.unlistedFieldSpecs(in: objects)).map(\.name)
				== names,
		)
	}

	@Test(
		arguments: [
			("I+", ["1", "3", "2"]),
			("I+/-", ["3", "1", "2"]),
			("I-", ["2", "1", "3"]),
			("I-/-", ["2", "3", "1"]),
		],
	)
	func `field order sort-option-set tiebreaks by position per field-order-tiebreaker`(
		options: String,
		expectedLabels: [String],
	) throws {
		let fieldSpecs = [("a", "1"), ("b", "2"), ("a", "3")].map(fieldSpec(name:label:))
		let fieldOrder = try parseFieldsConfig("/" + options).fieldOrder
		#expect(fieldOrder.applied(to: fieldSpecs, unlisted: .init()).map(\.label) == expectedLabels)
	}

	@Test(
		arguments: [
			("D", ["2", "1", "4", "3", "5"]),
			("D/-", ["2", "4", "1", "5", "3"]),
			("D-", ["3", "5", "1", "4", "2"]),
			("D-/-", ["5", "3", "4", "1", "2"]),
		],
	)
	func `document-order tiebreaks by position per field-order-tiebreaker`(
		options: String,
		expectedLabels: [String],
	) throws {
		let fieldSpecs = [("a", "1"), ("b", "2"), ("c", "3"), ("a", "4"), ("d", "5")].map(fieldSpec(name:label:))
		let object = JSON.Object([("b", .number(1)), ("a", .number(2))])
		let fieldOrder = try parseFieldsConfig("/" + options, outputFormat: .json(.default)).fieldOrder
		#expect(fieldOrder.itemMembers(fieldSpecs, for: object).map(\.fieldSpec.label) == expectedLabels)
	}
}

private func parseFieldsConfig(_ value: String, outputFormat: OutputFormat = .table(.default))
throws(ParsingError) -> any FieldsConfig {
	try resolvedFieldsConfig(from: value, standard: standardFixture, all: allFixture, outputFormat: outputFormat)
}

private func fieldSpec(name: String, label: String) -> FieldSpec {
	.init(name: name, label: label, format: .default(fieldName: name), sortSpec: nil)
}

private let adamIDFieldSpec = FieldSpec(
	name: "adamID",
	label: "adamID",
	format: .default(fieldName: "adamID"),
	sortSpec: .init(priority: 1000, isEnabled: true, optionSet: .default),
)
private let bundleIDFieldSpec =
	FieldSpec(name: "bundleID", label: "bundleID", format: .default(fieldName: "bundleID"), sortSpec: nil)

private let standardFixture = SelectedFieldsConfig(fieldSpecs: [adamIDFieldSpec])
private let allFixture = BaseIncludesAllFieldsConfig(fieldSpecs: [adamIDFieldSpec, bundleIDFieldSpec])
