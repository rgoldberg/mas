//
// FieldsConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation
internal import JSONAST

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

	/// Needed so `machineFacingVariant()` & `hidingAll()` can rebuild `Self`
	/// generically, over `some FieldsConfig` as well as `any FieldsConfig`.
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

/// `all` & any `--fields` result derived from it. `fieldSpecs` still carries
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
	//  inherited field specs' listed order & whether `<descending>` reverses
	//  only the inherited order, not subsequent `<field-spec-edits-section>`
	//  results
	case base(SortOptionSet.Direction?)
	/// `<source>` `"O"`: sorts by label, per the `<sort-option-set>`.
	case byLabel(SortOptionSet)
	/// `<source>` `"I"`: sorts by name, per the `<sort-option-set>`.
	case byName(SortOptionSet)
	/// `<field-order-section>` absent: substituted, by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)`, with the resolved
	/// base fields config's own `fieldOrder`.
	case inherited
	/// `<original-input-order>` (`"o"`): the order fields already have when
	/// `applied(to:)` runs, i.e., the order their underlying `JSON.Object`s' keys
	/// were originally found in (`CatalogApp` / `InstalledApp` normalization only
	/// renames keys, never reorders them). `direction`, if `.descending`,
	/// reverses that order.
	case original(SortOptionSet.Direction?)
}

extension FieldOrder {
	/// Reorders `fieldSpecs` per this order. `.inherited` & `.original` (which
	/// orders each item's fields independently; see `itemFieldSpecs(_:for:)`) are
	/// identity; `.base` is identity, too, unless its direction is `.descending`.
	/// `.byName` / `.byLabel` sort per their `<sort-option-set>` (direction
	/// included: `SortOptionSet.compare(_:_:)` already accounts for it).
	func applied(to fieldSpecs: [FieldSpec]) -> [FieldSpec] {
		switch self {
		case .inherited, .original:
			fieldSpecs
		case let .base(direction):
			direction == .descending ? .init(fieldSpecs.reversed()) : fieldSpecs
		case let .byName(optionSet):
			fieldSpecs.sorted { optionSet.compare($0.name, $1.name) == .orderedAscending }
		case let .byLabel(optionSet):
			fieldSpecs.sorted { optionSet.compare($0.label, $1.label) == .orderedAscending }
		}
	}
}

extension FieldOrder {
	/// `fieldSpecs` ordered for `object`: for `<original-input-order>`, in the
	/// order of `object`'s keys (field specs for absent fields last), reversed
	/// iff `.descending`; otherwise, unchanged.
	func itemFieldSpecs(_ fieldSpecs: [FieldSpec], for object: JSON.Object) -> [FieldSpec] {
		guard case let .original(direction) = self else {
			return fieldSpecs
		}
		let positionByName =
			Dictionary(object.fields.enumerated().map { ($1.key.rawValue, $0) }) { first, _ in first }
		let ordered = fieldSpecs.enumerated()
			.sorted { lhs, rhs in
				(positionByName[lhs.element.name] ?? .max, lhs.offset) < (positionByName[rhs.element.name] ?? .max, rhs.offset)
			}
			.map(\.element)
		return direction == .descending ? ordered.reversed() : ordered
	}
}

extension BaseIncludesAllFieldsConfig {
	/// `all`'s own default field order, absent a built-in field order: sorted by
	/// label (`<output>`), while other `<sort-option>`s are as per the defaults
	/// for string fields for `outputFormat`. Applied only if a command hasn't
	/// already customized `all`'s `fieldOrder` (i.e., it's still `.inherited`).
	func withDefaultFieldOrder(outputFormat: OutputFormat) -> Self {
		var optionSet = defaultSortOptionSet(forFieldNamed: nil, outputFormat: outputFormat)
		optionSet.source = .output
		return fieldOrder == .inherited
			? .init(fieldSpecs: fieldSpecs, fieldOrder: .byLabel(optionSet), itemSort: itemSort)
			: self
	}
}

extension FieldsConfig {
	/// A built-in fields config's machine-facing `@json` variant: favoring
	/// precision & parsability, each field spec's label is its field name & its
	/// format is `%i`.
	func machineFacingVariant() -> Self {
		.init(
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
	}

	/// This fields config followed by hidden copies of `fieldSpecs`' field specs
	/// for fields not already in it.
	func including(hidden fieldSpecs: [FieldSpec]) -> Self {
		let nameSet = Set(self.fieldSpecs.map(\.name))
		return .init(
			fieldSpecs: self.fieldSpecs
				+ Self(fieldSpecs: fieldSpecs.filter { !nameSet.contains($0.name) }, fieldOrder: fieldOrder, itemSort: itemSort)
				.hidingAll()
				.fieldSpecs,
			fieldOrder: fieldOrder,
			itemSort: itemSort,
		)
	}

	/// This fields config with every field spec hidden.
	func hidingAll() -> Self {
		.init(
			fieldSpecs: fieldSpecs.map { fieldSpec in
				.init(
					name: fieldSpec.name,
					label: fieldSpec.label,
					format: fieldSpec.format,
					sortSpec: fieldSpec.sortSpec,
					isHidden: true,
					isSynthesized: fieldSpec.isSynthesized,
					justification: fieldSpec.justification,
				)
			},
			fieldOrder: fieldOrder,
			itemSort: itemSort,
		)
	}
}
