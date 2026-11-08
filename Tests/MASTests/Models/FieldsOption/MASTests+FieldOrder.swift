//
// MASTests+FieldOrder.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import BigInt
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			("/P", FieldOrder.positional(.init())),
			("/-P", .positional(.init(direction: .descending))),
			("/P-", .positional(.init(direction: .descending))),
			("/DP", .positional(.init())),
			("/zP", .positional(.init())),
			(
				"/aDPf-",
				.positional(.init(
					direction: .descending,
					unpositionedFieldComparison: .least,
					unpositionedFieldPlacement: .fixed,
				)),
			),
			("/D", .document(.init())),
			("/D-", .document(.init(direction: .descending))),
			("/D/T-", .document(.init())),
			("/D-/T+", .document(.init(direction: .descending))),
			("/PD/T-", .document(.init())),
			("/D / T -", .document(.init())),
			("/D//-", .document(.init())),
			("/aD", .document(.init(unpositionedFieldComparison: .least))),
			("/PaD f-z", .document(.init(direction: .descending, unpositionedFieldPlacement: .fixed))),
		],
	)
	func `field order positional-order & document-order`(value: String, fieldOrder: FieldOrder) throws {
		#expect(try parseFieldsConfig(value, outputFormat: .json(.default)).fieldOrder == fieldOrder)
	}

	@Test(
		arguments: [
			("@all/P", ["adamID", "bundleID"]),
			("@all/P-", ["bundleID", "adamID"]),
			("@all/-P+", ["adamID", "bundleID"]),
			("@all/+P-", ["bundleID", "adamID"]),
			("@all/P-.%adamID", ["adamID", "bundleID"]),
			("@all/P-.%@1", ["bundleID", "adamID"]),
			("@all/P-.+@1", ["bundleID", "bundleID", "adamID"]),
			("@all/P-.-@1", ["adamID"]),
		],
	)
	func `positional-order's descending reverses positions before field spec edits`(value: String, names: [String])
	throws {
		#expect(try parseFieldSpecs(value).map(\.name) == names)
	}

	@Test(arguments: [("/P-", ["bundleID", "adamID"]), ("/P", ["bundleID", "adamID"]), ("/P+", ["adamID", "bundleID"])])
	func `positional-order reverses positions iff its direction differs from the working field order's`(
		value: String,
		names: [String],
	) throws {
		let standard = SelectedFieldsConfig(
			fieldSpecs: [bundleIDFieldSpec, adamIDFieldSpec], // Already reversed by `/P-`
			fieldOrders: .init(.positional(.init(direction: .descending))),
		)
		let fieldSpecs =
			try resolvedFieldsConfig(
				from: "@default" + value,
				standard: standard,
				all: allFixture,
				outputFormat: .table(.default),
			)
			.fieldSpecs
		#expect(fieldSpecs.map(\.name) == names)
	}

	@Test(arguments: [("/P-", ["bundleID", "adamID"]), ("/P", ["bundleID", "adamID"]), ("/P+", ["adamID", "bundleID"])])
	func `positional-order reverses positions iff its direction differs from the saved positional order's`(
		value: String,
		names: [String],
	) throws {
		var fieldOrders = FieldOrders(.positional(.init(direction: .descending)))
		fieldOrders.save(.byLabel(.default))
		let standard = SelectedFieldsConfig(
			fieldSpecs: [bundleIDFieldSpec, adamIDFieldSpec], // Already reversed by `/P-`
			fieldOrders: fieldOrders,
		)
		let fieldSpecs =
			try resolvedFieldsConfig(
				from: "@default" + value,
				standard: standard,
				all: allFixture,
				outputFormat: .table(.default),
			)
			.fieldSpecs
		#expect(fieldSpecs.map(\.name) == names)
	}

	@Test(
		arguments: [
			("@all/P-/I", ["bundleID", "adamID"]),
			("@all/P-/O/P", ["bundleID", "adamID"]),
			("@all/P-/O/P-", ["bundleID", "adamID"]),
			("@all/P-/O/P+", ["adamID", "bundleID"]),
			("@all/P-/P+", ["adamID", "bundleID"]),
		],
	)
	func `an overridden positional-order still reverses positions`(value: String, names: [String]) throws {
		#expect(try parseFieldSpecs(value).map(\.name) == names)
	}

	@Test(
		arguments: [
			("/O/P", "/P"),
			("/P/O", "/O"),
			("/iO/-O", "/iO-"),
			("/O/-", "/O-"),
			("/O / -", "/O-"),
			("/O/-P", "/P-"),
			("/O/-/P", "/P"),
			("/I/-O//-", "/O-//-"),
			("/O/a", "/Oa"),
			("/O/-/+", "/O+"),
			("/P/+-", "/P-"),
			("/O/T-", "/O"),
			("/T-/O", "/O"),
			("/O/T-/-", "/O-"),
		],
	)
	func `the last primary field order option set sets the field order`(value: String, equivalent: String) throws {
		let config = try parseFieldsConfig(value)
		let equivalentConfig = try parseFieldsConfig(equivalent)
		#expect(config.fieldOrder == equivalentConfig.fieldOrder)
		#expect(config.fieldSpecs == equivalentConfig.fieldSpecs)
	}

	@Test(
		arguments: [
			("/I+", SortOptionSet.Direction.ascending),
			("/I+/T-", .descending),
			("/T-/I+", .descending),
			("/T-/T+", .ascending),
			("/D/T-", .descending),
			("/P/T-", .descending),
			("/DP/T+", .ascending),
			("@none/T-", .descending),
			("@none/a/T-", .descending),
			("/T-/O/-", .descending),
			("@all/-/T+", .ascending),
		],
	)
	func `the last field-order-tiebreaker sets the tiebreak direction, whatever the field order's kind`(
		value: String,
		tiebreakDirection: SortOptionSet.Direction,
	) throws {
		let config = try parseFieldsConfig(value, outputFormat: .json(.default))
		#expect(config.fieldOrders.tiebreakDirection == tiebreakDirection)
	}

	@Test(arguments: [
		("/D/", ParsingError.missingFieldOrderOptionSet),
		("/I+/", .missingFieldOrderOptionSet),
		("/D/!", .invalidSortOption("!")),
		("/T", .missingFieldOrderTiebreakerDirection),
		("/D/T", .missingFieldOrderTiebreakerDirection),
		("/T/I", .missingFieldOrderTiebreakerDirection),
		("/Ta", .missingFieldOrderTiebreakerDirection),
		("/T-a", .unexpectedCharacter("a")),
		("/T-P", .unexpectedCharacter("P")),
		("/T--", .unexpectedCharacter("-")),
	])
	func `an invalid field order section is an error`(value: String, error: ParsingError) {
		#expect(throws: error) { try parseFieldsConfig(value, outputFormat: .json(.default)) }
	}

	@Test
	func `a transient fields config may save a field order of another kind`() throws {
		#expect(try parseFieldsConfig("/iO/D/P").fieldOrder == .positional(.init()))
	}

	@Test(arguments: ["/D", "/-D", "/P/D", "/D/T-", "/D/-"])
	func `document-order is unsupported for table output`(value: String) {
		#expect(throws: ParsingError.documentOrderUnsupportedForTable) { try parseFieldsConfig(value) }
	}

	@Test(arguments: [("/D-P", "/-P"), ("@none/-", "@none/P-"), ("@none/af", "@none/aPf"), ("/-", "/P-")])
	func `an overridden document-order is supported for table output, as is a positional adjustment set`(
		value: String,
		equivalent: String,
	) throws {
		let config = try parseFieldsConfig(value)
		let equivalentConfig = try parseFieldsConfig(equivalent)
		#expect(config.fieldOrder == equivalentConfig.fieldOrder)
		#expect(config.fieldSpecs == equivalentConfig.fieldSpecs)
	}

	@Test
	func `field order sort-option-set defaults source to output`() throws {
		guard case let .byLabel(sortSpec) = try parseFieldsConfig("/-i").fieldOrder else {
			Issue.record("Expected .byLabel")
			return
		}
		#expect(sortSpec.direction == .descending)
		guard case .byName = try parseFieldsConfig("/I+").fieldOrder else {
			Issue.record("Expected .byName")
			return
		}
	}

	@Test(
		arguments: [
			("/I-", "/i", "/I-i"),
			("/I-/T-", "/+", "/I+/T-"),
			("/I+/T-", "/I", "/I+/T-"),
			("/I+/T-", "/D", "/D/T-"),
			("/D-a/T-", "/Df", "/D-af/T-"),
			("/D-", "/PD", "/D-"),
			("/D-", "/i", "/i"),
			("/I-", "/D", "/D"),
			("/I-", "/P", "/P"),
			("/aPf", "/P", "/aPf"),
			("/aP-", "/P", "/aP-"),
			("/aPf", "/zP", "/zPf"),
			("/aP", "/D", "/D"),
			("/aD", "/P", "/P"),
			("/aP", "/-", "/aP-"),
			("/aP-", "/+", "/aP+"),
			("/D-a/T-", "/+", "/D+a/T-"),
			("/D", "/-/T-", "/D-/T-"),
			("/Ii", "/-", "/Ii-"),
			("/aP", "/f", "/aPf"),
			("/aP-", "/zr", "/zP-r"),
			("/D-", "/a", "/D-a"),
			("/D", "/af-/T-", "/D-af/T-"),
			("/Ii", "/a", "/Iia"),
			("/Iiz", "/kf", "/Iikf"),
			("/I-", "/O", "/O"),
			("/O-/T+", "/I", "/I"),
			("/O-/P", "/O", "/O-"),
			("/O-/P", "/I", "/I"),
			("/O-/P", "/-", "/P-"),
			("/iO/P", "/O", "/iO"),
			("/iI/O", "/I", "/iI"),
			("/O/-/iI/P", "/O", "/O-"),
			("/O/T-/P", "/I", "/I/T-"),
			("/iI-/T-", "", "/iI-/T-"),
			("/iI-/T-", ".adamID", "/iI-/T-"),
			("/D", "/T-", "/D/T-"),
			("/iI-", "/T-", "/iI-/T-"),
		],
	)
	func `a field order section retains the options of its kind's saved field order & the tiebreak direction`(
		base: String,
		value: String,
		equivalent: String,
	) throws {
		let standard = SelectedFieldsConfig(
			fieldSpecs: standardFixture.fieldSpecs,
			fieldOrders: try parseFieldsConfig(base, outputFormat: .json(.default)).fieldOrders,
		)
		let fieldOrders = try resolvedFieldsConfig(
			from: "@default@unsuffixed" + value, // `standard@json` would be `all@json`
			standard: standard,
			all: allFixture,
			outputFormat: .json(.default),
		)
		.fieldOrders
		let equivalentFieldOrders = try parseFieldsConfig(equivalent, outputFormat: .json(.default)).fieldOrders
		#expect(fieldOrders.fieldOrder == equivalentFieldOrders.fieldOrder)
		#expect(fieldOrders.tiebreakDirection == equivalentFieldOrders.tiebreakDirection)
	}

	@Test(arguments: ["/P", "/D", "/aP-"])
	func `effective all-conforming is an error in an adjustment set per positional-order or document-order`(
		base: String,
	) throws {
		let standard = SelectedFieldsConfig(
			fieldSpecs: standardFixture.fieldSpecs,
			fieldOrders: try parseFieldsConfig(base, outputFormat: .json(.default)).fieldOrders,
		)
		#expect(throws: ParsingError.allConformingUnsupported) {
			try resolvedFieldsConfig(
				from: "@default@unsuffixed/ak",
				standard: standard,
				all: allFixture,
				outputFormat: .json(.default),
			)
		}
		#expect(throws: Never.self) {
			try resolvedFieldsConfig(
				from: "@default@unsuffixed/ka",
				standard: standard,
				all: allFixture,
				outputFormat: .json(.default),
			)
		}
	}

	@Test
	func `overridden all-conforming means what the adjustment set without it means`() throws {
		let standard = SelectedFieldsConfig(
			fieldSpecs: standardFixture.fieldSpecs,
			fieldOrders: try parseFieldsConfig("/P", outputFormat: .json(.default)).fieldOrders,
		)
		let fieldOrder = try resolvedFieldsConfig(
			from: "@default@unsuffixed/ka",
			standard: standard,
			all: allFixture,
			outputFormat: .json(.default),
		)
		.fieldOrder
		#expect(fieldOrder == (try parseFieldsConfig("/aP", outputFormat: .json(.default)).fieldOrder))
	}
}

private func parseFieldSpecs(_ value: String) throws(ParsingError) -> [FieldSpec] {
	try parseFieldsConfig(value).fieldSpecs
}

private func parseFieldsConfig(_ value: String, outputFormat: OutputFormat = .table(.default))
throws(ParsingError) -> any FieldsConfig {
	try resolvedFieldsConfig(from: value, standard: standardFixture, all: allFixture, outputFormat: outputFormat)
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
