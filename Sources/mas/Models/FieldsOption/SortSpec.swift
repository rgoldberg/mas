//
// SortSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

// MARK: - Sort options (fields.md)

struct SortSpec: Equatable {
	enum Source: Character, CustomStringConvertible {
		case input = "I"
		case output = "O"

		var description: String {
			switch self {
			case .input:
				"input"
			case .output:
				"output"
			}
		}
	}

	enum Direction: Character, CustomStringConvertible {
		case ascending = "a"
		case descending = "d"

		var description: String {
			switch self {
			case .ascending:
				"ascending"
			case .descending:
				"descending"
			}
		}
	}

	enum CaseSensitivity: Character, CustomStringConvertible {
		case sensitive = "s"
		case insensitive = "i"

		var description: String {
			switch self {
			case .sensitive:
				"sensitive"
			case .insensitive:
				"insensitive"
			}
		}
	}

	enum Localization: Equatable, CustomStringConvertible {
		case canonical
		case localized(Locale)

		var description: String {
			switch self {
			case .canonical:
				"canonical"
			case let .localized(locale):
				"localized(\(locale))"
			}
		}
	}

	enum Grouping: Character, CustomStringConvertible {
		case ungrouped = "u"
		case grouped = "g"

		var description: String {
			switch self {
			case .ungrouped:
				"ungrouped"
			case .grouped:
				"grouped"
			}
		}
	}

	enum Interpretation: Character, CustomStringConvertible {
		case lexical = "x"
		case numeric = "n"
		case price = "p"
		case version = "v"

		var description: String {
			switch self {
			case .lexical:
				"lexical"
			case .numeric:
				"numeric"
			case .price:
				"price"
			case .version:
				"version"
			}
		}
	}

	/// A single member of a `<boundaries>` `<boundary-list>`: a literal boundary
	/// character, a `<multi-character-boundary-text>` (matched atomically, as 1
	/// token, not as its individual characters), or a `<character-class-name>`
	/// reference (whose members are supplied at sort time, since character
	/// class membership isn't a parse-time concern).
	enum Boundary: Equatable, CustomStringConvertible {
		case character(Character)
		case characters(String)
		case characterClass(CharacterClass)

		var description: String {
			switch self {
			case let .character(character):
				"\"\(character)\""
			case let .characters(characters):
				"\"\(characters)\""
			case let .characterClass(characterClass):
				"[:\(characterClass.rawValue):]"
			}
		}
	}

	/// A POSIX character class, plus the 2 GNU Extended POSIX character classes
	/// this spec also supports.
	enum CharacterClass: String, CustomStringConvertible {
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

		var description: String {
			rawValue
		}
	}

	/// A single boundary group: an ordered list of `<boundary-list>` members
	/// sharing 1 sort precedence.
	struct BoundaryGroup: Equatable, CustomStringConvertible {
		let boundaries: [Boundary]

		var description: String {
			"[\(boundaries.map(\.description).joined(separator: ", "))]"
		}
	}

	/// How `<boundaries>`' unclaimed whitespace (whitespace not itself named as
	/// an explicit boundary in any group) is treated, per a leading / trailing
	/// `<whitespace-boundary-modifier>` or a `<whitespace-boundary-suppressor>`.
	enum WhitespacePlacement: Equatable, CustomStringConvertible {
		/// No modifier & no suppressor (the default): unclaimed whitespace
		/// forms its own implicit group, after all explicit groups.
		case endmost
		/// A leading modifier & a trailing modifier: unclaimed whitespace joins
		/// the first explicit group.
		case mergedIntoFirst
		/// A trailing modifier only: unclaimed whitespace joins the last
		/// explicit group.
		case mergedIntoLast
		/// A leading modifier only: unclaimed whitespace forms its own
		/// implicit group, before all explicit groups.
		case leading
		/// A leading suppressor: unclaimed whitespace isn't a boundary at all.
		case suppressed

