//
// FieldsConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

// MARK: - Fields configs (fields.md)

/// A fields config: the field specs a display command outputs, plus its
/// field-ordering & item-sorting rules.
///
/// Used both for a **base fields config** (`none` / `standard` / `all` /
/// `default`) & for the fully-resolved result of parsing a `--fields` value.
protocol FieldsConfig {
	/// Whether this config's base is (or derives from) `all`. Kept as a protocol
	/// requirement (rather than computed from `fieldSpecs`) so it's fixed per
	/// conforming type, not per instance.
	var baseIncludesAllFields: Bool { get }
	var fieldSpecs: [FieldSpec] { get }
	/// This config's own default field order, substituted in by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)` whenever
	/// `--fields` doesn't specify a `<field-order-section>` of its own.
	var fieldOrder: FieldOrder { get }
	var itemSort: ItemSort { get }
}

/// `none` / `standard` / any `--fields` result not derived from `all`.
struct SelectedFieldsConfig: FieldsConfig { // swiftlint:disable:this one_declaration_per_file
	let baseIncludesAllFields = false
	let fieldSpecs: [FieldSpec]
	let fieldOrder: FieldOrder
	let itemSort: ItemSort

	init(fieldSpecs: [FieldSpec] = .init(), fieldOrder: FieldOrder = .inherited, itemSort: ItemSort = .empty) {
		self.fieldSpecs = fieldSpecs
		self.fieldOrder = fieldOrder
		self.itemSort = itemSort
	}
}

/// `all`, & any `--fields` result derived from it. `fieldSpecs` still carries
/// selected entries (e.g., `adamID`'s default sort priority) even though the
/// actual field _set_ is open-ended / dynamic, see `OutputConfig`.
struct BaseIncludesAllFieldsConfig: FieldsConfig { // swiftlint:disable:this one_declaration_per_file
	let baseIncludesAllFields = true
	let fieldSpecs: [FieldSpec]
	let fieldOrder: FieldOrder
	let itemSort: ItemSort

	init(fieldSpecs: [FieldSpec] = .init(), fieldOrder: FieldOrder = .inherited, itemSort: ItemSort = .empty) {
		self.fieldSpecs = fieldSpecs
		self.fieldOrder = fieldOrder
		self.itemSort = itemSort
	}
}

// MARK: - Field ordering (fields.md)

enum FieldOrder: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `<source>` `"O"`.
	case byLabel(SortSpec.Direction)
	/// `<source>` `"I"`.
	case byName(SortSpec.Direction)
	/// `<field-order-section>` absent: substituted, by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)`, with the
	/// resolved base fields config's own `fieldOrder`.
	case inherited
	/// `"o"`: the order fields already have when `applied(to:)` runs, i.e., the
	/// order their underlying `JSON.Object`s' keys were originally found in
	/// (`CatalogApp` / `InstalledApp` normalization only renames keys, never
	/// reorders them). `direction`, if `.descending`, reverses that order.
	case original(SortSpec.Direction?)
	/// Present, no `<field-order-option-set>`: identity, like `.inherited`, but
	/// (unlike `.inherited`) never substituted with the base fields config's own
	/// `fieldOrder`.
	case workingOrder
}

extension FieldOrder {
	/// Reorders `fieldSpecs` per this order. `.inherited` & `.workingOrder` are
	/// both identity; `.original` is identity too, unless its direction is
	/// `.descending`.
	func applied(to fieldSpecs: [FieldSpec]) -> [FieldSpec] {
		switch self {
		case .inherited, .workingOrder:
			fieldSpecs
		case let .original(direction):
			direction == .descending ? .init(fieldSpecs.reversed()) : fieldSpecs
		case let .byName(direction):
			fieldSpecs.sorted(using: KeyPathComparator(\.name, order: direction.sortOrder))
		case let .byLabel(direction):
			fieldSpecs.sorted(using: KeyPathComparator(\.label, order: direction.sortOrder))
		}
	}
}

private extension SortSpec.Direction {
	var sortOrder: SortOrder {
		self == .ascending ? .forward : .reverse
	}
}

// MARK: - Default sort options (fields.md)

/// Maps a field name (& the active output format) directly to the `SortSpec`
/// dimensions used to fill in an otherwise-incomplete explicit `<sort>`
/// (fields.md's "Default Sort Options" table), without an intermediate "value
/// kind" type: callers that don't recognize `fieldName` as a price / version /
/// path field get the generic (numeric-interpretation) row.
func defaultSortSpec(forFieldNamed fieldName: String, outputFormat: OutputFormat) -> SortSpec {
	let interpretation = priceFieldNameSet.contains(fieldName)
		? SortSpec.Interpretation.price
		: versionFieldNameSet.contains(fieldName) ? .version : .numeric
	let (caseSensitivity, localization) = outputFormat == .json
		? (SortSpec.CaseSensitivity.sensitive, SortSpec.Localization.canonical)
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
			groups: [.init(boundaries: [.character(pathFieldNameSet.contains(fieldName) ? "/" : "_")])],
			collapseContiguous: false,
			whitespacePlacement: .endmost,
		),
	)
}

private let priceFieldNameSet = Set(["price", "formattedPrice"])
private let versionFieldNameSet = Set(["version", "newVersion", "minimumOSVersion"])
private let pathFieldNameSet = Set(["path"])

/// Maps a field name directly to its default table-column justification (mas's
/// own built-in `standard` / `all` fields configs' shared policy: a number, or
/// a value with a fixed textual suffix that reads better right-aligned, e.g.,
/// `fileSizeBytes`'s appended `" MB"`, is right-justified; everything else is
/// left-justified). Consulted only by each display command's own field-spec
/// construction, not applied generically elsewhere; a user's own `--fields`
/// justify transform (see `extractJustification(from:)` in `FieldSpec.swift`)
/// overrides it per field spec.
func defaultJustification(forFieldNamed fieldName: String) -> Justification {
	rightJustifiedFieldNameSet.contains(fieldName) ? .end : .start
}

private let rightJustifiedFieldNameSet = Set(["adamID", "fileSizeBytes"])
