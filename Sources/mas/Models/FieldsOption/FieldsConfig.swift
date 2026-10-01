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
	/// requirement (rather than computed from `fieldSpecs`) so it is fixed per
	/// conforming type, not per instance.
	var baseIncludesAllFields: Bool { get }
	var fieldSpecs: [FieldSpec] { get }
	/// This config's own default field order, substituted in by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)` whenever
	/// `--fields` does not specify a `<field-order-section>` of its own.
	var fieldOrder: FieldOrder { get }
	var itemSort: ItemSort { get }

	/// Needed so `machineFacingVariant()`, `hidingAll()` & `disablingAllSorts()`
	/// can rebuild `Self` generically, over `some FieldsConfig` as well as
	/// `any FieldsConfig`.
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
	/// `<source>` `"O"`: sorts by label, per the `<sort-option-set>`, ties
	/// ordered per `tiebreakDirection`.
	case byLabel(SortOptionSet, tiebreakDirection: SortOptionSet.Direction)
	/// `<source>` `"I"`: sorts by name, per the `<sort-option-set>`, ties ordered
	/// per `tiebreakDirection`.
	case byName(SortOptionSet, tiebreakDirection: SortOptionSet.Direction)
	/// `<document-order>` (`"D"`): the order fields already have when
	/// `applied(to:)` runs, i.e., the order their underlying `JSON.Object`s' keys
	/// were originally found in (`CatalogApp` / `InstalledApp` normalization only
	/// renames keys, never reorders them). `direction`, if `.descending`,
	/// reverses that order, except among ties, which are ordered per
	/// `tiebreakDirection`.
	case document(SortOptionSet.Direction?, tiebreakDirection: SortOptionSet.Direction)
	/// `<field-order-section>` absent: substituted, by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)`, with the resolved
	/// base fields config's own `fieldOrder`.
	case inherited
	/// `<positional-order>` (`"P"`): the working fields config's field specs by
	/// position. Its `<descending>` reverses their positions while parsing,
	/// before `<field-spec-edits-section>`, so it needs no direction here.
	case positional
}

extension FieldOrder {
	/// Reorders `fieldSpecs` per this order. `.inherited`, `.document` (which
	/// orders each item's fields independently; see `itemFieldSpecs(_:for:)`) &
	/// `.positional` are identity. `.byName` / `.byLabel` sort per their
	/// `<sort-option-set>` (direction included: `SortOptionSet.compare(_:_:)`
	/// already accounts for it), ordering ties by position, or by reverse
	/// position iff `tiebreakDirection` is `.descending`.
	func applied(to fieldSpecs: [FieldSpec]) -> [FieldSpec] {
		switch self {
		case .document, .inherited, .positional:
			fieldSpecs
		case let .byName(optionSet, tiebreakDirection):
			fieldSpecs.sorted(by: \.name, optionSet: optionSet, tiebreakDirection: tiebreakDirection)
		case let .byLabel(optionSet, tiebreakDirection):
			fieldSpecs.sorted(by: \.label, optionSet: optionSet, tiebreakDirection: tiebreakDirection)
		}
	}
}

private extension [FieldSpec] {
	func sorted(
		by keyPath: KeyPath<FieldSpec, String>,
		optionSet: SortOptionSet,
		tiebreakDirection: SortOptionSet.Direction,
	) -> Self {
		enumerated()
			.sorted { lhs, rhs in
				switch optionSet.compare(lhs.element[keyPath: keyPath], rhs.element[keyPath: keyPath]) {
				case .orderedAscending:
					true
				case .orderedDescending:
					false
				case .orderedSame:
					tiebreakDirection == .ascending ? lhs.offset < rhs.offset : lhs.offset > rhs.offset
				}
			}
			.map(\.element)
	}
}

extension FieldOrder {
	/// `fieldSpecs` ordered for `object`: for `<document-order>`, in the order of
	/// `object`'s keys (field specs for absent fields last), reversed iff
	/// `.descending`, ties ordered by position, or by reverse position iff
	/// `tiebreakDirection` is `.descending`; otherwise, unchanged.
	func itemFieldSpecs(_ fieldSpecs: [FieldSpec], for object: JSON.Object) -> [FieldSpec] {
		guard case let .document(direction, tiebreakDirection) = self else {
			return fieldSpecs
		}
		let positionByName =
			Dictionary(object.fields.enumerated().map { ($1.key.rawValue, $0) }) { first, _ in first }
		return fieldSpecs.enumerated()
			.sorted { lhs, rhs in
				let lhsPosition = positionByName[lhs.element.name] ?? .max
				let rhsPosition = positionByName[rhs.element.name] ?? .max
				return lhsPosition == rhsPosition
					? tiebreakDirection == .ascending
						? lhs.offset < rhs.offset
						: lhs.offset > rhs.offset
					: (lhsPosition < rhsPosition) == (direction != .descending)
			}
			.map(\.element)
	}
}

extension BaseIncludesAllFieldsConfig {
	/// `all`'s own default field order, absent a built-in field order: sorted by
	/// label (`<output>`), while other `<sort-option>`s are as per the defaults
	/// for string fields for `outputFormat`. Applied only if a command has not
	/// already customized `all`'s `fieldOrder` (i.e., it is still `.inherited`).
	func withDefaultFieldOrder(outputFormat: OutputFormat) -> Self {
		var optionSet = defaultSortOptionSet(forFieldNamed: nil, outputFormat: outputFormat)
		optionSet.source = .output
		return fieldOrder == .inherited
			? .init(
				fieldSpecs: fieldSpecs,
				fieldOrder: .byLabel(optionSet, tiebreakDirection: .ascending),
				itemSort: itemSort,
			)
			: self
	}
}

extension FieldsConfig {
	/// A built-in fields config's machine-facing `@json` variant: favoring
	/// precision & parsability, each field spec's label is its field name & its
	/// output is formatted as `%i`, while its format still types its field.
	func machineFacingVariant() -> Self {
		.init(
			fieldSpecs: fieldSpecs.map { fieldSpec in
				.init(
					name: fieldSpec.name,
					label: fieldSpec.name,
					format: fieldSpec.format,
					sortSpec: fieldSpec.sortSpec,
					isHidden: fieldSpec.isHidden,
					isSynthesized: fieldSpec.isSynthesized,
					justification: fieldSpec.justification,
					outputsInput: true,
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

	/// This fields config with every field spec's sort disabled.
	func disablingAllSorts() -> Self {
		.init(
			fieldSpecs: fieldSpecs.map(\.withSortDisabled),
			fieldOrder: fieldOrder,
			itemSort: .init(keys: .init(), tiebreakDirection: itemSort.tiebreakDirection),
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
					outputsInput: fieldSpec.outputsInput,
				)
			},
			fieldOrder: fieldOrder,
			itemSort: itemSort,
		)
	}
}
