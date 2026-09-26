//
// MASTests+SortSpec.swift
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
			("1c", SortOptionSet.Localization.canonical),
			("1l", .localized(.current)),
			("1L+", .localized(.current)),
			("1L de_DE +d", .localized(.init(identifier: "de_DE"))),
		],
	)
	func `parses sort localization`(sort: String, localization: SortOptionSet.Localization) throws {
		#expect(try parsedSortSpec(sort).optionSet.localization == localization)
	}

	@Test(
		arguments: [
			("1ad", "direction", Character("d")),
			("1i", "caseSensitivity", "i"),
			("1x", "numbersInStrings", "x"),
			("1n", "numbersInStrings", "n"),
			("1g", "numbersInStrings", "g"),
			("1f", "nonconformingLocation", "f"),
			("1fe", "nonconformingLocation", "e"),
			("1h", "triviaOrder", "h"),
			("1p", "triviaOrder", "p"),
			("1q", "triviaOrder", "q"),
			("1 I O", "source", "O"),
		],
	)
	func `parses sort options, the last of each option winning`(sort: String, option: String, expected: Character)
	throws {
		let optionSet = try parsedSortSpec(sort).optionSet
		let value =
			switch option {
			case "caseSensitivity":
				optionSet.caseSensitivity.rawValue
			case "direction":
				optionSet.direction.rawValue
			case "nonconformingLocation":
				optionSet.nonconformingLocation.rawValue
			case "numbersInStrings":
				optionSet.numbersInStrings.rawValue
			case "source":
				optionSet.source.rawValue
			default:
				optionSet.triviaOrder.rawValue
			}
		#expect(value == expected)
	}

	@Test(
		arguments: [
			("1b", SortOptionSet.Boundaries.noBoundaries),
			("1B+", .uncollapsed(SortOptionSet.defaultBoundaryGroups)),
			("1C+", .collapsed(SortOptionSet.defaultBoundaryGroups)),
			(
				"1B/_:space:+",
				.uncollapsed([.init(boundaries: [.character("/")]), .init(boundaries: [.characterClass(.space)])]),
			),
			("1C%ab%-+", .collapsed([.init(boundaries: [.characters("ab"), .character("-")])])),
			("1B\\_\\+\\%+", .uncollapsed([.init(boundaries: [.character("_"), .character("+"), .character("%")])])),
		],
	)
	func `parses sort boundaries`(sort: String, boundaries: SortOptionSet.Boundaries) throws {
		#expect(try parsedSortSpec(sort).optionSet.boundaries == boundaries)
	}

	@Test(
		arguments: [
			("1L", ParsingError.missingSortOptionTerminator),
			("1Lxx_Bogus+", .invalidLocaleIdentifier("xx_Bogus")),
			("1B/", .missingSortOptionTerminator),
			("1B:bogus:+", .invalidCharacterClass("bogus")),
			("1B_+", .emptyBoundaryGroup),
			("1B/_+", .emptyBoundaryGroup),
			("1B%%+", .invalidMultiCharacterBoundary),
			("1z", .invalidSortOption("z")),
			("1/", .missingSortOptionSet),
			("/d", .missingSortOptionSet),
			("d", .missingSortPriority),
		],
	)
	func `reports a sort syntax error`(sort: String, error: ParsingError) {
		#expect(throws: error) { try parsedSortSpec(sort) }
	}

	@Test
	func `parses succeeding sort-option-sets`() throws {
		let sortSpec = try parsedSortSpec("2Id/Oa")
		#expect(sortSpec.priority == 2)
		#expect(sortSpec.optionSets.map(\.source) == [.input, .output])
		#expect(sortSpec.optionSets.map(\.direction) == [.descending, .ascending])
	}

	@Test
	func `an omitted option retains the working value, and an omitted sort-option-set its whole working value`()
	throws {
		let existing = SortSpec(priority: 1, optionSets: [
			try #require(.init(optionSetFrom: "id")),
			.default,
		]) // swiftlint:disable:this force_unwrapping
		let retained = try parsedSortSpec("2", existing: existing)
		#expect(retained.priority == 2)
		#expect(retained.optionSets == [existing.optionSet]) // Succeeding sort-option-sets are directly absent
		let overlaid = try parsedSortSpec("a", existing: existing)
		#expect(overlaid.priority == 1)
		#expect(overlaid.optionSet.caseSensitivity == .insensitive)
		#expect(overlaid.optionSet.direction == .ascending)
	}

	@Test(
		arguments: [
			// Numbers compare numerically
			("%n", "1", JSON.Node.number(2), JSON.Node.number(10), ComparisonResult.orderedAscending),
			("%n", "1d", .number(2), .number(10), .orderedDescending),
			// Lenient numbers compare by trivia per `<trivia-order>`, then number
			("%_n", "1q", .string("$999.00"), .string("$1,234.56"), .orderedAscending),
			("%_n", "1", .string("US$5"), .string("$10"), .orderedDescending),
			("%_n", "1h", .string("US$5"), .string("$10"), .orderedAscending),
			("%_n", "1", .string("$5"), .string("$10"), .orderedAscending),
			// Nonconforming values follow (or precede) conforming ones
			("%n", "1", .string("Free"), .number(5), .orderedDescending),
			("%n", "1f", .string("Free"), .number(5), .orderedAscending),
			("%n", "1d", .string("Free"), .number(5), .orderedDescending),
			// Values conforming to no sort-option-set compare as equal
			("%n", "1", .string("a"), .string("b"), .orderedSame),
			// A succeeding sort-option-set sorts the preceding ones' nonconforming
			// values
			("%N+%i+", "1/O", .string("a"), .string("b"), .orderedAscending),
			("%N+%i+", "1/O", .string("a"), .number(5), .orderedDescending),
			// Versions compare component by component
			("%v", "1", .string("1.9.3"), .string("1.10.2"), .orderedAscending),
			("%v", "1", .string("1.0b"), .string("1.0"), .orderedAscending),
			("%v", "1", .string("1.2"), .string("1.2.0"), .orderedAscending),
			("%v", "1", .string("1.2a"), .string("1.2b"), .orderedAscending),
			// Booleans sort `false` before `true`
			("%b", "1", .bool(true), .bool(false), .orderedDescending),
			("%.b", "1", .string("false"), .bool(true), .orderedAscending),
			// Chronologic values compare chronologically
			("%c", "1", .string("2020-03-18T17:39:23Z"), .string("2020-03-19"), .orderedAscending),
			("%c", "1", .number(0), .string("1969-12-31T00:00:00Z"), .orderedDescending),
			// Strings compare per the string options
			("%s", "1s", .string("B"), .string("a"), .orderedAscending),
			("%s", "1i", .string("B"), .string("a"), .orderedDescending),
			("%s", "1x", .string("file10"), .string("file2"), .orderedAscending),
			("%s", "1n", .string("file10"), .string("file2"), .orderedDescending),
			("%s", "1n", .string("1,234"), .string("999"), .orderedAscending),
			("%s", "1g", .string("1,234"), .string("999"), .orderedDescending),
			("%s", "1b", .string("a/b"), .string("a!b"), .orderedDescending),
			("%s", "1B/+", .string("a/b"), .string("a!b"), .orderedAscending),
			("%s", "1B/_:space:+", .string("a/b"), .string("a b"), .orderedAscending),
			("%s", "1B:space:_/+", .string("a/b"), .string("a b"), .orderedDescending),
			("%s", "1B\\_+", .string("a__c"), .string("a_b"), .orderedAscending),
			("%s", "1C\\_+", .string("a__c"), .string("a_b"), .orderedDescending),
			("%s", "1B%ab%+", .string("xab"), .string("xa"), .orderedAscending),
			// Any values compare by their JSON types
			("%i", "1", .number(10), .number(9), .orderedDescending),
			("%i", "1n", .string("10"), .string("9"), .orderedDescending),
		],
	)
	func `compares values per their type & sort options`(
		format: String,
		sort: String,
		lhs: JSON.Node,
		rhs: JSON.Node,
		result: ComparisonResult,
	) throws {
		let fieldSpec = try parsedFieldSpec(format: format, sort: sort)
		let sortSpec = try #require(fieldSpec.sortSpec)
		#expect(
			try inSystemTimeZone("America/New_York") {
				sortSpec.compare(
					try sortValues(lhs, fieldSpec: fieldSpec),
					try sortValues(rhs, fieldSpec: fieldSpec),
					typeDeterminant: fieldSpec.format.typeDeterminant,
				)
			}
				== result,
		)
	}

	@Test
	func `item sort orders by ascending priority, then tiebreaks by input order`() throws {
		let fieldSpec = try parsedFieldSpec(format: "%n", sort: "1")
		let itemSort =
			ItemSort(keys: [fieldSpec].enabledSortKeys, tiebreakDirection: .ascending)
		let values = [JSON.Node.number(10), .number(2), .number(10)]
		#expect(itemSort.sortedIndices(count: values.count) { index, _ in .init(input: values[index], output: nil) } == [
			1,
			0,
			2,
		])
	}
}

private extension SortOptionSet {
	init?(optionSetFrom options: String) {
		var input = options[...]
		guard let optionSet = try? Self.parsed(&input, terminatorSet: .init(), defaults: .default) else {
			return nil
		}
		self = optionSet
	}
}

private func parsedSortSpec(_ sort: String, existing: SortSpec? = nil) throws(ParsingError) -> SortSpec {
	var input = sort[...]
	guard let sortSpec = try SortSpec.parsed(&input, existing: existing, defaultOptionSet: .default) else {
		throw .missingSortPriority
	}
	guard input.isEmpty else {
		throw .unexpectedCharacter(input.first ?? " ")
	}
	return sortSpec
}

private func parsedFieldSpec(format: String, sort: String) throws(ParsingError) -> FieldSpec {
	try resolvedFieldsConfig(
		from: "n:\(format)/\(sort)",
		standard: SelectedFieldsConfig(),
		all: .init(),
		outputFormat: .json,
	)
	.fieldSpecs[0]
}

private func sortValues(_ value: JSON.Node, fieldSpec: FieldSpec) throws -> SortValues {
	.init(input: value, output: try fieldSpec.format.rendered(value: value, label: fieldSpec.label, name: fieldSpec.name))
}
