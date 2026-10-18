//
// MASTests+SortSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import BigInt
internal import Foundation
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			("1", Locale?.none),
			("1L:", .current),
			("1Lcanonical:", nil),
			("1L de_DE :-", .init(identifier: "de_DE")),
			("1L system :", .current),
			("1Lcanonical:Lde_DE:", .init(identifier: "de_DE")),
		],
	)
	func `parses sort locale`(sort: String, locale: Locale?) throws {
		#expect(try parsedSortSpec(sort).optionSet.locale == locale)
	}

	@Test(
		arguments: [
			("1+-", "direction", Character("-")),
			("1i", "caseSensitivity", "i"),
			("1x", "numberSegments", "x"),
			("1u", "numberSegments", "u"),
			("1v", "numberSegments", "v"),
			("1N:", "numberSegments", "N"),
			("1N:u", "numberSegments", "u"),
			("1a", "nonconformingComparison", "a"),
			("1az", "nonconformingComparison", "z"),
			("1zk", "nonconformingComparison", "k"),
			("1h", "textOrder", "h"),
			("1t", "textOrder", "t"),
			("1e", "textOrder", "e"),
			("1hp", "textOrder", "p"),
			("1 I O", "source", "O"),
			("1I+-", "source", "I"),
			("1I+-", "direction", "-"),
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
			case "nonconformingComparison":
				optionSet.nonconformingComparison.rawValue
			case "numberSegments":
				optionSet.numberSegments.option
			case "source":
				optionSet.source.rawValue
			default:
				optionSet.textOrder.rawValue
			}
		#expect(value == expected)
	}

	@Test(
		arguments: [
			("1", SortOptionSet.Boundaries.uncollapsed(SortOptionSet.defaultBoundaryGroups)),
			("1B:", .uncollapsed(.init())),
			("1M:", .collapsed(.init())),
			("1M:B:", .uncollapsed(.init())),
			(
				"1B/_+space+:",
				.uncollapsed([.init(boundaries: [.character("/")]), .init(boundaries: [.characterClass(.space)])]),
			),
			("1M%ab%-:", .collapsed([.init(boundaries: [.characters("ab"), .character("-")])])),
			("1B\\_\\:\\%:", .uncollapsed([.init(boundaries: [.character("_"), .character(":"), .character("%")])])),
		],
	)
	func `parses sort boundaries`(sort: String, boundaries: SortOptionSet.Boundaries) throws {
		#expect(try parsedSortSpec(sort).optionSet.boundaries == boundaries)
	}

	@Test(
		arguments: [
			("1N:", SortOptionSet.GroupedNumericArguments.default),
			(
				"1N canonical ,.,4,2,\\,,all:",
				.init(
					baseConventions: .canonical,
					digitGroupSeparator: ".",
					digitGroupSize: 4,
					secondaryDigitGroupSize: 2,
					decimalSeparator: ",",
					signs: .allSigns,
				),
			),
			(
				"1N, \\  , 3 ,,, none :",
				.init(
					baseConventions: nil,
					digitGroupSeparator: " ",
					digitGroupSize: 3,
					secondaryDigitGroupSize: nil,
					decimalSeparator: nil,
					signs: .noSigns,
				),
			),
			(
				"1N de_DE :",
				.init(
					baseConventions: .init(locale: .init(identifier: "de_DE")),
					digitGroupSeparator: nil,
					digitGroupSize: nil,
					secondaryDigitGroupSize: nil,
					decimalSeparator: nil,
					signs: .wordInitialSigns,
				),
			),
		],
	)
	func `parses grouped-numeric`(sort: String, arguments: SortOptionSet.GroupedNumericArguments) throws {
		#expect(try parsedSortSpec(sort).optionSet.numberSegments == .groupedNumeric(arguments))
	}

	@Test(
		arguments: [
			("1", Set(ISO8601Form.allCases)),
			("1C:", .init()),
			("1Ciso:", .init(ISO8601Form.allCases)),
			("1C iso-date , iso-time :", .init([.date, .time])),
			("1Ciso-datetime:", .init([.datetime])),
			("1C:Ciso-date:", .init([.date])),
		],
	)
	func `parses chronologic segments`(sort: String, forms: Set<ISO8601Form>) throws {
		#expect(try parsedSortSpec(sort).optionSet.chronologicSegments == forms)
	}

	@Test(
		arguments: [
			("1", false, Set(ISO8601Form.allCases)),
			("1Cunix-time:", true, .init()),
			("1C iso-date , unix-time :", true, .init([.date])),
			("1Cunix-time:Ciso:", false, .init(ISO8601Form.allCases)),
		],
	)
	func `parses unix-time chronologic segments`(sort: String, hasUnixTimeSegments: Bool, forms: Set<ISO8601Form>)
	throws {
		let optionSet = try parsedSortSpec(sort).optionSet
		#expect(optionSet.hasUnixTimeSegments == hasUnixTimeSegments)
		#expect(optionSet.chronologicSegments == forms)
	}

	@Test(
		arguments: [
			("1N", ParsingError.missingSortOptionTerminator),
			("1N,.:", .invalidSortOptionArguments("N")),
			("1N,,,,.:L de_DE :", .invalidSortOptionArguments("N")),
			("1N,,x:", .invalidSortOptionArguments("N")),
			("1N,,-1:", .invalidSortOptionArguments("N")),
			("1N,,,,,bogus:", .invalidSortOptionArguments("N")),
			("1N,,,,,,:", .invalidSortOptionArguments("N")),
			("1Nxx_Bogus:", .invalidLocaleIdentifier("xx_Bogus")),
			("1C", .missingSortOptionTerminator),
			("1Cbogus:", .invalidSortOptionArguments("C")),
			("1Ciso,:", .invalidSortOptionArguments("C")),
			("1Cunix:", .invalidSortOptionArguments("C")),
			("1L", .missingSortOptionTerminator),
			("1Lxx_Bogus:", .invalidLocaleIdentifier("xx_Bogus")),
			("1B/", .missingSortOptionTerminator),
			("1B+bogus+:", .invalidCharacterClass("bogus")),
			("1B_:", .emptyBoundaryGroup),
			("1B/_:", .emptyBoundaryGroup),
			("1B%%:", .invalidMultiCharacterBoundary),
			("1Z", .invalidSortOption("Z")),
			("1c", .invalidSortOption("c")),
			("1/", .invalidSortOption("/")),
			("1/O", .invalidSortOption("/")),
			("/-", .missingSortPriority),
			("-", .missingSortPriority),
		],
	)
	func `reports a sort syntax error`(sort: String, error: ParsingError) {
		#expect(throws: error) { try parsedSortSpec(sort) }
	}

	@Test
	func `parses a sort-priority beyond every fixed-width integer's range`() throws {
		#expect(try parsedSortSpec("0018446744073709551616").priority == BigUInt(1) << 64)
	}

	@Test
	func `an omitted option retains the working value, and an omitted sort-option-set its whole working value`()
	throws {
		let existing = SortSpec(priority: 1, optionSet: try #require(.init(optionSetFrom: "i-")))
		let retained = try parsedSortSpec("2", existing: existing)
		#expect(retained.priority == 2)
		#expect(retained.optionSet == existing.optionSet)
		let overlaid = try parsedSortSpec("+", existing: existing)
		#expect(overlaid.priority == 1)
		#expect(overlaid.optionSet.caseSensitivity == .insensitive)
		#expect(overlaid.optionSet.direction == .ascending)
	}

	@Test(
		arguments: [
			// A number is a single number segment, unless lexical
			("1", JSON.Node.number(2), JSON.Node.number(10), ComparisonResult.orderedDescending),
			("1u", .number(2), .number(10), .orderedAscending),
			("1u-", .number(2), .number(10), .orderedDescending),
			("1v", .number(2), .number(10), .orderedAscending),
			// Ungrouped number segments are runs of digits
			("1x", "file10", "file2", .orderedAscending),
			("1u", "file10", "file2", .orderedDescending),
			("1u", "1.5", "1.25", .orderedAscending),
			("1u", "a12345678901234567890", "a12345678901234567891", .orderedAscending),
			("1u", "1e3", "999", .orderedAscending),
			// Grouped number segments are grouped numbers
			("1N:", "1.5", "1.25", .orderedDescending),
			("1N:", "v1.5 b", "v1.50 a", .orderedDescending),
			("1N:", "1,234", "999", .orderedDescending),
			("1N:", "1.234", "999", .orderedAscending),
			("1L de_DE :N:", "1.234", "999", .orderedDescending),
			("1N de_DE :", "1.234", "999", .orderedDescending),
			("1N,.,3,,\\,:", "1.234,5", "1.234,25", .orderedDescending),
			("1N,,0:", "1,2345", "999", .orderedDescending),
			("1N:", "1,2345", "999", .orderedAscending),
			("1N:", "1.5e3", "999", .orderedDescending),
			// A sign is word-initial by default, or per <number-signs>
			("1N:", "-5", "3", .orderedAscending),
			("1N:", "a -5", "a 3", .orderedAscending),
			("1N:", "a-5", "a-3", .orderedDescending),
			("1N,,,,,all:", "a-5", "a-3", .orderedAscending),
			("1N,,,,,none:", "-5", "-3", .orderedDescending),
			("1u", "-5", "3", .orderedAscending),
			// Version segments compare component by component
			("1v", "1.9.3", "1.10.2", .orderedAscending),
			("1v", "1.0b", "1.0", .orderedAscending),
			("1v", "1.2", "1.2.0", .orderedAscending),
			("1v", "1.2a", "1.2b", .orderedAscending),
			("1v", "1.2.3-beta", "1.2.3", .orderedAscending),
			("1v", "(1.2)", "(1.10)", .orderedAscending),
			("1v", "1.18446744073709551616", "1.18446744073709551617", .orderedAscending),
			("1v", "v1.2", "1.3", .orderedDescending),
			("1ve", "v1.2", "1.3", .orderedAscending),
			// Chronologic segments compare chronologically, time-only ones 1st
			("1", "2020-03-18T17:39:23Z", "2020-03-19", .orderedAscending),
			("1", "2020-03-18T17:39:23-05:00", "2020-03-18T18:00:00Z", .orderedDescending),
			("1C:", "2020-03-18T17:39:23-05:00", "2020-03-18T18:00:00Z", .orderedAscending),
			("1", "2020-03-17", "2020-03-18T00:00:00Z", .orderedAscending),
			("1Ciso-datetime:", "2020-03-17", "2020-03-18T00:00:00Z", .orderedDescending),
			("1", "10:00:00+02:00", "09:00:00Z", .orderedAscending),
			("1", "23:00:00Z", "2020-01-01", .orderedAscending),
			("1Ciso-date:", "23:00:00Z", "2020-01-01", .orderedDescending),
			("1", "2020-03-18t17:39-05:00", "2020-03-18T18:00z", .orderedDescending),
			// A space-separated datetime is a single segment iff space is not a
			// boundary
			("1B:", "2020-03-18 17:39-05:00", "2020-03-18 18:00Z", .orderedDescending),
			("1", "2020-03-18 17:39-05:00", "2020-03-18 18:00Z", .orderedAscending),
			// A chronologic segment is not adjacent to a digit
			("1", "2020-03-180", "2020-03-19", .orderedDescending),
			// A number is a Unix time iff <chronologic-formats> includes <unix-time>
			("1", .number(1_584_553_163), "2020-03-19", .orderedDescending),
			("1Ciso,unix-time:", .number(1_584_553_163), "2020-03-19", .orderedAscending),
			("1Ciso,unix-time:", .number(1_584_553_163), "2020-03-17", .orderedDescending),
			("1Cunix-time:", .number(1e19), .number(2), .orderedDescending),
			// A Unix time segment is a whole whitespace-delimited word
			("1Ciso,unix-time:", "at 1584553163 UTC", "at 2020-03-19 UTC", .orderedAscending),
			("1Ciso,unix-time:", "1584553163", "2020-03-19", .orderedAscending),
			("1Ciso,unix-time:", "1584553163,", "2020-03-19", .orderedDescending),
			("1Ciso,unix-time:", "v1584553163", "2020-03-19", .orderedDescending),
			("1Cunix-time:", "1584553163", "2", .orderedDescending),
			("1Cunix-time:B+punct+:", "(1584553163)", "(2)", .orderedAscending),
			// Without <all-conforming>, a value without typed segments is
			// nonconforming
			("1N:", "Free", "$5", .orderedDescending),
			("1N:a", "Free", "$5", .orderedAscending),
			("1N:z", "Free", "$5", .orderedDescending),
			("1N:a-", "Free", "$5", .orderedDescending),
			("1N:a", .null, "Free", .orderedAscending),
			("1a", "Free", "$5", .orderedDescending),
			// <text-order> orders text & typed segments
			("1u", "File 10 a", "File 2 b", .orderedDescending),
			("1uB:", "File 10 a", "File 2 b", .orderedDescending),
			("1uhB:", "File 10 a", "File 2 b", .orderedAscending),
			("1uB:", "a 2", "b 1", .orderedAscending),
			("1utB:", "a 2", "b 1", .orderedDescending),
			("1ueB:", "a 2", "b 2", .orderedSame),
			("1u", "a1", "a1b", .orderedAscending),
			// Text compares per case sensitivity & locale
			("1s", "B", "a", .orderedAscending),
			("1i", "B", "a", .orderedDescending),
			// Boundaries take sort precedence over non-boundary text
			("1B:", "a/b", "a!b", .orderedDescending),
			("1B/:", "a/b", "a!b", .orderedAscending),
			("1B/_+space+:", "a/b", "a b", .orderedAscending),
			("1B+space+_/:", "a/b", "a b", .orderedDescending),
			("1B\\_:", "a__c", "a_b", .orderedAscending),
			("1M\\_:", "a__c", "a_b", .orderedDescending),
			("1B%ab%:", "xab", "xa", .orderedAscending),
			// Other values compare as strings, `null` as `""`
			("1", .bool(true), "s", .orderedDescending),
			("1", .null, "", .orderedSame),
		],
	)
	func `compares values per sort options`(sort: String, lhs: JSON.Node, rhs: JSON.Node, result: ComparisonResult)
	throws {
		let sortSpec = try parsedSortSpec(sort)
		#expect(
			try inSystemTimeZone("America/New_York") {
				sortSpec.compare(.init(input: lhs, output: nil), .init(input: rhs, output: nil))
			}
				== result,
		)
	}

	@Test(
		arguments: [
			("1", ComparisonResult.orderedAscending),
			("1O", .orderedSame),
		],
	)
	func `compares output values iff the sort source is output`(sort: String, result: ComparisonResult) throws {
		let fieldSpec = try parsedFieldSpec(format: "%C.dateOnly++", sort: sort)
		let sortSpec = try #require(fieldSpec.sortSpec)
		#expect(
			try inSystemTimeZone("America/New_York") {
				sortSpec.compare(
					try sortValues("2020-03-18T14:00:00Z", fieldSpec: fieldSpec),
					try sortValues("2020-03-18T20:00:00Z", fieldSpec: fieldSpec),
				)
			}
				== result,
		)
	}

	@Test(arguments: [OutputFormat.json(.default), .keyValue(.default), .table(.default)])
	func `sorts output values by their formatted values' types for every output format`(outputFormat: OutputFormat)
	throws {
		// As numbers, 1.5 > 1.10; as versions, 1.5 < 1.10
		let fieldSpec = try parsedFieldSpec(format: "..absoluteValue", sort: "1Ov", outputFormat: outputFormat)
		let sortSpec = try #require(fieldSpec.sortSpec)
		#expect(
			sortSpec.compare(try sortValues("1.5", fieldSpec: fieldSpec), try sortValues("1.10", fieldSpec: fieldSpec))
				== .orderedDescending,
		)
	}

	@Test
	func `compares a structured value as its compact JSON text`() throws {
		let fieldSpec = try parsedFieldSpec(format: "%i", sort: "1")
		let sortSpec = try #require(fieldSpec.sortSpec)
		#expect(
			sortSpec.compare(
				try sortValues(.array([.string("é"), .object(["a": .null])]), fieldSpec: fieldSpec),
				try sortValues(.string(#"["é",{"a":null}]"#), fieldSpec: fieldSpec),
			)
				== .orderedSame,
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

	@Test
	func `item sort lets values left unordered by a sort key fall through to the next sort key`() throws {
		let fieldSpecs = [try parsedFieldSpec(format: "%n", sort: "1"), try parsedFieldSpec(format: "%n", sort: "2")]
		let itemSort = ItemSort(keys: fieldSpecs.enabledSortKeys, tiebreakDirection: .ascending)
		let values = [[JSON.Node.string("Free"), .string("Free")], [.number(2), .number(1)]]
		#expect(
			itemSort.sortedIndices(count: 2) { index, keyIndex in .init(input: values[keyIndex][index], output: nil) }
				== [1, 0],
		)
	}
}

private extension SortOptionSet.NumberSegments {
	/// This `<number-segments>`' option letter.
	var option: Character {
		switch self {
		case .groupedNumeric:
			"N"
		case .lexical:
			"x"
		case .ungroupedNumeric:
			"u"
		case .versions:
			"v"
		}
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

private func parsedFieldSpec(format: String, sort: String, outputFormat: OutputFormat = .json(.default))
throws(ParsingError) -> FieldSpec {
	try resolvedFieldsConfig(
		from: "n:\(format)/\(sort)",
		standard: SelectedFieldsConfig(),
		all: .init(),
		outputFormat: outputFormat,
	)
	.fieldSpecs[0]
}

private func sortValues(_ value: JSON.Node, fieldSpec: FieldSpec) throws -> SortValues {
	.init(input: value, output: try fieldSpec.format.rendered(value: value, label: fieldSpec.label, name: fieldSpec.name))
}
