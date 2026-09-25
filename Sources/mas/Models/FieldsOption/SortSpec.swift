//
// SortSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST

// MARK: - Sorting (fields.md)

/// A field spec's `<sort>`, followed by its `<sort-modifier>`'s succeeding
/// `<sort-option-set>`s.
struct SortSpec: Equatable {
	/// `<sort-priority>`: `0` disables the sort.
	let priority: UInt64
	/// The `<sort>`'s `<sort-option-set>`, then the `<sort-modifier>`'s
	/// succeeding ones, each of which sorts, among themselves, the values that
	/// conform to none of the preceding ones' types. Never empty.
	let optionSets: [SortOptionSet]

	/// The `<sort>`'s `<sort-option-set>`.
	var optionSet: SortOptionSet {
		optionSets[0]
	}

	/// A copy with `priority` replaced.
	func withPriority(_ priority: UInt64) -> Self {
		.init(priority: priority, optionSets: optionSets)
	}
}

/// A `<sort-option-set>`, with every option resolved.
struct SortOptionSet: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `<source>`.
	enum Source: Character {
		case input = "I"
		case output = "O"
	}

	/// `<direction>`.
	enum Direction: Character {
		case ascending = "a"
		case descending = "d"
	}

	/// `<case-sensitivity>`.
	enum CaseSensitivity: Character {
		case insensitive = "i"
		case sensitive = "s"
	}

	/// `<localization>`.
	enum Localization: Equatable {
		case canonical
		case localized(Locale)
	}

	/// `<numbers-in-strings>`.
	enum NumbersInStrings: Character {
		case groupedNumeric = "g"
		case lexical = "x"
		case numeric = "n"
	}

	/// `<boundaries>`.
	enum Boundaries: Equatable {
		/// `<collapsed-boundaries>`.
		case collapsed([BoundaryGroup])
		/// `<no-boundaries>`.
		case noBoundaries
		/// `<uncollapsed-boundaries>`.
		case uncollapsed([BoundaryGroup])
	}

	/// A `<boundary-group>`'s boundaries, which share the same sort precedence.
	struct BoundaryGroup: Equatable {
		let boundaries: [Boundary]
	}

	/// A boundary.
	enum Boundary: Equatable {
		/// A `<boundary-characters>`' character.
		case character(Character)
		/// A `<character-class>`, each of whose characters is a boundary.
		case characterClass(CharacterClass)
		/// A `<multi-character-boundary-text>`.
		case characters(String)
	}

	/// A `<character-class-name>`.
	enum CharacterClass: String {
		case alnum
		case alpha
		case ascii
		case blank
		case cntrl
		case digit
		case graph
		case lower
		case print
		case punct
		case space
		case upper
		case word
		case xdigit
	}

	/// `<nonconforming-location>`.
	enum NonconformingLocation: Character {
		case afterConforming = "e"
		case beforeConforming = "f"
	}

	/// `<trivia-order>`.
	enum TriviaOrder: Character {
		case first = "t"
		case ignored = "q"
		case last = "h"
		case split = "p"
	}

	/// Every option's default.
	static let `default` = Self(
		source: .input,
		direction: .ascending,
		caseSensitivity: .sensitive,
		localization: .canonical,
		numbersInStrings: .lexical,
		boundaries: .uncollapsed(defaultBoundaryGroups),
		nonconformingLocation: .afterConforming,
		triviaOrder: .first,
	)

	/// `<boundary-groups>`' default: `:space:`.
	static let defaultBoundaryGroups = [BoundaryGroup(boundaries: [.characterClass(.space)])]

	var source: Source
	var direction: Direction
	var caseSensitivity: CaseSensitivity
	var localization: Localization
	var numbersInStrings: NumbersInStrings
	var boundaries: Boundaries
	var nonconformingLocation: NonconformingLocation
	var triviaOrder: TriviaOrder
}

// MARK: - Parsing

