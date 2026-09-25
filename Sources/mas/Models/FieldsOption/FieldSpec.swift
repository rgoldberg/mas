//
// FieldSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

// MARK: Internal types

struct FieldSpec: Equatable {
	/// A field spec with default settings for field `name`: labeled by its
	/// name, default format, no `<sort>`, visible.
	static func defaultSettings(forName name: String) -> Self {
		.init(name: name, label: name, format: .default(fieldName: name), sortSpec: nil)
	}

	let name: String
	let label: String
	let format: Format
	let sortSpec: SortSpec?
	/// Whether this field spec is hidden (`<field-spec-hide>`): not output, but
	/// otherwise behaving as a visible one (it has a position, may be referenced
	/// by a `<field-spec-reference>`, & its `<sort>` sorts items iff enabled).
	let isHidden: Bool
	/// Whether this field's value is computed after the display command's own
	/// fetch (e.g., `outdated`'s `newVersion`, from comparing the installed &
	/// latest versions), so it's never itself something to fetch.
	let isSynthesized: Bool
	/// Table-only column alignment (ignored by `json` / `keyValue` output, which
	/// have no column to align). Set directly by a display command's own
	/// `standard` / `all` fields config (see
	/// `defaultJustification(forFieldNamed:)` in `AppStoreFieldDefaults.swift`),
	/// or by a `--fields`
	/// `<format-transform-pipeline>` (see `parseFormat(_:existing:)` below).
	let justification: Justification

	init(
		name: String,
		label: String,
		format: Format,
		sortSpec: SortSpec?,
		isHidden: Bool = false,
		isSynthesized: Bool = false,
		justification: Justification = .start,
	) {
		self.name = name
		self.label = label
		self.format = format
		self.sortSpec = sortSpec
		self.isHidden = isHidden
		self.isSynthesized = isSynthesized
		self.justification = justification
	}
}

extension FieldSpec: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		"""
		FieldSpec(name: "\(name)", label: "\(label)", format: \(format), sortSpec: \(sortSpec, default: "nil"), \
		isHidden: \(isHidden), justification: \(justification))
		"""
	}
}

// MARK: Errors

enum ParsingError: Equatable, Error, CustomStringConvertible { // swiftlint:disable:this one_declaration_per_file
	case coercionNotSupported(Character)
	case danglingEscape
	case emptyBoundaryGroup
	case forbiddenWhitespace(after: Character)
	case invalidBaseFieldsConfigName(String)
	case invalidCharacterClass(String)
	case invalidLetter(Character)
	case invalidLocaleIdentifier(String)
	case invalidModifier(Character)
	case invalidMultiCharacterBoundary
	case invalidPipeline(String)
	case invalidPosition(Int)
	case invalidSortOption(Character)
	case invalidTransformArguments(name: String)
	case missingBlockTerminator
	case missingFieldName
	case missingFieldOrderOptionSet
	case missingIndex
	case missingItemSortOptionSet
	case missingPredicate
	case missingSortOptionSet
	case missingSortOptionTerminator
	case missingSortPriority
	case nonexistentFieldsConfig(String)
	case nonexistentFieldSpec(forName: String)
	case originalInputOrderUnsupportedForTable
	case singleBranch
	case templateLacksPlaceholder
	case unconditionalBranchNotLast
	case unexpectedCharacter(Character)
	case unknownNamedFormat(String)
	case unknownTransform(String)

