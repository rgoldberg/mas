//
// SortSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import BigInt
internal import Foundation
internal import JSONAST

// MARK: - Sorting (fields.md)

/// A field spec's `<sort>`.
struct SortSpec: Equatable {
	/// `<sort-priority>`.
	let priority: BigUInt
	/// `false` iff `<sort>` starts with `<disabled-sort-prefix>`: a disabled sort
	/// retains `priority` & `optionSet`, but does not sort items.
	let isEnabled: Bool
	/// `<sort-option-set>`.
	let optionSet: SortOptionSet

	/// A disabled copy.
	var disabled: Self {
		.init(priority: priority, isEnabled: false, optionSet: optionSet)
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
		case ascending = "+"
		case descending = "-"
	}

	/// `<case-sensitivity>`.
	enum CaseSensitivity: Character {
		case insensitive = "i"
		case sensitive = "s"
	}

	/// `<number-segments>`.
	enum NumberSegments: Equatable {
		/// `<grouped-numeric>`.
		case groupedNumeric(GroupedNumericArguments)
		case lexicographic
		/// `<ungrouped-numeric>`.
		case ungroupedNumeric
		case versions
	}

	/// `<grouped-numeric-arguments>`' values; each absent (`nil`) number format
	/// argument defaults to the base conventions.
	struct GroupedNumericArguments: Equatable {
		/// `<grouped-numeric>` without `<grouped-numeric-arguments>`.
		static let `default` = Self(
			baseConventions: nil,
			digitGroupSeparator: nil,
			digitGroupSize: nil,
			secondaryDigitGroupSize: nil,
			decimalSeparator: nil,
			signs: .wordInitialSigns,
		)

		/// The conventions that `<locale-identifier>` identifies; `nil` iff it is
		/// absent, so `<locale>`'s are the base conventions.
		let baseConventions: NumberConventions?
		let digitGroupSeparator: String?
		let digitGroupSize: Int?
		let secondaryDigitGroupSize: Int?
		let decimalSeparator: String?
		let signs: NumberSigns

		/// These arguments' conventions, `localeConventions` being the base
		/// conventions absent `<locale-identifier>`.
		func conventions(localeConventions: NumberConventions) -> NumberConventions {
			let baseConventions = baseConventions ?? localeConventions
			return .init(
				digitGroupSeparator: digitGroupSeparator ?? baseConventions.digitGroupSeparator,
				digitGroupSize: digitGroupSize ?? baseConventions.digitGroupSize,
				secondaryDigitGroupSize: secondaryDigitGroupSize ?? baseConventions.secondaryDigitGroupSize,
				decimalSeparator: decimalSeparator ?? baseConventions.decimalSeparator,
			)
		}
	}

	/// `<number-signs>`.
	enum NumberSigns: String, CaseIterable {
		/// `<all-signs>`.
		case allSigns = "all"
		/// `<no-signs>`.
		case noSigns = "none"
		/// `<word-initial-signs>`.
		case wordInitialSigns = "word-initial"
	}

	/// `<boundaries>`.
	enum Boundaries: Equatable {
		/// `<collapsed-boundaries>`.
		case collapsed([BoundaryGroup])
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

	/// `<nonconforming-comparison>`.
	enum NonconformingComparison: Character {
		/// `<all-conforming>`.
		case allConforming = "k"
		case greatest = "z"
		case least = "a"
	}

	/// `<nonconforming-placement>`: whether nonconforming values' location
	/// depends on `<direction>`.
	enum NonconformingPlacement: Character {
		/// `<fixed-nonconforming>`: 1st iff `<nonconforming-least>`, else last,
		/// regardless of `<direction>`.
		case fixed = "f"
		/// `<relative-nonconforming>`: `<descending>` reverses their location.
		case relative = "r"
	}

	/// `<text-order>`.
	enum TextOrder: Character {
		case excluded = "e"
		case first = "h"
		/// `<text-in-place>`.
		case inPlace = "p"
		case last = "t"
	}

	/// Every option's default.
	static let `default` = Self(
		source: .input,
		direction: .ascending,
		caseSensitivity: .sensitive,
		locale: nil,
		numberSegments: .ungroupedNumeric,
		chronologicSegments: Set(ISO8601Form.allCases),
		hasUnixTimeSegments: false,
		boundaries: .uncollapsed(defaultBoundaryGroups),
		nonconformingComparison: .allConforming,
		nonconformingPlacement: .relative,
		textOrder: .inPlace,
	)

	/// `<boundaries>`' default `<boundary-groups>`: `+space+`.
	static let defaultBoundaryGroups = [BoundaryGroup(boundaries: [.characterClass(.space)])]