extension SortSpec { // swiftlint:disable:this file_types_order
	/// Parses a `<sort-modifier>`'s payload (after its
	/// `<sort-modifier-prefix>`): `nil` iff `<sort>` is absent (its direct
	/// default). An option omitted from a present `<sort-option-set>` retains
	/// `existing`'s value, or `defaultOptionSet`'s absent `existing`.
	static func parsed(_ input: inout Substring, existing: Self?, defaultOptionSet: SortOptionSet)
	throws(ParsingError) -> Self? {
		skipWhitespace(&input)
		guard let first = input.first, first != fieldSpecSeparator else {
			return nil // `<sort>`'s direct default
		}
		guard first != sortModifierPrefix else {
			throw .missingSortOptionSet
		}
		let priority = parseUInt64(&input)
		guard let priority = priority ?? existing?.priority else {
			throw .missingSortPriority
		}
		skipWhitespace(&input)
		let firstDefaults = existing?.optionSet ?? defaultOptionSet
		var optionSets = [
			isAtSortOptionSetEnd(input, terminatorSet: sortModifierTerminatorSet)
				? firstDefaults
				: try SortOptionSet.parsed(&input, terminatorSet: sortModifierTerminatorSet, defaults: firstDefaults),
		]
		while input.first == sortModifierPrefix {
			input.removeFirst()
			skipWhitespace(&input)
			guard !isAtSortOptionSetEnd(input, terminatorSet: sortModifierTerminatorSet) else {
				throw .missingSortOptionSet
			}
			optionSets.append(
				try SortOptionSet.parsed(
					&input,
					terminatorSet: sortModifierTerminatorSet,
					defaults: existing.flatMap { $0.optionSets.count > optionSets.count ? $0.optionSets[optionSets.count] : nil }
						?? defaultOptionSet,
				),
			)
		}
		return .init(priority: priority, optionSets: optionSets)
	}
}

extension SortOptionSet { // swiftlint:disable:this file_types_order
	/// Parses a `<sort-option-set>` (last wins per option), each omitted option
	/// retaining its value from `defaults`, up to (but not including) a
	/// character in `terminatorSet`, or the end of the input.
	static func parsed(_ input: inout Substring, terminatorSet: Set<Character>, defaults: Self)
	throws(ParsingError) -> Self {
		var optionSet = defaults
		while skipWhitespace(&input), !isAtSortOptionSetEnd(input, terminatorSet: terminatorSet), let option = input.first {
			input.removeFirst()
			if let source = Source(rawValue: option) {
				optionSet.source = source
			} else if let direction = Direction(rawValue: option) {
				optionSet.direction = direction
			} else if let caseSensitivity = CaseSensitivity(rawValue: option) {
				optionSet.caseSensitivity = caseSensitivity
			} else if let numbersInStrings = NumbersInStrings(rawValue: option) {
				optionSet.numbersInStrings = numbersInStrings
			} else if let nonconformingLocation = NonconformingLocation(rawValue: option) {
				optionSet.nonconformingLocation = nonconformingLocation
			} else if let triviaOrder = TriviaOrder(rawValue: option) {
				optionSet.triviaOrder = triviaOrder
			} else {
				switch option {
				case canonical:
					optionSet.localization = .canonical
				case systemLocale:
					optionSet.localization = .localized(.current)
				case customLocale:
					optionSet.localization = .localized(try parseLocale(&input))
				case noBoundariesOption:
					optionSet.boundaries = .noBoundaries
				case uncollapsedBoundariesOption:
					optionSet.boundaries = .uncollapsed(try parseBoundaryGroups(&input))
				case collapsedBoundariesOption:
					optionSet.boundaries = .collapsed(try parseBoundaryGroups(&input))
				default:
					throw .invalidSortOption(option)
				}
			}
		}
		return optionSet
	}