	var description: String {
		switch self {
		case let .coercionNotSupported(letter):
			"<coercion> isn't supported for: \(letter)"
		case .danglingEscape:
			"Expected a character to escape after trailing '\\'"
		case .emptyBoundaryGroup:
			"<boundary-group> requires at least 1 boundary"
		case let .forbiddenWhitespace(token):
			"Whitespace is forbidden after: \(token)"
		case let .invalidBaseFieldsConfigName(baseFieldsConfigName):
			"Invalid base fields config name: \(baseFieldsConfigName)"
		case let .invalidCharacterClass(name):
			"Invalid character class: \(name)"
		case let .invalidLetter(letter):
			"Invalid <predicate>: \(letter)"
		case let .invalidLocaleIdentifier(identifier):
			"Invalid <locale-identifier>: \(identifier)"
		case let .invalidModifier(letter):
			"Invalid <modifiers> for <predicate>: \(letter)"
		case .invalidMultiCharacterBoundary:
			"<multi-character-boundary> requires non-empty text between its '%' fences"
		case let .invalidPipeline(nonterminal):
			"Invalid \(nonterminal)"
		case let .invalidPosition(index):
			"Invalid position for index: \(index)"
		case let .invalidSortOption(sortOption):
			"Invalid sort option: \(sortOption)"
		case let .invalidTransformArguments(name):
			"Invalid arguments for transform: \(name)"
		case .missingBlockTerminator:
			"Expected <block-terminator> '+'"
		case .missingFieldName:
			"Expected field name"
		case .missingFieldOrderOptionSet:
			"Expected <field-order-option-set> after <field-order-section-prefix> '/'"
		case .missingIndex:
			"Expected <index> after <index-prefix> '@'"
		case .missingItemSortOptionSet:
			"Expected <item-sort-option-set> after <item-sort-section-prefix> '//'"
		case .missingPredicate:
			"Expected <predicate>"
		case .missingSortOptionSet:
			"Expected <sort-option-set>"
		case .missingSortOptionTerminator:
			"Expected <sort-option-terminator> '+'"
		case .missingSortPriority:
			"Expected a numeric sort priority (only the field's existing sort options may be adjusted without one)"
		case let .nonexistentFieldSpec(name):
			"""
			Expected existing field spec for field name: \(
				name.isEmpty || name.first?.isWhitespace == true || name.last?.isWhitespace == true ? "'\(name)'" : name
			)
			"""
		case let .nonexistentFieldsConfig(name):
			"Nonexistent fields config: \(name)"
		case .originalInputOrderUnsupportedForTable:
			"<original-input-order> 'o' is supported only for JSON or key-value output"
		case .singleBranch:
			"<branches> requires at least 2 branches"
		case .templateLacksPlaceholder:
			"<format-template> requires at least 1 <placeholder>"
		case .unconditionalBranchNotLast:
			"An <unconditional-branch> may only be the last <branch>, which must be preceded by a <conditional-branch>"
		case let .unexpectedCharacter(character):
			"Unexpected character: \(character)"
		case let .unknownNamedFormat(name):
			"Unknown named format: \(name)"
		case let .unknownTransform(name):
			"Unknown transform: \(name)"
		}
	}
}

// MARK: - Entry points

/// Phase 1 (pre-fetch): the field names a display command needs to fetch for
/// `fieldsOptionValue` to be fully resolvable, given `standard`'s & `all`'s
/// _selected_ field specs (not yet merged with any dynamically-discovered
/// data): every field spec's that is visible or sorts items. Never includes a
/// synthesized field's name (see `FieldSpec.isSynthesized`), since fetching it
/// would be meaningless. Empty means "fetch everything", as for a base fields
/// config derived from `all`, whose dynamically-discovered fields are unknown
/// until fetched.
func fetchFieldNames(
	for fieldsOptionValue: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
) throws(ParsingError) -> [String] {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	if isRelativeConfig(input) {
		let baseName = try parseBaseFieldsConfigSection(&input)
		guard
			!(try resolveBaseFieldsConfig(named: baseName, standard: standard, all: all, outputFormat: outputFormat))
				.baseIncludesAllFields
		else {
			return .init()
		}
	}
	return .init(
		Set(
			try resolvedFieldsConfig(from: fieldsOptionValue, standard: standard, all: all, outputFormat: outputFormat)
				.fieldSpecs
				.compactMap { fieldSpec in
					fieldSpec.isSynthesized || fieldSpec.isHidden && (fieldSpec.sortSpec?.priority ?? 0) == 0
						? nil
						: fieldSpec.name
				},
		),
	)
}

/// Phase 2 (post-fetch): the fully-resolved `FieldsConfig` for
/// `fieldsOptionValue`. `all` should already have any dynamically-discovered
/// fields merged into its `fieldSpecs` by the caller (this function treats it
/// as static). If `fieldsOptionValue` doesn't specify its own
/// `<field-order-section>`, the resolved base fields config's own `fieldOrder`
/// is used instead of a bare `.inherited`.
func resolvedFieldsConfig(
	from fieldsOptionValue: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
) throws(ParsingError) -> any FieldsConfig {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	guard isRelativeConfig(input) else {
		var builder = FieldSpecsBuilder(fieldSpecs: .init(), outputFormat: outputFormat)
		try builder.parseAbsoluteConfig(&input)
		return SelectedFieldsConfig(
			fieldSpecs: builder.fieldSpecs,
			fieldOrder: .inherited,
			itemSort: .init(keys: builder.fieldSpecs.enabledSortKeys, tiebreakDirection: .ascending),
		)
	}
	let baseName = try parseBaseFieldsConfigSection(&input)
	let base = try resolveBaseFieldsConfig(named: baseName, standard: standard, all: all, outputFormat: outputFormat)
	var builder = FieldSpecsBuilder(fieldSpecs: base.fieldSpecs, outputFormat: outputFormat)
	let parsedFieldOrder = try builder.parseFieldOrderSection(&input)
	let fieldOrder = parsedFieldOrder == .inherited ? base.fieldOrder : parsedFieldOrder
	let tiebreakDirection = try builder.parseItemSortSection(&input)
	try builder.parseFieldSpecsSection(&input)
	let itemSort = ItemSort(keys: builder.fieldSpecs.enabledSortKeys, tiebreakDirection: tiebreakDirection)
	return base.baseIncludesAllFields
		? BaseIncludesAllFieldsConfig(fieldSpecs: builder.fieldSpecs, fieldOrder: fieldOrder, itemSort: itemSort)
		: SelectedFieldsConfig(fieldSpecs: builder.fieldSpecs, fieldOrder: fieldOrder, itemSort: itemSort)
}

