//
// FieldsConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST

// MARK: - Fields configs (fields.md)

/// A fields config: the field specs a display command outputs, plus its
/// field-ordering & item-sorting rules.
///
/// Used both for a **base fields config** (`none` / `standard` / `all` /
/// `default`) & for the fully-resolved result of parsing a `--fields` value.
protocol FieldsConfig {
	/// Whether this config's base is (or derives from) `all`, so its unlisted
	/// fields (fields.md "Unlisted Fields") are visible. Kept as a protocol
	/// requirement (rather than computed from `fieldSpecs`) so it is fixed per
	/// conforming type, not per instance.
	var baseIncludesAllFields: Bool { get }
	var fieldSpecs: [FieldSpec] { get }
	/// This config's field order & saved field orders, which a fields config that
	/// extends it retains, absent a `<field-order-sections>` of its own.
	var fieldOrders: FieldOrders { get }
	var itemSort: ItemSort { get }

	/// Needed so `machineFacingVariant()`, `hidingAll()` & `disablingAllSorts()`
	/// can rebuild `Self` generically, over `some FieldsConfig` as well as
	/// `any FieldsConfig`.
	init(fieldSpecs: [FieldSpec], fieldOrders: FieldOrders, itemSort: ItemSort)

	/// A field spec for each visible unlisted field of any of `objects`, in order
	/// of each field's 1st occurrence, each to be ordered after every one of
	/// `fieldSpecs`.
	func unlistedFieldSpecs(in objects: [JSON.Object]) -> [FieldSpec]
}

/// `none` / `standard` / any `--fields` result not derived from `all`.
struct SelectedFieldsConfig: FieldsConfig { // swiftlint:disable:this one_declaration_per_file
	let baseIncludesAllFields = false
	let fieldSpecs: [FieldSpec]
	let fieldOrders: FieldOrders
	let itemSort: ItemSort

	init(fieldSpecs: [FieldSpec] = .init(), fieldOrders: FieldOrders = .init(), itemSort: ItemSort = .empty) {
		self.fieldSpecs = fieldSpecs
		self.fieldOrders = fieldOrders
		self.itemSort = itemSort
	}

	/// None, because this config's unlisted fields are hidden.
	func unlistedFieldSpecs(in _: [JSON.Object]) -> [FieldSpec] {
		.init()
	}
}

/// `all` & any `--fields` result derived from it, whose unlisted fields
/// (fields.md "Unlisted Fields") are visible.
struct BaseIncludesAllFieldsConfig: FieldsConfig { // swiftlint:disable:this one_declaration_per_file
	let baseIncludesAllFields = true
	let fieldSpecs: [FieldSpec]
	let fieldOrders: FieldOrders
	let itemSort: ItemSort
	/// The fields that this config lists: the app's listed fields & each that a
	/// field name in `--fields` names. Every other field is unlisted.
	let listedFieldNameSet: Set<String>
	/// Whether this config is derived from a machine-facing variant, whose
	/// unlisted fields' field specs are labeled by name & formatted as `%i`.
	let isMachineFacing: Bool

	init(fieldSpecs: [FieldSpec] = .init(), fieldOrders: FieldOrders = .init(), itemSort: ItemSort = .empty) {
		self.init(
			fieldSpecs: fieldSpecs,
			fieldOrders: fieldOrders,
			itemSort: itemSort,
			listedFieldNameSet: .init(fieldSpecs.map(\.name)),
			isMachineFacing: false,
		)
	}

	init(
		fieldSpecs: [FieldSpec],
		fieldOrders: FieldOrders,
		itemSort: ItemSort,
		listedFieldNameSet: Set<String>,
		isMachineFacing: Bool,
	) {
		self.fieldSpecs = fieldSpecs
		self.fieldOrders = fieldOrders
		self.itemSort = itemSort
		self.listedFieldNameSet = listedFieldNameSet
		self.isMachineFacing = isMachineFacing
	}

	/// A default field spec for each unlisted field of any of `objects`, in order
	/// of each field's 1st occurrence (each item's own `JSON.Object` is
	/// normalized, i.e., renamed, but not reordered, so this is each object's own
	/// original key order).
	func unlistedFieldSpecs(in objects: [JSON.Object]) -> [FieldSpec] {
		// swiftlint:disable:next todo
		// TODO: Temp/todo.md "Persistent Custom Presets & Configs": give each
		//  key-value & JSON output item only its own unlisted fields (fields.md
		//  "Unlisted Fields"), because a custom `default` preset may give an absent
		//  field a formatted value that is not absent
		var seenNameSet = listedFieldNameSet
		return objects.flatMap(\.fields).compactMap { field in
			seenNameSet.insert(field.key.rawValue).inserted
				? isMachineFacing
					? .default(forName: field.key.rawValue)
					: builtInFieldSpec(forFieldNamed: field.key.rawValue)
				: nil
		}
	}
}

extension FieldsConfig {
	/// The field order (fields.md "Field Order").
	var fieldOrder: FieldOrder {
		fieldOrders.fieldOrder
	}

	/// This fields config, with its saved field order of `kind` as its field
	/// order (e.g., `all`'s of kind `O`, per fields.md "Immutable Built-In Named
	/// Fields Configs").
	func withFieldOrder(of kind: FieldOrderKind, outputFormat: OutputFormat) -> Self {
		.init(
			fieldSpecs: fieldSpecs,
			fieldOrders: fieldOrders.savingFieldOrder(of: kind, outputFormat: outputFormat),
			itemSort: itemSort,
		)
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
					presetNames: fieldSpec.presetNames,
					alignment: fieldSpec.baseAlignment,
				)
			},
			fieldOrders: fieldOrders,
			itemSort: itemSort,
		)
	}

	/// This fields config followed by hidden copies of `fieldSpecs`' field specs
	/// for fields not already in it.
	func including(hidden fieldSpecs: [FieldSpec]) -> Self {
		let nameSet = Set(self.fieldSpecs.map(\.name))
		return .init(
			fieldSpecs: self.fieldSpecs
				+ Self(
					fieldSpecs: fieldSpecs.filter { !nameSet.contains($0.name) },
					fieldOrders: fieldOrders,
					itemSort: itemSort,
				)
				.hidingAll()
				.fieldSpecs,
			fieldOrders: fieldOrders,
			itemSort: itemSort,
		)
	}

	/// This fields config with every field spec's `<sort>`, if any, disabled.
	func disablingAllSorts() -> Self {
		.init(
			fieldSpecs: fieldSpecs.map(\.withSortDisabled),
			fieldOrders: fieldOrders,
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
					presetNames: fieldSpec.presetNames,
					alignment: fieldSpec.baseAlignment,
				)
			},
			fieldOrders: fieldOrders,
			itemSort: itemSort,
		)
	}
}
