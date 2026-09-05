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
	func `item-sort reset-to-contextual replaces options but keeps priority`() throws {
		let sortSpec = try #require(try parseFieldSpecs("//r")[0].sortSpec)
		#expect(sortSpec.priority == 1000) // Unchanged
		#expect(sortSpec.caseSensitivity == .insensitive) // Table's contextual default; fixture default is `.sensitive`
	}

	@Test
	func `item-sort section without a reset option leaves inherited sorts alone`() throws {
		let sortSpec = try #require(try parseFieldSpecs("//d")[0].sortSpec)
		#expect(sortSpec.caseSensitivity == .sensitive) // Fixture default, unchanged: no reset was requested
	}

	@Test
	func `clears sort spec with empty slash`() throws {
		let sortSpec = try parseFieldSpecs(".adamID/")[0].sortSpec
		#expect(sortSpec == nil)
	}

	@Test
	func `throws error for nonexistent field edit`() {
		#expect(throws: (any Error).self) { try parseFieldSpecs(".nonexistentField") }
	}

	@Test
	func `fetchFieldNames returns empty for an all-derived base`() throws {
		#expect(try fetchFieldNames(for: "@all", standard: standardFixture, all: allFixture, outputFormat: .table).isEmpty)
	}

	@Test
	func `fetchFieldNames unions base names with insert names`() throws {
		let nameSet =
			Set(try fetchFieldNames(for: ".+extra", standard: standardFixture, all: allFixture, outputFormat: .table))
		#expect(nameSet == ["adamID", "extra"])
	}

	@Test
	func `fetchFieldNames for an absolute config is just its field names`() throws {
		let nameSet =
			Set(try fetchFieldNames(for: "adamID,bundleID", standard: standardFixture, all: allFixture, outputFormat: .table))
		#expect(nameSet == ["adamID", "bundleID"])
	}

	@Test
	func `evaluates bare %v as the verbatim value, preserving its JSON type`() {
		let format = Format.parts([.placeholder(.value(success: nil))])
		// A number's description has no quotes, unlike a string's, confirms the
		// type was preserved, not stringified
		#expect(format.rendered(value: .number(42), label: "Label", name: "name").description == "42")
	}

	@Test
	func `evaluates %v as an empty string for a null value`() {
		let format = Format.parts([.placeholder(.value(success: nil))])
		// `.stringValue` is `nil` for `.null` (by design, callers like table
		// rendering apply `?? ""`); this confirms %v's _display_ value is empty for
		// null, per fields.md ("empty string if null")
		#expect(format.rendered(value: .null, label: "Label", name: "name").stringValue?.isEmpty ?? true)
	}

	@Test
	func `evaluates %l as the label & negated %l as the field name`() {
		#expect(
			Format.parts([.placeholder(.label(negated: false, success: nil))])
				.rendered(value: nil, label: "Label", name: "name")
				.stringValue
				== "Label",
		)
		#expect(
			Format.parts([.placeholder(.label(negated: true, success: nil))])
				.rendered(value: nil, label: "Label", name: "name")
				.stringValue
				== "name",
		)
	}

	@Test
	func `evaluates standard placeholder %u for null & non-null values`() {
		let placeholder = Placeholder.standard(.isNull, negated: false, coerced: false, success: nil, failure: nil)
		let format = Format.parts([.placeholder(placeholder)])
		#expect(format.rendered(value: nil, label: "Label", name: "name").stringValue?.isEmpty == true)
		#expect(format.rendered(value: .string("x"), label: "Label", name: "name").stringValue?.isEmpty == true)
		#expect(
			Format.parts([.placeholder(.standard(.isNull, negated: true, coerced: false, success: nil, failure: nil))])
				.rendered(value: .string("x"), label: "Label", name: "name")
				.stringValue
				== "x",
		)
	}

	@Test
	func `applies string transforms`() {
		#expect(Transform.uppercase.applied(to: "abc") == "ABC")
		#expect(Transform.lowercase.applied(to: "ABC") == "abc")
		#expect(Transform.trimWhitespace.applied(to: "  x  ") == "x")
	}

	@Test
	func `hidden format hides a field from display`() {
		#expect(Format.reference(.init(namedFormat: "hidden", transforms: .init())).isHidden)
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
						boundaries: .default,
					),
				),
			],
			tiebreakDirection: .ascending,
		)
		let values = ["10", "2", "10"]
		let order = itemSort.sortedIndices(count: values.count) { index, _ in values[index] }
		#expect(order == [1, 0, 2]) // "2" < "10" numerically; the 2 "10"s tiebreak by input order
	}

	@Test
	func `compares prices numerically, ignoring currency symbols & grouping commas`() {
		let sortSpec = numericSortSpec(interpretation: .price)
		#expect(sortSpec.compare("$999.00", "$1,234.56") == .orderedAscending)
		// 1 side unparseable ("Free"): falls back to a plain text compare ('F' >
		// '$' in ASCII)
		#expect(sortSpec.compare("Free", "$0.99") == .orderedDescending)
	}

	@Test
	func `compares versions component-wise, numerically per component`() {
		let sortSpec = numericSortSpec(interpretation: .version)
		#expect(sortSpec.compare("1.9.3", "1.10.2") == .orderedAscending) // Not lexical ("1.10" < "1.9" as text)
		#expect(sortSpec.compare("1.2", "1.2.0") == .orderedSame) // Missing trailing component compares as 0
	}

	@Test
	func `boundary-aware comparison: an explicit boundary group outranks ordinary text`() {
		let sortSpec = numericSortSpec(interpretation: .lexical, boundaries: underscoreBoundaries(.endmost))
		// Plain lexical would put "file10" before "file_2" ('1' < '_' in ASCII);
		// boundary-aware tokenization instead treats "_" as a higher-precedence
		// boundary than ordinary text, so "file" (up to the boundary) is compared
		// first, & "file" < "file10" makes "file_2" sort first
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
	func `evaluates %d as ISO-8601 datetime by default, in the local time zone`() throws {
		let format = Format.parts([.placeholder(.date(negated: false, success: nil, failure: nil))])
		let rendered = try #require(
			format.rendered(value: .string("2020-03-18T17:39:23Z"), label: "L", name: "n").stringValue,
		)
		// Exact text depends on the test machine's local time zone; check it
		// round-trips to the same instant instead
		#expect(try Date(rendered, strategy: .iso8601) == Date("2020-03-18T17:39:23Z", strategy: .iso8601))
	}

	@Test
	func `evaluates %D dateOnly as just the date`() {
		let format =
			Format.parts([.placeholder(.date(negated: false, success: .init(outputTransforms: [.dateOnly]), failure: nil))])
		let rendered = format.rendered(value: .string("2020-03-18T17:39:23Z"), label: "L", name: "n").stringValue
		#expect(rendered?.count == "yyyy-MM-dd".count) // Exact day depends on the test machine's local time zone
	}

	@Test
	func `%d fails (& %-d succeeds) for a value that isn't a date`() {
		let format = Format.parts([.placeholder(.date(negated: false, success: nil, failure: nil))])
		#expect(format.rendered(value: .string("not a date"), label: "L", name: "n").stringValue?.isEmpty == true)
		let negated = Format.parts([.placeholder(.date(negated: true, success: nil, failure: nil))])
		#expect(negated.rendered(value: .string("not a date"), label: "L", name: "n").stringValue == "not a date")
	}

	@Test
	func `evaluates %n for a JSON number vs. a non-number`() {
		let format = Format.parts([.placeholder(.number(negated: false, coerced: false, success: nil, failure: nil))])
		#expect(format.rendered(value: .number(42), label: "L", name: "n").stringValue == "42")
		#expect(format.rendered(value: .string("42"), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `applies absoluteValue & round number transforms`() {
		#expect(Transform.absoluteValue.applied(to: "-5") == "5")
		#expect(Transform.absoluteValue.applied(to: "-5.5") == "5.5")
		#expect(Transform.round.applied(to: "5.6") == "6")
		#expect(Transform.absoluteValue.applied(to: "not a number") == "not a number")
	}

	@Test
	func `%cn coerces a numeric JSON string into a number, unlike plain %n`() {
		let coerced = Format.parts([.placeholder(.number(negated: false, coerced: true, success: nil, failure: nil))])
		#expect(coerced.rendered(value: .string("42"), label: "L", name: "n").stringValue == "42")
		#expect(coerced.rendered(value: .string("not a number"), label: "L", name: "n").stringValue?.isEmpty == true)
		let uncoerced = Format.parts([.placeholder(.number(negated: false, coerced: false, success: nil, failure: nil))])
		#expect(uncoerced.rendered(value: .string("42"), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `%cn's success format's number-transform-pipeline applies to a coerced string`() {
		let format = Format.parts([
			.placeholder(
				.number(
					negated: false,
					coerced: true,
					success: .reference(.init(namedFormat: nil, transforms: [.absoluteValue])),
					failure: nil,
				),
			),
		])
		#expect(format.rendered(value: .string("-5"), label: "L", name: "n").stringValue == "5")
	}

	@Test
	func `%co, %ct & %cf coerce string "true" / "false" into booleans, unlike their uncoerced forms`() {
		let coercedTruePlaceholder = Placeholder.standard(
			.isTrue,
			negated: false,
			coerced: true,
			success: nil,
			failure: nil,
		)
		let coercedTrue = Format.parts([.placeholder(coercedTruePlaceholder)])
		#expect(coercedTrue.rendered(value: .string("true"), label: "L", name: "n").stringValue == "true")
		#expect(coercedTrue.rendered(value: .string("false"), label: "L", name: "n").stringValue?.isEmpty == true)
		let uncoercedTrue =
			Format.parts([.placeholder(.standard(.isTrue, negated: false, coerced: false, success: nil, failure: nil))])
		#expect(uncoercedTrue.rendered(value: .string("true"), label: "L", name: "n").stringValue?.isEmpty == true)
		let coercedBoolean =
			Format.parts([.placeholder(.standard(.isBoolean, negated: false, coerced: true, success: nil, failure: nil))])
		#expect(coercedBoolean.rendered(value: .string("false"), label: "L", name: "n").stringValue == "false")
	}

	@Test
	func `coercion on a placeholder that doesn't support it is a parse error`() {
		#expect(throws: ParsingError.coercionNotSupported("v")) {
			try parseFieldSpecs(".adamID:%cv")
		}
	}
}

private func underscoreBoundaries(
	_ whitespacePlacement: SortSpec.WhitespacePlacement,
	collapseContiguous: Bool = false,
) -> SortSpec.Boundaries {
	.init(
		groups: [.init(boundaries: [.character("_")])],
		collapseContiguous: collapseContiguous,
		whitespacePlacement: whitespacePlacement,
	)
}

private func numericSortSpec(interpretation: SortSpec.Interpretation, boundaries: SortSpec.Boundaries = .default)
-> SortSpec {
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
		boundaries: .default,
	),
)
private let bundleIDFieldSpec =
	FieldSpec(name: "bundleID", label: "bundleID", format: .default(fieldName: "bundleID"), sortSpec: nil)

private let standardFixture = SelectedFieldsConfig(fieldSpecs: [adamIDFieldSpec])
private let allFixture = BaseIncludesAllFieldsConfig(fieldSpecs: [adamIDFieldSpec, bundleIDFieldSpec])

private func parseFieldSpecs(_ value: String) throws -> [FieldSpec] {
	try resolvedFieldsConfig(from: value, standard: standardFixture, all: allFixture, outputFormat: .table).fieldSpecs
}
