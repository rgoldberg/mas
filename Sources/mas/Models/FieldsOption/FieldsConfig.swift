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

	/// Needed so `defaultedForJSON()` can rebuild `Self` generically, over
	/// `some FieldsConfig` as well as `any FieldsConfig`.
	init(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder, itemSort: ItemSort)
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
	/// `<base-fields-config-order>` (`"w"`): the working fields config's field
	/// specs in their listed order. `direction`, if `.descending`, reverses that
	/// order.
	// swiftlint:disable:next todo
	// TODO: Temp/todo.md "`<base-fields-config-order>`": decide whether `w`
	//  orders as the base fields config would render (applying its inherited
	//  `<original-input-order>` / `<sort-option-set>`), or (as here) uses the
	//  inherited field specs' listed order, & whether `<descending>` reverses
	//  only the inherited order, not subsequent `<field-spec-edits-section>`
	//  results
	case base(SortOptionSet.Direction?)
	/// `<source>` `"O"`: sorts by label, per the `<sort-option-set>`.
	case byLabel(SortOptionSet)
	/// `<source>` `"I"`: sorts by name, per the `<sort-option-set>`.
	case byName(SortOptionSet)
	/// `<field-order-section>` absent: substituted, by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)`, with the
	/// resolved base fields config's own `fieldOrder`.
	case inherited
	/// `<original-input-order>` (`"o"`): the order fields already have when
	/// `applied(to:)` runs, i.e., the order their underlying `JSON.Object`s'
	/// keys were originally found in (`CatalogApp` / `InstalledApp`
	/// normalization only renames keys, never reorders them). `direction`, if
	/// `.descending`, reverses that order.
	case original(SortOptionSet.Direction?)
}

extension FieldOrder {
	/// Reorders `fieldSpecs` per this order. `.inherited` is identity; `.base` &
	/// `.original` are identity, too, unless their direction is `.descending`.
	/// `.byName` / `.byLabel` sort per their `<sort-option-set>` (direction
	/// included: `SortOptionSet.compare(_:_:)` already accounts for it).
	func applied(to fieldSpecs: [FieldSpec]) -> [FieldSpec] {
		switch self {
		case .inherited:
			fieldSpecs
		case let .base(direction), let .original(direction):
			direction == .descending ? .init(fieldSpecs.reversed()) : fieldSpecs
		case let .byName(optionSet):
			fieldSpecs.sorted { optionSet.compare($0.name, $1.name) == .orderedAscending }
		case let .byLabel(optionSet):
			fieldSpecs.sorted { optionSet.compare($0.label, $1.label) == .orderedAscending }
		}
	}
}

extension BaseIncludesAllFieldsConfig {
	/// `all`'s own default field order, absent a built-in field order: sorted
	/// by label (`<output>`), while other `<sort-option>`s are as per the
	/// defaults for string fields for `outputFormat`. Applied only if a command
	/// hasn't already customized `all`'s `fieldOrder` (i.e., it's still
	/// `.inherited`).
	func withDefaultFieldOrder(outputFormat: OutputFormat) -> Self {
		var optionSet = defaultSortOptionSet(forFieldNamed: nil, outputFormat: outputFormat)
		optionSet.source = .output
		return fieldOrder == .inherited
			? .init(fieldSpecs: fieldSpecs, fieldOrder: .byLabel(optionSet), itemSort: itemSort)
			: self
	}
}

extension FieldsConfig {
	/// For a built-in default fields config (`none` / `standard` / `all`) only:
	/// for `outputFormat` `.json`, resets every field spec's label to its name
	/// & format to its bare default (`.default(fieldName:)`), so JSON uses each
	/// field's raw name & value, ignoring whatever label / custom format it was
	/// given for `table` / `keyValue`; fields.md's Labeling section otherwise
	/// has a label serve as a field's JSON key exactly like it does for
	/// `table` / `keyValue`, which a built-in default's labels & formats were
	/// never meant to opt into. Identity for any other `outputFormat`.
	///
	/// Never applied to a resolved fields config's own fields (e.g., a future
	/// persisted custom one): a user's own explicit label / format is respected
	/// for every output format, including `.json`.
	func defaultedForJSON(outputFormat: OutputFormat) -> Self {
		outputFormat == .json
			? .init(
				fieldSpecs: fieldSpecs.map { fieldSpec in
					.init(
						name: fieldSpec.name,
						label: fieldSpec.name,
						format: .default(fieldName: fieldSpec.name),
						sortSpec: fieldSpec.sortSpec,
						isHidden: fieldSpec.isHidden,
						isSynthesized: fieldSpec.isSynthesized,
						justification: fieldSpec.justification,
					)
				},
				fieldOrder: fieldOrder,
				itemSort: itemSort,
			)
			: self
	}
}