/// Whether `input` (sans leading whitespace) is a `<relative-config>`, which
/// starts with a section prefix or is empty, rather than an
/// `<absolute-config>`.
private func isRelativeConfig(_ input: Substring) -> Bool {
	input.first.map(relativeConfigStartSet.contains) ?? true
}

/// Parses an optional `<base-fields-config-section>`: its
/// `<base-fields-config-name>`, or `""` iff absent.
private func parseBaseFieldsConfigSection(_ input: inout Substring) throws(ParsingError) -> String {
	guard input.first == baseFieldsConfigSectionPrefix else {
		return ""
	}
	input.removeFirst()
	return try parseEscapedText(&input, terminatorSet: [fieldOrderSectionPrefix, fieldSpecsSectionPrefix])
}

// MARK: - Base fields config resolution

/// Resolves a `<base-fields-config-name>` (already stripped of its
/// `<base-fields-config-section-prefix>`, empty if absent) against the
/// built-in named fields configs, whose variants are selected by an output
/// format suffix (`@json` / `@key-value` / `@table`), the `@none` reference
/// suffix (the unsuffixed variant), or, absent both, `outputFormat`:
///
/// - `none`: `all` with every field spec hidden.
/// - `all`: every field spec visible.
/// - `standard`: `standard`'s field specs; `standard@json` is a reference to
///   `all`.
/// - `default`: `standard`, absent a persisted custom `default`.
///
/// The `@json` variant is machine-facing (see `machineFacingVariant()`); the
/// others are user-facing. Any other name is an error: no custom named fields
/// configs are persisted yet.
func resolveBaseFieldsConfig(
	named rawName: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
) throws(ParsingError) -> any FieldsConfig {
	var stem = (rawName.isEmpty ? defaultFieldsConfigName : rawName)[...]
	let isUnsuffixedVariant = stem.hasSuffix(unsuffixedVariantReferenceSuffix)
	if isUnsuffixedVariant {
		stem.removeLast(unsuffixedVariantReferenceSuffix.count)
	}
	var outputFormatSuffix = Substring?.none
	if let atIndex = stem.lastIndex(of: outputFormatSuffixPrefix) {
		outputFormatSuffix = stem[stem.index(after: atIndex)...]
		stem = stem[..<atIndex]
		guard outputFormatSuffix.map(outputFormatSuffixSet.contains) == true else {
			throw .invalidBaseFieldsConfigName(rawName)
		}
	}
	guard !stem.isEmpty, stem.allSatisfy(\.isConfigNameCharacter) else {
		throw .invalidBaseFieldsConfigName(rawName)
	}
	let isMachineFacing = !isUnsuffixedVariant && (outputFormatSuffix.map { $0 == "json" } ?? (outputFormat == .json))
	let allVariant = all.withDefaultFieldOrder(outputFormat: outputFormat)
	let config: any FieldsConfig =
		switch stem {
		case allFieldsConfigName:
			allVariant
		case defaultFieldsConfigName, standardFieldsConfigName:
			isMachineFacing ? allVariant : standard
		case noneFieldsConfigName:
			allVariant.hidingAll()
		default:
			throw .nonexistentFieldsConfig(.init(stem))
		}
	return isMachineFacing ? config.machineFacingVariant() : config
}

private extension Character { // swiftlint:disable:this file_types_order
	/// Whether this character may be in a config name's stem, per configs.md's
	/// `^[-_0-9A-Za-z]+$`.
	var isConfigNameCharacter: Bool {
		isASCII && (isLetter || isNumber || self == "-" || self == "_")
	}
}

// MARK: - Field-spec references & positions (fields.md)

/// Translates an index (per fields.md's "Positions & Indices": non-negative ⇒
/// itself; negative ⇒ `length + 1 + index`) into a validated 1-based position,
/// throwing for non-positive or out-of-range positions.
func effectivePosition(forIndex index: Int, length: Int) throws(ParsingError) -> Int {
	let position = index >= 0 ? index : length + 1 + index
	guard position >= 1, position <= length else {
		throw .invalidPosition(index)
	}
	return position
}

// MARK: - Field specs builder (field-order / item-sort / field-specs sections)

private enum FieldSpecStrategy { // swiftlint:disable:this one_declaration_per_file
	// swiftlint:disable sorted_enum_cases
	case insert
	case overlay
	case move
	case hide
	case remove // swiftlint:enable sorted_enum_cases
}