	/// Parses a `<custom-locale>`'s optional `<locale-identifier>` & its
	/// `<sort-option-terminator>`.
	private static func parseLocale(_ input: inout Substring) throws(ParsingError) -> Locale {
		let identifier = try parseText(&input, terminatorSet: [sortOptionTerminator])
		try parseSortOptionTerminator(&input)
		guard !identifier.isEmpty else {
			return .current // `<locale-identifier>`'s default
		}
		guard Locale.availableIdentifiers.contains(identifier) else {
			throw .invalidLocaleIdentifier(identifier)
		}
		return .init(identifier: identifier)
	}

	/// Parses `<uncollapsed-boundaries>`' / `<collapsed-boundaries>`' optional
	/// `<boundary-groups>` & its `<sort-option-terminator>`.
	private static func parseBoundaryGroups(_ input: inout Substring) throws(ParsingError) -> [BoundaryGroup] {
		skipWhitespace(&input)
		guard input.first != sortOptionTerminator else {
			input.removeFirst()
			return defaultBoundaryGroups
		}
		var groups = [BoundaryGroup]()
		var boundaries = [Boundary]()
		while skipWhitespace(&input), let first = input.first, first != sortOptionTerminator {
			switch first {
			case boundaryGroupSeparator:
				input.removeFirst()
				guard !boundaries.isEmpty else {
					throw .emptyBoundaryGroup
				}
				groups.append(.init(boundaries: boundaries))
				boundaries.removeAll()
			case multiCharacterBoundaryFence:
				input.removeFirst()
				let text = try parseText(&input, terminatorSet: [multiCharacterBoundaryFence])
				guard input.first == multiCharacterBoundaryFence, !text.isEmpty else {
					throw .invalidMultiCharacterBoundary
				}
				input.removeFirst()
				boundaries.append(.characters(text))
			case characterClassFence:
				input.removeFirst()
				let name = input.prefix(while: \.isLetter)
				input.removeFirst(name.count)
				guard input.first == characterClassFence, let characterClass = CharacterClass(rawValue: .init(name)) else {
					throw .invalidCharacterClass(.init(name))
				}
				input.removeFirst()
				boundaries.append(.characterClass(characterClass))
			default:
				boundaries += try parseText(&input, terminatorSet: boundaryCharactersTerminatorSet).map(Boundary.character)
			}
		}
		try parseSortOptionTerminator(&input)
		guard !boundaries.isEmpty else {
			throw .emptyBoundaryGroup
		}
		groups.append(.init(boundaries: boundaries))
		return groups
	}

	private static func parseSortOptionTerminator(_ input: inout Substring) throws(ParsingError) {
		guard input.first == sortOptionTerminator else {
			throw .missingSortOptionTerminator
		}
		input.removeFirst()
	}
}

/// Whether `input` is at the end of a `<sort-option-set>`.
private func isAtSortOptionSetEnd(_ input: Substring, terminatorSet: Set<Character>) -> Bool {
	input.first.map(terminatorSet.contains) ?? true
}

/// Skips ignored bare whitespace; always returns `true`, so it may precede a
/// loop condition.
@discardableResult
private func skipWhitespace(_ input: inout Substring) -> Bool {
	input = input.drop(while: \.isWhitespace)
	return true
}

/// Parses a text token whose outer bare whitespace is ignored, up to (but not
/// including) an unescaped character in `terminatorSet`, or the end of the
/// input.
private func parseText(_ input: inout Substring, terminatorSet: Set<Character>) throws(ParsingError) -> String {
	try parseEscapedText(&input, terminatorSet: terminatorSet)
}

// MARK: - Comparison

/// An item's values for a sort key.
struct SortValues { // swiftlint:disable:this one_declaration_per_file
	/// The field's input value.
	let input: JSON.Node?
	/// The field's rendered value, iff a `<sort-option-set>` has `<output>`.
	let output: JSON.Node?
}

