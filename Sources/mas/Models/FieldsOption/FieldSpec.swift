//
// FieldSpec.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

// MARK: Internal types

struct FieldSpec: Equatable {
	let name: String
	let label: String
	let format: Format
	let sortSpec: SortSpec?
	/// Whether this field's value is computed after the display command's own
	/// fetch (e.g., `outdated`'s `newVersion`, from comparing the installed &
	/// latest versions), so it's never itself something to fetch.
	let isSynthesized: Bool
	/// Table-only column alignment (ignored by `json` / `keyValue` output, which
	/// have no column to align). Set directly by a display command's own
	/// `standard` / `all` fields config (see
	/// `defaultJustification(forFieldNamed:)` in `AppStoreFieldDefaults.swift`),
	/// or by a `--fields`
	/// `<format-transform-pipeline>` (see `parseFormat(_:fieldName:)` below).
	let justification: Justification

	init(
		name: String,
		label: String,
		format: Format,
		sortSpec: SortSpec?,
		isSynthesized: Bool = false,
		justification: Justification = .start,
	) {
		self.name = name
		self.label = label
		self.format = format
		self.sortSpec = sortSpec
		self.isSynthesized = isSynthesized
		self.justification = justification
	}
}

extension FieldSpec: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		"""
		FieldSpec(name: "\(name)", label: "\(label)", format: \(format), sortSpec: \(
			sortSpec.map(String.init(describing:)) ?? "nil"
		), justification: \(justification))
		"""
	}
}

// MARK: Errors

enum ParsingError: Equatable, Error, CustomStringConvertible { // swiftlint:disable:this one_declaration_per_file
	case coercionNotApplicable(kind: String)
	case coercionNotSupported(Character)
	case danglingEscape
	case hiddenFormatFollowedByContent
	case incompletePipelineTerminator
	case invalidBaseFieldsConfigName(String)
	case invalidCharacterClass(String)
	case invalidLetter(Character)
	case invalidPosition(Int)
	case invalidSortOption(Character)
	case invalidTransform(name: String, expectedKind: String)
	case invalidTransformArguments(name: String)
	case missingEndFence
	case missingFieldName
	case missingSortPriority
	case nonexistentFieldSpec(forName: String)
	case singleBranch
	case templateLacksPlaceholder
	case terminalNumberTransformFollowedByMore(name: String)
	case unknownNamedFormat(String)
	case unsupportedDateInputFormat
	case unsupportedDateOutputFormat

	var description: String {
		switch self {
		case let .coercionNotApplicable(kind):
			"""
			Coercion (a doubled '.') isn't applicable to \(kind)-kind value transforms: a string value never \
			needs coercion, & a date value is already parsed permissively (string or numeric) regardless
			"""
		case let .coercionNotSupported(letter):
			"Coercion ('.') isn't supported for placeholder letter: \(letter)"
		case .danglingEscape:
			"Expected a character to escape after trailing '\\'"
		case .hiddenFormatFollowedByContent:
			"'\(hiddenNamedFormatName)' must be the entire format-modifier; nothing may follow it"
		case .incompletePipelineTerminator:
			"Expected another ':' to complete the pipeline terminator '::'"
		case let .invalidBaseFieldsConfigName(baseFieldsConfigName):
			"Invalid base fields config name: \(baseFieldsConfigName)"
		case let .invalidCharacterClass(name):
			"Invalid character class: \(name)"
		case let .invalidLetter(letter):
			"Invalid placeholder letter: \(letter)"
		case let .invalidPosition(index):
			"Invalid position for index: \(index)"
		case let .invalidSortOption(sortOption):
			"Invalid sort option: \(sortOption)"
		case let .invalidTransform(name, expectedKind):
			"Invalid \(expectedKind) transform: \(name)"
		case let .invalidTransformArguments(name):
			"Invalid arguments for transform: \(name)"
		case .missingEndFence:
			"Expected end fence"
		case .missingFieldName:
			"Expected field name"
		case .missingSortPriority:
			"Expected a numeric sort priority (only the field's existing sort options may be adjusted without one)"
		case let .nonexistentFieldSpec(name):
			"""
			Expected existing field spec for field name: \(
				name.isEmpty || name.first?.isWhitespace == true || name.last?.isWhitespace == true ? "'\(name)'" : name
			)
			"""
		case .singleBranch:
			"<branches> needs at least 2 branches; a single 1 is just an ordinary placeholder, with no need for %b / %B"
		case .templateLacksPlaceholder:
			"A template needs at least 1 placeholder (e.g., %v); its output would otherwise never depend on the value"
		case let .terminalNumberTransformFollowedByMore(name):
			"'\(name)' must be the last transform in its number-transform-pipeline; nothing may follow it"
		case let .unknownNamedFormat(name):
			"Unknown named format: \(name)"
		case .unsupportedDateInputFormat:
			"A custom <input-date-format> isn't supported yet; omit it (input is always auto-detected)"
		case .unsupportedDateOutputFormat:
			"""
			A named format or literal pattern isn't supported yet for a date's output format; \
			use a bare date-transform-pipeline (e.g., .iso, .dateOnly) instead
			"""
		}
	}
}

