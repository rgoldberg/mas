//
// FieldSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import BigInt
internal import JSONAST

// MARK: Internal types

struct FieldSpec: Equatable {
	/// The default field spec for field `name`: labeled by its name, default
	/// format, no `<sort>`, visible.
	static func `default`(forName name: String) -> Self {
		.init(name: name, label: name, format: .default(fieldName: name), sortSpec: nil)
	}

	let name: String
	let label: String
	let format: Format
	let sortSpec: SortSpec?
	/// Whether this field spec is hidden (`<field-spec-hide>`): not output, but
	/// otherwise behaving as a visible one (it has a position, may be referenced
	/// by a `<field-spec-reference>` & its `<sort>` sorts items iff enabled).
	let isHidden: Bool
	/// Whether this field's value is computed after the display command's own
	/// fetch (e.g., `outdated`'s `newVersion`, from comparing the installed &
	/// latest versions), so it is never itself something to fetch.
	let isSynthesized: Bool
	/// Table-only column alignment (ignored by `json` / `keyValue` output, which
	/// have no column to align). Set directly by a display command's own
	/// `standard` / `all` fields config (see
	/// `defaultJustification(forFieldNamed:)` in `AppStoreFieldDefaults.swift`),
	/// or by a `--fields` `<format-transform-pipeline>` (see `parseFormat(_:)`
	/// below).
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

