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
	/// The names of the attached presets, in attachment order (see
	/// `parsePresetModifier(_:attached:)` in `Preset.swift`).
	let presetNames: [String]
	/// The table-only column alignment absent any attached preset that sets one,
	/// set directly by a display command's own `standard` / `all` fields config
	/// (see `defaultAlignment(forFieldNamed:)` in `AppStoreFieldDefaults.swift`).
	let baseAlignment: Alignment

	/// Table-only column alignment (ignored by `json` / `keyValue` output, which
	/// have no column to align): the alignment of the last attached preset that
	/// sets one, else `baseAlignment`.
	var alignment: Alignment {
		presetNames.reversed().lazy.compactMap { alignmentByPresetName[$0] }.first ?? baseAlignment
	}

	init(
		name: String,
		label: String,
		format: Format,
		sortSpec: SortSpec?,
		isHidden: Bool = false,
		isSynthesized: Bool = false,
		presetNames: [String] = [defaultConfigName],
		alignment: Alignment = .start,
	) {
		self.name = name
		self.label = label
		self.format = format
		self.sortSpec = sortSpec
		self.isHidden = isHidden
		self.isSynthesized = isSynthesized
		self.presetNames = presetNames
		baseAlignment = alignment
	}

	/// Renders `value` (`nil` iff the field does not exist for this item) per
	/// `format`; `nil` iff the formatted value is absent.
	func rendered(value: JSON.Node?) throws(FormattingError) -> JSON.Node? {
		try format.rendered(value: value, label: label, name: name)
	}

	/// `value`'s values for this field spec's sort key, rendering it iff `source`
	/// is `<output>`.
	func sortValues(input value: JSON.Node?, source: SortOptionSet.Source) throws(FormattingError) -> SortValues {
		source == .output ? try format.sortValues(input: value, label: label, name: name) : .init(input: value, output: nil)
	}
}

