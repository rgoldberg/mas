//
// MASTests+FieldSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `parses default field specs when input is empty`() throws {
		let specs = try parseFieldSpecs("")
		#expect(!specs.isEmpty)
		#expect(specs[0].name == "adamID")
	}

	@Test
	func `parses all field specs`() throws {
		let specs = try parseFieldSpecs("@all")
		#expect(specs.count == 2)
		#expect(specs.map(\.name).contains("adamID"))
		#expect(specs.map(\.name).contains("bundleID"))
	}

	@Test
	func `parses none as all with every field spec hidden, which an overlay unhides`() throws {
		#expect(try parseFieldSpecs("@none").map(\.isHidden) == [true, true])
		let specs = try parseFieldSpecs("@none.bundleID")
		#expect(specs.filter { !$0.isHidden }.map(\.name) == ["bundleID"])
	}

	@Test
	func `parses standalone field spec`() throws {
		let specs = try parseFieldSpecs("adamID=ID,bundleID")
		#expect(specs.count == 2)
		#expect(specs[0].name == "adamID")
		#expect(specs[0].label == "ID")
		#expect(specs[1].name == "bundleID")
		#expect(specs[1].label == "bundleID")
	}

	@Test
	func `parses in-place edit`() throws {
		let specs = try parseFieldSpecs(".adamID=AppID")
		#expect(!specs.isEmpty)
		#expect(specs[0].name == "adamID")
		#expect(specs[0].label == "AppID")
	}

	@Test
	func `parses field specs section insertion & overlay`() throws {
		let specs = try parseFieldSpecs(".+bundleID,adamID=SecondaryID")
		#expect(specs.count == 2)
		#expect(specs[0].name == "bundleID")
		let secondary = try #require(specs.last)
		#expect(secondary.name == "adamID")
		#expect(secondary.label == "SecondaryID")
	}

	@Test
	func `moves a field spec to the front`() throws {
		// Base is [adamID, bundleID]; move bundleID (@2) to immediately after
		// $previous$ (nothing yet ⇒ the front)
		let specs = try parseFieldSpecs("@all.%@2")
		#expect(specs.map(\.name) == ["bundleID", "adamID"])
	}

	@Test
	func `removes a field spec`() throws {
		let specs = try parseFieldSpecs("@all.-bundleID")
		#expect(specs.map(\.name) == ["adamID"])
	}

	@Test
	func `insert lands immediately after the previous field spec, not always at the end`() throws {
		// Base is [adamID]; overlay adamID (no-op-ish, just to set $previous$),
		// then insert 2 more fields, both should land after adamID, in order, not
		// accumulate before / after each other incorrectly
		let specs = try parseFieldSpecs(".adamID,+one,+two")
		#expect(specs.map(\.name) == ["adamID", "one", "two"])
	}

	@Test
	func `hides a field spec, retaining its sort`() throws {
		let specs = try parseFieldSpecs("@all._adamID/1d")
		#expect(specs.map(\.name) == ["adamID", "bundleID"])
		#expect(specs[0].isHidden)
		#expect(specs[0].sortSpec?.priority == 1)
		#expect(specs[0].sortSpec?.optionSet.direction == .descending)
		#expect(!specs[1].isHidden)
	}

	@Test
	func `hiding a nonexistent field inserts a hidden field spec`() throws {
		let specs = try parseFieldSpecs("@all.adamID,_size/1d")
		#expect(specs.map(\.name) == ["adamID", "size", "bundleID"])
		#expect(specs[1].isHidden)
		#expect(specs[1].sortSpec?.priority == 1)
	}

	@Test
	func `hiding a field removed earlier in the section inserts a hidden copy of its base field spec`() throws {
		let specs = try parseFieldSpecs("@all.-adamID,_adamID")
		#expect(specs.map(\.name) == ["adamID", "bundleID"])
		#expect(specs[0].isHidden)
		#expect(specs[0].sortSpec?.priority == 1000)
	}

	@Test
	func `a named reference to a field spec removed earlier in the section is an error`() {
		#expect(throws: ParsingError.nonexistentFieldSpec(forName: "adamID")) {
			try parseFieldSpecs("@all.-adamID,adamID")
		}
	}

	@Test(arguments: ["@all._adamID,adamID", "@all._adamID,%adamID"])
	func `overlay & move unhide a hidden field spec`(value: String) throws {
		#expect(try parseFieldSpecs(value).map(\.isHidden) == [false, false])
	}

	@Test
	func `insertion copies the base fields config's field spec, by name or index`() throws {
		let byName = try parseFieldSpecs("@all.+adamID")
		#expect(byName.map(\.name) == ["adamID", "adamID", "bundleID"])
		#expect(byName[0].sortSpec?.priority == 1000)
		let byIndex = try parseFieldSpecs("@all.+@-1")
		#expect(byIndex.map(\.name) == ["bundleID", "adamID", "bundleID"])
		#expect(throws: ParsingError.invalidPosition(3)) { try parseFieldSpecs("@all.+@3") }
	}

	@Test
	func `insertion of an unknown name selects default settings`() throws {
		let specs = try parseFieldSpecs("@all.+size")
		#expect(specs[0].name == "size")
		#expect(specs[0].label == "size")
		#expect(specs[0].sortSpec == nil)
		#expect(!specs[0].isHidden)
	}

	@Test
	func `parses sort spec without numeric priority`() throws {
		let specs = try parseFieldSpecs(".adamID/a")
		let sortSpec = try #require(specs[0].sortSpec)
		#expect(sortSpec.optionSet.direction == .ascending)
	}

	@Test
	func `parses sort spec with numeric priority`() throws {
		let specs = try parseFieldSpecs(".adamID/500d")
		let sortSpec = try #require(specs[0].sortSpec)
		#expect(sortSpec.priority == 500)
		#expect(sortSpec.optionSet.direction == .descending)
	}

	@Test
	func `item-sort disable-all-sorts sets priority to 0 but retains sort options`() throws {
		let config = try parseFieldsConfig("//r")
		let sortSpec = try #require(config.fieldSpecs[0].sortSpec)
		#expect(sortSpec.priority == 0)
		#expect(sortSpec.optionSet.caseSensitivity == .sensitive) // Fixture default, retained
		#expect(config.itemSort.keys.isEmpty)
	}

	@Test
	func `field spec edit re-enables a sort disabled by disable-all-sorts`() throws {
		let config = try parseFieldsConfig("//r.adamID/1")
		#expect(config.fieldSpecs[0].sortSpec?.priority == 1)
		#expect(config.itemSort.keys.map(\.name) == ["adamID"])
	}

	@Test
	func `item-sort section without disable-all-sorts leaves inherited sorts alone`() throws {
		let config = try parseFieldsConfig("//d")
		#expect(config.fieldSpecs[0].sortSpec?.priority == 1000)
		#expect(config.itemSort.tiebreakDirection == .descending)
	}

	@Test
	func `field order section requires a field-order-option-set`() {
		#expect(throws: ParsingError.missingFieldOrderOptionSet) { try parseFieldsConfig("/") }
		#expect(throws: ParsingError.missingFieldOrderOptionSet) { try parseFieldsConfig("/.adamID") }
	}

	@Test(
		arguments: [
			("/w", FieldOrder.base(nil)),
			("/dw", .base(.descending)),
			("/wd", .base(.descending)),
			("/ow", .base(nil)),
			("/o", .original(nil)),
			("/od", .original(.descending)),
		],
	)
	func `field order base-fields-config-order & original-input-order`(value: String, fieldOrder: FieldOrder) throws {
		#expect(try parseFieldsConfig(value, outputFormat: .json).fieldOrder == fieldOrder)
	}

	@Test(arguments: [("o", ["b", "a", "c"]), ("od", ["c", "a", "b"])])
	func `original-input-order orders each item's fields by its own key order`(order: String, expected: [String]) throws {
		let fieldSpecs = ["a", "b", "c"].map(FieldSpec.defaultSettings(forName:))
		let object = JSON.Object([("b", .number(1)), ("a", .number(2))])
		let fieldOrder = try parseFieldsConfig("/" + order, outputFormat: .json).fieldOrder
		#expect(fieldOrder.itemFieldSpecs(fieldSpecs, for: object).map(\.name) == expected)
	}

	@Test(arguments: ["/o", "/do"])
	func `original-input-order is unsupported for table output`(value: String) {
		#expect(throws: ParsingError.originalInputOrderUnsupportedForTable) { try parseFieldsConfig(value) }
	}

	@Test
	func `field order sort-option-set defaults source to output`() throws {
		guard case let .byLabel(sortSpec) = try parseFieldsConfig("/d").fieldOrder else {
			Issue.record("Expected .byLabel")
			return
		}
		#expect(sortSpec.direction == .descending)
		guard case .byName = try parseFieldsConfig("/Ia").fieldOrder else {
			Issue.record("Expected .byName")
			return
		}
	}

	@Test
	func `clears sort spec with empty slash`() throws {
		let sortSpec = try parseFieldSpecs(".adamID/")[0].sortSpec
		#expect(sortSpec == nil)
	}

	@Test(
		arguments: [
			(".adamID@", ParsingError.missingIndex),
			(".@", .missingIndex),
			(".+adamID@x", .missingIndex),
			(".-adamID=x", .nonexistentFieldSpec(forName: "adamID=x")),
			("@all.adamID@3", .invalidPosition(3)),
		],
	)
	func `reports a field-spec-reference error`(value: String, error: ParsingError) {
		#expect(throws: error) { try parseFieldSpecs(value) }
	}

	@Test(arguments: ["@all . bundleID @ 1 = Bundle , adamID", "@all.bundleID@-1=Bundle"])
	func `ignores whitespace around field-spec-edits' syntax tokens`(value: String) throws {
		#expect(try parseFieldSpecs(value).first { $0.name == "bundleID" }?.label == "Bundle")
	}

	@Test
	func `throws error for nonexistent field edit`() {
		#expect(throws: ParsingError.nonexistentFieldSpec(forName: "nonexistentField")) {
			try parseFieldSpecs(".nonexistentField")
		}
	}

	@Test
	func `fetchFieldNames returns empty for an all-derived base`() throws {
		#expect(
			try fetchFieldNames(for: "@all", standard: standardFixture, all: allFixture, outputFormat: .table(.default))
				.isEmpty,
		)
	}

	@Test
	func `fetchFieldNames unions base names with insert names`() throws {
		let nameSet = Set(
			try fetchFieldNames(for: ".+extra", standard: standardFixture, all: allFixture, outputFormat: .table(.default)),
		)
		#expect(nameSet == ["adamID", "extra"])
	}

	@Test
	func `fetchFieldNames excludes hidden field specs that don't sort items`() throws {
		let nameSet = Set(
			try fetchFieldNames(
				for: "._adamID/0,_extra/1",
				standard: standardFixture,
				all: allFixture,
				outputFormat: .table(.default),
			),
		)
		#expect(nameSet == ["extra"])
	}

	@Test
	func `fetchFieldNames for an absolute config is just its field names`() throws {
		let nameSet = Set(
			try fetchFieldNames(
				for: "adamID,bundleID",
				standard: standardFixture,
				all: allFixture,
				outputFormat: .table(.default),
			),
		)
		#expect(nameSet == ["adamID", "bundleID"])
	}

	@Test
	func `a built-in fields config's machine-facing variant labels & formats each field spec by its name`() {
		let builtIn = BaseIncludesAllFieldsConfig(
			fieldSpecs: [.init(name: "fileSizeBytes", label: "Size", format: .template([.text("custom")]), sortSpec: nil)],
		)
		let json = builtIn.machineFacingVariant()
		#expect(json.fieldSpecs[0].label == "fileSizeBytes")
		#expect(json.fieldSpecs[0].format == .default(fieldName: "fileSizeBytes"))
	}

	@Test(
		arguments: [
			("@standard", OutputFormat.json, ["adamID", "bundleID"], "adamID"), // `standard@json` is `all`
			("@standard@none", .json, ["adamID"], "Adam"),
			("@standard@table", .json, ["adamID"], "Adam"),
			("@all@json", .table(.default), ["adamID", "bundleID"], "adamID"),
			("@default@key-value", .json, ["adamID"], "Adam"),
			("@standard", .keyValue, ["adamID"], "Adam"),
		],
	)
	func `resolves a built-in fields config's variant by suffix or output format`(
		value: String,
		outputFormat: OutputFormat,
		names: [String],
		adamIDLabel: String,
	) throws {
		let config = try resolvedFieldsConfig(
			from: value,
			standard: SelectedFieldsConfig(
				fieldSpecs: [.init(name: "adamID", label: "Adam", format: .default(fieldName: "adamID"), sortSpec: nil)],
			),
			all: allFixture,
			outputFormat: outputFormat,
		)
		#expect(config.fieldSpecs.map(\.name).sorted() == names)
		#expect(config.fieldSpecs.first { $0.name == "adamID" }?.label == adamIDLabel)
	}

	@Test(
		arguments: [
			("@bogus", ParsingError.nonexistentFieldsConfig("bogus")),
			("@all@xml", .invalidBaseFieldsConfigName("all@xml")),
			("@a b", .invalidBaseFieldsConfigName("a b")),
			("@@json", .invalidBaseFieldsConfigName("@json")),
		],
	)
	func `reports an invalid or nonexistent base fields config name`(value: String, error: ParsingError) {
		#expect(throws: error) { try parseFieldSpecs(value) }
	}

	@Test
	func `table end-justifies a field per its field spec's justification; a start-justified last column isn't padded`(
	) throws {
		let table = try [
			JSON.Object([("adamID", .number(7)), ("name", .string("Slack"))]),
			.init([("adamID", .number(1_234_567)), ("name", .string("A"))]),
		]
			.table(
				fieldSpecs: [
					.init(name: "adamID", label: "ID", format: .default(fieldName: "adamID"), sortSpec: nil, justification: .end),
					.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
				],
				tableConfig: .default,
			)
		let expected = "      7  Slack\n1234567  A"
		#expect(table == expected)
	}

	@Test
	func `table pads even a end-justified last column`() throws {
		let table = try [
			JSON.Object([("name", .string("A")), ("adamID", .number(1_234_567))]),
			.init([("name", .string("Slack")), ("adamID", .number(7))]),
		]
			.table(
				fieldSpecs: [
					.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "adamID", label: "ID", format: .default(fieldName: "adamID"), sortSpec: nil, justification: .end),
				],
				tableConfig: .default,
			)
		let expected = "A      1234567\nSlack        7"
		#expect(table == expected)
	}

	@Test
	func `table still gaps a end-justified middle column from the column after it`() throws {
		let table = try [
			JSON.Object([("name", .string("A")), ("adamID", .number(1_234_567)), ("version", .string("1.0"))]),
			.init([("name", .string("Slack")), ("adamID", .number(7)), ("version", .string("2.0"))]),
		]
			.table(
				fieldSpecs: [
					.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "adamID", label: "ID", format: .default(fieldName: "adamID"), sortSpec: nil, justification: .end),
					.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
				],
				tableConfig: .default,
			)
		let expected = "A      1234567  1.0\nSlack        7  2.0"
		#expect(table == expected)
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
	sortSpec: .init(priority: 1000, optionSets: [.default]),
)
private let bundleIDFieldSpec =
	FieldSpec(name: "bundleID", label: "bundleID", format: .default(fieldName: "bundleID"), sortSpec: nil)

private let standardFixture = SelectedFieldsConfig(fieldSpecs: [adamIDFieldSpec])
private let allFixture = BaseIncludesAllFieldsConfig(fieldSpecs: [adamIDFieldSpec, bundleIDFieldSpec])
