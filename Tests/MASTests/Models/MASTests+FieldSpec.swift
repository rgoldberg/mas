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
	func `parses none field specs`() throws {
		let specs = try parseFieldSpecs("@none")
		#expect(specs.isEmpty)
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
		#expect(specs[0].sortSpec?.direction == .descending)
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

	@Test(
		arguments: [
			(".adamID/1c", SortSpec.Localization.canonical),
			(".adamID/1l", .localized(.current)),
			(".adamID/1L+", .localized(.current)),
			(".adamID/1Lde_DE+d", .localized(.init(identifier: "de_DE"))),
		],
	)
	func `parses sort localization: c, l & L…+`(value: String, localization: SortSpec.Localization) throws {
		#expect(try parseFieldSpecs(value)[0].sortSpec?.localization == localization)
	}

	@Test
	func `a sort option after a custom-locale's terminator still applies`() throws {
		#expect(try parseFieldSpecs(".adamID/1Lde_DE+d")[0].sortSpec?.direction == .descending)
	}

	@Test
	func `a custom-locale without a sort-option-terminator is an error`() {
		#expect(throws: ParsingError.missingSortOptionTerminator) { try parseFieldSpecs(".adamID/1Lde_DE") }
	}

	@Test
	func `parses sort spec without numeric priority`() throws {
		let specs = try parseFieldSpecs(".adamID/a")
		let sortSpec = try #require(specs[0].sortSpec)
		#expect(sortSpec.direction == .ascending)
	}

	@Test
	func `parses sort spec with numeric priority`() throws {
		let specs = try parseFieldSpecs(".adamID/500d")
		let sortSpec = try #require(specs[0].sortSpec)
		#expect(sortSpec.priority == 500)
		#expect(sortSpec.direction == .descending)
	}

	@Test
	func `item-sort disable-all-sorts sets priority to 0 but retains sort options`() throws {
		let config = try parseFieldsConfig("//r")
		let sortSpec = try #require(config.fieldSpecs[0].sortSpec)
		#expect(sortSpec.priority == 0)
		#expect(sortSpec.caseSensitivity == .sensitive) // Fixture default, retained
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
	func `defaultedForJSON resets a default config's labels & formats to bare defaults, only for JSON`() {
		let builtIn = BaseIncludesAllFieldsConfig(
			fieldSpecs: [.init(name: "fileSizeBytes", label: "Size", format: .template([.text("custom")]), sortSpec: nil)],
		)
		let json = builtIn.defaultedForJSON(outputFormat: .json)
		#expect(json.fieldSpecs[0].label == "fileSizeBytes")
		#expect(json.fieldSpecs[0].format == .default(fieldName: "fileSizeBytes"))
		let table = builtIn.defaultedForJSON(outputFormat: .table(.default))
		#expect(table.fieldSpecs[0].label == "Size")
		#expect(table.fieldSpecs[0].format == .template([.text("custom")]))
	}

	@Test
	func `item sort orders by ascending priority, then tiebreaks by input order`() {
		let itemSort = ItemSort(
			keys: [
				.init(
					name: "a",
					sortSpec: .init(
						priority: 1,
						source: .input,
						direction: .ascending,
						caseSensitivity: .sensitive,
						localization: .canonical,
						grouping: .ungrouped,
						interpretation: .numeric,
						boundaries: .init(groups: .init(), collapseContiguous: false, whitespacePlacement: .endmost),
					),
				),
			],
			tiebreakDirection: .ascending,
		)
		let values = ["10", "2", "10"]
		let order = itemSort.sortedIndices(count: values.count) { index, _ in values[index] }
		#expect(order == [1, 0, 2]) // "2" < "10" numerically; the 2 "10"s tiebreak by input order
	}

	@Test(
		arguments: [
			("$999.00", "$1,234.56", ComparisonResult.orderedAscending),
			// 1 side unparseable ("Free"): falls back to a plain text compare ('F' >
			// '$' in ASCII)
			("Free", "$0.99", .orderedDescending),
		],
	)
	func `compares prices numerically, ignoring currency symbols & grouping commas`(
		lhs: String,
		rhs: String,
		result: ComparisonResult,
	) {
		#expect(numericSortSpec(interpretation: .price).compare(lhs, rhs) == result)
	}

	@Test(
		arguments: [
			("1.9.3", "1.10.2", ComparisonResult.orderedAscending), // Not lexical ("1.10" < "1.9" as text)
			("1.2", "1.2.0", .orderedSame), // Missing trailing component compares as 0
		],
	)
	func `compares versions component-wise, numerically per component`(
		lhs: String,
		rhs: String,
		result: ComparisonResult,
	) {
		#expect(numericSortSpec(interpretation: .version).compare(lhs, rhs) == result)
	}

	@Test
	func `boundary-aware comparison: an explicit boundary group outranks ordinary text`() {
		let sortSpec = numericSortSpec(interpretation: .lexical, boundaries: underscoreBoundaries(.endmost))
		// Plain lexical would put "file10" before "file_2" ('1' < '_' in ASCII);
		// boundary-aware tokenization instead treats "_" as a higher-precedence
		// boundary than ordinary text, so "file" (up to the boundary) is compared
		// first; "file" < "file10" makes "file_2" sort first
		#expect(sortSpec.compare("file10", "file_2") == .orderedDescending)
	}

	@Test
	func `boundary-aware comparison: default endmost whitespace sorts after explicit boundary groups`() {
		let sortSpec = numericSortSpec(interpretation: .lexical, boundaries: underscoreBoundaries(.endmost))
		#expect(sortSpec.compare("a_b", "a b") == .orderedAscending) // "_" (rank 0) precedes whitespace (rank 1)
	}

	@Test
	func `boundary-aware comparison: leading whitespace placement sorts before explicit boundary groups`() {
		let sortSpec = numericSortSpec(interpretation: .lexical, boundaries: underscoreBoundaries(.leading))
		#expect(sortSpec.compare("a_b", "a b") == .orderedDescending) // Now whitespace (rank 0) precedes "_" (rank 1)
	}

	@Test
	func `boundary-aware comparison: suppressed whitespace behaves as ordinary text`() {
		let sortSpec = numericSortSpec(
			interpretation: .lexical,
			boundaries: .init(groups: .init(), collapseContiguous: false, whitespacePlacement: .suppressed),
		)
		// No explicit groups & whitespace suppressed ⇒ falls back to a plain text
		// compare, where " " (0x20) < "b" (0x62)
		#expect(sortSpec.compare("a b", "ab") == .orderedAscending)
	}

	@Test
	func `boundary-aware comparison: collapseContiguous reduces a repeated boundary run to 1`() {
		let collapsed = numericSortSpec(
			interpretation: .lexical,
			boundaries: underscoreBoundaries(.endmost, collapseContiguous: true),
		)
		#expect(collapsed.compare("a__b", "a_b") == .orderedSame)
		let uncollapsed = numericSortSpec(interpretation: .lexical, boundaries: underscoreBoundaries(.endmost))
		#expect(uncollapsed.compare("a__b", "a_b") == .orderedDescending) // "_" is a prefix of "__"
	}

	@Test
	func `boundary-aware comparison: a character class matches any of its members`() {
		let sortSpec = numericSortSpec(
			interpretation: .lexical,
			boundaries: .init(
				groups: [.init(boundaries: [.characterClass(.digit)])],
				collapseContiguous: false,
				whitespacePlacement: .endmost,
			),
		)
		#expect(sortSpec.compare("a1b", "a2c") == .orderedAscending) // Both digits are boundaries; "1" < "2" as text
	}

	@Test
	func `parses boundaries option: collapse-contiguous & an escaped literal boundary character`() throws {
		let sortSpec = try #require(try parseFieldSpecs(".adamID/500nb%+\\_+")[0].sortSpec)
		#expect(sortSpec.boundaries.collapseContiguous)
		#expect(sortSpec.boundaries.groups == [.init(boundaries: [.character("_")])])
		#expect(sortSpec.boundaries.whitespacePlacement == .endmost)
	}

	@Test
	func `boundary-aware comparison: a multi-character boundary matches atomically, not per-character`() {
		let sortSpec = numericSortSpec(
			interpretation: .lexical,
			boundaries: .init(
				groups: [.init(boundaries: [.characters("ab")])],
				collapseContiguous: false,
				whitespacePlacement: .endmost,
			),
		)
		// "ab" matches the whole multi-character boundary (rank 0); "axb" has
		// neither "a" nor "b" individually registered as its own boundary (unlike
		// the old, buggy per-character-exploded behavior), so it's ordinary text
		// (rank 1) throughout & sorts after
		#expect(sortSpec.compare("ab", "axb") == .orderedAscending)
	}

	@Test
	func `boundary-aware comparison: the longest matching boundary wins, regardless of group order`() {
		let sortSpec = numericSortSpec(
			interpretation: .lexical,
			boundaries: .init(
				groups: [.init(boundaries: [.character("a")]), .init(boundaries: [.characters("ab")])],
				collapseContiguous: false,
				whitespacePlacement: .endmost,
			),
		)
		// "ab" matches both group 0's "a" (length 1) & group 1's "ab" (length 2);
		// the longer match wins, so "ab" gets group 1's (lower) precedence, not
		// group 0's, even though group 0 sorts earlier
		#expect(sortSpec.compare("ab", "ac") == .orderedDescending) // "ac" matches only group 0's "a"
	}

	@Test
	func `parses boundaries option: ungrouped members each get their own precedence group`() throws {
		let sortSpec = try #require(try parseFieldSpecs(".adamID/500nb_ba_")[0].sortSpec)
		#expect(sortSpec.boundaries.groups == [.init(boundaries: [.character("b")]), .init(boundaries: [.character("a")])])
		#expect(sortSpec.compare("za", "zb") == .orderedDescending) // "b"'s group (0) outranks "a"'s group (1)
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

private func underscoreBoundaries(_ whitespacePlacement: SortSpec.WhitespacePlacement, collapseContiguous: Bool = false)
-> SortSpec.Boundaries {
	.init(
		groups: [.init(boundaries: [.character("_")])],
		collapseContiguous: collapseContiguous,
		whitespacePlacement: whitespacePlacement,
	)
}

private func numericSortSpec(
	interpretation: SortSpec.Interpretation,
	boundaries: SortSpec.Boundaries = .init(groups: .init(), collapseContiguous: false, whitespacePlacement: .endmost),
) -> SortSpec {
	.init(
		priority: 0,
		source: .input,
		direction: .ascending,
		caseSensitivity: .sensitive,
		localization: .canonical,
		grouping: .ungrouped,
		interpretation: interpretation,
		boundaries: boundaries,
	)
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
	sortSpec: .init(
		priority: 1000,
		source: .input,
		direction: .ascending,
		caseSensitivity: .sensitive,
		localization: .canonical,
		grouping: .ungrouped,
		interpretation: .numeric,
		boundaries: .init(groups: .init(), collapseContiguous: false, whitespacePlacement: .endmost),
	),
)
private let bundleIDFieldSpec =
	FieldSpec(name: "bundleID", label: "bundleID", format: .default(fieldName: "bundleID"), sortSpec: nil)

private let standardFixture = SelectedFieldsConfig(fieldSpecs: [adamIDFieldSpec])
private let allFixture = BaseIncludesAllFieldsConfig(fieldSpecs: [adamIDFieldSpec, bundleIDFieldSpec])