extension SortSpec {
	/// Compares 2 items' values for this sort key, whose field's type is
	/// `typeDeterminant`: a value belongs to the 1st `<sort-option-set>` whose
	/// type it conforms to, which compares values that belong to it; a
	/// `<sort-option-set>`'s `<nonconforming-location>` orders the values that
	/// belong to succeeding ones before or after its own; values that belong to
	/// none compare as equal, retaining their input order.
	func compare(_ lhs: SortValues, _ rhs: SortValues, typeDeterminant: TypeDeterminant) -> ComparisonResult {
		let lhsIndex = conformingOptionSetIndex(lhs, typeDeterminant: typeDeterminant)
		let rhsIndex = conformingOptionSetIndex(rhs, typeDeterminant: typeDeterminant)
		guard lhsIndex != rhsIndex else {
			return lhsIndex.map { index in
				let optionSet = optionSets[index]
				return optionSet.compareConforming(
					optionSet.value(of: lhs),
					optionSet.value(of: rhs),
					typeDeterminant: optionSet.typeDeterminant(for: typeDeterminant),
				)
			}
				?? .orderedSame
		}
		let index = min(lhsIndex ?? optionSets.count, rhsIndex ?? optionSets.count)
		let lhsIsConforming = lhsIndex == index
		return switch optionSets[index].nonconformingLocation {
		case .afterConforming:
			lhsIsConforming ? .orderedAscending : .orderedDescending
		case .beforeConforming:
			lhsIsConforming ? .orderedDescending : .orderedAscending
		}
	}

	private func conformingOptionSetIndex(_ values: SortValues, typeDeterminant: TypeDeterminant) -> Int? {
		optionSets.indices.first { index in
			let optionSet = optionSets[index]
			return optionSet.typeDeterminant(for: typeDeterminant).conforms(optionSet.value(of: values))
		}
	}
}

extension SortOptionSet {
	/// Whether any `<sort-option-set>` in `optionSets` has `<output>`.
	static func anyHasOutputSource(_ optionSets: [Self]) -> Bool {
		optionSets.contains { $0.source == .output }
	}