extension FieldSpec: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		"""
		FieldSpec(name: "\(name)", label: "\(label)", format: \(format), sortSpec: \(sortSpec, default: "nil"), \
		isHidden: \(isHidden), presetNames: \(presetNames), alignment: \(alignment))
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
	case invalidLetter(Character)
	case invalidLocaleIdentifier(String)
	case invalidModifier(Character)
	case invalidMultiCharacterBoundary
	case invalidNumberCoercionArguments
	case invalidPipeline(String)
	case invalidPosition(String)
	case invalidPresetName(String)
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
	case mixedAbsoluteAndRelativePresets
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
	case unknownPreset(String)
	case unknownTransform(String)

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
		case let .invalidPresetName(name):
			"Invalid preset name: \(name)"
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
		case .mixedAbsoluteAndRelativePresets:
			"<absolute-presets> & <relative-presets> cannot be mixed"
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
		case let .unknownPreset(name):
			"Unknown preset: \(name)"
		case let .unknownTransform(name):
			"Unknown transform: \(name)"
		}
	}
}

// MARK: - Entry points

/// Phase 1 (pre-fetch): the field names a display command needs to fetch to
/// output per `fieldsOptionValue`: every field spec's that is visible or sorts
/// items. Never includes a synthesized field's name (see
/// `FieldSpec.isSynthesized`), since fetching it would be meaningless. Empty
/// means "fetch everything", as for a base fields config derived from `all`,
/// whose visible unlisted fields (fields.md "Unlisted Fields") are unknown
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
		let (base, _) = try resolveBaseFieldsConfig(
			named: try parseBaseFieldsConfigSection(&input),
			standard: standard,
			all: all,
			outputFormat: outputFormat,
		)
		guard !base.baseIncludesAllFields else {
			return .init()
		}
	}
	return .init(
		Set(
			try resolvedFieldsConfig(
				from: fieldsOptionValue,
				standard: standard,
				all: all,
				outputFormat: outputFormat,
				fieldNameSet: fieldNameSet,
			)
			.fieldSpecs
			.compactMap { fieldSpec in
				fieldSpec.isSynthesized || fieldSpec.isHidden && fieldSpec.sortSpec?.isEnabled != true
					? nil
					: fieldSpec.name
			},
		),
	)
}

/// The fully-resolved `FieldsConfig` for `fieldsOptionValue`, which, like its
/// positions, is independent of every item, because unlisted fields (fields.md
/// "Unlisted Fields") have no positions. If `fieldsOptionValue` does not
/// specify its own `<field-order-section>`, the resolved base fields config's
/// own `fieldOrder` is used instead of a bare `.inherited`.
func resolvedFieldsConfig(
	from fieldsOptionValue: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
	fieldNameSet: Set<String>? = nil, // swiftlint:disable:this discouraged_optional_collection
) throws(ParsingError) -> any FieldsConfig {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	guard isRelativeConfig(input) else {
		// An `<absolute-config>` is equivalent to `@none` followed by a
		// `<field-spec-insertion>` per field spec
		let (none, isMachineFacing) =
			try resolveBaseFieldsConfig(named: noneFieldsConfigName, standard: standard, all: all, outputFormat: outputFormat)
		var builder = FieldSpecsBuilder(
			fieldSpecs: none.fieldSpecs,
			outputFormat: outputFormat,
			isMachineFacing: isMachineFacing,
			fieldNameSet: fieldNameSet,
		)
		try builder.parseAbsoluteConfig(&input)
		return SelectedFieldsConfig(
			fieldSpecs: builder.fieldSpecs,
			fieldOrder: .positional(.init()),
			itemSort: .init(keys: builder.fieldSpecs.enabledSortKeys, tiebreakDirection: .ascending),
		)
	}
	let (base, isMachineFacing) = try resolveBaseFieldsConfig(
		named: try parseBaseFieldsConfigSection(&input),
		standard: standard,
		all: all,
		outputFormat: outputFormat,
	)
	var builder = FieldSpecsBuilder(
		fieldSpecs: base.fieldSpecs,
		outputFormat: outputFormat,
		isMachineFacing: isMachineFacing,
		fieldNameSet: fieldNameSet,
	)
	let parsedFieldOrder = try builder.parseFieldOrderSection(&input, inheriting: base.fieldOrder)
	let fieldOrder = parsedFieldOrder == .inherited ? base.fieldOrder : parsedFieldOrder
	let tiebreakDirection = try builder.parseItemSortSection(&input, inheriting: base.itemSort.tiebreakDirection)
	try builder.parseFieldSpecEditsSection(&input)
	guard input.isEmpty else {
		throw .unexpectedCharacter(input.first ?? " ")
	}
	let itemSort = ItemSort(keys: builder.fieldSpecs.enabledSortKeys, tiebreakDirection: tiebreakDirection)
	return base.baseIncludesAllFields
		? BaseIncludesAllFieldsConfig(
			fieldSpecs: builder.fieldSpecs,
			fieldOrder: fieldOrder,
			itemSort: itemSort,
			listedFieldNameSet: all.listedFieldNameSet
				.union(builder.fieldSpecs.map(\.name))
				.union(builder.removedUnmatchedFieldNameSet),
			isMachineFacing: isMachineFacing,
		)
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
// TODO: Temp/todo.md "Persistent Custom Presets & Configs": once custom named
//  fields configs are persisted, look a name up through the command's context
//  stack (most to least specific context), resolving a config that extends a
//  config of its own name from the next less specific context, reporting any
//  other reference cycle & substituting `standard` for a nonexistent `default`
//  (appending any output format suffix)

/// Resolves a `<base-fields-config-name>` (already stripped of its
/// `<base-fields-config-section-prefix>`, empty if absent) against the built-in
/// named fields configs, whose variants are selected by an output format suffix
/// (`@json` / `@key-value` / `@table`), the `@unsuffixed` reference suffix (the
/// unsuffixed variant, valid only directly after a stem), or, absent both,
/// `outputFormat`:
///
/// - `none`: `all` with every field spec's `<sort>`, if any, disabled & with
///   every field spec & unlisted field hidden, ordered by `<positional-order>`.
/// - `all`: every field spec visible, as are unlisted fields.
/// - `standard`: `standard`'s field specs, then `all`'s other field specs,
///   hidden, so `none`, `all` & `standard` differ only in which field specs &
///   whether unlisted fields are hidden; `standard@json` is a reference to
///   `all@json`.
/// - `default`: `standard`, absent a custom `default`.
///
/// The `@json` variant is machine-facing (see `machineFacingVariant()`); the
/// others are user-facing. Any other name is an error: no custom named fields
/// configs are persisted yet.
func resolveBaseFieldsConfig(
	named rawName: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
) throws(ParsingError) -> (config: any FieldsConfig, isMachineFacing: Bool) {
	var stem = (rawName.isEmpty ? defaultConfigName : rawName)[...]
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
	guard stem.isConfigName else {
		throw .invalidBaseFieldsConfigName(rawName)
	}
	let isMachineFacing = !isUnsuffixedVariant && (outputFormatSuffix.map { $0 == "json" } ?? outputFormat.isJSON)
	let allVariant = all.withDefaultFieldOrder(outputFormat: outputFormat)
	let config: any FieldsConfig =
		switch stem {
		case allFieldsConfigName:
			allVariant
		case defaultConfigName, standardConfigName:
			isMachineFacing ? allVariant : standard.including(hidden: allVariant.fieldSpecs)
		case noneFieldsConfigName:
			SelectedFieldsConfig(
				fieldSpecs: allVariant.fieldSpecs,
				fieldOrder: .positional(.init()),
				itemSort: allVariant.itemSort,
			)
			.hidingAll()
			.disablingAllSorts()
		default:
			throw .nonexistentFieldsConfig(.init(stem))
		}
	return (isMachineFacing ? config.machineFacingVariant() : config, isMachineFacing)
}

extension Character { // swiftlint:disable:this file_types_order
	/// Whether this character may be in a config name's stem, or in a preset
	/// name, per configs.md's `^[_0-9A-Za-z][-_0-9A-Za-z]*$`.
	var isNameCharacter: Bool {
		isASCII && (isLetter || isNumber || self == "-" || self == "_")
	}
}

extension StringProtocol { // swiftlint:disable:this file_types_order
	/// Whether this is a valid config name's stem, or a valid preset name, per
	/// configs.md's `^[_0-9A-Za-z][-_0-9A-Za-z]*$`.
	var isConfigName: Bool {
		first.map { $0 != "-" } == true && allSatisfy(\.isNameCharacter)
	}
}

// MARK: - Field-spec references & positions (fields.md)

/// Translates an index (per fields.md's "Positions & Indices": non-negative ⇒
/// itself; negative ⇒ `length + 1 + index`) into a validated 1-based position,
/// throwing for non-positive or out-of-range positions.
func normalizedPosition(forIndex index: Int, length: Int) throws(ParsingError) -> Int {
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
/// which, per spec, cannot be referenced by later entries in the same section,
/// except one that a `<reference-sourced-field-spec-edit>` inserted as its
/// `source`), so a reference's _current_ working position can always be found
/// again after earlier inserts / moves / removals have shifted things around.
private struct FieldSpecsBuilder { // swiftlint:disable:this one_declaration_per_file
	private(set) var fieldSpecs: [FieldSpec]

	/// The field names of `<field-spec-removal>`s whose `<reference-field-name>`
	/// named no field spec, each of which only lists its field (fields.md
	/// "Unlisted Fields").
	private(set) var removedUnmatchedFieldNameSet = Set<String>()

	private let outputFormat: OutputFormat
	/// Whether the base fields config is a machine-facing variant, whose default
	/// field specs are labeled by name, else per
	/// `builtInFieldSpec(forFieldNamed:)`.
	private let isMachineFacing: Bool
	/// Every field that may exist in any input, iff determinable up front (see
	/// fields.md's "Nonexistent Fields"); `nil` iff not.
	private let fieldNameSet: Set<String>? // swiftlint:disable:this discouraged_optional_collection

	private var workingTags: [Int?]
	/// The baseline fields config's field specs (the working field specs
	/// immediately before `<field-spec-edits-section>`): the `source` of a
	/// `<baseline-sourced-field-spec-edit>` (i.e., a `<field-spec-insertion>`).
	private var baselineFieldSpecs: [FieldSpec]
	/// The reference fields config's field specs, followed by each field spec
	/// that a `<reference-sourced-field-spec-edit>` inserted for a field that
	/// names no field spec in the reference fields config (at
	/// `unmatchedReferencePositionByName`), which no index references.
	private var referenceFieldSpecs: [FieldSpec?]
	/// The 1-based position in `referenceFieldSpecs` of the field spec that a
	/// `<reference-sourced-field-spec-edit>` inserted for each field that names
	/// no field spec in the reference fields config, `nil` there once removed.
	private var unmatchedReferencePositionByName = [String: Int]()
	/// "$previous$": the working index after which the next insert / move's
	/// direct result lands. `-1` = before the 1st field spec.
	private var previousIndex = -1

	// swiftlint:disable:next discouraged_optional_collection
	init(fieldSpecs: [FieldSpec], outputFormat: OutputFormat, isMachineFacing: Bool, fieldNameSet: Set<String>?) {
		self.fieldSpecs = fieldSpecs
		self.outputFormat = outputFormat
		self.isMachineFacing = isMachineFacing
		self.fieldNameSet = fieldNameSet
		workingTags = Array(fieldSpecs.indices)
		baselineFieldSpecs = fieldSpecs
		referenceFieldSpecs = fieldSpecs
	}

	/// Parses `<field-order-section>`: `<field-order-section-prefix>` followed by
	/// a required `<field-order-option-set>`, either a
	/// `<positional-order-option-set>` / `<document-order-option-set>`
	/// (`<direction>`s & `<order>`s, the last `<order>` being `P` / `D`,
	/// respectively, plus `<unpositioned-field-comparison>`s &
	/// `<unpositioned-field-placement>`s, last wins per setting) or a
	/// `<sort-option-set>` (whose `<source>` defaults to `<output>`, i.e., sorted
	/// by label), the latter 2 followed by an optional
	/// `<field-order-tiebreaker>`. The alternatives are disjoint: each but
	/// `<sort-option-set>` contains an `<order>` letter, which is no
	/// `<sort-option>`. Each option that a `<document-order-option-set>` or a
	/// `<sort-option-set>` omits, including its tiebreak direction, retains
	/// `inheritedFieldOrder`'s iff that is also `.document` or also sorts,
	/// respectively; each option that a `<positional-order-option-set>` omits
	/// retains `inheritedFieldOrder`'s iff that is also `.positional`.
	mutating func parseFieldOrderSection(_ input: inout Substring, inheriting inheritedFieldOrder: FieldOrder)
	throws(ParsingError) -> FieldOrder {
		guard input.first == fieldOrderSectionPrefix, !input.hasPrefix(itemSortSectionPrefix) else {
			return .inherited
		}
		input.removeFirst()
		input = input.drop(while: \.isWhitespace)
		guard
			let first = input.first,
			first != fieldSpecSeparator,
			!itemSortAndFieldSpecEditsPrefixSet.contains(first)
		else {
			throw .missingFieldOrderOptionSet
		}
		guard let order = orderOptionSetOrder(input) else {
			let inherited: (optionSet: SortOptionSet, tiebreakDirection: SortOptionSet.Direction)? =
				switch inheritedFieldOrder {
				case let .byLabel(optionSet, tiebreakDirection), let .byName(optionSet, tiebreakDirection):
					(optionSet, tiebreakDirection)
				case .document, .inherited, .positional:
					nil
				}
			var defaults = defaultSortOptionSet(forFieldNamed: nil, outputFormat: outputFormat)
			defaults.source = .output // `<field-order-option-set>`'s `default source: <output>`
			let optionSet = try SortOptionSet.parsed(
				&input,
				terminatorSet: itemSortAndFieldSpecEditsPrefixSet,
				defaults: inherited?.optionSet ?? defaults,
			)
			let tiebreakDirection = try parseFieldOrderTiebreaker(&input) ?? inherited?.tiebreakDirection ?? .ascending
			return switch optionSet.source {
			case .input:
				.byName(optionSet, tiebreakDirection: tiebreakDirection)
			case .output:
				.byLabel(optionSet, tiebreakDirection: tiebreakDirection)
			}
		}
		let inherited: (optionSet: OrderOptionSet, tiebreakDirection: SortOptionSet.Direction)? =
			if order == documentOrderOption, case let .document(optionSet, tiebreakDirection) = inheritedFieldOrder {
				(optionSet, tiebreakDirection)
			} else if order == positionalOrderOption, case let .positional(optionSet) = inheritedFieldOrder {
				(optionSet, .ascending)
			} else {
				nil
			}
		var optionSet = inherited?.optionSet ?? .init()
		while let char = input.first, char != fieldSpecSeparator, !itemSortAndFieldSpecEditsPrefixSet.contains(char) {
			if let direction = SortOptionSet.Direction(rawValue: char) {
				optionSet.direction = direction
			} else if let comparison = OrderOptionSet.UnpositionedFieldComparison(rawValue: char) {
				optionSet.unpositionedFieldComparison = comparison
			} else if let placement = OrderOptionSet.UnpositionedFieldPlacement(rawValue: char) {
				optionSet.unpositionedFieldPlacement = placement
			}
			input.removeFirst()
		}
		let tiebreakDirection = try parseFieldOrderTiebreaker(&input)
		return switch (order, outputFormat, tiebreakDirection) {
		case (positionalOrderOption, _, nil):
			reversingPositions(optionSet, inheritedDirection: inherited?.optionSet.direction ?? .ascending)
		case (positionalOrderOption, _, _): // `<field-order-tiebreaker>` is only for a field order other than `P`
			throw .tiebreakerUnsupportedForPositionalOrder
		case (_, .table, _): // `<document-order-option-set>` is `(* only for: JSON or key-value output *)`
			throw .documentOrderUnsupportedForTable
		default:
			.document(optionSet, tiebreakDirection: tiebreakDirection ?? inherited?.tiebreakDirection ?? .ascending)
		}
	}

	/// Parses `<item-sort-section>`: `<item-sort-section-prefix>` followed by
	/// `<item-sort-option-set>` (`<item-sort-option>+`, last wins per setting).
	/// `<disable-all-sorts>` disables each field spec's `<sort>`, retaining its
	/// `<sort-priority>` & `<sort-option>`s; `<direction>` is the item-sort
	/// tiebreak (input order / reverse input order). An absent section or
	/// `<direction>` retains `inheritedDirection`.
	mutating func parseItemSortSection(
		_ input: inout Substring,
		inheriting inheritedDirection: SortOptionSet.Direction,
	) throws(ParsingError) -> SortOptionSet.Direction {
		guard input.hasPrefix(itemSortSectionPrefix) else {
			return inheritedDirection
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
		return direction ?? inheritedDirection
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
					modifiersInput: &input,
				)
			case .overlay:
				// A `<named-field-spec-reference>` whose `<reference-field-name>` names
				// no field spec, or a `<field-spec-reference>` that resolves to a
				// `null`, inserts a new field spec (as `<field-spec-insertion>` would)
				// as `source`, replacing any such `null`, as for each
				// `<reference-sourced-field-spec-edit>` other than
				// `<field-spec-removal>`
				let (reference, restored, existing) = try parseInsertingReference(&input)
				try apply(
					reference.map { .overlay($0, isHidden: false) } ?? .insert(isHidden: false, restoring: restored),
					name: existing.name,
					existing: existing,
					modifiersInput: &input,
				)
			case .move:
				let (reference, restored, existing) = try parseInsertingReference(&input)
				try apply(
					reference.map(ResolvedStrategy.move) ?? .insert(isHidden: false, restoring: restored),
					name: existing.name,
					existing: existing,
					modifiersInput: &input,
				)
			case .hide:
				let (reference, restored, existing) = try parseInsertingReference(&input)
				try apply(
					reference.map { .overlay($0, isHidden: true) } ?? .insert(isHidden: true, restoring: restored),
					name: existing.name,
					existing: existing,
					modifiersInput: &input,
				)
			case .removal:
				// A `<field-spec-removal>`'s `<reference-field-name>` has no modifiers
				// to terminate it
				switch try parseReference(&input, nameTerminatorSet: [fieldOccurrenceIndexPrefix, fieldSpecSeparator]) {
				case let .resolved(reference):
					_ = try resolvedReferenceFieldSpec(reference) // Validates existence
					remove(reference)
				case let .unmatched(name):
					_ = try defaultFieldSpec(forName: name) // Validates that it is not a nonexistent field
					removedUnmatchedFieldNameSet.insert(name)
				}
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
				terminatorSet: [
					presetPrefix,
					labelModifierPrefix,
					formatModifierPrefix,
					sortModifierPrefix,
					fieldSpecSeparator,
				],
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
				modifiersInput: &input,
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

	/// `.positional(optionSet)`, after reversing the positions of the working &
	/// reference field specs iff `optionSet`'s direction differs from
	/// `inheritedDirection` (the working fields config's `<positional-order>`
	/// `<direction>`, which already reversed its positions iff `.descending`),
	/// before `<field-spec-edits-section>`, so its edits & each `<index>` apply
	/// to the reversed positions. No edit precedes `<field-order-section>`, so
	/// `workingTags` remains the identity mapping.
	private mutating func reversingPositions(
		_ optionSet: OrderOptionSet,
		inheritedDirection: SortOptionSet.Direction,
	) -> FieldOrder {
		if optionSet.direction != inheritedDirection {
			fieldSpecs.reverse()
			referenceFieldSpecs.reverse()
		}
		return .positional(optionSet)
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
/// top-level character is a `<direction>`, an
/// `<unpositioned-field-comparison>`, an `<unpositioned-field-placement>`, or
/// an `<order>`, with at least 1 `<order>` (last wins). `nil` means it is a
/// `<sort-option-set>` instead: the alternatives share no valid text (a
/// sequence with no `<order>` can only be `<sort-option-set>`), so checking
/// without consuming `input` is safe.
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
				|| OrderOptionSet.UnpositionedFieldComparison(rawValue: char) != nil
				|| OrderOptionSet.UnpositionedFieldPlacement(rawValue: char) != nil
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
	private enum ParsedReference {
		case resolved(Reference)
		/// A `<named-field-spec-reference>` without a `<field-occurrence-index>`
		/// whose `<reference-field-name>` names no field spec.
		case unmatched(name: String)
	}

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
				position: try normalizedPosition(
					forIndex: parseIndex(&input, ifMissing: .missingFieldSpecIndex),
					length: baselineFieldSpecs.count,
				),
			)
		}
		let (name, index) = try parseNameAndIndex(&input, nameTerminatorSet: nameTerminatorSet)
		return try namedReference(name: name, index: index, positions: referencePositions(forName: name))
	}

	/// Parses a `<field-spec-reference>` for a
	/// `<baseline-sourced-field-spec-edit>` & resolves its `source` from the
	/// baseline fields config (as in the reference fields config, except that a
	/// `<named-field-spec-reference>` without a `<field-occurrence-index>` whose
	/// `<reference-field-name>` names no field spec selects the default field
	/// spec for field `<reference-field-name>`).
	private func parseBaselineSourcedFieldSpec(_ input: inout Substring) throws(ParsingError) -> FieldSpec {
		guard input.first != fieldSpecIndexPrefix else {
			return baselineFieldSpecs[try normalizedPosition(
				forIndex: parseIndex(&input, ifMissing: .missingFieldSpecIndex),
				length: baselineFieldSpecs.count,
			) - 1]
		}
		let (name, index) = try parseNameAndIndex(&input)
		let positions = referencePositions(forName: name)
		guard !positions.isEmpty || index != nil else {
			return try defaultFieldSpec(forName: name)
		}
		return baselineFieldSpecs[try namedReference(name: name, index: index, positions: positions).position - 1]
	}

	/// Parses a `<reference-sourced-field-spec-edit>`'s `<field-spec-reference>`:
	/// its resolved reference, or, iff it is a `<named-field-spec-reference>`
	/// without a `<field-occurrence-index>` whose `<reference-field-name>` names
	/// no field spec (e.g., for an unlisted field), the reference to the field
	/// spec that an earlier `<reference-sourced-field-spec-edit>` inserted for
	/// that name, if not since removed, else that name.
	private func parseReference(
		_ input: inout Substring,
		nameTerminatorSet: Set<Character> = modifiedFieldNameTerminatorSet,
	) throws(ParsingError) -> ParsedReference {
		guard input.first != fieldSpecIndexPrefix else {
			return .resolved(try parseFieldSpecReference(&input))
		}
		let (name, index) = try parseNameAndIndex(&input, nameTerminatorSet: nameTerminatorSet)
		let positions = referencePositions(forName: name)
		return if !positions.isEmpty || index != nil {
			.resolved(try namedReference(name: name, index: index, positions: positions))
		} else if
			let position = unmatchedReferencePositionByName[name],
			referenceFieldSpecs[position - 1] != nil
		{
			.resolved(.init(name: name, position: position))
		} else {
			.unmatched(name: name)
		}
	}

	/// Parses a `<field-spec-overlay>`'s, a `<field-spec-move>`'s, or a
	/// `<field-spec-hide>`'s `<field-spec-reference>`: the resolved reference &
	/// its `source` from the reference fields config; or, iff it names no field
	/// spec, or the reference resolves to a `null` (a field spec removed earlier
	/// in this section), `nil` & the field spec that a `<field-spec-insertion>`
	/// would insert (copied from the baseline fields config, or a default field
	/// spec), with the reference to the `null`, or to a new `null` for that name
	/// in `referenceFieldSpecs`, as `restored`, so the inserted field spec
	/// replaces the `null`.
	private mutating func parseInsertingReference(_ input: inout Substring)
	throws(ParsingError) -> (reference: Reference?, restored: Reference?, source: FieldSpec) {
		switch try parseReference(&input) {
		case let .resolved(reference):
			referenceFieldSpecs[reference.position - 1].map { (reference, nil, $0) }
				?? (nil, reference, baselineFieldSpecs[reference.position - 1])
		case let .unmatched(name):
			(nil, unmatchedReference(forName: name), try defaultFieldSpec(forName: name))
		}
	}

	/// The reference to the `null` in `referenceFieldSpecs` for field `name`,
	/// which names no field spec in the reference fields config, appending one
	/// iff no earlier `<reference-sourced-field-spec-edit>` inserted a field spec
	/// for it.
	private mutating func unmatchedReference(forName name: String) -> Reference {
		let position = unmatchedReferencePositionByName[name] ?? referenceFieldSpecs.count + 1
		if position > referenceFieldSpecs.count {
			referenceFieldSpecs.append(nil)
			unmatchedReferencePositionByName[name] = position
		}
		return .init(name: name, position: position)
	}

	/// The reference to the field spec for field `name` at `index` (`nil` iff
	/// absent, meaning `1`) among `positions`, the positions of field `name`'s
	/// field specs in the reference fields config.
	private func namedReference(name: String, index: Int?, positions: [Int]) throws(ParsingError) -> Reference {
		guard !positions.isEmpty else {
			throw .nonexistentFieldSpec(forName: name)
		}
		return .init(
			name: name,
			position: positions[try normalizedPosition(forIndex: index ?? 1, length: positions.count) - 1],
		)
	}

	/// The default field spec for field `name`, which must not be a nonexistent
	/// field: labeled by name & formatted as `%i` for a machine-facing base
	/// fields config, else per `builtInFieldSpec(forFieldNamed:)` (mas.md
	/// "Built-In Field Specs").
	private func defaultFieldSpec(forName name: String) throws(ParsingError) -> FieldSpec {
		guard fieldNameSet?.contains(name) != false else {
			throw .nonexistentField(name)
		}
		// swiftlint:disable:next todo
		// TODO: Temp/todo.md "Persistent Custom Presets & Configs": overlay a
		//  custom `default` preset, if one exists, then disable its sort after a
		//  `<disable-all-sorts>` in this or an extended fields config (including
		//  `none`'s last item-sort option)
		return isMachineFacing ? .default(forName: name) : builtInFieldSpec(forFieldNamed: name)
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
	/// `<field-occurrence-index-prefix>` `<field-occurrence-index>` (`nil` iff
	/// absent).
	private func parseNameAndIndex(
		_ input: inout Substring,
		nameTerminatorSet: Set<Character> = modifiedFieldNameTerminatorSet,
	) throws(ParsingError) -> (name: String, index: Int?) {
		let name = try parseFieldName(&input, terminatorSet: nameTerminatorSet)
		return (
			name,
			input.first == fieldOccurrenceIndexPrefix
				? try parseIndex(&input, ifMissing: .missingFieldOccurrenceIndex)
				: nil,
		)
	}

	/// Parses an `<index>`'s prefix & its required `<index>`, throwing
	/// `missingError` absent the latter.
	private func parseIndex(_ input: inout Substring, ifMissing missingError: ParsingError)
	throws(ParsingError) -> Int {
		input.removeFirst()
		input = input.drop(while: \.isWhitespace)
		guard let text = parseIntegerText(&input, isSigned: true, allowsLeadingZeros: true) else {
			throw missingError
		}
		// An index beyond `Int`'s range is beyond every position
		guard let index = Int(text) else {
			throw .invalidPosition(text)
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
		/// Inserts a field spec, which replaces the `null` at `restoring`'s
		/// position in the reference fields config iff non-`nil`.
		case insert(isHidden: Bool, restoring: Reference? = nil)
		case move(Reference)
		case overlay(Reference, isHidden: Bool)
	}

	private mutating func apply(
		_ strategy: ResolvedStrategy,
		name: String,
		existing: FieldSpec?,
		modifiersInput input: inout Substring,
	) throws(ParsingError) {
		let presetNames = try parsePresetModifier(&input, attached: existing?.presetNames ?? [defaultConfigName])
		let label = try parseLabel(&input)
		let format = try parseFormat(&input)
		let isHidden = switch strategy {
		case let .insert(isHidden, _), let .overlay(_, isHidden):
			isHidden
		case .move:
			false
		}
		let merged = FieldSpec(
			name: name,
			label: label ?? existing?.label ?? name,
			format: format ?? existing?.format ?? .default(fieldName: name),
			sortSpec: // swiftformat:disable:next indent
				try parseSortSpecModifier(&input, existing: existing?.sortSpec, fieldName: name, outputFormat: outputFormat),
			isHidden: isHidden,
			isSynthesized: existing?.isSynthesized ?? false,
			presetNames: presetNames,
			alignment: existing?.baseAlignment ?? .start,
		)
		switch strategy {
		case let .insert(_, restored):
			let newIndex = previousIndex + 1
			fieldSpecs.insert(merged, at: newIndex)
			workingTags.insert(restored.map { $0.position - 1 }, at: newIndex)
			if let restored {
				referenceFieldSpecs[restored.position - 1] = merged
			}
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
/// format.
private func parseFormat(_ input: inout Substring) throws(ParsingError) -> Format? {
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

/// Consumes the longest integer variable token at the start of `input` (1 or
/// more ASCII digits, the 1st of which is not `0` unless `allowsLeadingZeros`,
/// preceded by an optional `+` or `-` iff `isSigned`; each bare or escaped),
/// returning its value's text (sans escape prefixes); else `nil`, consuming
/// nothing.
func parseIntegerText(_ input: inout Substring, isSigned: Bool, allowsLeadingZeros: Bool) -> String? {
	// The unescaped character that `text` starts with, with the count of
	// characters that denote it
	func unescapedFirst(_ text: Substring) -> (char: Character, count: Int)? {
		text.first == escapePrefix ? text.dropFirst().first.map { ($0, 2) } : text.first.map { ($0, 1) }
	}
	var rest = input
	var text = ""
	if isSigned, let sign = unescapedFirst(rest), sign.char == "+" || sign.char == "-" {
		text.append(sign.char)
		rest.removeFirst(sign.count)
	}
	let signCount = text.count
	while
		let digit = unescapedFirst(rest),
		digit.char.isASCIIDigit,
		allowsLeadingZeros || text.count > signCount || digit.char != "0"
	{
		text.append(digit.char)
		rest.removeFirst(digit.count)
	}
	guard text.count > signCount else {
		return nil
	}
	input = rest
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
private let modifiedFieldNameTerminatorSet = Set([
	fieldOccurrenceIndexPrefix,
	presetPrefix,
	labelModifierPrefix,
	formatModifierPrefix,
	sortModifierPrefix,
	fieldSpecSeparator,
])

private let positionalOrderOption = Character("P")
private let documentOrderOption = Character("D")
private let orderOptionSet = Set([positionalOrderOption, documentOrderOption])
private let disableAllSortsOption = Character("0")

private let outputFormatSuffixSet = Set(["json", "key-value", "table"] as [Substring])
private let outputFormatSuffixPrefix = Character("@")
private let unsuffixedVariantReferenceSuffix = "@unsuffixed"

let defaultConfigName = "default"
let noneFieldsConfigName = "none"
let allFieldsConfigName = "all"
let standardConfigName = "standard"
