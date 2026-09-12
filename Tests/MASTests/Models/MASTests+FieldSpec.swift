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
		let curated = BaseIncludesAllFieldsConfig(
			fieldSpecs: [.init(name: "fileSizeBytes", label: "Size", format: .parts([.text("custom")]), sortSpec: nil)],
		)
		let json = curated.defaultedForJSON(outputFormat: .json)
		#expect(json.fieldSpecs[0].label == "fileSizeBytes")
		#expect(json.fieldSpecs[0].format == .default(fieldName: "fileSizeBytes"))
		let table = curated.defaultedForJSON(outputFormat: .table(.default))
		#expect(table.fieldSpecs[0].label == "Size")
		#expect(table.fieldSpecs[0].format == .parts([.text("custom")]))
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
	func `evaluates standard placeholders %e & %w as string-only, not structural, emptiness checks`() {
		let emptyFormat =
			Format.parts([.placeholder(.standard(.isEmpty, negated: true, coerced: false, success: nil, failure: nil))])
		let whitespaceFormat =
			Format.parts([.placeholder(.standard(.isWhitespace, negated: true, coerced: false, success: nil, failure: nil))])
		// negated %e / %w default to the verbatim field value when NOT matched,
		// so an empty array / object (structurally empty, but not an empty
		// string) round-trips unchanged, proving these placeholders test JSON
		// string values (or null), not arrays / objects.
		#expect(emptyFormat.rendered(value: .array(.init(.init())), label: "L", name: "n").stringValue == "[]")
		#expect(emptyFormat.rendered(value: .object(.init(.init())), label: "L", name: "n").stringValue == "{}")
		#expect(whitespaceFormat.rendered(value: .array(.init(.init())), label: "L", name: "n").stringValue == "[]")
		#expect(whitespaceFormat.rendered(value: .object(.init(.init())), label: "L", name: "n").stringValue == "{}")
		#expect(emptyFormat.rendered(value: .string(""), label: "L", name: "n").stringValue?.isEmpty == true)
		#expect(whitespaceFormat.rendered(value: .string(" "), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `evaluates standard placeholder %u for null & non-null values`() {
		let format =
			Format.parts([.placeholder(.standard(.isNull, negated: false, coerced: false, success: nil, failure: nil))])
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
		let rendered = try #require(
			Format.parts([.placeholder(.date(negated: false, success: nil, failure: nil))])
				.rendered(value: .string("2020-03-18T17:39:23Z"), label: "L", name: "n")
				.stringValue,
		)
		// Exact text depends on the test machine's local time zone; check it
		// round-trips to the same instant instead
		#expect(try Date(rendered, strategy: .iso8601) == .init("2020-03-18T17:39:23Z", strategy: .iso8601))
	}

	@Test
	func `evaluates %D dateOnly as just the date`() {
		let rendered = Format
			.parts([.placeholder(.date(negated: false, success: .init(outputTransforms: [.dateOnly]), failure: nil))])
			.rendered(value: .string("2020-03-18T17:39:23Z"), label: "L", name: "n")
			.stringValue
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
	func `a custom input-date-format is a parse error, not a silent no-op`() {
		#expect(throws: ParsingError.unsupportedDateInputFormat) { try parseFieldSpecs("adamID:%D.iso_++") }
		#expect(throws: ParsingError.unsupportedDateInputFormat) { try parseFieldSpecs("adamID:%D.iso,.dateOnly_++") }
	}

	@Test
	func `a named or literal output-date-format is a parse error, not a silent fallback to the default`() {
		#expect(throws: ParsingError.unsupportedDateOutputFormat) { try parseFieldSpecs("adamID:%D:hidden++") }
		#expect(throws: ParsingError.unsupportedDateOutputFormat) { try parseFieldSpecs("adamID:%DliteralPattern++") }
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
	func `applies group, grouping only the integer part, from the right, leaving sign & fraction alone`() {
		let commaEvery3 = Transform.group(separator: ",", digitCount: 3)
		#expect(commaEvery3.applied(to: "1234567") == "1,234,567")
		#expect(commaEvery3.applied(to: "123") == "123")
		#expect(commaEvery3.applied(to: "-1234567") == "-1,234,567")
		#expect(commaEvery3.applied(to: "1234567.89") == "1,234,567.89")
		#expect(Transform.group(separator: "'", digitCount: 2).applied(to: "1462715242") == "14'62'71'52'42")
		#expect(commaEvery3.applied(to: "not a number") == "not a number")
	}

	@Test
	func `group(locale:) resolves a locale's own grouping separator & digit count`() {
		#expect(Transform.group(locale: .init(identifier: "en_US")).applied(to: "1234567") == "1,234,567")
		#expect(Transform.group(locale: .init(identifier: "de_DE")).applied(to: "1234567") == "1.234.567")
	}

	@Test
	func `parses group with no arguments as the current locale, with arguments as a locale name or explicit values`()
	throws {
		#expect(try Transform.parsed(name: "group", kind: .number) == .group(locale: .current))
		#expect(try Transform.parsed(name: "group:de_DE:", kind: .number) == .group(locale: .init(identifier: "de_DE")))
		#expect(try Transform.parsed(name: "group:.,3:", kind: .number) == .group(separator: ".", digitCount: 3))
		#expect(try Transform.parsed(name: "group", kind: .string) == nil)
	}

	@Test
	func `group with empty arguments, a non-positive digit count, or too many arguments is a parse error`() {
		#expect(throws: ParsingError.invalidTransformArguments(name: "group:")) {
			try Transform.parsed(name: "group:", kind: .number)
		}
		#expect(throws: ParsingError.invalidTransformArguments(name: "group:.,0:")) {
			try Transform.parsed(name: "group:.,0:", kind: .number)
		}
		#expect(throws: ParsingError.invalidTransformArguments(name: "group:.,3,4:")) {
			try Transform.parsed(name: "group:.,3,4:", kind: .number)
		}
	}

	@Test
	func `group, a terminal-number-transform, may be preceded by others but never followed`() throws {
		#expect(throws: ParsingError.terminalNumberTransformFollowedByMore(name: "group")) {
			try parseFieldSpecs("adamID:%N.group.round++")
		}
		#expect(throws: ParsingError.terminalNumberTransformFollowedByMore(name: "group")) {
			try parseFieldSpecs("adamID:%N.group.absoluteValue++")
		}
		// Doesn't throw: group alone, or preceded by 1+ non-terminal transforms
		#expect(try parseFieldSpecs("adamID:%N.group++").count == 1)
		#expect(try parseFieldSpecs("adamID:%N.round.group++").count == 1)
		#expect(try parseFieldSpecs("adamID:%N.absoluteValue.round.group++").count == 1)
	}

	@Test
	func `%.n coerces a numeric JSON string into a number, unlike plain %n`() {
		let coerced = Format.parts([.placeholder(.number(negated: false, coerced: true, success: nil, failure: nil))])
		#expect(coerced.rendered(value: .string("42"), label: "L", name: "n").stringValue == "42")
		#expect(coerced.rendered(value: .string("not a number"), label: "L", name: "n").stringValue?.isEmpty == true)
		let uncoerced = Format.parts([.placeholder(.number(negated: false, coerced: false, success: nil, failure: nil))])
		#expect(uncoerced.rendered(value: .string("42"), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `%.n's success format's number-transform-pipeline applies to a coerced string`() {
		let format = Format.parts(
			[
				.placeholder(
					.number(
						negated: false,
						coerced: true,
						success: .reference(.init(namedFormat: nil, transforms: [.absoluteValue])),
						failure: nil,
					),
				),
			],
		)
		#expect(format.rendered(value: .string("-5"), label: "L", name: "n").stringValue == "5")
	}

	@Test
	func `%.o, %.t & %.f coerce string "true" / "false" into booleans, unlike their uncoerced forms`() {
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
		#expect(throws: ParsingError.coercionNotSupported("v")) { try parseFieldSpecs(".adamID:%.v") }
	}

	@Test
	func `a verbose standard placeholder's uppercase letter resolves to its lowercase StandardKind`() throws {
		// Regression: `StandardKind`'s raw values are all lowercase, but a
		// verbose placeholder's own letter is uppercase (e.g., 'T' for isTrue),
		// so looking it up case-sensitively always failed
		let fieldSpec = try #require(parseFieldSpecs("adamID:%.TYes+No+").first)
		#expect(fieldSpec.format.rendered(value: .string("true"), label: "L", name: "n").stringValue == "Yes")
		#expect(fieldSpec.format.rendered(value: .string("false"), label: "L", name: "n").stringValue == "No")
	}

	@Test
	func `a top-level fallible placeholder's success / failure may be placeholder-less; an infallible 1 may not`()
	throws {
		// %.N is fallible (conditional on the value), so a fixed label per
		// branch is meaningful, unlike a top-level template
		let fallible = try #require(parseFieldSpecs("adamID:%.NNumber+NotANumber+").first).format
		#expect(fallible.rendered(value: .string("42"), label: "L", name: "n").stringValue == "Number")
		#expect(fallible.rendered(value: .string("nope"), label: "L", name: "n").stringValue == "NotANumber")
		// %V / %L are infallible (their own success always applies), so a
		// placeholder-less success is just as constant as a bare template
		#expect(throws: ParsingError.templateLacksPlaceholder) { try parseFieldSpecs("adamID:%Vconstant+") }
		#expect(throws: ParsingError.templateLacksPlaceholder) { try parseFieldSpecs("adamID:%Lconstant+") }
	}

	@Test
	func `a %V / %L branch inside %b may be placeholder-less, even though it's infallible`() throws {
		// A `%b` branch, unlike a standalone top-level placeholder, can't be
		// replaced by a bare literal without losing "only if every earlier
		// branch failed" — true even for an infallible %V / %L branch used as
		// the catch-all last branch
		let format = try #require(parseFieldSpecs("adamID:%bNnumber+Oboolean+Vother++").first).format
		#expect(format.rendered(value: .number(42), label: "L", name: "n").stringValue == "number")
		#expect(format.rendered(value: .bool(true), label: "L", name: "n").stringValue == "boolean")
		#expect(format.rendered(value: .string("x"), label: "L", name: "n").stringValue == "other")
	}

	@Test
	func `a single-branch %b, fallible or not, is a parse error, since it's just an ordinary placeholder`() {
		#expect(throws: ParsingError.singleBranch) { try parseFieldSpecs("adamID:%bNnum++") }
		#expect(throws: ParsingError.singleBranch) { try parseFieldSpecs("adamID:%bVconstant++") }
	}

	@Test
	func `a top-level justify transform sets justification & is stripped from the rendered format`() throws {
		let fieldSpec = try #require(parseFieldSpecs("adamID:.rightJustify").first)
		#expect(fieldSpec.justification == .end)
		// Stripped from the format: a real transform would force stringification
		// (see `%.n coerces...`), but a bare justify-only pipeline leaves a JSON
		// number passed through unchanged.
		#expect(isJSONNumber(fieldSpec.format.rendered(value: .number(42), label: "L", name: "n")))
	}

	@Test
	func `the last justify transform in a pipeline wins`() throws {
		let rightThenLeft = try #require(parseFieldSpecs("adamID:.rightJustify.leftJustify").first)
		#expect(rightThenLeft.justification == .start)
		let leftThenRight = try #require(parseFieldSpecs("adamID:.leftJustify.rightJustify").first)
		#expect(leftThenRight.justification == .end)
	}

	@Test
	func `a field spec with no justify transform defaults to start justification`() throws {
		#expect(try #require(parseFieldSpecs("adamID:.uppercase").first).justification == .start)
		#expect(try #require(parseFieldSpecs("adamID").first).justification == .start)
	}

	@Test
	func `a justify transform composes with a trailing string transform, in that order only`() throws {
		let fieldSpec = try #require(parseFieldSpecs("adamID:.rightJustify.uppercase").first)
		#expect(fieldSpec.justification == .end)
		#expect(fieldSpec.format.rendered(value: .string("ab"), label: "L", name: "n").stringValue == "AB")
		// Reversed order: `rightJustify` isn't a string transform, so it's a parse
		// error once it's no longer in leading position.
		#expect(throws: ParsingError.self) { try parseFieldSpecs("adamID:.uppercase.rightJustify") }
	}

	@Test
	func `a pipeline terminator lets a justify transform precede template text, which still needs a placeholder`()
	throws {
		// A single stray ':' is a parse error: justify never ends with a closed
		// argument fence (it never takes arguments at all), so it's never exempt
		// from needing the full doubled pipeline terminator
		#expect(throws: ParsingError.incompletePipelineTerminator) { try parseFieldSpecs("adamID:.rightJustify: MB") }
		#expect(throws: ParsingError.templateLacksPlaceholder) { try parseFieldSpecs("adamID:.rightJustify:: MB") }
		let fieldSpec = try #require(parseFieldSpecs("adamID:.rightJustify::%v MB").first)
		#expect(fieldSpec.justification == .end)
		#expect(fieldSpec.format.rendered(value: .number(7), label: "L", name: "n").stringValue == "7 MB")
	}

	@Test
	func `a bare template with no placeholder at all is a parse error`() {
		#expect(throws: ParsingError.templateLacksPlaceholder) {
			try parseFieldSpecs("adamID:literal text, no placeholder at all")
		}
	}

	@Test
	func `infers a value-transform-pipeline's kind from its 1st transform`() throws {
		let numberFormat = try #require(parseFieldSpecs("adamID:.round.absoluteValue").first).format
		#expect(numberFormat.rendered(value: .number(-5.6), label: "L", name: "n").stringValue == "6")
		let rendered = try #require(parseFieldSpecs("adamID:.dateOnly").first)
			.format
			.rendered(value: .string("2020-03-18T17:39:23Z"), label: "L", name: "n")
			.stringValue
		#expect(rendered?.count == "yyyy-MM-dd".count) // Exact day depends on the test machine's local time zone
	}

	@Test
	func `an uncoerced value-transform-pipeline's number kind requires a real JSON number, blanking on failure`() throws {
		let numberFormat = try #require(parseFieldSpecs("adamID:.round").first).format
		#expect(numberFormat.rendered(value: .number(5.6), label: "L", name: "n").stringValue == "6")
		#expect(numberFormat.rendered(value: .string("5.6"), label: "L", name: "n").stringValue?.isEmpty == true)
		#expect(numberFormat.rendered(value: nil, label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `a doubled leading '.' coerces a value-transform-pipeline's number kind, accepting a numeric string too`()
	throws {
		let coercedFormat = try #require(parseFieldSpecs("adamID:..round").first).format
		#expect(coercedFormat.rendered(value: .string("5.6"), label: "L", name: "n").stringValue == "6")
		#expect(coercedFormat.rendered(value: .string("not a number"), label: "L", name: "n").stringValue?.isEmpty == true)
		#expect(throws: ParsingError.coercionNotApplicable(kind: "string")) { try parseFieldSpecs("adamID:..uppercase") }
		#expect(throws: ParsingError.coercionNotApplicable(kind: "date")) { try parseFieldSpecs("adamID:..dateOnly") }
	}

	@Test
	func `a value-transform-coercion is only meaningful on the pipeline's 1st transform, but is harmless elsewhere`()
	throws {
		// A later transform's own marker has no effect: uncoerced overall, since
		// the 1st transform (`round`) wasn't marked
		let fieldSpec = try #require(parseFieldSpecs("adamID:.round..absoluteValue").first)
		#expect(fieldSpec.format.rendered(value: .number(-5.6), label: "L", name: "n").stringValue == "6")
		#expect(fieldSpec.format.rendered(value: .string("-5.6"), label: "L", name: "n").stringValue?.isEmpty == true)
		// Likewise inside a placeholder's own sub-format
		#expect(try parseFieldSpecs("adamID:%N..round++").count == 1)
	}

	@Test
	func `a value-transform-pipeline's date kind always parses permissively, blanking on failure`() throws {
		let dateFormat = try #require(parseFieldSpecs("adamID:.dateOnly").first).format
		#expect(dateFormat.rendered(value: .string("not a date"), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `a pipeline terminator lets an argument-less value-transform-pipeline be followed directly by a template`() {
		// A template that never references the pipeline's output (no `%v`) would
		// render identically for every value, so it's a parse error (see the
		// next test for the same pipeline terminator, but with a placeholder)
		#expect(throws: ParsingError.templateLacksPlaceholder) { try parseFieldSpecs("adamID:.round.absoluteValue:: MB") }
	}

	@Test
	func `a value-transform-pipeline's template renders %v against the pipeline's own output, never doubling it`()
	throws {
		let fieldSpec = try #require(parseFieldSpecs("adamID:.round.absoluteValue::%v MB").first)
		#expect(fieldSpec.format.rendered(value: .number(-6.4), label: "L", name: "n").stringValue == "6 MB")
	}

	@Test
	func `a fenced last transform needs no pipeline terminator before a template`() throws {
		let fieldSpec = try #require(parseFieldSpecs("adamID:.group:.,3:%v MB").first)
		#expect(fieldSpec.format.rendered(value: .number(1_234_567), label: "L", name: "n").stringValue == "1.234.567 MB")
	}

	@Test
	func `extra pipeline terminators after a fenced last transform are literal template text, not a 2nd terminator`()
	throws {
		let fieldSpec = try #require(parseFieldSpecs("adamID:.group:.,3:::%v").first)
		#expect(fieldSpec.format.rendered(value: .number(1_234_567), label: "L", name: "n").stringValue == "::1.234.567")
	}

	@Test
	func `a single stray pipeline terminator (not doubled) after an argument-less last transform is a parse error`() {
		#expect(throws: ParsingError.incompletePipelineTerminator) {
			try parseFieldSpecs("adamID:.round.absoluteValue: MB")
		}
	}

	@Test
	func `a transform call right after a pipeline terminator is just literal template text, not specially banned`()
	throws {
		// No placeholder in the resulting template (".absoluteValue" alone): an
		// error, but from the general "a template needs a placeholder" rule, not
		// from a dedicated ban on a leading '.'
		#expect(throws: ParsingError.templateLacksPlaceholder) { try parseFieldSpecs("adamID:.round::.absoluteValue") }
		// With a placeholder present, it parses fine: literal ".absoluteValue",
		// then %v reading round's own transformed output
		let fieldSpec = try #require(parseFieldSpecs("adamID:.round::.absoluteValue%v").first)
		#expect(fieldSpec.format.rendered(value: .number(5.6), label: "L", name: "n").stringValue == ".absoluteValue6")
	}

	@Test
	func `an unhandled placeholder failure mid-template aborts the whole format to blank, not just what preceded it`() {
		let failingPlaceholder = Placeholder.standard(.isNull, negated: false, coerced: false, success: nil, failure: nil)
		let format = Format.parts([.text("A"), .placeholder(failingPlaceholder), .text("B")])
		#expect(format.rendered(value: .string("x"), label: "L", name: "n").stringValue?.isEmpty == true)
	}

	@Test
	func `a justify transform has no effect inside a placeholder's own success format`() throws {
		#expect(throws: ParsingError.self) { try parseFieldSpecs("adamID:%V.rightJustify+") }
	}

	@Test
	func `a bare hidden named format parses successfully & hides the field`() throws {
		#expect(try #require(parseFieldSpecs("adamID::hidden").first).format.isHidden)
	}

	@Test
	func `a name / transform name swallows a following placeholder prefix absent a separator`() {
		// No separator between "hidden" & "%v": the whole run is 1 attempted named
		// format name, "hidden%v", which doesn't exist — not `hidden` followed by a
		// `%v` placeholder.
		#expect(throws: ParsingError.unknownNamedFormat("hidden%v")) { try parseFieldSpecs("adamID::hidden%v") }
	}

	@Test
	func `hidden must be the entire format-modifier: nothing may follow it, even with a separator`() {
		#expect(throws: ParsingError.hiddenFormatFollowedByContent) { try parseFieldSpecs("adamID::hidden.rightJustify") }
		#expect(throws: ParsingError.hiddenFormatFollowedByContent) { try parseFieldSpecs("adamID::hidden.uppercase") }
		#expect(throws: ParsingError.hiddenFormatFollowedByContent) { try parseFieldSpecs("adamID::hidden:%v") }
		#expect(throws: ParsingError.hiddenFormatFollowedByContent) { try parseFieldSpecs("adamID::hidden:") }
	}

	@Test
	func `a sort modifier or later field spec may still follow ::hidden`() throws {
		// Both terminate the format-modifier itself, so they're not "content
		// following hidden" within it.
		let sorted = try #require(parseFieldSpecs("adamID::hidden/1a").first)
		#expect(sorted.format.isHidden)
		#expect(sorted.sortSpec?.priority == 1)
		let fieldSpecs = try parseFieldSpecs("adamID::hidden,bundleID")
		#expect(fieldSpecs.map(\.name) == ["adamID", "bundleID"])
		#expect(fieldSpecs.first?.format.isHidden == true)
	}

	@Test
	func `table right-justifies a field per its field spec's justification; a left-justified last column isn't padded`() {
		let table = [
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
	func `table pads even a right-justified last column`() {
		let table = [
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
	func `table still gaps a right-justified middle column from the column after it`() {
		let table = [
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

private func isJSONNumber(_ node: JSON.Node) -> Bool {
	if case .number = node {
		true
	} else {
		false
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

private func parseFieldSpecs(_ value: String) throws -> [FieldSpec] {
	try resolvedFieldsConfig(from: value, standard: standardFixture, all: allFixture, outputFormat: .table(.default))
		.fieldSpecs
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