/// Applies `<field-order-section>` / `<item-sort-section>` /
/// `<field-spec-edits-section>` against a baseline `[FieldSpec]`, producing the
/// working (final) `[FieldSpec]`.
///
/// `<field-spec-reference>`s resolve against an immutable-_position_ snapshot
/// of the baseline (`referenceFieldSpecs`); per fields.md, inserts / moves /
/// removals during the section never change where an existing entry is _found_
/// by name / index, even though its content (via a later overlay / move) & the
/// _working_ list's order do change. `workingTags` runs parallel to
/// `fieldSpecs`, remembering each working entry's index into
/// `referenceFieldSpecs` (`nil` for entries inserted during this section,
/// which, per spec, can't be referenced by later entries in the same section),
/// so a reference's _current_ working position can always be found again after
/// earlier inserts / moves / removals have shifted things around.
private struct FieldSpecsBuilder { // swiftlint:disable:this one_declaration_per_file
	private(set) var fieldSpecs: [FieldSpec]

	private let outputFormat: OutputFormat

	private var workingTags: [Int?]
	/// The base fields config's field specs, immutable: the `source` of a
	/// `<base-sourced-field-spec-edit>` (i.e., a `<field-spec-insertion>`).
	private let baseFieldSpecs: [FieldSpec]
	private var referenceFieldSpecs: [FieldSpec?]
	/// "$previous$": the working index after which the next insert / move's
	/// direct result lands. `-1` = before the first field spec.
	private var previousIndex = -1

	init(fieldSpecs: [FieldSpec], outputFormat: OutputFormat) {
		self.fieldSpecs = fieldSpecs
		self.outputFormat = outputFormat
		workingTags = Array(fieldSpecs.indices)
		baseFieldSpecs = fieldSpecs
		referenceFieldSpecs = fieldSpecs
	}

	/// Parses `<field-order-section>`: `<field-order-section-prefix>` followed by
	/// a required `<field-order-option-set>`, either an `<order-option-set>`
	/// (`[ <direction>+ ] <order> [ <order-option>+ ]`, `<order>` being `w` /
	/// `o`, last wins per axis) or a `<sort-option-set>` (whose `<source>`
	/// defaults to `<output>`, i.e., sorted by label). The 2 alternatives are
	/// disjoint: an `<order-option-set>` contains an `<order>` letter, which is
	/// no `<sort-option>`.
	mutating func parseFieldOrderSection(_ input: inout Substring) throws(ParsingError) -> FieldOrder {
		guard input.first == fieldOrderSectionPrefix, !input.hasPrefix(itemSortSectionPrefix) else {
			return .inherited
		}
		input.removeFirst()
		guard let first = input.first, first != fieldSpecSeparator, !itemSortAndFieldSpecsPrefixSet.contains(first) else {
			throw .missingFieldOrderOptionSet
		}
		guard let order = orderOptionSetOrder(input) else {
			var defaults = defaultSortOptionSet(forFieldNamed: nil, outputFormat: outputFormat)
			defaults.source = .output // `<field-order-option-set>`'s `default source: <output>`
			let optionSet =
				try SortOptionSet.parsed(&input, terminatorSet: itemSortAndFieldSpecsPrefixSet, defaults: defaults)
			return switch optionSet.source {
			case .input:
				.byName(optionSet)
			case .output:
				.byLabel(optionSet)
			}
		}
		var direction = SortOptionSet.Direction?.none
		while let char = input.first, char != fieldSpecSeparator, !itemSortAndFieldSpecsPrefixSet.contains(char) {
			if let match = SortOptionSet.Direction(rawValue: char) {
				direction = match
			}
			input.removeFirst()
		}
		return switch (order, outputFormat) {
		case (baseFieldsConfigOrderOption, _):
			.base(direction)
		case (_, .table): // `<original-input-order>` is `(* only for: json or key-value output *)`
			throw .originalInputOrderUnsupportedForTable
		default:
			.original(direction)
		}
	}

	/// Parses `<item-sort-section>`: `<item-sort-section-prefix>` followed by
	/// `<item-sort-option-set>` (`<item-sort-option>+`, last wins per axis).
	/// `<disable-all-sorts>` sets each field spec's `<sort-priority>` to `0`,
	/// retaining its `<sort-option-set>`; `<direction>` is the item-sort
	/// tiebreak (input order / reverse input order).
	mutating func parseItemSortSection(_ input: inout Substring) throws(ParsingError) -> SortOptionSet.Direction {
		guard input.hasPrefix(itemSortSectionPrefix) else {
			return .ascending
		}
		input.removeFirst(itemSortSectionPrefix.count)
		var shouldDisableAllSorts = false
		var direction = SortOptionSet.Direction?.none
		while let option = input.first, option != fieldSpecsSectionPrefix {
			input.removeFirst()
			if let match = SortOptionSet.Direction(rawValue: option) {
				direction = match
			} else if option == disableAllSortsOption {
				shouldDisableAllSorts = true
			} else if !option.isWhitespace {
				throw .invalidSortOption(option)
			}
		}
		guard direction != nil || shouldDisableAllSorts else {
			throw .missingItemSortOptionSet
		}
		if shouldDisableAllSorts {
			fieldSpecs = fieldSpecs.map(disablingSort)
			referenceFieldSpecs = referenceFieldSpecs.map { $0.map(disablingSort) }
		}
		return direction ?? .ascending
	}