	/// Compares 2 strings (e.g., field names or labels) as strings.
	func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
		directed(compareStrings(lhs, rhs))
	}

	fileprivate func value(of values: SortValues) -> JSON.Node? {
		switch source {
		case .input:
			values.input
		case .output:
			values.output
		}
	}

	/// The type values are compared as: the field's type for `<input>`, or the
	/// rendered value's type for `<output>`.
	fileprivate func typeDeterminant(for fieldTypeDeterminant: TypeDeterminant) -> TypeDeterminant {
		switch source {
		case .input:
			fieldTypeDeterminant
		case .output:
			// swiftlint:disable:next todo
			// TODO: Temp/todo.md "`<output>` sort source": this compares rendered
			//  values by their JSON type (only a passthrough `%i` retains a
			//  non-string type); the alternative is the output type of the format's
			//  final pipeline / placeholder
			.any
		}
	}

	/// Compares 2 values that conform to `typeDeterminant`.
	fileprivate func compareConforming(
		_ lhs: JSON.Node?,
		_ rhs: JSON.Node?,
		typeDeterminant: TypeDeterminant,
	) -> ComparisonResult {
		let result =
			switch typeDeterminant.type {
			case .any:
				compareAny(lhs, rhs)
			case .boolean:
				compareBooleans(
					lhs.boolean(coercion: typeDeterminant.coercion) == true,
					rhs.boolean(coercion: typeDeterminant.coercion) == true,
				)
			case .chronologic:
				ComparableComparator()
					.compare(chronologicDate(from: lhs) ?? .distantPast, chronologicDate(from: rhs) ?? .distantPast)
			case .number:
				compareNumbers(
					numberWithTrivia(in: lhs, coercion: typeDeterminant.coercion),
					numberWithTrivia(in: rhs, coercion: typeDeterminant.coercion),
				)
			case .string:
				compareStrings(lhs?.stringValue ?? "", rhs?.stringValue ?? "")
			case .version:
				compareVersions(lhs?.stringValue ?? "", rhs?.stringValue ?? "")
			}
		return directed(result)
	}

	private func directed(_ result: ComparisonResult) -> ComparisonResult {
		direction == .ascending ? result : result.reversed
	}

	/// Compares 2 values of any type: numbers numerically, booleans `false`
	/// before `true` & anything else as strings.
	private func compareAny(_ lhs: JSON.Node?, _ rhs: JSON.Node?) -> ComparisonResult {
		switch (lhs, rhs) {
		case let (.bool(lhs), .bool(rhs)):
			compareBooleans(lhs, rhs)
		case (.number, .number):
			compareNumbers(numberWithTrivia(in: lhs, coercion: nil), numberWithTrivia(in: rhs, coercion: nil))
		default:
			compareStrings(lhs?.stringValue ?? "", rhs?.stringValue ?? "")
		}
	}

	/// Compares 2 booleans, `false` preceding `true`.
	private func compareBooleans(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
		lhs == rhs ? .orderedSame : lhs ? .orderedDescending : .orderedAscending
	}

	/// Compares 2 numbers & their trivia per `triviaOrder`.
	private func compareNumbers(_ lhs: NumberWithTrivia?, _ rhs: NumberWithTrivia?) -> ComparisonResult {
		let lhs = lhs ?? .init(number: 0, triviaPrefix: "", triviaSuffix: "")
		let rhs = rhs ?? .init(number: 0, triviaPrefix: "", triviaSuffix: "")
		let comparisons: [() -> ComparisonResult] = [
			{ ComparableComparator().compare(lhs.number, rhs.number) },
			{ compareStrings(.init(lhs.triviaPrefix), .init(rhs.triviaPrefix)) },
			{ compareStrings(.init(lhs.triviaSuffix), .init(rhs.triviaSuffix)) },
		]
		let order =
			switch triviaOrder {
			case .first:
				[1, 2, 0]
			case .ignored:
				[0]
			case .last:
				[0, 1, 2]
			case .split:
				[1, 0, 2]
			}
		return order.lazy.map { comparisons[$0]() }.first { $0 != .orderedSame } ?? .orderedSame
	}

	/// Compares 2 versions component by component: numerically, then by the
	/// non-`.` characters (a component with non-`.` characters precedes the
	/// same integer without them); a version with fewer components precedes 1
	/// that extends it.
	private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
		let lhsComponents = lhs.split(separator: ".", omittingEmptySubsequences: false)
		let rhsComponents = rhs.split(separator: ".", omittingEmptySubsequences: false)
		for (lhsComponent, rhsComponent) in zip(lhsComponents, rhsComponents) {
			let lhsDigits = lhsComponent.prefix(while: \.isASCIIDigit)
			let rhsDigits = rhsComponent.prefix(while: \.isASCIIDigit)
			let lhsSuffix = lhsComponent.dropFirst(lhsDigits.count)
			let rhsSuffix = rhsComponent.dropFirst(rhsDigits.count)
			let result =
				ComparableComparator().compare(UInt64(lhsDigits) ?? 0, UInt64(rhsDigits) ?? 0).nonSame
					?? (lhsSuffix.isEmpty == rhsSuffix.isEmpty
						? compareStrings(.init(lhsSuffix), .init(rhsSuffix))
						: lhsSuffix.isEmpty ? .orderedDescending : .orderedAscending)
			guard result == .orderedSame else {
				return result
			}
		}
		return ComparableComparator().compare(lhsComponents.count, rhsComponents.count)
	}

	/// Compares 2 strings per `boundaries`, `caseSensitivity`, `localization` &
	/// `numbersInStrings`: segment by segment, a segment of an earlier
	/// boundary group preceding a segment of a later group, which precedes
	/// non-boundary text; boundaries of the same group share the same sort
	/// precedence.
	private func compareStrings(_ lhs: String, _ rhs: String) -> ComparisonResult {
		let lhsSegments = boundaries.segments(of: lhs)
		let rhsSegments = boundaries.segments(of: rhs)
		for (lhsSegment, rhsSegment) in zip(lhsSegments, rhsSegments) {
			guard lhsSegment.rank == rhsSegment.rank else {
				return ComparableComparator().compare(lhsSegment.rank, rhsSegment.rank)
			}
			guard lhsSegment.rank == boundaries.groups.count else {
				continue
			}
			let result = compareText(.init(lhsSegment.text), .init(rhsSegment.text))
			guard result == .orderedSame else {
				return result
			}
		}
		return ComparableComparator().compare(lhsSegments.count, rhsSegments.count)
	}

	private func compareText(_ lhs: String, _ rhs: String) -> ComparisonResult {
		var options = String.CompareOptions()
		if caseSensitivity == .insensitive {
			options.insert(.caseInsensitive)
		}
		if numbersInStrings != .lexical {
			options.insert(.numeric)
		}
		let locale =
			if case let .localized(locale) = localization {
				locale
			} else {
				Locale?.none
			}
		let groupingSeparator = numbersInStrings == .groupedNumeric ? locale?.groupingSeparator ?? "," : nil
		return ungrouped(lhs, groupingSeparator: groupingSeparator)
			.compare(ungrouped(rhs, groupingSeparator: groupingSeparator), options: options, range: nil, locale: locale)
	}
}