// MARK: - Entry points

/// Phase 1 (pre-fetch): the field names a display command needs to fetch for
/// `fieldsOptionValue` to be fully resolvable, given `standard`'s & `all`'s
/// _selected_ field specs (not yet merged with any dynamically-discovered
/// data). Never includes a synthesized field's name (see
/// `FieldSpec.isSynthesized`), since fetching it would be meaningless.
/// Empty means "fetch everything".
func fetchFieldNames(
	for fieldsOptionValue: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
) throws -> [String] {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	switch input.first {
	case baseFieldsConfigSectionPrefix, fieldOrderSectionPrefix, fieldSpecsSectionPrefix, nil:
		var baseName = ""
		if input.first == baseFieldsConfigSectionPrefix {
			input.removeFirst()
			baseName = try parseEscapedText(&input, terminatorSet: [fieldOrderSectionPrefix, fieldSpecsSectionPrefix])
		}
		let base = try resolveBaseFieldsConfig(named: baseName, standard: standard, all: all, outputFormat: outputFormat)
		guard !base.baseIncludesAllFields else {
			return .init()
		}
		try skipFieldOrderAndItemSortSections(&input, outputFormat: outputFormat)
		return .init(
			Set(base.fieldSpecs.compactMap { $0.isSynthesized ? nil : $0.name })
				.union(try topLevelFieldSpecNames(in: input, requiringPrefix: insertIndicator)),
		)
	default:
		return try topLevelFieldSpecNames(in: input, requiringPrefix: nil)
	}
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
) throws -> any FieldsConfig {
	var input = fieldsOptionValue[...].drop(while: \.isWhitespace)
	switch input.first {
	case baseFieldsConfigSectionPrefix, fieldOrderSectionPrefix, fieldSpecsSectionPrefix, nil:
		var baseName = ""
		if input.first == baseFieldsConfigSectionPrefix {
			input.removeFirst()
			baseName = try parseEscapedText(&input, terminatorSet: [fieldOrderSectionPrefix, fieldSpecsSectionPrefix])
		}
		let base = try resolveBaseFieldsConfig(named: baseName, standard: standard, all: all, outputFormat: outputFormat)
		var builder = FieldSpecsBuilder(fieldSpecs: base.fieldSpecs, outputFormat: outputFormat)
		let parsedFieldOrder = try builder.parseFieldOrderSection(&input)
		let fieldOrder = parsedFieldOrder == .inherited ? base.fieldOrder : parsedFieldOrder
		let tiebreakDirection = try builder.parseItemSortSection(&input)
		try builder.parseFieldSpecsSection(&input)
		let itemSort = ItemSort(
			keys: builder.fieldSpecs
				.compactMap { fieldSpec in fieldSpec.sortSpec.map { .init(name: fieldSpec.name, sortSpec: $0) } },
			tiebreakDirection: tiebreakDirection,
		)
		return base.baseIncludesAllFields
			? BaseIncludesAllFieldsConfig(fieldSpecs: builder.fieldSpecs, fieldOrder: fieldOrder, itemSort: itemSort)
			: SelectedFieldsConfig(fieldSpecs: builder.fieldSpecs, fieldOrder: fieldOrder, itemSort: itemSort)
	default:
		var builder = FieldSpecsBuilder(fieldSpecs: .init(), outputFormat: outputFormat)
		try builder.parseAbsoluteConfig(&input)
		return SelectedFieldsConfig(
			fieldSpecs: builder.fieldSpecs,
			fieldOrder: .inherited,
			itemSort: .init(
				keys: builder.fieldSpecs
					.compactMap { fieldSpec in fieldSpec.sortSpec.map { .init(name: fieldSpec.name, sortSpec: $0) } },
				tiebreakDirection: .ascending,
			),
		)
	}
}

// MARK: - Base fields config resolution