	mutating func parseFieldSpecsSection(_ input: inout Substring) throws(ParsingError) {
		guard input.first == fieldSpecsSectionPrefix else {
			return
		}
		input.removeFirst()
		while !input.isEmpty {
			switch parseFieldSpecStrategy(&input) {
			case .insert:
				let source = try parseBaseSourcedFieldSpec(&input)
				try apply(
					.insert(isHidden: false),
					name: source.name,
					existing: source,
					label: try parseLabel(&input),
					format: try parseFormat(&input, existing: source.format),
					sortModifierInput: &input,
				)
			case .overlay:
				let reference = try parseFieldSpecReference(&input)
				let existing = try resolvedReferenceFieldSpec(reference)
				try apply(
					.overlay(reference, isHidden: false),
					name: existing.name,
					existing: existing,
					label: try parseLabel(&input),
					format: try parseFormat(&input, existing: existing.format),
					sortModifierInput: &input,
				)
			case .move:
				let reference = try parseFieldSpecReference(&input)
				let existing = try resolvedReferenceFieldSpec(reference)
				try apply(
					.move(reference),
					name: existing.name,
					existing: existing,
					label: try parseLabel(&input),
					format: try parseFormat(&input, existing: existing.format),
					sortModifierInput: &input,
				)
			case .hide:
				// A `<named-field-spec-reference>` that resolves to no field spec
				// inserts a new field spec (as `<field-spec-insertion>` would) as
				// `source`
				let (reference, existing) = try parseHideReference(&input)
				try apply(
					reference.map { .overlay($0, isHidden: true) } ?? .insert(isHidden: true),
					name: existing.name,
					existing: existing,
					label: try parseLabel(&input),
					format: try parseFormat(&input, existing: existing.format),
					sortModifierInput: &input,
				)
			case .remove:
				// A `<field-spec-removal>`'s `<reference-field-name>` has no modifiers
				// to terminate it
				let reference = try parseFieldSpecReference(&input, nameTerminatorSet: [indexPrefix, fieldSpecSeparator])
				_ = try resolvedReferenceFieldSpec(reference) // Validates existence
				remove(reference)
			}
			input = input.drop(while: \.isWhitespace)
			guard input.first == fieldSpecSeparator else {
				break
			}
			input.removeFirst()
		}
		guard input.isEmpty else {
			throw .unexpectedCharacter(input.first ?? " ")
		}
	}

	mutating func parseAbsoluteConfig(_ input: inout Substring) throws(ParsingError) {
		while true {
			let name = try parseName(&input)
			let label = try parseLabel(&input) ?? name
			let parsed = try parseFormat(&input, existing: nil)
			fieldSpecs.append(
				.init(
					name: name,
					label: label,
					format: parsed?.format ?? .default(fieldName: name),
					sortSpec: try parseSortSpecModifier(&input, existing: nil, fieldName: name, outputFormat: outputFormat),
					justification: parsed?.justification ?? .start,
				),
			)
			input = input.drop(while: \.isWhitespace)
			guard !input.isEmpty else {
				return
			}
			guard input.first == fieldSpecSeparator else {
				throw .unexpectedCharacter(input.first ?? " ")
			}
			input.removeFirst()
		}
	}

	/// `fieldSpec` unchanged if it has no `sortSpec` (nothing to disable);
	/// otherwise, its `sortSpec`'s `<sort-priority>` set to `0` (disabled),
	/// retaining its `<sort-option-set>`.
	private func disablingSort(_ fieldSpec: FieldSpec) -> FieldSpec {
		fieldSpec.sortSpec.map { sortSpec in
			.init(
				name: fieldSpec.name,
				label: fieldSpec.label,
				format: fieldSpec.format,
				sortSpec: sortSpec.withPriority(0),
				isHidden: fieldSpec.isHidden,
				isSynthesized: fieldSpec.isSynthesized,
				justification: fieldSpec.justification,
			)
		}
			?? fieldSpec
	}
}