	var source: Source
	var direction: Direction
	var caseSensitivity: CaseSensitivity
	/// `<locale>`'s locale; `nil` iff it identifies the canonical conventions.
	var locale: Locale?
	var numberSegments: NumberSegments
	/// `<chronologic-segments>`' ISO-8601 forms.
	var chronologicSegments: Set<ISO8601Form>
	/// Whether `<chronologic-segments>` includes `<unix-time>`.
	var hasUnixTimeSegments: Bool
	var boundaries: Boundaries
	var nonconformingComparison: NonconformingComparison
	var nonconformingPlacement: NonconformingPlacement
	var textOrder: TextOrder
}

// MARK: - Parsing

extension SortSpec { // swiftlint:disable:this file_types_order
	/// Parses a `<sort-modifier>`'s payload (after its `<sort-modifier-prefix>`):
	/// `nil` iff `<sort>` is absent (its direct default). 1 or more
	/// `<disabled-sort-prefix>`es disable the sort. An omitted `<sort-priority>`
	/// retains `existing`'s, if any, else is `defaultSortPriority`. An option
	/// omitted from a present `<sort-option-set>` retains `existing`'s value, or
	/// `defaultOptionSet`'s absent `existing`.
	static func parsed(_ input: inout Substring, existing: Self?, defaultOptionSet: SortOptionSet)
	throws(ParsingError) -> Self? {
		skipWhitespace(&input)
		guard let first = input.first, first != fieldSpecSeparator else {
			return nil // `<sort>`'s direct default
		}
		let isEnabled = first != disabledSortPrefix
		while input.first == disabledSortPrefix {
			input.removeFirst()
			skipWhitespace(&input)
		}
		let priority = parseIntegerText(&input, isSigned: false, allowsLeadingZeros: false).flatMap { BigUInt($0) }
			?? existing?.priority
			?? defaultSortPriority
		skipWhitespace(&input)
		let optionSetDefaults = existing?.optionSet ?? defaultOptionSet
		return .init(
			priority: priority,
			isEnabled: isEnabled,
			optionSet: isAtSortOptionSetEnd(input, terminatorSet: sortModifierTerminatorSet)
				? optionSetDefaults
				: try SortOptionSet.parsed(&input, terminatorSet: sortModifierTerminatorSet, defaults: optionSetDefaults),
		)
	}
}

extension SortOptionSet { // swiftlint:disable:this file_types_order
	/// Parses a `<sort-option-set>` (last wins per option), each omitted option
	/// retaining its value from `defaults`, up to (but not including) a character
	/// in `terminatorSet`, or the end of the input.
	static func parsed(_ input: inout Substring, terminatorSet: Set<Character>, defaults: Self)
	throws(ParsingError) -> Self {
		try parsed(&input, terminatorSet: terminatorSet) { _ in defaults }
	}

	/// Parses a `<sort-option-set>` (last wins per option), each omitted option
	/// retaining its value from `defaults` of its effective `<source>`, if any,
	/// else of `nil`, up to (but not including) a character in `terminatorSet`,
	/// or the end of the input, so the defaults may depend on `<source>` wherever
	/// it is in the set (e.g., a field order's, per fields.md "Field Order").
	static func parsed(
		_ input: inout Substring,
		terminatorSet: Set<Character>,
		defaults: (Source?) -> Self,
	) throws(ParsingError) -> Self {
		var source = Source?.none
		var setters = [(inout Self) -> Void]()
		while skipWhitespace(&input), !isAtSortOptionSetEnd(input, terminatorSet: terminatorSet), let option = input.first {
			input.removeFirst()
			if let match = Source(rawValue: option) {
				source = match
			} else if let direction = Direction(rawValue: option) {
				setters.append { $0.direction = direction }
			} else if let caseSensitivity = CaseSensitivity(rawValue: option) {
				setters.append { $0.caseSensitivity = caseSensitivity }
			} else if let numberSegments = numberSegmentsByOption[option] {
				setters.append { $0.numberSegments = numberSegments }
			} else if let nonconformingComparison = NonconformingComparison(rawValue: option) {
				setters.append { $0.nonconformingComparison = nonconformingComparison }
			} else if let nonconformingPlacement = NonconformingPlacement(rawValue: option) {
				setters.append { $0.nonconformingPlacement = nonconformingPlacement }
			} else if let textOrder = TextOrder(rawValue: option) {
				setters.append { $0.textOrder = textOrder }
			} else {
				switch option {
				case localeOption:
					let locale = try parseLocale(&input)
					setters.append { $0.locale = locale }
				case groupedNumericOption:
					let arguments = try parseGroupedNumericArguments(&input)
					setters.append { $0.numberSegments = .groupedNumeric(arguments) }
				case chronologicSegmentsOption:
					let (chronologicSegments, hasUnixTimeSegments) = try parseChronologicFormats(&input)
					setters.append { optionSet in
						optionSet.chronologicSegments = chronologicSegments
						optionSet.hasUnixTimeSegments = hasUnixTimeSegments
					}
				case uncollapsedBoundariesOption:
					let boundaryGroups = try parseBoundaryGroups(&input)
					setters.append { $0.boundaries = .uncollapsed(boundaryGroups) }
				case collapsedBoundariesOption:
					let boundaryGroups = try parseBoundaryGroups(&input)
					setters.append { $0.boundaries = .collapsed(boundaryGroups) }
				default:
					throw .invalidSortOption(option)
				}
			}
		}
		var optionSet = defaults(source)
		if let source {
			optionSet.source = source
		}
		for setter in setters {
			setter(&optionSet)
		}
		if
			case let .groupedNumeric(arguments) = optionSet.numberSegments,
			arguments.conventions(localeConventions: optionSet.locale.numberConventions).hasAmbiguousSeparators
		{
			throw .invalidSortOptionArguments(groupedNumericOption)
		}
		return optionSet
	}