/// Resolves a `<base-fields-config-name>` (already stripped of its
/// `<base-fields-config-section-prefix>`, empty if absent) against `standard`
/// & `all`, applying the universal built-in rules: `none`, `all`, `default` (⇒
/// `standard`, absent a persisted custom `default`, which doesn't exist yet),
/// the `@none` / `@<format>` suffixes, & the `standard@json` ⇒ `all`
/// substitution. Any other name is an error: no other named fields configs are
/// persisted yet.
func resolveBaseFieldsConfig(
	named rawName: String,
	standard: some FieldsConfig,
	all: BaseIncludesAllFieldsConfig,
	outputFormat: OutputFormat,
) throws(ParsingError) -> any FieldsConfig {
	var name = rawName.isEmpty ? defaultFieldsConfigName : rawName
	var appliesJSONSubstitution = outputFormat == .json
	if let atIndex = name.lastIndex(of: "@") {
		let suffix = String(name[name.index(after: atIndex)...])
		if suffix == "none" {
			name = .init(name[..<atIndex])
			appliesJSONSubstitution = false
		} else if outputFormatSuffixSet.contains(suffix) {
			name = .init(name[..<atIndex])
			appliesJSONSubstitution = suffix == "json" && outputFormat == .json
		}
	}
	return switch name {
	case noneFieldsConfigName:
		SelectedFieldsConfig()
	case allFieldsConfigName:
		all.withDefaultFieldOrder(outputFormat: outputFormat).defaultedForJSON(outputFormat: outputFormat)
	case defaultFieldsConfigName, standardFieldsConfigName:
		appliesJSONSubstitution // swiftlint:disable:next void_function_in_ternary
			? all.withDefaultFieldOrder(outputFormat: outputFormat).defaultedForJSON(outputFormat: outputFormat)
			: standard.defaultedForJSON(outputFormat: outputFormat)
	default:
		throw .invalidBaseFieldsConfigName(rawName)
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
	case remove // swiftlint:enable sorted_enum_cases
}

/// Applies `<field-order-section>` / `<item-sort-section>` /
/// `<field-specs-section>` against a baseline `[FieldSpec]`, producing the
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
	private var referenceFieldSpecs: [FieldSpec?]
	/// "$previous$": the working index after which the next insert / move's
	/// direct result lands. `-1` = before the first field spec.
	private var previousIndex = -1

	init(fieldSpecs: [FieldSpec], outputFormat: OutputFormat) {
		self.fieldSpecs = fieldSpecs
		self.outputFormat = outputFormat
		workingTags = Array(fieldSpecs.indices)
		referenceFieldSpecs = fieldSpecs
	}

	mutating func parseFieldOrderSection(_ input: inout Substring) throws -> FieldOrder {
		guard input.first == fieldOrderSectionPrefix, !input.hasPrefix(itemSortSectionPrefix) else {
			return .inherited
		}
		input.removeFirst()
		guard let first = input.first, first != fieldSpecSeparator, !itemSortAndFieldSpecsPrefixSet.contains(first) else {
			return .workingOrder
		}
		guard !isOriginalOrderOptionSet(input) else {
			var direction = SortSpec.Direction?.none
			while let char = input.first, char != fieldSpecSeparator, !itemSortAndFieldSpecsPrefixSet.contains(char) {
				if let match = SortSpec.Direction(rawValue: char) {
					direction = match
				}
				input.removeFirst()
			}
			return .original(direction)
		}
		let sortSpec = try SortSpec.parsedOptionSet(
			&input,
			nextSectionPrefixSet: itemSortAndFieldSpecsPrefixSet,
			priority: 0,
			defaults: .textDefault(outputFormat: outputFormat),
		)
		return switch sortSpec.source {
		case .input:
			.byName(sortSpec)
		case .output:
			.byLabel(sortSpec)
		}
	}

	/// Neither reset option resets anything unless explicitly given (per
	/// fields.md's "default: inherited item sorting" for an absent
	/// `<item-sort-option-set>`): a bare `//` or `//a` only sets / keeps
	/// `tiebreakDirection`, leaving every field's inherited `sortSpec` alone.
	/// When a reset _is_ given, each currently-sorted field's options (not
	/// priority) are replaced with the contextual "Default Sort Options" row for
	/// its name & the active output format.
	/// TODO: distinguish `<reset-to-global>` ("R") from `<reset-to-contextual>`
	///  ("r") once persisted fields configs exist: absent persistence, there's no
	///  separate "global" tier to reset to, so both currently apply the same
	///  built-in contextual defaults.
	mutating func parseItemSortSection(_ input: inout Substring) throws(ParsingError) -> SortSpec.Direction {
		guard input.hasPrefix(itemSortSectionPrefix) else {
			return .ascending
		}
		input.removeFirst(itemSortSectionPrefix.count)
		var shouldReset = false
		var direction = SortSpec.Direction.ascending
		try parseOptions(
			&input,
			nextSectionPrefixSet: [fieldSpecsSectionPrefix],
		) { input, currentIndex, char throws(ParsingError) in
			if let match = SortSpec.Direction(rawValue: char) {
				direction = match
			} else {
				switch char {
				case resetToContextual, resetToGlobal:
					shouldReset = true
				default:
					input = input[currentIndex...]
					throw .invalidSortOption(char)
				}
			}
		}
		if shouldReset {
			fieldSpecs = fieldSpecs.map(resetToContextualSortDefaults)
			referenceFieldSpecs = referenceFieldSpecs.map { $0.map(resetToContextualSortDefaults) }
		}
		return direction
	}

	mutating func parseFieldSpecsSection(_ input: inout Substring) throws {
		guard input.first == fieldSpecsSectionPrefix else {
			return
		}
		input.removeFirst()
		while !input.isEmpty {
			switch parseFieldSpecStrategy(&input) {
			case .insert:
				let name = try parseName(&input)
				try apply(
					.insert,
					name: name,
					existing: nil,
					label: try parseLabel(&input),
					format: try parseFormat(&input, fieldName: name),
					sortModifierInput: &input,
				)
			case .overlay:
				let reference = try parseFieldSpecReference(&input)
				let existing = try resolvedReferenceFieldSpec(reference)
				try apply(
					.overlay(reference),
					name: existing.name,
					existing: existing,
					label: try parseLabel(&input),
					format: try parseFormat(&input, fieldName: existing.name),
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
					format: try parseFormat(&input, fieldName: existing.name),
					sortModifierInput: &input,
				)
			case .remove:
				let reference = try parseFieldSpecReference(&input)
				_ = try resolvedReferenceFieldSpec(reference) // Validates existence
				remove(reference)
			}
			guard input.first == fieldSpecSeparator else {
				break
			}
			input.removeFirst()
		}
		guard input.isEmpty else {
			throw ParsingError.missingFieldName
		}
	}

	mutating func parseAbsoluteConfig(_ input: inout Substring) throws {
		while true {
			let name = try parseName(&input)
			let label = try parseLabel(&input) ?? name
			let parsed = try parseFormat(&input, fieldName: name)
			fieldSpecs.append(
				.init(
					name: name,
					label: label,
					format: parsed?.format ?? .default(fieldName: name),
					sortSpec: try parseSortSpecModifier(&input, existing: nil, fieldName: name, outputFormat: outputFormat),
					justification: parsed?.justification ?? .start,
				),
			)
			guard !input.isEmpty else {
				return
			}
			guard input.first == fieldSpecSeparator else {
				throw ParsingError.missingFieldName
			}
			input.removeFirst()
		}
	}

	/// `fieldSpec` unchanged if it has no `sortSpec` (nothing to reset);
	/// otherwise, its `sortSpec`'s options (not priority) replaced with the
	/// contextual "Default Sort Options" row for its name & `outputFormat`.
	private func resetToContextualSortDefaults(_ fieldSpec: FieldSpec) -> FieldSpec {
		fieldSpec.sortSpec.map { sortSpec in
			let contextualDefault = defaultSortSpec(forFieldNamed: fieldSpec.name, outputFormat: outputFormat)
			return .init(
				name: fieldSpec.name,
				label: fieldSpec.label,
				format: fieldSpec.format,
				sortSpec: .init(
					priority: sortSpec.priority,
					source: contextualDefault.source,
					direction: contextualDefault.direction,
					caseSensitivity: contextualDefault.caseSensitivity,
					localization: contextualDefault.localization,
					grouping: contextualDefault.grouping,
					interpretation: contextualDefault.interpretation,
					boundaries: contextualDefault.boundaries,
				),
				justification: fieldSpec.justification,
			)
		}
			?? fieldSpec
	}
}