/// The `<order>` letter (`w` / `o`) of `input`'s `<field-order-option-set>`
/// (up to, but not including, its terminating `<field-spec-separator>` /
/// `<item-sort-section-prefix>` / `<field-spec-edits-section-prefix>`) iff it
/// is an `<order-option-set>`: every top-level character is a `<direction>` or
/// an `<order>`, with at least 1 `<order>` (last wins). `nil` means it is a
/// `<sort-option-set>` instead: the 2 alternatives share no valid text (an
/// all-`<direction>` sequence with no `<order>` can only be
/// `<sort-option-set>`), so checking without consuming `input` is safe.
private func orderOptionSetOrder(_ input: Substring) -> Character? {
	var order = Character?.none
	for char in input {
		if char == fieldSpecSeparator || itemSortAndFieldSpecsPrefixSet.contains(char) {
			break
		}
		guard orderOptionSet.contains(char) else {
			guard char.isWhitespace || SortOptionSet.Direction(rawValue: char) != nil else {
				return nil
			}
			continue
		}
		order = char
	}
	return order
}

// MARK: Private: field-spec-reference resolution

private extension FieldSpecsBuilder {
	private struct Reference {
		let name: String?
		let position: Int
	}

	private func parseFieldSpecReference(
		_ input: inout Substring,
		nameTerminatorSet: Set<Character> = modifiedFieldNameTerminatorSet,
	) throws(ParsingError) -> Reference {
		guard input.first != indexPrefix else {
			return .init(
				name: nil,
				position: try effectivePosition(forIndex: parseIndex(&input), length: referenceFieldSpecs.count),
			)
		}
		let (name, index) = try parseNameAndIndex(&input, nameTerminatorSet: nameTerminatorSet)
		let positions = referencePositions(forName: name)
		guard !positions.isEmpty else {
			throw .nonexistentFieldSpec(forName: name)
		}
		return .init(name: name, position: positions[try effectivePosition(forIndex: index, length: positions.count) - 1])
	}

	/// Parses a `<field-spec-reference>` for a `<base-sourced-field-spec-edit>`
	/// & resolves its `source` from the base fields config (as in the reference
	/// fields config, except that a `<named-field-spec-reference>` that
	/// references no field spec selects a field spec with default settings for
	/// field `<reference-field-name>`).
	private func parseBaseSourcedFieldSpec(_ input: inout Substring) throws(ParsingError) -> FieldSpec {
		guard input.first != indexPrefix else {
			return baseFieldSpecs[try effectivePosition(forIndex: parseIndex(&input), length: baseFieldSpecs.count) - 1]
		}
		let (name, index) = try parseNameAndIndex(&input)
		let positions = referencePositions(forName: name)
		return positions.isEmpty
			? .defaultSettings(forName: name)
			: baseFieldSpecs[positions[try effectivePosition(forIndex: index, length: positions.count) - 1] - 1]
	}

	/// Parses a `<field-spec-hide>`'s `<field-spec-reference>`: the resolved
	/// reference & its `source` from the reference fields config; or, iff a
	/// `<named-field-spec-reference>` resolves to no field spec (none for its
	/// field, or 1 removed earlier in this section), `nil` & the field spec that
	/// a `<field-spec-insertion>` would copy from the base fields config.
	private func parseHideReference(_ input: inout Substring)
	throws(ParsingError) -> (reference: Reference?, source: FieldSpec) {
		guard input.first != indexPrefix else {
			let reference = try parseFieldSpecReference(&input)
			return (reference, try resolvedReferenceFieldSpec(reference))
		}
		let (name, index) = try parseNameAndIndex(&input)
		let positions = referencePositions(forName: name)
		guard !positions.isEmpty else {
			return (nil, .defaultSettings(forName: name))
		}
		let reference =
			Reference(name: name, position: positions[try effectivePosition(forIndex: index, length: positions.count) - 1])
		return referenceFieldSpecs[reference.position - 1].map { (reference, $0) }
			?? (nil, baseFieldSpecs[reference.position - 1])
	}

	/// The 1-based positions in the reference fields config of field specs for
	/// field `name`, including any since replaced by `null`: the reference
	/// fields config's order & names are immutable, & are those of the base
	/// fields config.
	private func referencePositions(forName name: String) -> [Int] {
		baseFieldSpecs.indices.compactMap { baseFieldSpecs[$0].name == name ? $0 + 1 : nil }
	}

	/// Parses a `<named-field-spec-reference>`'s `<reference-field-name>`, up to
	/// a character in `nameTerminatorSet`, & optional `<index-prefix>`
	/// `<index>` (default `1`).
	private func parseNameAndIndex(
		_ input: inout Substring,
		nameTerminatorSet: Set<Character> = modifiedFieldNameTerminatorSet,
	) throws(ParsingError) -> (name: String, index: Int) {
		let name = try parseEscapedText(&input, terminatorSet: nameTerminatorSet)
		guard !name.isEmpty else {
			throw .missingFieldName
		}
		return (name, input.first == indexPrefix ? try parseIndex(&input) : 1)
	}