	/// Parses `<locale>`'s optional `<locale-identifier>` (`system` iff absent) &
	/// its `<sort-option-terminator>`: `nil` iff it identifies the canonical
	/// conventions.
	private static func parseLocale(_ input: inout Substring) throws(ParsingError) -> Locale? {
		let identifier = try parseText(&input, terminatorSet: [sortOptionTerminator])
		try parseSortOptionTerminator(&input)
		return switch identifier {
		case "":
			.current
		case canonicalLocaleIdentifier:
			nil
		default:
			try mas.locale(forIdentifier: identifier)
		}
	}

	/// Parses `<grouped-numeric>`'s optional `<grouped-numeric-arguments>` & its
	/// `<sort-option-terminator>`.
	private static func parseGroupedNumericArguments(_ input: inout Substring)
	throws(ParsingError) -> GroupedNumericArguments {
		let invalidArgumentsError = ParsingError.invalidSortOptionArguments(groupedNumericOption)
		let arguments = try parseArguments(
			&input,
			count: numberFormatArgumentCount,
			terminator: sortOptionTerminator,
			isLastArgumentSeparatorTerminated: true,
		)
		let hasNumberSigns = input.first == argumentSeparator
		if hasNumberSigns {
			input.removeFirst()
		}
		let signs = hasNumberSigns ? parseNameLiteral(&input, from: NumberSigns.allCases.map(\.rawValue)) : nil
		guard isAtSortOptionSetEnd(input, terminatorSet: [sortOptionTerminator]) else {
			throw invalidArgumentsError
		}
		try parseSortOptionTerminator(&input)
		func size(_ argument: String?) throws(ParsingError) -> Int? {
			try argument.map { argument throws(ParsingError) in
				guard let size = nonNegativeInteger(argument) else {
					throw invalidArgumentsError
				}
				return size
			}
		}
		return .init(
			baseConventions: try arguments[0].map(numberConventions(forIdentifier:)),
			digitGroupSeparator: arguments[1],
			digitGroupSize: try size(arguments[2]),
			secondaryDigitGroupSize: try size(arguments[3]),
			decimalSeparator: arguments[4],
			signs: signs.flatMap(NumberSigns.init(rawValue:)) ?? .wordInitialSigns,
		)
	}

	/// Parses `<chronologic-segments>`' optional `<chronologic-formats>` (none
	/// iff absent) & its `<sort-option-terminator>`: its ISO-8601 forms & whether
	/// it includes `<unix-time>`.
	private static func parseChronologicFormats(_ input: inout Substring)
	throws(ParsingError) -> (iso8601Forms: Set<ISO8601Form>, hasUnixTime: Bool) {
		var forms = Set<ISO8601Form>()
		var hasUnixTime = false
		var isAtChronologicFormat = skipWhitespace(&input)
			&& !isAtSortOptionSetEnd(input, terminatorSet: [sortOptionTerminator])
		while isAtChronologicFormat {
			guard let format = parseNameLiteral(&input, from: chronologicFormats) else {
				throw .invalidSortOptionArguments(chronologicSegmentsOption)
			}
			if let formatForms = iso8601FormsByChronologicFormat[format] {
				forms.formUnion(formatForms)
			} else {
				hasUnixTime = true
			}
			isAtChronologicFormat = input.first == argumentSeparator
			if isAtChronologicFormat {
				input.removeFirst()
			}
		}
		guard isAtSortOptionSetEnd(input, terminatorSet: [sortOptionTerminator]) else {
			throw .invalidSortOptionArguments(chronologicSegmentsOption)
		}
		try parseSortOptionTerminator(&input)
		return (forms, hasUnixTime)
	}