		var description: String {
			switch self {
			case .endmost:
				"endmost"
			case .mergedIntoFirst:
				"mergedIntoFirst"
			case .mergedIntoLast:
				"mergedIntoLast"
			case .leading:
				"leading"
			case .suppressed:
				"suppressed"
			}
		}
	}

	/// A fully-parsed `<boundaries>` value.
	struct Boundaries: Equatable, CustomStringConvertible {
		/// Ordered highest- to lowest-precedence; empty means no explicit
		/// boundaries at all (only `whitespacePlacement` may still apply).
		let groups: [BoundaryGroup]
		/// `<collapse-contiguous>`: collapses contiguous boundaries belonging
		/// to the same boundary group into 1, for comparison purposes.
		let collapseContiguous: Bool
		let whitespacePlacement: WhitespacePlacement

		var description: String {
			"""
			Boundaries(groups: \(groups), collapseContiguous: \(collapseContiguous), whitespacePlacement: \(
				whitespacePlacement
			))
			"""
		}
	}

	let priority: UInt64
	let source: Source
	let direction: Direction
	let caseSensitivity: CaseSensitivity
	let localization: Localization
	let grouping: Grouping
	let interpretation: Interpretation
	let boundaries: Boundaries
}

// MARK: - Boundary-aware tokenization (applying `SortSpec.Boundaries`)

/// Reduces a `SortSpec.Boundaries` value to a per-character sort-precedence
/// rank: lower ranks sort before higher ranks & before `textRank` (ordinary,
/// non-boundary characters).
private struct BoundaryRankTable { // swiftlint:disable:this one_declaration_per_file
	/// 1 element of `segments(of:collapseContiguous:)`: a maximal run of
	/// same-rank characters, either 1 boundary group's worth of boundary
	/// characters, or (`rank == textRank`) ordinary text.
	struct Segment {
		let rank: Int
		let text: Substring
	}

	private let boundaries: SortSpec.Boundaries
	/// `1` iff `whitespacePlacement` is `.leading` (reserving rank `0` for
	/// unclaimed whitespace & shifting every explicit group's rank up by 1),
	/// else `0`.
	private let explicitGroupShift: Int
	/// The rank shared by every ordinary (non-boundary) character: always
	/// strictly greater than every boundary's rank.
	private let textRank: Int

	init(_ boundaries: SortSpec.Boundaries) {
		self.boundaries = boundaries
		explicitGroupShift = boundaries.whitespacePlacement == .leading ? 1 : 0
		textRank = switch boundaries.whitespacePlacement {
		case .endmost, .leading:
			boundaries.groups.count + 1
		case .mergedIntoFirst, .mergedIntoLast, .suppressed:
			boundaries.groups.count
		}
	}

	/// Splits `string` into maximal same-rank runs; `collapseContiguous`
	/// reduces each non-text (boundary) run to its first character only, per
	/// `<collapse-contiguous>`.
	func segments(of string: String, collapseContiguous: Bool) -> [Segment] {
		guard let firstIndex = string.indices.first else {
			return .init()
		}
		var segments = [Segment]()
		let (firstRank, firstLength) = rankAndLength(in: string, at: firstIndex)
		var currentRank = firstRank
		var currentStart = firstIndex
		var index = string.index(firstIndex, offsetBy: firstLength)
		while index < string.endIndex {
			let (rank, length) = rankAndLength(in: string, at: index)
			if rank != currentRank {
				segments.append(.init(rank: currentRank, text: string[currentStart..<index]))
				currentRank = rank
				currentStart = index
			}
			index = string.index(index, offsetBy: length)
		}
		segments.append(.init(rank: currentRank, text: string[currentStart...]))
		return collapseContiguous
			? segments.map { $0.rank == textRank ? $0 : .init(rank: $0.rank, text: $0.text.prefix(1)) }
			: segments
	}