/// Whether `input`'s `<field-order-option-set>` (up to, but not including, its
/// terminating `<field-spec-separator>` / `<item-sort-section-prefix>` /
/// `<field-specs-section-prefix>`) is an `<original-order-option-set>`: every
/// top-level character is in `{"o", "a", "d"}`, with at least 1 `"o"` (its
/// mandatory `<original-order>`). Any other top-level character (including 1
/// that introduces a fenced `<sort-option>`, e.g., `"l"` / `"b"`) means it's a
/// `<sort-option-set>` instead: the 2 alternatives share no valid text (an
/// all-`{"a", "d"}` sequence with no `"o"` can only be `<sort-option-set>`,
/// since `<original-order-option-set>` requires `"o"`), so checking without
/// consuming `input` is safe: only 1 alternative ever actually gets parsed.
private func isOriginalOrderOptionSet(_ input: Substring) -> Bool {
	var sawOriginalOrder = false
	for char in input {
		if char == fieldSpecSeparator || itemSortAndFieldSpecsPrefixSet.contains(char) {
			break
		}
		guard char == originalOrderOption else {
			guard SortSpec.Direction(rawValue: char) != nil else {
				return false
			}
			continue
		}
		sawOriginalOrder = true
	}
	return sawOriginalOrder
}

// MARK: Private: field-spec-reference resolution

private extension FieldSpecsBuilder {
	private struct Reference {
		let name: String?
		let position: Int
	}

	private func parseFieldSpecReference(_ input: inout Substring) throws(ParsingError) -> Reference {
		guard input.first != indexPrefix else {
			input.removeFirst()
			return .init(
				name: nil,
				position: try effectivePosition(forIndex: parseInt(&input) ?? 1, length: referenceFieldSpecs.count),
			)
		}
		let name = try parseName(&input, extraTerminatorSet: [indexPrefix])
		var index = 1
		if input.first == indexPrefix {
			input.removeFirst()
			index = parseInt(&input) ?? 1
		}
		let matchingPositions = referenceFieldSpecs.indices.filter { referenceFieldSpecs[$0]?.name == name }
		return .init(
			name: name,
			position: matchingPositions[try effectivePosition(forIndex: index, length: matchingPositions.count) - 1] + 1,
		)
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
		case insert
		case overlay(Reference)
		case move(Reference)
	}