/// `string` without `groupingSeparator` iff it's between digits.
private func ungrouped(_ string: String, groupingSeparator: String?) -> String {
	guard let groupingSeparator, !groupingSeparator.isEmpty else {
		return string
	}
	var result = ""
	var remaining = string[...]
	while let first = remaining.first {
		if
			remaining.hasPrefix(groupingSeparator),
			result.last?.isASCIIDigit == true,
			remaining.dropFirst(groupingSeparator.count).first?.isASCIIDigit == true
		{
			remaining.removeFirst(groupingSeparator.count)
		} else {
			result.append(first)
			remaining.removeFirst()
		}
	}
	return result
}

private extension TypeDeterminant {
	/// Whether `value` conforms to this type: the type's predicate, with this
	/// coercion, matches it; all values conform to "any".
	func conforms(_ value: JSON.Node?) -> Bool {
		switch type {
		case .any:
			true
		case .boolean:
			Matcher(predicate: .boolean, coercion: coercion).conforms(value)
		case .chronologic:
			Matcher(predicate: .chronologic, coercion: nil).conforms(value)
		case .number:
			Matcher(predicate: .number, coercion: coercion).conforms(value)
		case .string:
			Matcher(predicate: .string, coercion: nil).conforms(value)
		case .version:
			Matcher(predicate: .version, coercion: nil).conforms(value)
		}
	}
}

private extension JSON.Node? {
	func boolean(coercion: Coercion?) -> Bool? { // swiftlint:disable:this discouraged_optional_boolean
		switch self {
		case let .bool(bool):
			bool
		case let .string(literal) where coercion != nil:
			["false": false, "true": true][literal.value]
		default:
			nil
		}
	}
}

private extension ComparisonResult {
	/// This result, or `nil` iff `.orderedSame`.
	var nonSame: Self? {
		self == .orderedSame ? nil : self
	}
}

private extension Character {
	var isASCIIDigit: Bool {
		isASCII && isWholeNumber
	}
}

// MARK: - Boundaries

private extension SortOptionSet.Boundaries {
	/// A segment of a string, of a rank: a boundary group's index, or the group
	/// count for non-boundary text.
	struct Segment {
		let rank: Int
		let text: Substring
	}

	var groups: [SortOptionSet.BoundaryGroup] {
		switch self {
		case let .collapsed(groups), let .uncollapsed(groups):
			groups
		case .noBoundaries:
			.init()
		}
	}