	/// Parses an `<index-prefix>` & its required `<index>`.
	private func parseIndex(_ input: inout Substring) throws(ParsingError) -> Int {
		input.removeFirst()
		input = input.drop(while: \.isWhitespace)
		guard let index = parseInt(&input) else {
			throw .missingIndex
		}
		return index
	}

	/// The `source` field spec for a resolved reference: errors if its
	/// reference-config position is `nil` (already removed earlier in this
	/// section).
	private func resolvedReferenceFieldSpec(_ reference: Reference) throws(ParsingError) -> FieldSpec {
		guard let fieldSpec = referenceFieldSpecs[reference.position - 1] else {
			throw .nonexistentFieldSpec(forName: reference.name ?? "@\(reference.position)")
		}
		return fieldSpec
	}

	private func currentWorkingIndex(ofReferencePosition position: Int) -> Int {
		workingTags.firstIndex(of: position - 1)! // swiftlint:disable:this force_unwrapping
	}
}

// MARK: Private: applying field specs

private extension FieldSpecsBuilder {
	private enum ResolvedStrategy {
		case insert(isHidden: Bool)
		case move(Reference)
		case overlay(Reference, isHidden: Bool)
	}

	private mutating func apply(
		_ strategy: ResolvedStrategy,
		name: String,
		existing: FieldSpec?,
		label: String?,
		format: (format: Format, justification: Justification?)?,
		sortModifierInput input: inout Substring,
	) throws(ParsingError) {
		let isHidden = switch strategy {
		case let .insert(isHidden), let .overlay(_, isHidden):
			isHidden
		case .move:
			false
		}
		let merged = FieldSpec(
			name: name,
			label: label ?? existing?.label ?? name,
			format: format?.format ?? existing?.format ?? .default(fieldName: name),
			sortSpec: // swiftformat:disable:next indent
				try parseSortSpecModifier(&input, existing: existing?.sortSpec, fieldName: name, outputFormat: outputFormat),
			isHidden: isHidden,
			isSynthesized: existing?.isSynthesized ?? false,
			justification: format?.justification ?? existing?.justification ?? .start,
		)
		switch strategy {
		case .insert:
			let newIndex = previousIndex + 1
			fieldSpecs.insert(merged, at: newIndex)
			workingTags.insert(nil, at: newIndex)
			previousIndex = newIndex
		case let .overlay(reference, _):
			referenceFieldSpecs[reference.position - 1] = merged
			let workingIndex = currentWorkingIndex(ofReferencePosition: reference.position)
			fieldSpecs[workingIndex] = merged
			previousIndex = workingIndex
		case let .move(reference):
			let oldWorkingIndex = currentWorkingIndex(ofReferencePosition: reference.position)
			referenceFieldSpecs[reference.position - 1] = merged
			fieldSpecs.remove(at: oldWorkingIndex)
			workingTags.remove(at: oldWorkingIndex)
			let insertAt = oldWorkingIndex <= previousIndex ? previousIndex : previousIndex + 1
			fieldSpecs.insert(merged, at: insertAt)
			workingTags.insert(reference.position - 1, at: insertAt)
			previousIndex = insertAt
		}
	}

	private mutating func remove(_ reference: Reference) {
		referenceFieldSpecs[reference.position - 1] = nil
		let workingIndex = currentWorkingIndex(ofReferencePosition: reference.position)
		fieldSpecs.remove(at: workingIndex)
		workingTags.remove(at: workingIndex)
		previousIndex = workingIndex - 1
	}
}

private func parseFieldSpecStrategy(_ input: inout Substring) -> FieldSpecStrategy {
	input = input.drop(while: \.isWhitespace)
	guard
		let strategy = input.first.flatMap(
			{ char in
				switch char {
				case insertIndicator:
					FieldSpecStrategy.insert
				case moveIndicator:
					.move
				case hideIndicator:
					.hide
				case removeIndicator:
					.remove
				default:
					nil
				}
			},
		)
	else {
		return .overlay
	}
	input.removeFirst()
	return strategy
}

// MARK: - Field modifiers (name / label / format / sort)

private func parseName(_ input: inout Substring, extraTerminatorSet: Set<Character> = .init())
throws(ParsingError) -> String {
	let name = try parseEscapedText(
		&input,
		terminatorSet: // swiftformat:disable:next indent
			extraTerminatorSet.union([labelModifierPrefix, formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator]),
	)
	guard !name.isEmpty else {
		throw .missingFieldName
	}
	return name
}

private func parseLabel(_ input: inout Substring) throws(ParsingError) -> String? {
	input = input.drop(while: \.isWhitespace)
	guard input.first == labelModifierPrefix else {
		return nil
	}
	input.removeFirst()
	return try parseEscapedText(&input, terminatorSet: [formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator])
}