	/// Parses `<uncollapsed-boundaries>`' / `<collapsed-boundaries>`' optional
	/// `<boundary-groups>` (none iff absent; each empty group omitted) & its
	/// `<sort-option-terminator>`.
	private static func parseBoundaryGroups(_ input: inout Substring) throws(ParsingError) -> [BoundaryGroup] {
		var groups = [BoundaryGroup]()
		var boundaries = [Boundary]()
		while skipWhitespace(&input), let first = input.first, first != sortOptionTerminator {
			switch first {
			case boundaryGroupSeparator:
				input.removeFirst()
				if !boundaries.isEmpty {
					groups.append(.init(boundaries: boundaries))
					boundaries.removeAll()
				}
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
				let name = try parseText(&input, terminatorSet: [characterClassFence, sortOptionTerminator])
				guard input.first == characterClassFence, let characterClass = CharacterClass(rawValue: name) else {
					throw .invalidCharacterClass(name)
				}
				input.removeFirst()
				boundaries.append(.characterClass(characterClass))
			default:
				boundaries += try parseText(&input, terminatorSet: boundaryCharactersTerminatorSet).map(Boundary.character)
			}
		}
		try parseSortOptionTerminator(&input)
		return boundaries.isEmpty ? groups : groups + [.init(boundaries: boundaries)]
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

/// Parses a variable token whose outer bare whitespace is ignored, up to (but
/// not including) an unescaped character in `terminatorSet`, or the end of the
/// input.
private func parseText(_ input: inout Substring, terminatorSet: Set<Character>) throws(ParsingError) -> String {
	try parseEscapedText(&input, terminatorSet: terminatorSet)
}

// MARK: - Comparison

/// An item's values for a sort key.
struct SortValues { // swiftlint:disable:this one_declaration_per_file
	/// The field's input value.
	let input: JSON.Node?
	/// The field's rendered value, iff `<sort-option-set>` has `<output>`, a
	/// number without its trivia.
	let output: JSON.Node?
	/// `output`'s trivia prefix & suffix iff it is a number (both empty unless
	/// coerced with a trivia regex).
	var outputTrivia = (prefix: Substring(), suffix: Substring())
}

extension SortSpec {
	/// Compares 2 items' values for this sort key, per `optionSet`.
	func compare(_ lhs: SortValues, _ rhs: SortValues) -> ComparisonResult {
		optionSet.compare(lhs, rhs)
	}
}

extension SortOptionSet {
	/// A segment of a run of non-boundary text.
	private enum Segment {
		case chronologic(Chronologic)
		/// A number segment that is a number.
		case number(DecimalNumber)
		case text(Substring)
		/// A number segment that is a version.
		case version(Substring)

		/// The rank of this segment's kind, in ascending order: time-only
		/// chronologic, other chronologic, number, then text.
		var kindRank: Int {
			switch self {
			case .chronologic(.time):
				0
			case .chronologic:
				1
			case .number, .version:
				2
			case .text:
				3
			}
		}

		var isTyped: Bool {
			if case .text = self {
				false
			} else {
				true
			}
		}
	}

	/// A piece of a value: a boundary of a boundary group's rank, or, iff `rank`
	/// is the boundary group count, a run of non-boundary text's segments.
	private struct Piece {
		let rank: Int
		let segments: [Segment]

		var hasTypedSegment: Bool {
			segments.contains(where: \.isTyped)
		}
	}

	/// Compares 2 strings (e.g., field names or labels).
	func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
		compare(pieces(of: lhs), pieces(of: rhs))
	}

	/// Compares 2 items' values per this option set.
	fileprivate func compare(_ lhs: SortValues, _ rhs: SortValues) -> ComparisonResult {
		compare(pieces(of: lhs), pieces(of: rhs))
	}

	private func directed(_ result: ComparisonResult) -> ComparisonResult {
		direction == .ascending ? result : result.reversed
	}

	/// The pieces of `values`' value per `source`: a number is a single segment,
	/// per `numberValueSegment(of:)`, if any, between its trivia, each compared
	/// as a string; any other value, an output number's trivia included, is
	/// compared as a string (`null` as an empty string).
	private func pieces(of values: SortValues) -> [Piece] {
		let (value, trivia) =
			switch source {
			case .input:
				(values.input, (prefix: Substring(), suffix: Substring()))
			case .output:
				(values.output, values.outputTrivia)
			}
		return if let segment = numberValueSegment(of: value) {
			concatenated(
				pieces(of: String(trivia.prefix)),
				[.init(rank: boundaries.groups.count, segments: [segment])],
				pieces(of: String(trivia.suffix)),
			)
		} else {
			pieces(of: "\(trivia.prefix)\(value?.stringValue ?? "")\(trivia.suffix)")
		}
	}

	/// `pieceLists` concatenated, merging each run of non-boundary text that
	/// spans adjacent lists into 1 piece.
	private func concatenated(_ pieceLists: [Piece]...) -> [Piece] {
		let textRank = boundaries.groups.count
		return pieceLists.joined().reduce(into: []) { pieces, piece in
			if let last = pieces.last, last.rank == textRank, piece.rank == textRank {
				pieces[pieces.count - 1] = .init(rank: textRank, segments: last.segments + piece.segments)
			} else {
				pieces.append(piece)
			}
		}
	}

	/// `value`'s single segment iff it is a number: a chronologic segment iff
	/// `hasUnixTimeSegments` & it is a representable Unix time, else a number
	/// segment unless `numberSegments` is `<lexicographic>` or `<versions>`
	/// (either of which compares its text); else `nil`.
	private func numberValueSegment(of value: JSON.Node?) -> Segment? {
		guard case let .number(number)? = value, let number = DecimalNumber("\(number)") else {
			return nil
		}
		return (hasUnixTimeSegments ? unixTimeInstant(number).map { .chronologic(.datetime($0)) } : nil)
			?? (numberSegments == .lexicographic || numberSegments == .versions ? nil : .number(number))
	}

	/// `string`'s pieces: each boundary outside its typed segments & each run of
	/// non-boundary text's segments (typed segments being detected across the
	/// whole string, before boundaries).
	private func pieces(of string: String) -> [Piece] {
		let textRank = boundaries.groups.count
		var pieces = [Piece]()
		func append(_ segment: Segment) {
			if let last = pieces.last, last.rank == textRank {
				pieces[pieces.count - 1] = .init(rank: textRank, segments: last.segments + [segment])
			} else {
				pieces.append(.init(rank: textRank, segments: [segment]))
			}
		}
		func appendUntyped(_ text: Substring) {
			for piece in boundaries.pieces(of: text) {
				if piece.rank == textRank {
					append(.text(piece.text))
				} else {
					pieces.append(.init(rank: piece.rank, segments: .init()))
				}
			}
		}
		var untypedStart = string.startIndex
		var index = string.startIndex
		while index < string.endIndex {
			guard let typedSegment = typedSegment(at: index, in: string) else {
				index = string.index(after: index)
				continue
			}
			appendUntyped(string[untypedStart..<index])
			append(typedSegment.segment)
			index = typedSegment.end
			untypedStart = index
		}
		appendUntyped(string[untypedStart...])
		return pieces
	}

	/// Compares 2 values' pieces per `direction`: with `<nonconforming-least>` or
	/// `<nonconforming-greatest>`, a value without any typed segment is
	/// nonconforming, comparing as less or greater than any conforming value
	/// (regardless of `direction` iff `<fixed-nonconforming>`); otherwise, piece
	/// by piece, a boundary of an earlier boundary group preceding a boundary of
	/// a later group, which precedes non-boundary text; boundaries of the same
	/// group share the same sort precedence.
	private func compare(_ lhs: [Piece], _ rhs: [Piece]) -> ComparisonResult {
		let isLHSConforming = lhs.contains(where: \.hasTypedSegment)
		guard nonconformingComparison != .allConforming, isLHSConforming != rhs.contains(where: \.hasTypedSegment) else {
			return directed(compareConforming(lhs, rhs))
		}
		let result =
			isLHSConforming == (nonconformingComparison == .greatest) ? ComparisonResult.orderedAscending : .orderedDescending
		return nonconformingPlacement == .fixed ? result : directed(result)
	}

	/// Compares 2 values' pieces, piece by piece, regardless of `direction`.
	private func compareConforming(_ lhs: [Piece], _ rhs: [Piece]) -> ComparisonResult {
		for (lhsPiece, rhsPiece) in zip(lhs, rhs) {
			guard lhsPiece.rank == rhsPiece.rank else {
				return ComparableComparator().compare(lhsPiece.rank, rhsPiece.rank)
			}
			let result = compareSegments(lhsPiece.segments, rhsPiece.segments)
			guard result == .orderedSame else {
				return result
			}
		}
		return ComparableComparator().compare(lhs.count, rhs.count)
	}

	/// Compares 2 runs of non-boundary text's segments per `textOrder`.
	private func compareSegments(_ lhs: [Segment], _ rhs: [Segment]) -> ComparisonResult {
		let lhsTyped = lhs.filter(\.isTyped)
		let rhsTyped = rhs.filter(\.isTyped)
		let lhsText = lhs.filter { !$0.isTyped }
		let rhsText = rhs.filter { !$0.isTyped }
		return switch textOrder {
		case .excluded:
			compareSegmentList(lhsTyped, rhsTyped)
		case .first:
			compareSegmentList(lhsText, rhsText).nonSame ?? compareSegmentList(lhsTyped, rhsTyped)
		case .inPlace:
			compareSegmentList(lhs, rhs)
		case .last:
			compareSegmentList(lhsTyped, rhsTyped).nonSame ?? compareSegmentList(lhsText, rhsText)
		}
	}

	/// Compares 2 lists of segments element by element: the 1st unequal pair
	/// decides, else a list that is a prefix of the other precedes it.
	private func compareSegmentList(_ lhs: [Segment], _ rhs: [Segment]) -> ComparisonResult {
		zip(lhs, rhs).lazy.map(compareSegment).first { $0 != .orderedSame }
			?? ComparableComparator().compare(lhs.count, rhs.count)
	}

	/// Compares 2 segments: by kind, then per their kind.
	private func compareSegment(_ lhs: Segment, _ rhs: Segment) -> ComparisonResult {
		switch (lhs, rhs) {
		case let (.chronologic(.time(lhsTime)), .chronologic(.time(rhsTime))):
			ComparableComparator().compare(lhsTime.utcMillisecondOfDay, rhsTime.utcMillisecondOfDay)
		case let (.chronologic(lhsChronologic), .chronologic(rhsChronologic)):
			if let lhsInstant = lhsChronologic.instant, let rhsInstant = rhsChronologic.instant {
				ComparableComparator().compare(lhsInstant, rhsInstant)
			} else {
				ComparableComparator().compare(lhs.kindRank, rhs.kindRank)
			}
		case let (.number(lhsNumber), .number(rhsNumber)):
			ComparableComparator().compare(lhsNumber, rhsNumber)
		case let (.text(lhsText), .text(rhsText)):
			compareLexically(lhsText, rhsText)
		case let (.version(lhsVersion), .version(rhsVersion)):
			compareVersions(lhsVersion, rhsVersion)
		default:
			ComparableComparator().compare(lhs.kindRank, rhs.kindRank)
		}
	}

	/// Compares 2 versions component by component: numerically by each
	/// component's leading ASCII digits, then by its remaining characters (a
	/// component with remaining characters precedes the same integer without
	/// them); a version with fewer components precedes 1 that extends it.
	private func compareVersions(_ lhs: Substring, _ rhs: Substring) -> ComparisonResult {
		let lhsComponents = lhs.split(separator: ".", omittingEmptySubsequences: false)
		let rhsComponents = rhs.split(separator: ".", omittingEmptySubsequences: false)
		for (lhsComponent, rhsComponent) in zip(lhsComponents, rhsComponents) {
			let lhsDigits = lhsComponent.prefix(while: \.isASCIIDigit)
			let rhsDigits = rhsComponent.prefix(while: \.isASCIIDigit)
			let lhsSuffix = lhsComponent.dropFirst(lhsDigits.count)
			let rhsSuffix = rhsComponent.dropFirst(rhsDigits.count)
			let result =
				ComparableComparator()
				.compare(DecimalNumber(lhsDigits) ?? .zero, DecimalNumber(rhsDigits) ?? .zero)
				.nonSame
				?? (lhsSuffix.isEmpty == rhsSuffix.isEmpty
					? compareVersionSuffixes(lhsSuffix, rhsSuffix)
					: lhsSuffix.isEmpty ? .orderedDescending : .orderedAscending)
			guard result == .orderedSame else {
				return result
			}
		}
		return ComparableComparator().compare(lhsComponents.count, rhsComponents.count)
	}

	/// Compares 2 version components' remaining characters as lists of their
	/// maximal runs of ASCII digits (each compared numerically) & of other
	/// characters (each compared lexically), e.g., `b9` precedes `b10`.
	private func compareVersionSuffixes(_ lhs: Substring, _ rhs: Substring) -> ComparisonResult {
		let lhsRuns = versionSuffixRuns(of: lhs)
		let rhsRuns = versionSuffixRuns(of: rhs)
		return zip(lhsRuns, rhsRuns)
			.lazy
			.map { lhsRun, rhsRun in
				lhsRun.first?.isASCIIDigit == true && rhsRun.first?.isASCIIDigit == true
					? ComparableComparator().compare(DecimalNumber(lhsRun) ?? .zero, DecimalNumber(rhsRun) ?? .zero)
					: compareLexically(lhsRun, rhsRun)
			}
			.first { $0 != .orderedSame }
			?? ComparableComparator().compare(lhsRuns.count, rhsRuns.count)
	}

	/// `suffix`'s maximal runs of ASCII digits & of other characters, in order.
	private func versionSuffixRuns(of suffix: Substring) -> [Substring] {
		var runs = [Substring]()
		var start = suffix.startIndex
		while start < suffix.endIndex {
			let isDigitRun = suffix[start].isASCIIDigit
			let end = suffix[start...].firstIndex { $0.isASCIIDigit != isDigitRun } ?? suffix.endIndex
			runs.append(suffix[start..<end])
			start = end
		}
		return runs
	}

	/// Compares 2 texts per `caseSensitivity` & `locale`'s collation, the CLDR
	/// root collation iff `locale` is `nil` (i.e., the canonical conventions).
	private func compareLexically(_ lhs: Substring, _ rhs: Substring) -> ComparisonResult {
		var options = String.CompareOptions()
		if caseSensitivity == .insensitive {
			options.insert(.caseInsensitive)
		}
		return lhs.compare(rhs, options: options, range: nil, locale: locale ?? rootLocale)
	}

	/// The typed segment at `index` in `value` & its end; else `nil`.
	private func typedSegment(at index: String.Index, in value: String) -> (segment: Segment, end: String.Index)? {
		chronologicSegment(at: index, in: value)
			?? unixTimeSegment(at: index, in: value)
			?? numberSegment(at: index, in: value)
	}

	/// The chronologic segment at `index` in `value` & its end, unless an ASCII
	/// digit immediately precedes or follows it, or it starts with an expanded
	/// year's sign that is not word-initial; else `nil`.
	private func chronologicSegment(at index: String.Index, in value: String) -> (segment: Segment, end: String.Index)? {
		guard
			!chronologicSegments.isEmpty,
			index == value.startIndex || !value[value.index(before: index)].isASCIIDigit,
			value[index] != "-" && value[index] != "+" || isSign(at: index, in: value, signs: .wordInitialSigns),
			let prefix = iso8601ChronologicPrefix(of: value[index...], forms: chronologicSegments),
			prefix.end == value.endIndex || !value[prefix.end].isASCIIDigit
		else {
			return nil
		}
		return (.chronologic(prefix.chronologic), prefix.end)
	}

	/// The Unix time chronologic segment at `index` in `value` & its end iff
	/// `hasUnixTimeSegments` & it is neither preceded nor followed by a
	/// non-whitespace character; else `nil`.
	private func unixTimeSegment(at index: String.Index, in value: String) -> (segment: Segment, end: String.Index)? {
		guard hasUnixTimeSegments, index == value.startIndex || value[value.index(before: index)].isWhitespace else {
			return nil
		}
		let word = value[index...].prefix { !$0.isWhitespace }
		return word.endIndex == value.endIndex || value[word.endIndex].isWhitespace
			? unixTimeInstant(in: word).map { (.chronologic(.datetime($0)), word.endIndex) }
			: nil
	}

	/// The number segment (including its sign, if any) at `index` in `value` &
	/// its end; else `nil`. A `-` or `+` that is not a number's sign may start an
	/// unsigned number's decimal separator (e.g., `-x5` is `.5` for a decimal
	/// separator of `-x`).
	private func numberSegment(at index: String.Index, in value: String) -> (segment: Segment, end: String.Index)? {
		let signs: NumberSigns
		switch numberSegments {
		case .lexicographic:
			return nil
		case let .groupedNumeric(arguments):
			signs = arguments.signs
		case .ungroupedNumeric:
			signs = .wordInitialSigns
		case .versions:
			return value[index].isASCIIDigit
				? value[index...].prefixMatch(of: unsafe versionRegex).map { (.version($0.output), $0.range.upperBound) }
				: nil
		}
		let afterSign = value.index(after: index)
		let signedNumber = (value[index] == "-" || value[index] == "+")
			&& afterSign < value.endIndex
			&& isSign(at: index, in: value, signs: signs)
			? unsignedNumberPrefix(of: value[afterSign...]).map { number in
				(segment: Segment.number(value[index] == "-" ? number.number.negated : number.number), end: number.end)
			}
			: nil
		return signedNumber ?? unsignedNumberPrefix(of: value[index...])
			.map { number in (.number(number.number), number.end) }
	}

	/// The unsigned number at the start of `string` per `numberSegments` & its
	/// end; else `nil`.
	private func unsignedNumberPrefix(of string: Substring) -> (number: DecimalNumber, end: Substring.Index)? {
		switch numberSegments {
		case let .groupedNumeric(arguments):
			arguments.conventions(localeConventions: locale.numberConventions).groupedNumberPrefix(of: string)
		case .lexicographic, .versions:
			nil
		case .ungroupedNumeric:
			string.prefix(while: \.isASCIIDigit).nilIfEmpty.flatMap { digits in
				DecimalNumber(digits).map { ($0, digits.endIndex) }
			}
		}
	}
}

/// Whether the `-` or `+` at `index` in `value` is a sign per `signs`.
private func isSign(at index: String.Index, in value: String, signs: SortOptionSet.NumberSigns) -> Bool {
	switch signs {
	case .allSigns:
		true
	case .noSigns:
		false
	case .wordInitialSigns:
		index == value.startIndex || value[value.index(before: index)].isWhitespace
	}
}

private extension Chronologic {
	/// The instant of a date-only or datetime; `nil` for a time-only.
	var instant: Int? {
		switch self {
		case let .date(instant), let .datetime(instant):
			instant
		case .time:
			nil
		}
	}
}

private extension Locale? {
	/// The canonical conventions iff `nil`, else this locale's.
	var numberConventions: NumberConventions {
		map(NumberConventions.init(locale:)) ?? .canonical
	}
}

private extension Substring {
	/// This substring, or `nil` iff it is empty.
	var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}
}

private extension ComparisonResult {
	/// This result, or `nil` iff `.orderedSame`.
	var nonSame: Self? {
		self == .orderedSame ? nil : self
	}
}

// MARK: - Boundaries

private extension SortOptionSet.Boundaries {
	/// A piece of a string, of a rank: a boundary group's index, or the group
	/// count for non-boundary text.
	struct Piece {
		let rank: Int
		let text: Substring
	}