	/// `string`'s segments: each maximal run of non-boundary text & each
	/// boundary (iff collapsed, each maximal run of contiguous boundaries of the
	/// same group).
	func segments(of string: String) -> [Segment] {
		let textRank = groups.count
		let isCollapsed = if case .collapsed = self {
			true
		} else {
			false
		}
		var segments = [Segment]()
		var index = string.startIndex
		while index < string.endIndex {
			let (rank, length) = rankAndLength(in: string, at: index)
			let end = string.index(index, offsetBy: length)
			if let last = segments.last, last.rank == rank, rank == textRank || isCollapsed {
				segments[segments.count - 1] = .init(rank: rank, text: string[last.text.startIndex..<end])
			} else {
				segments.append(.init(rank: rank, text: string[index..<end]))
			}
			index = end
		}
		return segments
	}

	/// The rank & length of the longest boundary at `index` (a boundary defined
	/// by multiple groups belongs to the last one), else non-boundary text's
	/// rank & a length of 1.
	private func rankAndLength(in string: String, at index: String.Index) -> (rank: Int, length: Int) {
		var best = (rank: groups.count, length: 1)
		var matchedLength = 0
		for (groupIndex, group) in groups.enumerated() {
			for boundary in group.boundaries {
				guard let length = boundary.matchLength(in: string, at: index), length >= matchedLength else {
					continue
				}
				matchedLength = length
				best = (groupIndex, length)
			}
		}
		return best
	}
}

private extension SortOptionSet.Boundary {
	/// The number of characters this boundary matches at `index` in `string`,
	/// or `nil` iff it doesn't match there.
	func matchLength(in string: String, at index: String.Index) -> Int? {
		switch self {
		case let .character(match):
			string[index] == match ? 1 : nil
		case let .characterClass(characterClass):
			characterClass.contains(string[index]) ? 1 : nil
		case let .characters(match):
			string[index...].hasPrefix(match) ? match.count : nil
		}
	}
}

private extension SortOptionSet.CharacterClass {
	/// Whether `character` belongs to this GNU Extended POSIX character class,
	/// approximated via `Character`'s Unicode-aware properties.
	func contains(_ character: Character) -> Bool {
		switch self {
		case .alnum:
			character.isLetter || character.isNumber
		case .alpha:
			character.isLetter
		case .ascii:
			character.isASCII
		case .blank:
			character == " " || character == "\t"
		case .cntrl:
			character.asciiValue.map { $0 < 0x20 || $0 == 0x7f } ?? false
		case .digit:
			character.isASCIIDigit
		case .graph:
			character.asciiValue.map { (0x21...0x7e).contains($0) } ?? false
		case .lower:
			character.isLowercase
		case .print:
			character.asciiValue.map { (0x20...0x7e).contains($0) } ?? false
		case .punct:
			character.isPunctuation || character.isSymbol
		case .space:
			character.isWhitespace
		case .upper:
			character.isUppercase
		case .word:
			character.isLetter || character.isNumber || character == "_"
		case .xdigit:
			character.isHexDigit
		}
	}
}

// MARK: - Constants

private let sortOptionTerminator = Character("+")
private let sortModifierTerminatorSet = Set([sortModifierPrefix, fieldSpecSeparator])

private let canonical = Character("c")
private let systemLocale = Character("l")
private let customLocale = Character("L")

private let noBoundariesOption = Character("b")
private let uncollapsedBoundariesOption = Character("B")
private let collapsedBoundariesOption = Character("C")
private let boundaryGroupSeparator = Character("_")
private let multiCharacterBoundaryFence = Character("%")
private let characterClassFence = Character(":")
private let boundaryCharactersTerminatorSet =
	Set([multiCharacterBoundaryFence, characterClassFence, boundaryGroupSeparator, sortOptionTerminator])