/// Parses an optional `<format-modifier>`: `nil` iff absent; otherwise, the
/// format & the justification (`nil` iff the working fields config's is
/// retained). `existing` is the working fields config's format, if any.
private func parseFormat(_ input: inout Substring, existing: Format?)
throws(ParsingError) -> (format: Format, justification: Justification?)? {
	input = input.drop(while: \.isWhitespace)
	guard input.first == formatModifierPrefix else {
		return nil
	}
	input.removeFirst()
	return try parseFormatBlock(&input, existing: existing ?? .default(fieldName: ""))
}

private func parseSortSpecModifier(
	_ input: inout Substring,
	existing: SortSpec?,
	fieldName: String,
	outputFormat: OutputFormat,
) throws(ParsingError) -> SortSpec? {
	input = input.drop(while: \.isWhitespace)
	guard input.first == sortModifierPrefix else {
		return existing
	}
	input.removeFirst()
	return try .parsed(
		&input,
		existing: existing,
		defaultOptionSet: defaultSortOptionSet(forFieldNamed: fieldName, outputFormat: outputFormat),
	)
}

// MARK: - Shared parsing primitives

func parseUInt64(_ input: inout Substring) -> UInt64? {
	let digits = input.prefix { $0.isASCII && $0.isNumber }
	guard !digits.isEmpty, let value = UInt64(digits) else {
		return nil
	}
	input.removeFirst(digits.count)
	return value
}

func parseInt(_ input: inout Substring) -> Int? {
	let sign = input.first == "-" ? "-" : ""
	let digits = sign + input.dropFirst(sign.count).prefix { $0.isASCII && $0.isNumber }
	guard !digits.isEmpty, let value = Int(digits) else {
		return nil
	}
	input.removeFirst(digits.count)
	return value
}

func parseEscapedText(_ input: inout Substring, terminatorSet: Set<Character>) throws(ParsingError) -> String {
	try parseEscapedTextAndIndex(&input, terminatorSet: terminatorSet).unescapedText
}

func parseEscapedTextAndIndex(_ input: inout Substring, terminatorSet: Set<Character>)
throws(ParsingError) -> (unescapedText: String, index: String.Index) {
	input = input.drop { $0.isWhitespace && !terminatorSet.contains($0) }
	var unescapedText = ""
	var currentIndex = input.startIndex
	var trailingUnescapedWhitespaceCount = 0
	while currentIndex < input.endIndex {
		let char = input[currentIndex]
		if char == escapePrefix {
			trailingUnescapedWhitespaceCount = 0
			let nextIndex = input.index(after: currentIndex)
			guard nextIndex < input.endIndex else {
				input = input[nextIndex...]
				throw .danglingEscape
			}
			unescapedText.append(input[nextIndex]) // Append the escaped character
			currentIndex = input.index(after: nextIndex)
		} else if terminatorSet.contains(char) {
			break
		} else {
			unescapedText.append(char)
			trailingUnescapedWhitespaceCount = char.isWhitespace ? trailingUnescapedWhitespaceCount + 1 : 0
			currentIndex = input.index(after: currentIndex)
		}
	}
	input = input[currentIndex...]
	unescapedText.removeLast(trailingUnescapedWhitespaceCount)
	return (unescapedText, currentIndex)
}

// MARK: Constants

let escapePrefix = Character("\\")

let fieldSpecSeparator = Character(",")

let baseFieldsConfigSectionPrefix = Character("@")
let fieldOrderSectionPrefix = Character("/")
let itemSortSectionPrefix = "//"
let fieldSpecsSectionPrefix = Character(".")

private let relativeConfigStartSet = Set([
	baseFieldsConfigSectionPrefix,
	fieldOrderSectionPrefix,
	fieldSpecsSectionPrefix,
])

private let itemSortAndFieldSpecsPrefixSet =
	Set([itemSortSectionPrefix[itemSortSectionPrefix.startIndex], fieldSpecsSectionPrefix])

let insertIndicator = Character("+")
let moveIndicator = Character("%")
let hideIndicator = Character("_")
let removeIndicator = Character("-")

let labelModifierPrefix = Character("=")
let sortModifierPrefix = Character("/")

let indexPrefix = Character("@")

/// The characters that terminate a `<reference-field-name>` that may be
/// followed by `<field-modifiers>`.
private let modifiedFieldNameTerminatorSet =
	Set([indexPrefix, labelModifierPrefix, formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator])

private let baseFieldsConfigOrderOption = Character("w")
private let originalInputOrderOption = Character("o")
private let orderOptionSet = Set([baseFieldsConfigOrderOption, originalInputOrderOption])
private let disableAllSortsOption = Character("r")

private let outputFormatSuffixSet = Set(["json", "key-value", "table"] as [Substring])
private let outputFormatSuffixPrefix = Character("@")
private let unsuffixedVariantReferenceSuffix = "@none"

let defaultFieldsConfigName = "default"
let noneFieldsConfigName = "none"
let allFieldsConfigName = "all"
let standardFieldsConfigName = "standard"