	/// `string[index...]`'s sort-precedence rank & how many characters this
	/// position's match spans (`> 1` only for an atomic
	/// `<multi-character-boundary-text>` match): the longest explicit boundary
	/// match at `index` (see `longestExplicitMatch(in:at:)`), else 1
	/// character's worth of unclaimed whitespace's `whitespacePlacement`-derived
	/// rank, else 1 character of `textRank`.
	private func rankAndLength(in string: String, at index: String.Index) -> (rank: Int, length: Int) {
		if let match = longestExplicitMatch(in: string, at: index) {
			return match
		}
		guard string[index].isWhitespace else {
			return (textRank, 1)
		}
		let rank = switch boundaries.whitespacePlacement {
		case .suppressed:
			textRank
		case .endmost:
			boundaries.groups.count
		case .leading, .mergedIntoFirst:
			0
		case .mergedIntoLast:
			boundaries.groups.count - 1
		}
		return (rank, 1)
	}

	/// The longest explicit boundary matching at `index` (checked across every
	/// group, since a shorter match from an earlier group must not shadow a
	/// longer, atomic `<multi-character-boundary-text>` match from a later
	/// one): its (shifted) group's rank, paired with how many characters it
	/// spans. A length tie (only possible for the exact same boundary
	/// declared in >1 group) goes to the last group, per fields.md's "the
	/// last occurrence of an explicit boundary … overrides all other
	/// boundaries … for the same value".
	private func longestExplicitMatch(in string: String, at index: String.Index) -> (rank: Int, length: Int)? {
		var best: (rank: Int, length: Int)?
		for (groupIndex, group) in boundaries.groups.enumerated() {
			for boundary in group.boundaries {
				guard let length = boundary.matchLength(in: string, at: index), length >= (best?.length ?? 0) else {
					continue
				}
				best = (rank: groupIndex + explicitGroupShift, length: length)
			}
		}
		return best
	}
}

extension SortSpec {
	/// fields.md's "Default Sort Options" table: the default `SortSpec` for a
	/// field of `interpretation`, for `outputFormat`. `boundaryCharacter`, if
	/// given, is a single explicit boundary character (`"/"` for Path); `nil`
	/// (Text / Price / Version) means no explicit boundary at all. Doesn't know
	/// or care what field this is for by name; a caller (e.g.,
	/// `defaultSortSpec(forFieldNamed:outputFormat:)` in
	/// `AppStoreFieldDefaults.swift`) maps a field name to an `interpretation` &
	/// `boundaryCharacter` first.
	static func `default`(interpretation: Interpretation, boundaryCharacter: Character?, outputFormat: OutputFormat)
	-> Self {
		let (caseSensitivity, localization) = outputFormat == .json
			? (CaseSensitivity.sensitive, Localization.canonical)
			: (.insensitive, .localized(.current))
		return .init(
			priority: 0, // Priority is never format- / type-defaulted; callers ignore this field & supply their own
			source: .input,
			direction: .ascending,
			caseSensitivity: caseSensitivity,
			localization: localization,
			grouping: interpretation == .version ? .ungrouped : .grouped,
			interpretation: interpretation,
			boundaries: .init(
				groups: boundaryCharacter.map { [.init(boundaries: [.character($0)])] } ?? .init(),
				collapseContiguous: false,
				// JSON suppresses the implicit whitespace boundary entirely (table
				// value `+++` / `++/+`), matching its already-more-literal case-
				// sensitive / canonical choices on the other axes: it's read by
				// programs, so nothing gets special-cased. Table / Key-Value default
				// it instead (`+_+` / `+/+`): a solitary modifier (`boundaryCharacter`
				// `nil`) is `.leading` per fields.md ("a solitary or a leading …
				// modifier … positions the whitespace implicit group before all
				// explicit groups"); otherwise (a real boundary character, no modifier
				// / suppressor at all) the ordinary `.endmost` default applies.
				// `.leading` / `.endmost` are behaviorally identical today (there's
				// only ever 0 or 1 explicit group here), but `.leading` is the
				// semantically correct value for the solitary case
				whitespacePlacement: outputFormat == .json ? .suppressed : boundaryCharacter == nil ? .leading : .endmost,
			),
		)
	}