	/// Renders `value` (`nil` iff the field does not exist for this item) per
	/// `format`; `nil` iff the formatted value is absent.
	func rendered(value: JSON.Node?) throws(FormattingError) -> JSON.Node? {
		try format.rendered(value: value, label: label, name: name)
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
	case documentOrderUnsupportedForTable
	case emptyBoundaryGroup
	case forbiddenWhitespace(after: Character)
	case invalidBaseFieldsConfigName(String)
	case invalidCharacterClass(String)
	case invalidFormatName(String)
	case invalidLetter(Character)
	case invalidLocaleIdentifier(String)
	case invalidModifier(Character)
	case invalidMultiCharacterBoundary
	case invalidNumberCoercionArguments
	case invalidPipeline(String)
	case invalidPosition(String)
	case invalidSortOption(Character)
	case invalidSortOptionArguments(Character)
	case invalidTransformArguments(name: String)
	case invalidTriviaRegex(String)
	case missingBlockTerminator
	case missingFieldName
	case missingFieldOccurrenceIndex
	case missingFieldOrderOptionSet
	case missingFieldOrderTiebreakerDirection
	case missingFieldSpecIndex
	case missingItemSortOptionSet
	case missingPredicate
	case missingSortOptionTerminator
	case missingSortPriority
	case nonexistentField(String)
	case nonexistentFieldsConfig(String)
	case nonexistentFieldSpec(forName: String)
	case numberCoercionArgumentsNotSupported(String)
	case reservedFieldNameCharacter(Character)
	case singleBranch
	case templateLacksPlaceholder
	case tiebreakerUnsupportedForPositionalOrder
	case unconditionalBranchNotLast
	case unexpectedCharacter(Character)
	case unknownNamedFormat(String)
	case unknownTransform(String)
	case unsupportedAbsentFieldOption(Character)

	var description: String {
		switch self {
		case let .coercionNotSupported(letter):
			"<coercion> is not supported for: \(letter)"
		case .danglingEscape:
			"Expected a character to escape after trailing '\\'"
		case .documentOrderUnsupportedForTable:
			"<document-order> 'D' is supported only for JSON or key-value output"
		case .emptyBoundaryGroup:
			"<boundary-group> requires at least 1 boundary"
		case let .forbiddenWhitespace(token):
			"Whitespace is forbidden after: \(token)"
		case let .invalidBaseFieldsConfigName(baseFieldsConfigName):
			"Invalid base fields config name: \(baseFieldsConfigName)"
		case let .invalidCharacterClass(name):
			"Invalid character class: \(name)"
		case let .invalidFormatName(name):
			"Invalid format name: \(name)"
		case let .invalidLetter(letter):
			"Invalid <predicate>: \(letter)"
		case let .invalidLocaleIdentifier(identifier):
			"Invalid <locale-identifier>: \(identifier)"
		case let .invalidModifier(letter):
			"Invalid <modifiers> for <predicate>: \(letter)"
		case .invalidMultiCharacterBoundary:
			"<multi-character-boundary> requires non-empty text between its '%' fences"
		case .invalidNumberCoercionArguments:
			"Invalid <number-coercion-arguments>"
		case let .invalidPipeline(nonterminal):
			"Invalid \(nonterminal)"
		case let .invalidPosition(index):
			"Invalid position for index: \(index)"
		case let .invalidSortOption(sortOption):
			"Invalid sort option: \(sortOption)"
		case let .invalidSortOptionArguments(sortOption):
			"Invalid arguments for sort option: \(sortOption)"
		case let .invalidTransformArguments(name):
			"Invalid arguments for transform: \(name)"
		case let .invalidTriviaRegex(pattern):
			"Invalid trivia regex: \(pattern)"
		case .missingBlockTerminator:
			"Expected <block-terminator> '+'"
		case .missingFieldName:
			"Expected field name"
		case .missingFieldOccurrenceIndex:
			"Expected <field-occurrence-index> after <field-occurrence-index-prefix> '@'"
		case .missingFieldOrderOptionSet:
			"Expected <field-order-option-set> after <field-order-section-prefix> '/'"
		case .missingFieldOrderTiebreakerDirection:
			"Expected <direction> after <field-order-tiebreaker>'s <sort-modifier-prefix> '/'"
		case .missingFieldSpecIndex:
			"Expected <field-spec-index> after <field-spec-index-prefix> '@'"
		case .missingItemSortOptionSet:
			"Expected <item-sort-option-set> after <item-sort-section-prefix> '//'"
		case .missingPredicate:
			"Expected <predicate>"
		case .missingSortOptionTerminator:
			"Expected <sort-option-terminator> ':'"
		case .missingSortPriority:
			"Expected a numeric sort priority (only the field's existing sort options may be adjusted without one)"
		case let .nonexistentFieldSpec(name):
			"""
			Expected existing field spec for field name: \(
				name.isEmpty || name.first?.isWhitespace == true || name.last?.isWhitespace == true ? "'\(name)'" : name
			)
			"""
		case let .nonexistentField(name):
			"Nonexistent field: \(name)"
		case let .nonexistentFieldsConfig(name):
			"Nonexistent fields config: \(name)"
		case let .numberCoercionArgumentsNotSupported(name):
			"<number-coercion-arguments> are not supported for: \(name)"
		case let .reservedFieldNameCharacter(character):
			"A field name must escape its reserved character: \(character)"
		case .singleBranch:
			"<branches> requires at least 2 branches"
		case .templateLacksPlaceholder:
			"<format-template> requires at least 1 <placeholder>"
		case .tiebreakerUnsupportedForPositionalOrder:
			"<field-order-tiebreaker> is not supported for <positional-order> 'P'"
		case .unconditionalBranchNotLast:
			"An <unconditional-branch> may only be the last <branch>, which must be preceded by a <conditional-branch>"
		case let .unexpectedCharacter(character):
			"Unexpected character: \(character)"
		case let .unknownNamedFormat(name):
			"Unknown named format: \(name)"
		case let .unknownTransform(name):
			"Unknown transform: \(name)"
		case let .unsupportedAbsentFieldOption(option):
			"<absent-field-comparison> & <absent-field-placement> are supported only for <document-order> 'D': \(option)"
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
	fieldNameSet: Set<String>? = nil, // swiftlint:disable:this discouraged_optional_collection
) throws(ParsingError) -> [String] {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	if isRelativeConfig(input) {
		guard
			!(
				try resolveBaseFieldsConfig(
					named: try parseBaseFieldsConfigSection(&input),
					standard: standard,
					all: all,
					outputFormat: outputFormat,
				)
			)
			.baseIncludesAllFields
		else {
			return .init()
		}
	}
	let resolved: any FieldsConfig
	do {
		resolved = try resolvedFieldsConfig(
			from: fieldsOptionValue,
			standard: standard,
			all: all,
			outputFormat: outputFormat,
			fieldNameSet: fieldNameSet,
		)
	} catch .nonexistentFieldSpec {
		return .init() // It may reference a field that is only discovered once every field is fetched
	}
	return .init(
		Set(
			resolved
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
/// as static). If `fieldsOptionValue` does not specify its own
/// `<field-order-section>`, the resolved base fields config's own `fieldOrder`
/// is used instead of a bare `.inherited`.
func resolvedFieldsConfig(
	from fieldsOptionValue: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
	fieldNameSet: Set<String>? = nil, // swiftlint:disable:this discouraged_optional_collection
) throws(ParsingError) -> any FieldsConfig {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	guard isRelativeConfig(input) else {
		// An `<absolute-config>` is equivalent to `@none/P` followed by a
		// `<field-spec-insertion>` per field spec
		let none =
			try resolveBaseFieldsConfig(named: noneFieldsConfigName, standard: standard, all: all, outputFormat: outputFormat)
		var builder = FieldSpecsBuilder(fieldSpecs: none.fieldSpecs, outputFormat: outputFormat, fieldNameSet: fieldNameSet)
		try builder.parseAbsoluteConfig(&input)
		return SelectedFieldsConfig(
			fieldSpecs: builder.fieldSpecs,
			fieldOrder: .positional,
			itemSort: .init(keys: builder.fieldSpecs.enabledSortKeys, tiebreakDirection: .ascending),
		)
	}
	let base = try resolveBaseFieldsConfig(
		named: try parseBaseFieldsConfigSection(&input),
		standard: standard,
		all: all,
		outputFormat: outputFormat,
	)
	var builder = FieldSpecsBuilder(fieldSpecs: base.fieldSpecs, outputFormat: outputFormat, fieldNameSet: fieldNameSet)
	let parsedFieldOrder = try builder.parseFieldOrderSection(&input)
	let fieldOrder = parsedFieldOrder == .inherited ? base.fieldOrder : parsedFieldOrder
	let tiebreakDirection = try builder.parseItemSortSection(&input)
	try builder.parseFieldSpecEditsSection(&input)
	guard input.isEmpty else {
		throw .unexpectedCharacter(input.first ?? " ")
	}
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
	return try parseEscapedText(&input, terminatorSet: [fieldOrderSectionPrefix, fieldSpecEditsSectionPrefix])
}

// MARK: - Base fields config resolution

// swiftlint:disable:next todo
// TODO: Temp/todo.md "Persisted Custom Named Formats & Configs": once custom
//  named fields configs are persisted, look a name up through the command's
//  context stack (most to least specific context), resolving a config that
//  extends a config of its own name from the next less specific context,
//  reporting any other reference cycle & substituting `standard` for a
//  nonexistent `default` (appending any output format suffix)

/// Resolves a `<base-fields-config-name>` (already stripped of its
/// `<base-fields-config-section-prefix>`, empty if absent) against the built-in
/// named fields configs, whose variants are selected by an output format suffix
/// (`@json` / `@key-value` / `@table`), the `@unsuffixed` reference suffix (the
/// unsuffixed variant, valid only directly after a stem), or, absent both,
/// `outputFormat`:
///
/// - `none`: `all` with every field spec hidden & its sort disabled.
/// - `all`: every field spec visible.
/// - `standard`: `standard`'s field specs, then `all`'s other field specs,
///   hidden, so `none`, `all` & `standard` differ only in which field specs are
///   hidden; `standard@json` is a reference to `all@json`.
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
		guard !isUnsuffixedVariant, outputFormatSuffix.map(outputFormatSuffixSet.contains) == true else {
			throw .invalidBaseFieldsConfigName(rawName)
		}
	}
	guard !stem.isEmpty, stem.allSatisfy(\.isNameCharacter) else {
		throw .invalidBaseFieldsConfigName(rawName)
	}
	let isMachineFacing = !isUnsuffixedVariant && (outputFormatSuffix.map { $0 == "json" } ?? outputFormat.isJSON)
	let allVariant = all.withDefaultFieldOrder(outputFormat: outputFormat)
	let config: any FieldsConfig =
		switch stem {
		case allFieldsConfigName:
			allVariant
		case defaultFieldsConfigName, standardFieldsConfigName:
			isMachineFacing ? allVariant : standard.including(hidden: allVariant.fieldSpecs)
		case noneFieldsConfigName:
			allVariant.hidingAll().disablingAllSorts()
		default:
			throw .nonexistentFieldsConfig(.init(stem))
		}
	return isMachineFacing ? config.machineFacingVariant() : config
}

extension Character { // swiftlint:disable:this file_types_order
	/// Whether this character may be in a config name's stem or in a format name,
	/// per configs.md's & fields-format.md's `^[-_0-9A-Za-z]+$`.
	var isNameCharacter: Bool {
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
		throw .invalidPosition(String(index))
	}
	return position
}

// MARK: - Field specs builder (field-order / item-sort / field-spec-edits sections)

/// A `<field-spec-edit>`'s kind.
private enum FieldSpecEditKind { // swiftlint:disable:this one_declaration_per_file
	// swiftlint:disable sorted_enum_cases
	case insertion
	case overlay
	case move
	case hide
	case removal // swiftlint:enable sorted_enum_cases
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
/// which, per spec, cannot be referenced by later entries in the same section),
/// so a reference's _current_ working position can always be found again after
/// earlier inserts / moves / removals have shifted things around.
private struct FieldSpecsBuilder { // swiftlint:disable:this one_declaration_per_file
	private(set) var fieldSpecs: [FieldSpec]

	private let outputFormat: OutputFormat
	/// Every field that may exist in any input, iff determinable up front (see
	/// fields.md's "Nonexistent Fields"); `nil` iff not.
	private let fieldNameSet: Set<String>? // swiftlint:disable:this discouraged_optional_collection

	private var workingTags: [Int?]
	/// The baseline fields config's field specs (the working field specs
	/// immediately before `<field-spec-edits-section>`): the `source` of a
	/// `<baseline-sourced-field-spec-edit>` (i.e., a `<field-spec-insertion>`).
	private var baselineFieldSpecs: [FieldSpec]
	private var referenceFieldSpecs: [FieldSpec?]
	/// "$previous$": the working index after which the next insert / move's
	/// direct result lands. `-1` = before the 1st field spec.
	private var previousIndex = -1

	// swiftlint:disable:next discouraged_optional_collection
	init(fieldSpecs: [FieldSpec], outputFormat: OutputFormat, fieldNameSet: Set<String>?) {
		self.fieldSpecs = fieldSpecs
		self.outputFormat = outputFormat
		self.fieldNameSet = fieldNameSet
		workingTags = Array(fieldSpecs.indices)
		baselineFieldSpecs = fieldSpecs
		referenceFieldSpecs = fieldSpecs
	}

	/// Parses `<field-order-section>`: `<field-order-section-prefix>` followed by
	/// a required `<field-order-option-set>`, either a
	/// `<positional-order-option-set>` / `<document-order-option-set>`
	/// (`<direction>`s & `<order>`s, the last `<order>` being `P` / `D`,
	/// respectively, plus, only for the latter, `<absent-field-comparison>`s &
	/// `<absent-field-placement>`s, last wins per axis) or a `<sort-option-set>`
	/// (whose `<source>` defaults to `<output>`, i.e., sorted by label), the
	/// latter 2 followed by an optional `<field-order-tiebreaker>`. The
	/// alternatives are disjoint: each but `<sort-option-set>` contains an
	/// `<order>` letter, which is no `<sort-option>`.
	mutating func parseFieldOrderSection(_ input: inout Substring) throws(ParsingError) -> FieldOrder {
		guard input.first == fieldOrderSectionPrefix, !input.hasPrefix(itemSortSectionPrefix) else {
			return .inherited
		}
		input.removeFirst()
		input = input.drop(while: \.isWhitespace)
		guard
			let first = input.first, first != fieldSpecSeparator,
			!itemSortAndFieldSpecEditsPrefixSet.contains(first)
		else {
			throw .missingFieldOrderOptionSet
		}
		guard let order = orderOptionSetOrder(input) else {
			var defaults = defaultSortOptionSet(forFieldNamed: nil, outputFormat: outputFormat)
			defaults.source = .output // `<field-order-option-set>`'s `default source: <output>`
			let optionSet =
				try SortOptionSet.parsed(&input, terminatorSet: itemSortAndFieldSpecEditsPrefixSet, defaults: defaults)
			let tiebreakDirection = try parseFieldOrderTiebreaker(&input) ?? .ascending
			return switch optionSet.source {
			case .input:
				.byName(optionSet, tiebreakDirection: tiebreakDirection)
			case .output:
				.byLabel(optionSet, tiebreakDirection: tiebreakDirection)
			}
		}
		var optionSet = DocumentOrderOptionSet()
		var absentFieldOption = Character?.none
		while let char = input.first, char != fieldSpecSeparator, !itemSortAndFieldSpecEditsPrefixSet.contains(char) {
			if let direction = SortOptionSet.Direction(rawValue: char) {
				optionSet.direction = direction
			} else if let comparison = DocumentOrderOptionSet.AbsentFieldComparison(rawValue: char) {
				optionSet.absentFieldComparison = comparison
				absentFieldOption = char
			} else if let placement = DocumentOrderOptionSet.AbsentFieldPlacement(rawValue: char) {
				optionSet.absentFieldPlacement = placement
				absentFieldOption = char
			}
			input.removeFirst()
		}
		let tiebreakDirection = try parseFieldOrderTiebreaker(&input)
		if order == positionalOrderOption, let absentFieldOption {
			// `<positional-order-option-set>` has only `<order-option>`s
			throw .unsupportedAbsentFieldOption(absentFieldOption)
		}
		return switch (order, outputFormat, tiebreakDirection) {
		case (positionalOrderOption, _, nil):
			reversingPositions(iff: optionSet.direction == .descending)
		case (positionalOrderOption, _, _): // `<field-order-tiebreaker>` is only for a field order other than `P`
			throw .tiebreakerUnsupportedForPositionalOrder
		case (_, .table, _): // `<document-order-option-set>` is `(* only for: JSON or key-value output *)`
			throw .documentOrderUnsupportedForTable
		default:
			.document(optionSet, tiebreakDirection: tiebreakDirection ?? .ascending)
		}
	}

	/// Parses `<item-sort-section>`: `<item-sort-section-prefix>` followed by
	/// `<item-sort-option-set>` (`<item-sort-option>+`, last wins per axis).
	/// `<disable-all-sorts>` sets each field spec's `<sort-priority>` to `0`,
	/// retaining its `<sort-option-set>`; `<direction>` is the item-sort tiebreak
	/// (input order / reverse input order).
	mutating func parseItemSortSection(_ input: inout Substring) throws(ParsingError) -> SortOptionSet.Direction {
		guard input.hasPrefix(itemSortSectionPrefix) else {
			return .ascending
		}
		input.removeFirst(itemSortSectionPrefix.count)
		var shouldDisableAllSorts = false
		var direction = SortOptionSet.Direction?.none
		while let option = input.first, option != fieldSpecEditsSectionPrefix {
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
			fieldSpecs = fieldSpecs.map(\.withSortDisabled)
			referenceFieldSpecs = referenceFieldSpecs.map { $0?.withSortDisabled }
		}
		return direction ?? .ascending
	}

	mutating func parseFieldSpecEditsSection(_ input: inout Substring) throws(ParsingError) {
		guard input.first == fieldSpecEditsSectionPrefix else {
			return
		}
		input.removeFirst()
		input = input.drop(while: \.isWhitespace)
		guard !input.isEmpty else {
			return
		}
		baselineFieldSpecs = fieldSpecs
		while true {
			switch parseFieldSpecEditKind(&input) {
			case .insertion:
				let source = try parseBaselineSourcedFieldSpec(&input)
				try apply(
					.insert(isHidden: false),
					name: source.name,
					existing: source,
					label: try parseLabel(&input),
					format: try parseFormat(&input),
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
					format: try parseFormat(&input),
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
					format: try parseFormat(&input),
					sortModifierInput: &input,
				)
			case .hide:
				// A `<named-field-spec-reference>` whose `<reference-field-name>` names
				// no field spec, or a `<field-spec-reference>` that resolves to a
				// `null`, inserts a new field spec (as `<field-spec-insertion>` would)
				// as `source`
				let (reference, existing) = try parseHideReference(&input)
				try apply(
					reference.map { .overlay($0, isHidden: true) } ?? .insert(isHidden: true),
					name: existing.name,
					existing: existing,
					label: try parseLabel(&input),
					format: try parseFormat(&input),
					sortModifierInput: &input,
				)
			case .removal:
				// A `<field-spec-removal>`'s `<reference-field-name>` has no modifiers
				// to terminate it
				let reference = try parseFieldSpecReference(
					&input,
					nameTerminatorSet: [fieldOccurrenceIndexPrefix, fieldSpecSeparator],
				)
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

	/// Parses an `<absolute-config>`, replacing the working field specs (the base
	/// fields config `none`'s) with its field specs, each a visible copy of the
	/// base fields config's 1st field spec for its field (or of its default field
	/// spec, absent one), overlaid with its `<field-modifiers>`.
	mutating func parseAbsoluteConfig(_ input: inout Substring) throws(ParsingError) {
		fieldSpecs.removeAll()
		workingTags.removeAll()
		while true {
			let name = try parseFieldName(
				&input,
				terminatorSet: [labelModifierPrefix, formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator],
			)
			let source =
				if let fieldSpec = baselineFieldSpecs.first(where: { $0.name == name }) {
					fieldSpec
				} else {
					try defaultFieldSpec(forName: name)
				}
			try apply(
				.insert(isHidden: false),
				name: name,
				existing: source,
				label: try parseLabel(&input),
				format: try parseFormat(&input),
				sortModifierInput: &input,
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

	/// `.positional`, after reversing the positions of the working & reference
	/// field specs iff `shouldReverse` (`<positional-order>`'s `<descending>`),
	/// before `<field-spec-edits-section>`, so its edits & each `<index>` apply
	/// to the reversed positions. No edit precedes `<field-order-section>`, so
	/// `workingTags` remains the identity mapping.
	private mutating func reversingPositions(iff shouldReverse: Bool) -> FieldOrder {
		if shouldReverse {
			fieldSpecs.reverse()
			referenceFieldSpecs.reverse()
		}
		return .positional
	}
}

/// Parses an optional `<field-order-tiebreaker>`
/// (`<field-order-tiebreaker-prefix> <direction>`), returning its
/// `<direction>`, or `nil` iff absent.
private func parseFieldOrderTiebreaker(_ input: inout Substring) throws(ParsingError) -> SortOptionSet.Direction? {
	guard input.first == fieldOrderTiebreakerPrefix, !input.hasPrefix(itemSortSectionPrefix) else {
		return nil
	}
	input.removeFirst()
	input = input.drop(while: \.isWhitespace)
	guard let direction = input.first.flatMap(SortOptionSet.Direction.init(rawValue:)) else {
		throw .missingFieldOrderTiebreakerDirection
	}
	input.removeFirst()
	input = input.drop(while: \.isWhitespace)
	return direction
}

/// The `<order>` letter (`P` / `D`) of `input`'s `<field-order-option-set>` (up
/// to, but not including, its terminating `<field-spec-separator>` /
/// `<item-sort-section-prefix>` / `<field-spec-edits-section-prefix>`) iff it
/// is a `<positional-order-option-set>` / `<document-order-option-set>`: every
/// top-level character is a `<direction>`, an `<absent-field-comparison>`, an
/// `<absent-field-placement>`, or an `<order>`, with at least 1 `<order>` (last
/// wins). `nil` means it is a `<sort-option-set>` instead: the alternatives
/// share no valid text (a sequence with no `<order>` can only be
/// `<sort-option-set>`), so checking without consuming `input` is safe.
private func orderOptionSetOrder(_ input: Substring) -> Character? {
	var order = Character?.none
	for char in input {
		if char == fieldSpecSeparator || itemSortAndFieldSpecEditsPrefixSet.contains(char) {
			break
		}
		guard orderOptionSet.contains(char) else {
			guard
				char.isWhitespace
				|| SortOptionSet.Direction(rawValue: char) != nil
				|| DocumentOrderOptionSet.AbsentFieldComparison(rawValue: char) != nil
				|| DocumentOrderOptionSet.AbsentFieldPlacement(rawValue: char) != nil
			else {
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
		guard input.first != fieldSpecIndexPrefix else {
			return .init(
				name: nil,
				position: try effectivePosition(
					forIndex: parseIndex(&input, ifMissing: .missingFieldSpecIndex),
					length: referenceFieldSpecs.count,
				),
			)
		}
		let (name, index) = try parseNameAndIndex(&input, nameTerminatorSet: nameTerminatorSet)
		let positions = referencePositions(forName: name)
		guard !positions.isEmpty else {
			throw .nonexistentFieldSpec(forName: name)
		}
		return .init(name: name, position: positions[try effectivePosition(forIndex: index, length: positions.count) - 1])
	}

	/// Parses a `<field-spec-reference>` for a
	/// `<baseline-sourced-field-spec-edit>` & resolves its `source` from the
	/// baseline fields config (as in the reference fields config, except that a
	/// `<named-field-spec-reference>` whose `<reference-field-name>` names no
	/// field spec selects the default field spec for field
	/// `<reference-field-name>`).
	private func parseBaselineSourcedFieldSpec(_ input: inout Substring) throws(ParsingError) -> FieldSpec {
		guard input.first != fieldSpecIndexPrefix else {
			return baselineFieldSpecs[try effectivePosition(
				forIndex: parseIndex(&input, ifMissing: .missingFieldSpecIndex),
				length: baselineFieldSpecs.count,
			) - 1]
		}
		let (name, index) = try parseNameAndIndex(&input)
		let positions = referencePositions(forName: name)
		return positions.isEmpty
			? try defaultFieldSpec(forName: name)
			: baselineFieldSpecs[positions[try effectivePosition(forIndex: index, length: positions.count) - 1] - 1]
	}

	/// Parses a `<field-spec-hide>`'s `<field-spec-reference>`: the resolved
	/// reference & its `source` from the reference fields config; or, iff a
	/// `<named-field-spec-reference>`'s `<reference-field-name>` names no field
	/// spec, or the reference resolves to a `null` (a field spec removed earlier
	/// in this section), `nil` & the field spec that a `<field-spec-insertion>`
	/// would copy from the baseline fields config.
	private func parseHideReference(_ input: inout Substring)
	throws(ParsingError) -> (reference: Reference?, source: FieldSpec) {
		guard input.first != fieldSpecIndexPrefix else {
			return hideSource(for: try parseFieldSpecReference(&input))
		}
		let (name, index) = try parseNameAndIndex(&input)
		let positions = referencePositions(forName: name)
		guard !positions.isEmpty else {
			return (nil, try defaultFieldSpec(forName: name))
		}
		return hideSource(
			for: .init(name: name, position: positions[try effectivePosition(forIndex: index, length: positions.count) - 1]),
		)
	}

	/// `reference` & its `source` from the reference fields config; or, iff it
	/// resolves to a `null`, `nil` & its field spec in the baseline fields
	/// config.
	private func hideSource(for reference: Reference) -> (reference: Reference?, source: FieldSpec) {
		referenceFieldSpecs[reference.position - 1].map { (reference, $0) }
			?? (nil, baselineFieldSpecs[reference.position - 1])
	}

	/// The default field spec for field `name`, which must not be a nonexistent
	/// field.
	private func defaultFieldSpec(forName name: String) throws(ParsingError) -> FieldSpec {
		guard fieldNameSet?.contains(name) != false else {
			throw .nonexistentField(name)
		}
		return .default(forName: name)
	}

	/// The 1-based positions in the reference fields config of field specs for
	/// field `name`, including any since replaced by `null`: the reference fields
	/// config's order & names are immutable & are those of the baseline fields
	/// config.
	private func referencePositions(forName name: String) -> [Int] {
		baselineFieldSpecs.indices.compactMap { baselineFieldSpecs[$0].name == name ? $0 + 1 : nil }
	}

	/// Parses a `<named-field-spec-reference>`'s `<reference-field-name>`, up to
	/// a character in `nameTerminatorSet` & optional
	/// `<field-occurrence-index-prefix>` `<field-occurrence-index>` (default
	/// `1`).
	private func parseNameAndIndex(
		_ input: inout Substring,
		nameTerminatorSet: Set<Character> = modifiedFieldNameTerminatorSet,
	) throws(ParsingError) -> (name: String, index: Int) {
		let name = try parseFieldName(&input, terminatorSet: nameTerminatorSet)
		return (
			name,
			input.first == fieldOccurrenceIndexPrefix
				? try parseIndex(&input, ifMissing: .missingFieldOccurrenceIndex)
				: 1,
		)
	}

	/// Parses an `<index>`'s prefix & its required `<index>`, throwing
	/// `missingError` absent the latter.
	private func parseIndex(_ input: inout Substring, ifMissing missingError: ParsingError)
	throws(ParsingError) -> Int {
		input.removeFirst()
		input = input.drop(while: \.isWhitespace)
		guard let text = parseIntegerText(&input, isSigned: true) else {
			throw missingError
		}
		// An index beyond `Int`'s range is beyond every position
		guard let index = Int(text) else {
			throw .invalidPosition(String(text))
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

private func parseFieldSpecEditKind(_ input: inout Substring) -> FieldSpecEditKind {
	input = input.drop(while: \.isWhitespace)
	guard
		let strategy = input.first.flatMap(
			{ char in
				switch char {
				case insertLiteral:
					FieldSpecEditKind.insertion
				case moveLiteral:
					.move
				case hideLiteral:
					.hide
				case removeLiteral:
					.removal
				default:
					nil
				}
			},
		)
	else {
		return .overlay
	}
	input.removeFirst()
	input = input.drop(while: \.isWhitespace) // E.g., before a `<field-spec-index-prefix>`
	return strategy
}

// MARK: - Field modifiers (name / label / format / sort)

/// Parses a non-empty field name up to a character in `terminatorSet`; a bare
/// `fieldNameReservedCharacter` is invalid (fields.md "Appendix: Escaping").
private func parseFieldName(_ input: inout Substring, terminatorSet: Set<Character>) throws(ParsingError) -> String {
	let name = try parseEscapedText(&input, terminatorSet: terminatorSet.union([fieldNameReservedCharacter]))
	guard input.first != fieldNameReservedCharacter else {
		throw .reservedFieldNameCharacter(fieldNameReservedCharacter)
	}
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
/// retained).
private func parseFormat(_ input: inout Substring)
throws(ParsingError) -> (format: Format, justification: Justification?)? {
	input = input.drop(while: \.isWhitespace)
	guard input.first == formatModifierPrefix else {
		return nil
	}
	input.removeFirst()
	return try parseFormatBlock(&input)
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

/// Consumes & returns the longest integer scalar token (1 or more ASCII digits,
/// preceded by an optional `+` or `-` iff `isSigned`) at the start of `input`;
/// else `nil`, consuming nothing.
func parseIntegerText(_ input: inout Substring, isSigned: Bool) -> Substring? {
	let signCount = isSigned && (input.first == "+" || input.first == "-") ? 1 : 0
	let text = input.prefix(signCount + input.dropFirst(signCount).prefix(while: \.isASCIIDigit).count)
	guard text.count > signCount else {
		return nil
	}
	input.removeFirst(text.count)
	return text
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

private let fieldNameReservedCharacter = Character(".")

let fieldSpecSeparator = Character(",")

let baseFieldsConfigSectionPrefix = Character("@")
let fieldOrderSectionPrefix = Character("/")
let fieldOrderTiebreakerPrefix = Character("/")
let itemSortSectionPrefix = "//"
let fieldSpecEditsSectionPrefix = Character(".")

private let relativeConfigStartSet = Set([
	baseFieldsConfigSectionPrefix,
	fieldOrderSectionPrefix,
	fieldSpecEditsSectionPrefix,
])

private let itemSortAndFieldSpecEditsPrefixSet =
	Set([itemSortSectionPrefix[itemSortSectionPrefix.startIndex], fieldSpecEditsSectionPrefix])

let insertLiteral = Character("+")
let moveLiteral = Character("%")
let hideLiteral = Character("_")
let removeLiteral = Character("-")

let labelModifierPrefix = Character("=")
let sortModifierPrefix = Character("/")

let fieldOccurrenceIndexPrefix = Character("@")
let fieldSpecIndexPrefix = Character("@")

/// The characters that terminate a `<reference-field-name>` that may be
/// followed by `<field-modifiers>`.
private let modifiedFieldNameTerminatorSet =
	Set([fieldOccurrenceIndexPrefix, labelModifierPrefix, formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator])

private let positionalOrderOption = Character("P")
private let documentOrderOption = Character("D")
private let orderOptionSet = Set([positionalOrderOption, documentOrderOption])
private let disableAllSortsOption = Character("0")

private let outputFormatSuffixSet = Set(["json", "key-value", "table"] as [Substring])
private let outputFormatSuffixPrefix = Character("@")
private let unsuffixedVariantReferenceSuffix = "@unsuffixed"

let defaultFieldsConfigName = "default"
let noneFieldsConfigName = "none"
let allFieldsConfigName = "all"
let standardFieldsConfigName = "standard"
