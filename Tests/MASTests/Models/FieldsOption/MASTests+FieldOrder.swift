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
			("/D", .document(.init(), tiebreakDirection: .ascending)),
			("/D-", .document(.init(direction: .descending), tiebreakDirection: .ascending)),
			("/D/-", .document(.init(), tiebreakDirection: .descending)),
			("/D-/+", .document(.init(direction: .descending), tiebreakDirection: .ascending)),
			("/PD/-", .document(.init(), tiebreakDirection: .descending)),
			("/D / -", .document(.init(), tiebreakDirection: .descending)),
			("/D//-", .document(.init(), tiebreakDirection: .ascending)),
			("/aD", .document(.init(unpositionedFieldComparison: .least), tiebreakDirection: .ascending)),
			(
				"/PaD f-z",
				.document(.init(direction: .descending, unpositionedFieldPlacement: .fixed), tiebreakDirection: .ascending),
			),
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
		fieldOrders.save(.byLabel(.default, tiebreakDirection: .ascending))
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
			("/O/-", "/O/-"),
			("/O / -", "/O/-"),
			("/O/-P", "/P-"),
			("/O/-/P", "/P"),
			("/I/-O//-", "/O-//-"),
		],
	)
	func `the last field order section sets the field order`(value: String, equivalent: String) throws {
		#expect(try parseFieldsConfig(value).fieldOrder == (try parseFieldsConfig(equivalent).fieldOrder))
	}

	@Test(arguments: ["/O/a", "/P/+-", "/O/-/+"])
	func `a field order adjustment set after the 1st field order section is an error`(value: String) {
		#expect(throws: ParsingError.misplacedFieldOrderAdjustmentSet) { try parseFieldsConfig(value) }
	}

	@Test(arguments: [
		("/D/", ParsingError.missingFieldOrderOptionSet),
		("/I+/", .missingFieldOrderOptionSet),
		("/D/!", .invalidSortOption("!")),
	])
	func `an invalid field order section after a field order option set is an error`(value: String, error: ParsingError) {
		#expect(throws: error) { try parseFieldsConfig(value, outputFormat: .json(.default)) }
	}

	@Test
	func `a transient fields config may save a field order of another kind`() throws {
		#expect(try parseFieldsConfig("/iO/D/P").fieldOrder == .positional(.init()))
	}

	@Test(arguments: ["/D", "/-D", "/P/D"])
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
		guard case let .byLabel(sortSpec, _) = try parseFieldsConfig("/-i").fieldOrder else {
			Issue.record("Expected .byLabel")
			return
		}
		#expect(sortSpec.direction == .descending)
		guard case .byName = try parseFieldsConfig("/I+").fieldOrder else {
			Issue.record("Expected .byName")
			return
		}
	}

	@Test(arguments: [("/I+", SortOptionSet.Direction.ascending), ("/I+/-", .descending), ("@all/-/+", .ascending)])
	func `field order sort-option-set parses field-order-tiebreaker`(
		value: String,
		tiebreakDirection: SortOptionSet.Direction,
	) throws {
		let parsedTiebreakDirection =
			switch try parseFieldsConfig(value).fieldOrder {
			case let .byLabel(_, tiebreakDirection), let .byName(_, tiebreakDirection):
				tiebreakDirection
			default:
				SortOptionSet.Direction?.none
			}
		#expect(parsedTiebreakDirection == tiebreakDirection)
	}

	@Test(
		arguments: [
			("/I-", "/i", "/I-i"),
			("/I-/-", "/+", "/I+/-"),
			("/I+/-", "/I", "/I+/-"),
			("/I+/-", "/D", "/D"),
			("/D-a/-", "/Df", "/D-af/-"),
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
			("/D-a/-", "/+", "/D+a/-"),
			("/D", "/-/-", "/D-/-"),
			("/Ii", "/-", "/Ii-"),
			("/aP", "/f", "/aPf"),
			("/aP-", "/zr", "/zP-r"),
			("/D-", "/a", "/D-a"),
			("/D", "/af-/-", "/D-af/-"),
			("/Ii", "/a", "/Iia"),
			("/Iiz", "/kf", "/Iikf"),
			("/I-", "/O", "/O"),
			("/O-/+", "/I", "/I"),
			("/O-/P", "/O", "/O-"),
			("/O-/P", "/I", "/I"),
			("/O-/P", "/-", "/P-"),
			("/iO/P", "/O", "/iO"),
			("/iI/O", "/I", "/iI"),
			("/O/-/iI/P", "/O", "/O/-"),
		],
	)
	func `a field order section retains the options of the saved field order of its kind`(
		base: String,
		value: String,
		equivalent: String,
	) throws {
		let standard = SelectedFieldsConfig(
			fieldSpecs: standardFixture.fieldSpecs,
			fieldOrders: try parseFieldsConfig(base, outputFormat: .json(.default)).fieldOrders,
		)
		let fieldOrder = try resolvedFieldsConfig(
			from: "@default@unsuffixed" + value, // `standard@json` would be `all@json`
			standard: standard,
			all: allFixture,
			outputFormat: .json(.default),
		)
		.fieldOrder
		#expect(fieldOrder == (try parseFieldsConfig(equivalent, outputFormat: .json(.default)).fieldOrder))
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

	@Test(
		arguments: [
			("/P/-", ParsingError.tiebreakerUnsupportedForPositionalOrder),
			("/DP/+", .tiebreakerUnsupportedForPositionalOrder),
			("@none/-/+", .tiebreakerUnsupportedForPositionalOrder),
			("@none/a/+", .tiebreakerUnsupportedForPositionalOrder),
		],
	)
	func `invalid field-order-tiebreaker is an error`(value: String, error: ParsingError) {
		#expect(throws: error) { try parseFieldsConfig(value, outputFormat: .json(.default)) }
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