	/// The generic engine's own default for a field-agnostic `<sort-option-set>`
	/// (i.e., a bare `<field-order-option-set>`, which sorts field names /
	/// labels, never a specific field's value): exactly `default(interpretation:
	/// boundaryCharacter:outputFormat:)`'s Text row (`interpretation: .numeric,
	/// boundaryCharacter: nil`), the same call `defaultSortSpec(forFieldNamed:
	/// outputFormat:)` makes for any field name it doesn't recognize as price /
	/// version / path, kept as 1 shared definition so the 2 can't drift apart.
	static func textDefault(outputFormat: OutputFormat) -> Self {
		.default(interpretation: .numeric, boundaryCharacter: nil, outputFormat: outputFormat)
	}

	/// Parses a bare `<sort-option-set>` (`<sort-option>+`; no leading
	/// `<sort-priority>`), applying each recognized option over `defaults`
	/// (last 1 per axis wins), leaving every other axis at its `defaults`
	/// value. Shared by `init(from:nextSectionPrefixSet:existing:fieldName:
	/// outputFormat:)` (which parses `<sort>`'s optional leading
	/// `<sort-priority>` itself, before calling this) & `<field-order-
	/// option-set>` (fields.md's `field-order-option-set = … | <sort-option-
	/// set>`, which has no priority at all).
	static func parsedOptionSet(
		_ input: inout Substring,
		nextSectionPrefixSet: Set<Character>,
		priority: UInt64,
		defaults: Self,
	) throws -> Self {
		var source = defaults.source
		var direction = defaults.direction
		var caseSensitivity = defaults.caseSensitivity
		var localization = defaults.localization
		var grouping = defaults.grouping
		var interpretation = defaults.interpretation
		var boundaries = defaults.boundaries
		try parseOptions(
			&input,
			nextSectionPrefixSet: nextSectionPrefixSet,
		) { input, currentIndex, char in
			if let match = Self.Source(rawValue: char) {
				source = match
			} else if let match = Self.Direction(rawValue: char) {
				direction = match
			} else if let match = Self.CaseSensitivity(rawValue: char) {
				caseSensitivity = match
			} else if let match = Self.Grouping(rawValue: char) {
				grouping = match
			} else if let match = Self.Interpretation(rawValue: char) {
				interpretation = match
			} else {
				switch char {
				case canonical:
					localization = .canonical
				case localized:
					let localeName = try input.parseFencedValue(fence: localeNameFence, after: &currentIndex)
					localization = .localized(localeName.isEmpty ? .current : .init(identifier: localeName))
				case boundariesOptionPrefix:
					boundaries = try input.parseBoundaries(after: &currentIndex)
				default:
					input = input[currentIndex...]
					throw ParsingError.invalidSortOption(char)
				}
			}
		}
		return .init(
			priority: priority,
			source: source,
			direction: direction,
			caseSensitivity: caseSensitivity,
			localization: localization,
			grouping: grouping,
			interpretation: interpretation,
			boundaries: boundaries,
		)
	}

	/// `fieldName` / `outputFormat` are only consulted when `existing` is `nil`
	/// (a fresh `<sort>`, not inheriting from another field spec's sort): they
	/// select the fields.md "Default Sort Options" row used to fill in any
	/// unspecified dimension.
	init?(
		from input: inout Substring,
		nextSectionPrefixSet: Set<Character>,
		existing sortSpec: SortSpec?,
		fieldName: String,
		outputFormat: OutputFormat,
	) throws {
		input = input.drop(while: \.isWhitespace)
		guard let first = input.first, first != fieldSpecSeparator, !nextSectionPrefixSet.contains(first) else {
			return nil
		}
		let priority = parseUInt64(&input)
		guard priority != nil || sortSpec != nil else {
			throw ParsingError.missingSortPriority
		}
		self = try Self.parsedOptionSet(
			&input,
			nextSectionPrefixSet: nextSectionPrefixSet,
			priority: priority ?? sortSpec?.priority ?? 0,
			defaults: sortSpec ?? defaultSortSpec(forFieldNamed: fieldName, outputFormat: outputFormat),
		)
	}
}

