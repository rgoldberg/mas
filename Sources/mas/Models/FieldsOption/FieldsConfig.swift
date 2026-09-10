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