	var groups: [SortOptionSet.BoundaryGroup] {
		switch self {
		case let .collapsed(groups), let .uncollapsed(groups):
			groups
		}
	}

	/// `string`'s pieces: each maximal run of non-boundary text & each boundary
	/// (iff collapsed, each maximal run of contiguous boundaries of the same
	/// group).
	func pieces(of string: Substring) -> [Piece] {
		let textRank = groups.count
		let isCollapsed = if case .collapsed = self {
			true
		} else {
			false
		}
		var pieces = [Piece]()
		var index = string.startIndex
		while index < string.endIndex {
			let (rank, length) = rankAndLength(in: string, at: index)
			let end = string.index(index, offsetBy: length)
			if let last = pieces.last, last.rank == rank, rank == textRank || isCollapsed {
				pieces[pieces.count - 1] = .init(rank: rank, text: string[last.text.startIndex..<end])
			} else {
				pieces.append(.init(rank: rank, text: string[index..<end]))
			}
			index = end
		}
		return pieces
	}

	/// The rank & length of the longest boundary at `index` (a boundary defined
	/// by multiple groups belongs to the last one), else non-boundary text's rank
	/// & a length of 1.
	private func rankAndLength(in string: Substring, at index: String.Index) -> (rank: Int, length: Int) {
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
	/// The number of characters this boundary matches at `index` in `string`, or
	/// `nil` iff it does not match there.
	func matchLength(in string: Substring, at index: String.Index) -> Int? {
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
	/// Whether `character`'s 1st Unicode scalar belongs to this character class,
	/// per UTS #18 Annex C's POSIX Compatible definitions (`ascii` being U+0000
	/// to U+007F).
	func contains(_ character: Character) -> Bool {
		character.unicodeScalars.first.map(contains) ?? false
	}

	private func contains(_ scalar: Unicode.Scalar) -> Bool {
		let properties = scalar.properties
		return switch self {
		case .alnum:
			properties.isAlphabetic || Self.digit.contains(scalar)
		case .alpha:
			properties.isAlphabetic
		case .ascii:
			scalar.isASCII
		case .blank:
			properties.generalCategory == .spaceSeparator || scalar == "\t"
		case .cntrl:
			properties.generalCategory == .control
		case .digit:
			("0"..."9").contains(scalar)
		case .graph:
			!properties.isWhitespace && !nonGraphCategorySet.contains(properties.generalCategory)
		case .lower:
			properties.isLowercase
		case .print:
			(Self.graph.contains(scalar) || Self.blank.contains(scalar)) && !Self.cntrl.contains(scalar)
		case .punct:
			punctuationCategorySet.contains(properties.generalCategory)
				|| symbolCategorySet.contains(properties.generalCategory) && !properties.isAlphabetic
		case .space:
			properties.isWhitespace
		case .upper:
			properties.isUppercase
		case .word:
			properties.isAlphabetic
				|| markCategorySet.contains(properties.generalCategory)
				|| Self.digit.contains(scalar)
				|| properties.generalCategory == .connectorPunctuation
				|| properties.isJoinControl
		case .xdigit:
			Self.digit.contains(scalar) || ("A"..."F").contains(scalar) || ("a"..."f").contains(scalar)
		}
	}
}

private let markCategorySet = Set([Unicode.GeneralCategory.enclosingMark, .nonspacingMark, .spacingMark])
private let nonGraphCategorySet = Set([Unicode.GeneralCategory.control, .surrogate, .unassigned])
private let punctuationCategorySet = Set([
	Unicode.GeneralCategory.closePunctuation,
	.connectorPunctuation,
	.dashPunctuation,
	.finalPunctuation,
	.initialPunctuation,
	.openPunctuation,
	.otherPunctuation,
])
private let symbolCategorySet = Set([
	Unicode.GeneralCategory.currencySymbol,
	.mathSymbol,
	.modifierSymbol,
	.otherSymbol,
])

// MARK: - Constants

/// The `<sort-priority>` of a `<sort>` that omits it, absent one in the working
/// fields config.
private let defaultSortPriority = BigUInt(100)
private let disabledSortPrefix = Character("0")
private let sortOptionTerminator = Character(":")

/// The CLDR root locale, whose collation the canonical conventions compare text
/// per.
private let rootLocale = Locale(identifier: "root")
private let sortModifierTerminatorSet = Set([fieldSpecSeparator])

private let localeOption = Character("L")

private let numberSegmentsByOption = [
	Character("u"): SortOptionSet.NumberSegments.ungroupedNumeric,
	"v": .versions,
	"x": .lexicographic,
]
private let groupedNumericOption = Character("N")

private let chronologicSegmentsOption = Character("C")
/// The `<chronologic-format>`s other than `<unix-time>`, by name literal.
private let iso8601FormsByChronologicFormat = [
	"iso": Set(ISO8601Form.allCases),
	"iso-date": [.date],
	"iso-datetime": [.datetime],
	"iso-time": [.time],
] as [String: Set<ISO8601Form>]
private let chronologicFormats = iso8601FormsByChronologicFormat.keys + ["unix-time"]

private let uncollapsedBoundariesOption = Character("B")
private let collapsedBoundariesOption = Character("M")
private let boundaryGroupSeparator = Character("_")
private let multiCharacterBoundaryFence = Character("%")
private let characterClassFence = Character("+")
private let boundaryCharactersTerminatorSet =
	Set([multiCharacterBoundaryFence, characterClassFence, boundaryGroupSeparator, sortOptionTerminator])