// MARK: - Comparator (applies a `SortSpec` to compare 2 field values)

extension SortSpec {
	private var textCompareOptions: String.CompareOptions {
		var options = interpretation == .lexical ? String.CompareOptions() : [.numeric]
		if caseSensitivity == .insensitive {
			options.insert(.caseInsensitive)
		}
		return options
	}

	private var localeForComparison: Locale? {
		if case let .localized(locale) = localization {
			locale
		} else {
			nil
		}
	}

	/// `grouping`'s effective separator: only meaningful for `.numeric`
	/// (`.lexical` never treats a value as a number at all; `.price` / `.version`
	/// already strip / split on their own & never consult `grouping`, same as
	/// `boundaries`). `.canonical` uses `,`, matching a plain, locale-independent
	/// reading of a grouped number (e.g., `1,234`); `.localized` uses that
	/// locale's own separator.
	private var groupingSeparator: String? {
		guard interpretation == .numeric, grouping == .grouped else {
			return nil
		}
		switch localization {
		case .canonical:
			return ","
		case let .localized(locale):
			return locale.groupingSeparator
		}
	}

	/// Compares 2 field values (already-rendered strings; `nil` for a missing /
	/// absent value) per this spec's effective source-independent options.
	///
	/// `boundaries` applies only to `.lexical` / `.numeric`, via
	/// `compareBoundaryAware(_:_:)`: `.price` / `.version` already have their
	/// own bespoke, whole-value algorithms (digit extraction; `.`-component
	/// splitting) that fields.md doesn't define any boundary interaction for,
	/// so layering boundary tokenization on top of them would be a new,
	/// unspecified behavior rather than an implementation of the spec.
	/// `grouping`, when `.grouped` & `.numeric`, strips `groupingSeparator`
	/// from both sides first (e.g., `"1,234"` compares as `1234`), so a
	/// grouped number's digits aren't broken up into smaller ones by the
	/// separator; `.ungrouped` (or `.lexical`, or `.price` / `.version`)
	/// leaves the value as-is.
	func compare(_ lhs: String?, _ rhs: String?) -> ComparisonResult {
		let lhs = strippedOfGroupingSeparator(lhs ?? "")
		let rhs = strippedOfGroupingSeparator(rhs ?? "")
		let result = switch interpretation {
		case .lexical, .numeric:
			compareBoundaryAware(lhs, rhs)
		case .price:
			comparePrices(lhs, rhs)
		case .version:
			compareVersions(lhs, rhs)
		}
		return direction == .ascending ? result : result.reversed
	}

	private func strippedOfGroupingSeparator(_ string: String) -> String {
		guard let groupingSeparator, !groupingSeparator.isEmpty else {
			return string
		}
		return string.replacing(groupingSeparator, with: "")
	}

	/// Tokenizes `lhs` & `rhs` per `boundaries` (see `BoundaryRankTable`), then
	/// compares them segment-by-segment: a rank mismatch decides the result
	/// immediately (a lower rank, i.e., an earlier boundary group, or any
	/// boundary at all vs. ordinary text, sorts first); a rank tie compares the
	/// 2 segments' text per `textCompareOptions` / `localeForComparison`,
	/// falling through to the next segment pair on a tie. Exhausting 1 side's
	/// segments before the other (with every compared pair tied) is a tie
	/// broken by segment count, mirroring how a shorter, otherwise-identical
	/// prefix sorts before a longer string.
	private func compareBoundaryAware(_ lhs: String, _ rhs: String) -> ComparisonResult {
		let rankTable = BoundaryRankTable(boundaries)
		let lhsSegments = rankTable.segments(of: lhs, collapseContiguous: boundaries.collapseContiguous)
		let rhsSegments = rankTable.segments(of: rhs, collapseContiguous: boundaries.collapseContiguous)
		for (lhsSegment, rhsSegment) in zip(lhsSegments, rhsSegments) {
			guard lhsSegment.rank == rhsSegment.rank else {
				return lhsSegment.rank < rhsSegment.rank ? .orderedAscending : .orderedDescending
			}
			let result = String(lhsSegment.text)
				.compare(String(rhsSegment.text), options: textCompareOptions, range: nil, locale: localeForComparison)
			guard result == .orderedSame else {
				return result
			}
		}
		return ComparableComparator().compare(lhsSegments.count, rhsSegments.count)
	}