	private mutating func apply(
		_ strategy: ResolvedStrategy,
		name: String,
		existing: FieldSpec?,
		label: String?,
		format: (format: Format, justification: Justification)?,
		sortModifierInput input: inout Substring,
	) throws {
		let merged = FieldSpec(
			name: name,
			label: label ?? existing?.label ?? name,
			format: format?.format ?? existing?.format ?? .default(fieldName: name),
			sortSpec: // swiftformat:disable:next indent
				try parseSortSpecModifier(&input, existing: existing?.sortSpec, fieldName: name, outputFormat: outputFormat),
			justification: format?.justification ?? existing?.justification ?? .start,
		)
		switch strategy {
		case .insert:
			let newIndex = previousIndex + 1
			fieldSpecs.insert(merged, at: newIndex)
			workingTags.insert(nil, at: newIndex)
			previousIndex = newIndex
		case let .overlay(reference):
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
	guard
		let strategy = input.first.flatMap(
			{ char in
				switch char {
				case insertIndicator:
					FieldSpecStrategy.insert
				case moveIndicator:
					.move
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
	guard input.first == labelModifierPrefix else {
		return nil
	}
	input.removeFirst()
	return try parseEscapedText(&input, terminatorSet: [formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator])
}

/// Parses `<format>`: at least 1 of `<named-format>`,
/// `<format-transform-pipeline>`, `<value-transform-pipeline>`, `<template>`,
/// in that order (see fields-formatting.md for the full 4-branch grammar).
/// `<format-transform-pipeline>` (currently just `<justify-transform>`) is
/// recognized only here, right after the optional named format & before
/// anything else, never inside a placeholder's own success / failure
/// sub-format (`parseDelimitedFormat` / `parseDateSpec` in `Format.swift` don't
/// call this). A name / transform name never stops at `<placeholder-prefix>`
/// on its own: `.uppercase%v` is an attempt at a transform literally named
/// `uppercase%v` (& fails as one), not `.uppercase` followed by a `%v`
/// placeholder; a `<pipeline-terminator>` (or `.` for another transform) is
/// what actually separates them; see `parseTrailingTemplate(_:terminatorSet:
/// endedWithClosedArgumentFence:)` for exactly when 1 is required.
private func parseFormat(_ input: inout Substring, fieldName: String)
throws(ParsingError) -> (format: Format, justification: Justification)? {
	guard input.first == formatModifierPrefix else {
		return nil
	}
	input.removeFirst()
	let terminatorSet = Set([sortModifierPrefix, fieldSpecSeparator])
	guard let first = input.first, !terminatorSet.contains(first) else {
		// `<format-modifier>` present, `<format>` absent: reset to the contextual
		// default
		return (.default(fieldName: fieldName), .start)
	}
	var namedFormat = String?.none
	if first == namePrefix {
		input.removeFirst()
		let name = try parseEscapedText(&input, terminatorSet: terminatorSet.union([transformCallPrefix, colon]))
		guard knownNamedFormatNameSet.contains(name) else {
			throw .unknownNamedFormat(name)
		}
		// `hidden` is special: unlike any other named format (once persisted named
		// formats exist), it precludes anything else in the format-modifier: a
		// hidden field is never rendered, so a trailing format-transform-pipeline,
		// value-transform-pipeline, or template would be dead configuration
		if name == hiddenNamedFormatName, let next = input.first, !terminatorSet.contains(next) {
			throw .hiddenFormatFollowedByContent
		}
		namedFormat = name
	}
	let justification = try parseFormatTransformPipeline(&input, terminatorSet: terminatorSet)
	let format =
		if input.first == transformCallPrefix {
			// A trailing `<value-transform-pipeline>` (`namedFormat` was already
			// consumed above, if present), optionally followed by a
			// `<pipeline-terminator>` & a template
			try parseValueTransformPipelineThenTemplate(&input, namedFormat: namedFormat, terminatorSet: terminatorSet)
		} else if namedFormat != nil || justification != nil {
			// `<named-format>` and/or `<format-transform-pipeline>` (no
			// `<value-transform-pipeline>`): a trailing template, if any, is gated by
			// `<pipeline-terminator>` exactly like a `<value-transform-pipeline>`'s
			// own; neither of these 2 ever ends with `:` on its own (`group` /
			// `scale`'s closing `<argument-fence>` is the only way anything here
			// does), so `endedWithClosedArgumentFence` is always `false`
			try parseTrailingTemplateOrNamedFormat(
				&input,
				namedFormat: namedFormat,
				fieldName: fieldName,
				terminatorSet: terminatorSet,
			)
		} else if let next = input.first, !terminatorSet.contains(next) {
			// No named format, no format transform survived (backtracked): a bare
			// `<template>` is `<format>`'s entire content, with nothing before it to
			// need a `<pipeline-terminator>` from
			try parseTemplate(&input, terminatorSet: terminatorSet)
		} else {
			// Nothing at all: implicit `%v`, preserving the value's real JSON type
			Format.default(fieldName: fieldName)
		}
	return (format, justification ?? .start)
}

/// Parses `<template>`, rejecting 1 with no `<placeholder>` at all: such a
/// `<template>` would render identically regardless of the field's value,
/// which is never useful, even for a `<format-transform-pipeline>`'s
/// (justify's) own template, which is otherwise exempt from everything else
/// about the field's value (justify never reads it), since the `<template>`
/// is still the field's entire rendering.
private func parseTemplate(_ input: inout Substring, terminatorSet: Set<Character>) throws(ParsingError) -> Format {
	let format = try FormatContentParser(terminatorSet: terminatorSet).parse(&input)
	guard !formatLacksPlaceholder(format) else {
		throw .templateLacksPlaceholder
	}
	return format
}

/// Whatever precedes a `<template>` (`<named-format>`, `<format-transform-
/// pipeline>`, and/or `<value-transform-pipeline>`), a trailing `<template>`
/// is optional, & a `<pipeline-terminator>` (`::`) is needed to introduce it
/// UNLESS `endedWithClosedArgumentFence` (only ever true right after a
/// `<value-transform-pipeline>` whose last `<transform>` is `group` / `scale`
/// called with explicit arguments): that closing `<argument-fence>` (also `:`)
/// already unambiguously ends things, so a `<template>` there starts
/// immediately, with no `<pipeline-terminator>` written or expected; any `:`
/// there is just literal `<template>` content. Otherwise, a single stray `:`
/// (not doubled) is a parse error, never a lenient no-op. Returns `[]`
/// (`parseTemplate(_:terminatorSet:)` never itself returns an empty 1) if no
/// `<template>` follows (a bare pipeline / named format / format transform, or
/// nothing further at all).
private func parseTrailingTemplate(
	_ input: inout Substring,
	terminatorSet: Set<Character>,
	endedWithClosedArgumentFence: Bool,
) throws(ParsingError) -> [FormatPart] {
	if !endedWithClosedArgumentFence {
		guard input.first == colon else {
			return .init()
		}
		var afterFirstColon = input
		afterFirstColon.removeFirst()
		guard afterFirstColon.first == colon else {
			throw .incompletePipelineTerminator
		}
		input = afterFirstColon
		input.removeFirst() // the pipeline terminator's 2nd ':'
	}
	guard let next = input.first, !terminatorSet.contains(next) else {
		return .init()
	}
	guard case let .parts(template) = try parseTemplate(&input, terminatorSet: terminatorSet) else {
		preconditionFailure("parseTemplate always returns .parts")
	}
	return template
}

/// `<format>`'s trailing template when only `<named-format>` and/or
/// `<format-transform-pipeline>` (never `<value-transform-pipeline>`, which
/// has its own reference to fold a `namedFormat` into) precede it: with a
/// template, that's the whole format (`namedFormat`, if present, is
/// discarded here; `hidden` can never reach this function, since it
/// precludes anything else in the format-modifier, checked by its own
/// caller); without a template, `namedFormat` (if present) is the whole
/// format instead; absent both, it's an implicit `%v`.
/// TODO: once user-defined named formats exist, splice `namedFormat`'s own
///  rendered value in as a trailing template's first part, instead of
///  discarding it.
private func parseTrailingTemplateOrNamedFormat(
	_ input: inout Substring,
	namedFormat: String?,
	fieldName: String,
	terminatorSet: Set<Character>,
) throws(ParsingError) -> Format {
	let template = try parseTrailingTemplate(&input, terminatorSet: terminatorSet, endedWithClosedArgumentFence: false)
	return template.isEmpty
		? namedFormat.map { .reference(.init(namedFormat: $0, transforms: .init())) } ?? .default(fieldName: fieldName)
		: .parts(template)
}

/// `<format>`'s trailing `<value-transform-pipeline>` (generalizing the old
/// `<string-transform-pipeline>`-only pipeline to `<number-transform-
/// pipeline>` / `<date-transform-pipeline>` too): unlike every other
/// `<*-transform-pipeline>` site, which always knows its kind statically from
/// its own grammar position (e.g., `%N`'s own success sub-format is always
/// number-kind), `<format>` itself doesn't, since a field's raw value has no
/// fixed type, so kind is inferred from the pipeline's own 1st `<transform>`
/// instead. Every `<transform>` name is unique across kinds, so peeking just
/// the 1st 1 unambiguously determines kind for the whole pipeline;
/// `FormatReferenceParser.parse` then enforces that every later `<transform>`
/// shares it (a mismatched name throws `.invalidTransform`, same as it always
/// has). `namedFormat`, if present, folds into the returned reference,
/// mirroring the old bare `<string-transform-pipeline>` case this replaces.
private func parseValueTransformPipelineThenTemplate(
	_ input: inout Substring,
	namedFormat: String?,
	terminatorSet: Set<Character>,
) throws(ParsingError) -> Format {
	var peek = input
	peek.removeFirst() // '.'
	var coerced = false
	if peek.first == transformCallPrefix {
		coerced = true
		peek.removeFirst() // the coercion marker's own '.'
	}
	let firstName = try parseTransformName(&peek, terminatorSet: terminatorSet)
	guard let kind = try TransformKind.of(transformName: firstName) else {
		throw .invalidTransform(name: firstName, expectedKind: "value")
	}
	if coerced {
		guard kind == .number else {
			throw .coercionNotApplicable(kind: kind.rawValue)
		}
		// Drop just the coercion marker's own '.', leaving a single leading
		// `<transform-call-prefix>` for `FormatReferenceParser.parse` below,
		// exactly as it already expects for every other transform pipeline
		input.remove(at: input.index(after: input.startIndex))
	}
	let beforePipeline = input
	guard let reference = try FormatReferenceParser(kind: kind, terminatorSet: terminatorSet).parse(&input) else {
		preconditionFailure("Just confirmed a leading transform call for \(kind), so this always succeeds")
	}
	return .valuePipeline(
		namedFormat == nil ? reference : FormatReference(namedFormat: namedFormat, transforms: reference.transforms),
		kind: kind,
		coerced: coerced,
		template: try parseTrailingTemplate(
			&input,
			terminatorSet: terminatorSet,
			endedWithClosedArgumentFence: beforePipeline[beforePipeline.index(before: input.startIndex)] == colon,
		),
	)
}

private extension Justification {
	/// A `<format-transform>`'s `<format-transform-name>`: table-output column
	/// alignment. Consumed entirely at parse time into `FieldSpec.justification`,
	/// never part of a rendered `Format` (unlike `Transform`, never valid
	/// inside a placeholder's own success / failure sub-format).
	init?(formatTransformSimpleName name: String) {
		switch name {
		case "centerEndJustify":
			self = .centerEnd
		case "centerStartJustify":
			self = .centerStart
		case "leftJustify":
			self = .start
		case "rightJustify":
			self = .end
		default:
			return nil
		}
	}
}

/// Parses `<format-transform-pipeline>` (`( <transform-call-prefix>
/// <format-transform> )+`): as many leading `<format-transform>`s as match
/// (last 1 wins). Backtracks (consuming nothing) as soon as a `.`-prefixed
/// name doesn't match a known `<format-transform>`, leaving it for the caller
/// to try as something else (e.g., a `<string-transform>`); per
/// fields-formatting.md, a `<format-transform>` & every other transform share
/// no names, so there's nothing to disambiguate: this is 1st-match-wins
/// ordering, not a lookup. The caller (`parseFormat`), not this function,
/// handles a trailing `<pipeline-terminator>`, since 1 may be needed even
/// with 0 matches (e.g., right after a bare named format, before a
/// template); `:` still ends a name-scan here regardless, so a lone or
/// doubled 1 is never swallowed into an attempted `<format-transform>` name.
private func parseFormatTransformPipeline(_ input: inout Substring, terminatorSet: Set<Character>)
throws(ParsingError) -> Justification? {
	var justification = Justification?.none
	while input.first == transformCallPrefix {
		let beforeTransform = input
		input.removeFirst()
		let name = try parseEscapedText(
			&input,
			terminatorSet: terminatorSet.union([transformCallPrefix, colon]),
		)
		guard let matched = Justification(formatTransformSimpleName: name) else {
			input = beforeTransform
			break
		}
		justification = matched
	}
	return justification
}

private func parseSortSpecModifier(
	_ input: inout Substring,
	existing: SortSpec?,
	fieldName: String,
	outputFormat: OutputFormat,
) throws -> SortSpec? {
	guard input.first == sortModifierPrefix else {
		return existing
	}
	input.removeFirst()
	return try .init(
		from: &input,
		nextSectionPrefixSet: .init(),
		existing: existing,
		fieldName: fieldName,
		outputFormat: outputFormat,
	)
}

// MARK: - Shared parsing primitives

func parseOptions<E: Error>(
	_ input: inout Substring,
	nextSectionPrefixSet: Set<Character>,
	body: (inout Substring, inout Substring.Index, Character) throws(E) -> Void,
) throws(E) {
	var currentIndex = input.startIndex
	while currentIndex < input.endIndex {
		let char = input[currentIndex]
		guard char != fieldSpecSeparator, !nextSectionPrefixSet.contains(char) else {
			break
		}
		defer {
			if currentIndex < input.endIndex {
				currentIndex = input.index(after: currentIndex)
			}
		}
		if char.isWhitespace {
			continue
		}
		try body(&input, &currentIndex, char)
	}
	input = input[currentIndex...]
}

func parseUInt64(_ input: inout Substring) -> UInt64? {
	let digits = input.prefix { $0.isASCII && $0.isNumber }
	guard !digits.isEmpty, let value = UInt64(digits) else {
		return nil
	}
	input.removeFirst(digits.count)
	return value
}

func parseInt(_ input: inout Substring) -> Int? {
	let digits = input.prefix { $0 == "-" || ($0.isASCII && $0.isNumber) }
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

extension Substring {
	/// Like `firstIndex(of:)`, but skips a match immediately preceded by an odd
	/// number of `\`s (i.e., an escaped occurrence).
	func firstUnescapedIndex(of target: Character) -> Index? {
		var index = startIndex
		var escaped = false
		while index < endIndex {
			let char = self[index]
			if char == target, !escaped {
				return index
			}
			escaped = char == escapePrefix ? !escaped : false
			index = self.index(after: index)
		}
		return nil
	}
}

// MARK: - Lightweight pre-fetch scanning helpers

/// Skips (without interpreting) an optional `<field-order-section>` &
/// `<item-sort-section>`, leaving `input` positioned at the start of
/// `<field-specs-section>` (or empty). `<field-order-section>` is skipped via
/// the real parser (`FieldSpecsBuilder.parseFieldOrderSection(_:)`, result
/// discarded): unlike `<item-sort-section>`, its `<sort-option-set>`
/// alternative can carry fenced sub-content (a `<localization>` locale name,
/// `<boundaries>`) that may itself contain an unescaped `.` / `/`, so a naive
/// scan for those characters isn't safe here. `<item-sort-section>`'s own
/// option alphabet (`a` / `d` / `r` / `R`) has no such fencing & never
/// overlaps with `.`, so it can still be skipped directly.
private func skipFieldOrderAndItemSortSections(_ input: inout Substring, outputFormat: OutputFormat) throws {
	if input.first == fieldOrderSectionPrefix, !input.hasPrefix(itemSortSectionPrefix) {
		var builder = FieldSpecsBuilder(fieldSpecs: .init(), outputFormat: outputFormat)
		_ = try builder.parseFieldOrderSection(&input)
	}
	if input.hasPrefix(itemSortSectionPrefix) {
		input = input.dropFirst(itemSortSectionPrefix.count).drop { $0 != fieldSpecsSectionPrefix }
	}
}

/// Splits `input` (a `<field-specs-section>`'s content, sans its `.` prefix, or
/// a whole `<absolute-config>`) on top-level (unescaped) `,`s & extracts each
/// segment's leading field name, optionally requiring a leading `prefix` (`+`,
/// for scanning only `<insert-field-spec>`s; `nil` to accept every segment, for
/// `<absolute-config>`). Needn't understand label / format / sort-modifier
/// syntax at all, since `,` is reserved (must be escaped if literal) everywhere
/// within a field spec.
private func topLevelFieldSpecNames(in input: Substring, requiringPrefix prefix: Character?)
throws(ParsingError) -> [String] {
	var names = [String]()
	var remaining = input
	if remaining.first == fieldSpecsSectionPrefix {
		remaining.removeFirst()
	}
	while !remaining.isEmpty {
		let segmentEnd = remaining.firstUnescapedIndex(of: fieldSpecSeparator) ?? remaining.endIndex
		var segment = remaining[..<segmentEnd]
		remaining =
			segmentEnd < remaining.endIndex ? remaining[remaining.index(after: segmentEnd)...] : remaining[segmentEnd...]
		if let prefix {
			guard segment.first == prefix else {
				continue
			}
			segment.removeFirst()
		} else if segment.first == moveIndicator || segment.first == removeIndicator {
			continue // Absolute-config has no move / remove, but be defensive rather than mis-parse
		} else if segment.first == insertIndicator {
			segment.removeFirst()
		}
		let name = try parseEscapedText(
			&segment,
			terminatorSet: [labelModifierPrefix, formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator],
		)
		if !name.isEmpty {
			names.append(name)
		}
	}
	return names
}

// MARK: Constants

let escapePrefix = Character("\\")

let fieldSpecSeparator = Character(",")

let baseFieldsConfigSectionPrefix = Character("@")
let fieldOrderSectionPrefix = Character("/")
let itemSortSectionPrefix = "//"
let fieldSpecsSectionPrefix = Character(".")

private let itemSortAndFieldSpecsPrefixSet =
	Set([itemSortSectionPrefix[itemSortSectionPrefix.startIndex], fieldSpecsSectionPrefix])

let insertIndicator = Character("+")
let moveIndicator = Character("%")
let removeIndicator = Character("-")

let labelModifierPrefix = Character("=")
let sortModifierPrefix = Character("/")

/// This character has no 1 dedicated grammar name of its own; it plays
/// several distinct roles depending on where it appears, the same way `/`
/// (`<sort-modifier-prefix>`) can end a `<format>` without being a
/// `<format-terminator>`: it's `<name-prefix>` / `<format-modifier-prefix>`
/// (both defined in `Format.swift`), a `<group>` / `<scale>` `<argument-
/// fence>`, & (checked twice in a row, never on its own) `<format>`'s own
/// `<pipeline-terminator>`; see `parseTrailingTemplate(_:terminatorSet:
/// endedWithClosedArgumentFence:)`.
let colon = Character(":")

let indexPrefix = Character("@")

private let originalOrderOption = Character("o")
private let resetToContextual = Character("r")
private let resetToGlobal = Character("R")

private let outputFormatSuffixSet = Set(["json", "key-value", "table"])

let defaultFieldsConfigName = "default"
let noneFieldsConfigName = "none"
let allFieldsConfigName = "all"
let standardFieldsConfigName = "standard"