	/// Compares 2 prices by their numeric value (see `price(from:)`), falling
	/// back to a plain numeric-aware string compare if either side has no
	/// recognizable numeric value (e.g., comparing against `"Free"`).
	private func comparePrices(_ lhs: String, _ rhs: String) -> ComparisonResult {
		guard let lhsPrice = price(from: lhs), let rhsPrice = price(from: rhs) else {
			return lhs.compare(rhs, options: textCompareOptions, range: nil, locale: localeForComparison)
		}
		return ComparableComparator().compare(lhsPrice, rhsPrice)
	}

	/// Compares 2 `.`-delimited version strings component-wise (numerically per
	/// component when both sides parse as integers, lexically otherwise; a
	/// missing trailing component compares as `0`) rather than via a strict
	/// semver parser, which could crash or misbehave on the wide variety of
	/// real-world version strings (pre-release suffixes, build metadata, etc.).
	private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
		let lhsComponents = lhs.split(separator: ".", omittingEmptySubsequences: false)
		let rhsComponents = rhs.split(separator: ".", omittingEmptySubsequences: false)
		for index in 0..<max(lhsComponents.count, rhsComponents.count) {
			let lhsComponent = index < lhsComponents.count ? lhsComponents[index] : "0"
			let rhsComponent = index < rhsComponents.count ? rhsComponents[index] : "0"
			let result = if let lhsInt = Int(lhsComponent), let rhsInt = Int(rhsComponent) {
				ComparableComparator().compare(lhsInt, rhsInt)
			} else {
				lhsComponent.compare(rhsComponent, options: textCompareOptions, range: nil, locale: localeForComparison)
			}
			guard result == .orderedSame else {
				return result
			}
		}
		return .orderedSame
	}
}

private extension SortSpec.Boundary {
	/// The number of characters this boundary matches starting at `index` in
	/// `string`, or `nil` if it doesn't match there at all.
	func matchLength(in string: String, at index: String.Index) -> Int? {
		switch self {
		case let .character(match):
			string[index] == match ? 1 : nil
		case let .characters(match):
			!match.isEmpty && string[index...].hasPrefix(match) ? match.count : nil
		case let .characterClass(characterClass):
			characterClass.contains(string[index]) ? 1 : nil
		}
	}
}

private extension SortSpec.CharacterClass {
	/// Approximates the named POSIX / GNU Extended POSIX character class using
	/// `Character`'s Unicode-aware properties, broader than the traditional
	/// byte-oriented, locale-dependent POSIX definitions (e.g., `alpha`
	/// matches any Unicode letter, not just `A`-`Z` / `a`-`z`).
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
			character.isASCII && character.isNumber
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

/// Extracts a price's numeric value from `string` (e.g., `"$1,234.56"` ⇒
/// `1234.56`) by keeping only its digits, a single `.`, & a leading `-`; other
/// characters (currency symbols, grouping commas, etc.) are simply skipped
/// over. `nil` for a string with no digits at all (e.g., `"Free"`).
private func price(from string: String) -> Double? {
	var cleaned = ""
	var sawDecimalPoint = false
	for (index, character) in string.enumerated() {
		if character.isNumber {
			cleaned.append(character)
		} else if character == ".", !sawDecimalPoint {
			sawDecimalPoint = true
			cleaned.append(character)
		} else if character == "-", index == 0 {
			cleaned.append(character)
		}
	}
	return cleaned.isEmpty || cleaned == "-" ? nil : Double(cleaned)
}

// MARK: Private extensions

private extension Substring {
	mutating func parseFencedValue(fence: Character, after currentIndex: inout Index) throws(ParsingError) -> String {
		let startFenceIndex = index(after: currentIndex)
		guard startFenceIndex < endIndex, self[startFenceIndex] == fence else {
			return ""
		}
		var string = self[index(after: startFenceIndex)...]
		let (value, endFenceIndex) = try parseEscapedTextAndIndex(&string, terminatorSet: [fence])
		guard endFenceIndex < string.endIndex else {
			currentIndex = endIndex
			self = self[currentIndex...]
			throw .missingEndFence
		}
		currentIndex = endFenceIndex
		return value
	}

	/// Parses a `<boundaries>` value (the content following `b`) into a
	/// `SortSpec.Boundaries`, per `<boundaries-option-set>` &
	/// `<grouped-boundaries>` / `<ungrouped-boundaries>`.
	mutating func parseBoundaries(after currentIndex: inout Index) throws -> SortSpec.Boundaries {
		var fenceIndex = index(after: currentIndex)
		var collapseContiguous = false
		while fenceIndex < endIndex, self[fenceIndex] == collapseContiguousOption {
			collapseContiguous = true
			fenceIndex = index(after: fenceIndex)
		}
		guard fenceIndex < endIndex else {
			throw ParsingError.missingEndFence
		}
		let isGrouped = self[fenceIndex] == groupedBoundariesFence
		let outerFence = isGrouped ? groupedBoundariesFence : ungroupedBoundariesFence
		guard self[fenceIndex] == outerFence else {
			throw ParsingError.missingEndFence
		}
		let separator = isGrouped ? groupSeparator : groupJoiner
		// A suppressor is always the same character as `outerFence` itself (a
		// leading suppressor, with no list, is valid, e.g., grouped `+++`), so
		// the closing-fence search must skip a leading suppressor first, or it'd
		// mistake it for an early close
		let suppressor = isGrouped ? groupedWhitespaceBoundarySuppressor : ungroupedWhitespaceBoundarySuppressor
		let modifier = isGrouped ? groupedWhitespaceBoundaryModifier : ungroupedWhitespaceBoundaryModifier
		let body = self[index(after: fenceIndex)...]
		let closeSearchStart = body.first == suppressor ? body.index(after: body.startIndex) : body.startIndex
		guard let outerCloseOffset = body[closeSearchStart...].firstUnescapedIndex(of: outerFence) else {
			currentIndex = endIndex
			self = self[currentIndex...]
			throw ParsingError.missingEndFence
		}
		let content = body[..<outerCloseOffset]
		// `currentIndex` lands ON the closing fence (matching `parseFencedValue`'s
		// convention), not past it: `parseOptions`'s caller-side `defer` always
		// advances 1 more position after this call returns
		currentIndex = outerCloseOffset

		var elements = [Self]()
		var remainder = content
		while let separatorOffset = remainder.firstUnescapedIndex(of: separator) {
			elements.append(remainder[..<separatorOffset])
			remainder = remainder[remainder.index(after: separatorOffset)...]
		}
		elements.append(remainder)

		// A leading / trailing whitespace-boundary-modifier / -suppressor is glued
		// onto the first and/or last real element rather than being its own element
		// separated by `separator`; peel it off first, tracking which was seen (a
		// suppressor can't combine with a trailing modifier, per the grammar's 2
		// alternative forms)
		var sawLeadingSuppressor = false
		var sawLeadingModifier = false
		var sawTrailingModifier = false
		if let first = elements.first {
			if first.first == suppressor {
				sawLeadingSuppressor = true
				elements[0].removeFirst()
			} else if first.first == modifier {
				sawLeadingModifier = true
				elements[0].removeFirst()
			}
		}
		if !sawLeadingSuppressor, elements.count > 1, let last = elements.last, last.last == modifier {
			sawTrailingModifier = true
			elements[elements.count - 1].removeLast()
		}
		let whitespacePlacement = sawLeadingSuppressor
			? SortSpec.WhitespacePlacement.suppressed
			: sawLeadingModifier && sawTrailingModifier
				? .mergedIntoFirst
				: sawLeadingModifier ? .leading : sawTrailingModifier ? .mergedIntoLast : .endmost
		let boundaryLists = try elements.compactMap { $0.isEmpty ? nil : try $0.parseBoundaryList() }
		let groups = isGrouped
			// Grouped: every element (i.e., everything between `<group-separator>`s)
			// is 1 group
			? boundaryLists.map { SortSpec.BoundaryGroup(boundaries: $0) }
			// Ungrouped: each member (a character, a `<character-class-fence>`
			// reference, or an atomic `<multi-character-boundary-fence>` token) is
			// its own group
			: boundaryLists.flatMap { $0.map { SortSpec.BoundaryGroup(boundaries: [$0]) } }
		return .init(groups: groups, collapseContiguous: collapseContiguous, whitespacePlacement: whitespacePlacement)
	}

	/// Parses 1 `<boundary-list>` element's members: a run of characters,
	/// `[:<character-class-name>:]` references, & `%…%`
	/// `<multi-character-boundary-fence>`-delimited multi-character boundaries.
	private func parseBoundaryList() throws(ParsingError) -> [SortSpec.Boundary] {
		var boundaries = [SortSpec.Boundary]()
		var chars = self[...]
		while let char = chars.first {
			if char == escapePrefix {
				chars.removeFirst()
				guard let escaped = chars.first else {
					break
				}
				boundaries.append(.character(escaped))
				chars.removeFirst()
			} else if char == characterClassFence {
				chars.removeFirst()
				guard let closeIndex = chars.firstIndex(of: characterClassFence) else {
					throw .missingEndFence
				}
				let name = String(chars[..<closeIndex])
				guard let characterClass = SortSpec.CharacterClass(rawValue: name) else {
					throw .invalidCharacterClass(name)
				}
				boundaries.append(.characterClass(characterClass))
				chars = chars[chars.index(after: closeIndex)...]
			} else if char == multiCharacterBoundaryFence {
				chars.removeFirst()
				let (value, endIndex) = try parseEscapedTextAndIndex(&chars, terminatorSet: [multiCharacterBoundaryFence])
				guard endIndex < chars.endIndex else {
					throw .missingEndFence
				}
				chars = chars[chars.index(after: endIndex)...]
				// An empty `%%` matches nothing (`Boundary.matchLength(in:at:)`
				// rejects an empty `.characters` boundary), rather than being kept
				// as a 0-length "boundary" that could stall tokenization
				if !value.isEmpty {
					boundaries.append(.characters(value))
				}
			} else {
				boundaries.append(.character(char))
				chars.removeFirst()
			}
		}
		return boundaries
	}
}

// MARK: Constants

private let localeNameFence = Character("+")

private let canonical = Character("c")
private let localized = Character("l")
private let boundariesOptionPrefix = Character("b")
private let collapseContiguousOption = Character("%")

private let groupedBoundariesFence = Character("+")
private let groupedWhitespaceBoundarySuppressor = Character("+")
private let groupedWhitespaceBoundaryModifier = Character("_")
private let groupSeparator = Character("_")

private let ungroupedBoundariesFence = Character("_")
private let ungroupedWhitespaceBoundarySuppressor = Character("_")
private let ungroupedWhitespaceBoundaryModifier = Character("+")
private let groupJoiner = Character("+")

private let characterClassFence = Character(":")
private let multiCharacterBoundaryFence = Character("%")
