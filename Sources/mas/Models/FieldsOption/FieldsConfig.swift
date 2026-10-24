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
	/// Whether this config's base is (or derives from) `all`, so its unlisted
	/// fields (fields.md "Unlisted Fields") are visible. Kept as a protocol
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

	/// A field spec for each visible unlisted field of any of `objects`, in order
	/// of each field's 1st occurrence, each to be ordered after every one of
	/// `fieldSpecs`.
	func unlistedFieldSpecs(in objects: [JSON.Object]) -> [FieldSpec]
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
	let fieldOrder: FieldOrder
	let itemSort: ItemSort
	/// The fields that this config lists: the app's listed fields & each that a
	/// field name in `--fields` names. Every other field is unlisted.
	let listedFieldNameSet: Set<String>
	/// Whether this config is derived from a machine-facing variant, whose
	/// unlisted fields' field specs are labeled by name & formatted as `%i`.
	let isMachineFacing: Bool

	init(fieldSpecs: [FieldSpec] = .init(), fieldOrder: FieldOrder = .inherited, itemSort: ItemSort = .empty) {
		self.init(
			fieldSpecs: fieldSpecs,
			fieldOrder: fieldOrder,
			itemSort: itemSort,
			listedFieldNameSet: .init(fieldSpecs.map(\.name)),
			isMachineFacing: false,
		)
	}

	init(
		fieldSpecs: [FieldSpec],
		fieldOrder: FieldOrder,
		itemSort: ItemSort,
		listedFieldNameSet: Set<String>,
		isMachineFacing: Bool,
	) {
		self.fieldSpecs = fieldSpecs
		self.fieldOrder = fieldOrder
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
		// TODO: Temp/todo.md "Streaming Output": give each key-value & JSON output
		//  item only its own unlisted fields (fields.md "Unlisted Fields"), because
		//  a custom `default` named format may render an absent field as something
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

// MARK: - Field ordering (fields.md)

enum FieldOrder: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `<source>` `"O"`: sorts by label, per the `<sort-option-set>`, ties
	/// ordered per `tiebreakDirection`.
	case byLabel(SortOptionSet, tiebreakDirection: SortOptionSet.Direction)
	/// `<source>` `"I"`: sorts by name, per the `<sort-option-set>`, ties ordered
	/// per `tiebreakDirection`.
	case byName(SortOptionSet, tiebreakDirection: SortOptionSet.Direction)
	/// `<document-order>` (`"D"`): each item's fields in the order of its own
	/// `JSON.Object`'s keys (`CatalogApp` / `InstalledApp` normalization only
	/// renames keys, never reorders them), per `optionSet` &
	/// `itemMembers(_:for:)`, ties ordered per `tiebreakDirection`.
	case document(OrderOptionSet, tiebreakDirection: SortOptionSet.Direction)
	/// `<field-order-section>` absent: substituted, by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)`, with the resolved
	/// base fields config's own `fieldOrder`.
	case inherited
	/// `<positional-order>` (`"P"`): the working fields config's field specs by
	/// position, per `optionSet`. Its `<descending>` reverses their positions
	/// while parsing, before `<field-spec-edits-section>`, but also orders
	/// unpositioned (i.e., visible unlisted) fields; see `applied(to:unlisted:)`.
	case positional(OrderOptionSet)
}

/// A `<positional-order-option-set>`'s or a `<document-order-option-set>`'s
/// options other than its `<order>`s.
struct OrderOptionSet: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `<unpositioned-field-comparison>`.
	enum UnpositionedFieldComparison: Character {
		/// `<unpositioned-fields-greatest>`.
		case greatest = "z"
		/// `<unpositioned-fields-least>`.
		case least = "a"
	}

	/// `<unpositioned-field-placement>`: whether `<descending>` reverses the
	/// location of an unpositioned field.
	enum UnpositionedFieldPlacement: Character {
		/// `<fixed-unpositioned-fields>`.
		case fixed = "f"
		/// `<relative-unpositioned-fields>`.
		case relative = "r"
	}

	var direction = SortOptionSet.Direction.ascending
	var unpositionedFieldComparison = UnpositionedFieldComparison.greatest
	var unpositionedFieldPlacement = UnpositionedFieldPlacement.relative

	/// Whether an unpositioned field precedes every positioned one.
	var isUnpositionedFieldFirst: Bool {
		(unpositionedFieldComparison == .least) != (unpositionedFieldPlacement == .relative && direction == .descending)
	}
}

extension FieldOrder {
	/// Reorders `fieldSpecs`, followed by `unlisted` (the field specs of visible
	/// unlisted fields, in order of their 1st occurrence in the input), per this
	/// order. `.inherited` & `.document` (which orders each item's fields
	/// independently; see `itemMembers(_:for:)`) are identity. `.positional`
	/// orders `unlisted`, as unpositioned fields, reversed iff `.descending`, 1st
	/// iff `isUnpositionedFieldFirst`, else last. `.byName` / `.byLabel` sort per
	/// their `<sort-option-set>` (direction included:
	/// `SortOptionSet.compare(_:_:)` already accounts for it), ordering ties by
	/// position, or by reverse position iff `tiebreakDirection` is `.descending`.
	func applied(to fieldSpecs: [FieldSpec], unlisted: [FieldSpec]) -> [FieldSpec] {
		switch self {
		case .document, .inherited:
			fieldSpecs + unlisted
		case let .positional(optionSet) where optionSet.isUnpositionedFieldFirst:
			unlisted.ordered(optionSet.direction) + fieldSpecs
		case let .positional(optionSet):
			fieldSpecs + unlisted.ordered(optionSet.direction)
		case let .byName(optionSet, tiebreakDirection):
			(fieldSpecs + unlisted).sorted(by: \.name, optionSet: optionSet, tiebreakDirection: tiebreakDirection)
		case let .byLabel(optionSet, tiebreakDirection):
			(fieldSpecs + unlisted).sorted(by: \.label, optionSet: optionSet, tiebreakDirection: tiebreakDirection)
		}
	}
}

private extension [FieldSpec] {
	/// These field specs, reversed iff `direction` is `.descending`.
	func ordered(_ direction: SortOptionSet.Direction) -> Self {
		direction == .ascending ? self : reversed()
	}

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
	/// `fieldSpecs`' members in `object` (fields.md "Members"), each with its
	/// value (`nil` for a field spec whose field `object` lacks, which formats
	/// its absent value once), each field spec's members in input order: for
	/// `<document-order>`, each member at its own position among `object`'s keys,
	/// reversed iff `.descending`, and field specs for absent fields 1st iff
	/// `isUnpositionedFieldFirst`, else last, ties ordered by position, or by
	/// reverse position iff `tiebreakDirection` is `.descending`; otherwise, in
	/// `fieldSpecs`' order.
	func itemMembers(_ fieldSpecs: [FieldSpec], for object: JSON.Object)
	-> [(fieldSpec: FieldSpec, value: JSON.Node?)] {
		let members = fieldSpecs.enumerated().flatMap { offset, fieldSpec in
			let fieldMembers = object.fields.enumerated().filter { $0.element.key.rawValue == fieldSpec.name }
			return fieldMembers.isEmpty
				? [(offset: offset, documentPosition: Int?.none, fieldSpec: fieldSpec, value: JSON.Node?.none)]
				: fieldMembers.map { member in
					(offset: offset, documentPosition: member.offset, fieldSpec: fieldSpec, value: member.element.value)
				}
		}
		guard case let .document(optionSet, tiebreakDirection) = self else {
			return members.map { ($0.fieldSpec, $0.value) }
		}
		func isTiebrokenBefore(_ lhsOffset: Int, _ rhsOffset: Int) -> Bool {
			tiebreakDirection == .ascending ? lhsOffset < rhsOffset : lhsOffset > rhsOffset
		}
		let presentMembers = members
			.compactMap { member in member.documentPosition.map { (position: $0, member: member) } }
			.sorted { lhs, rhs in
				lhs.position == rhs.position
					? isTiebrokenBefore(lhs.member.offset, rhs.member.offset)
					: (lhs.position < rhs.position) == (optionSet.direction == .ascending)
			}
			.map(\.member)
		let absentMembers = members.filter { $0.documentPosition == nil }.sorted { isTiebrokenBefore($0.offset, $1.offset) }
		return (optionSet.isUnpositionedFieldFirst ? absentMembers + presentMembers : presentMembers + absentMembers)
			.map { ($0.fieldSpec, $0.value) }
	}
}

extension BaseIncludesAllFieldsConfig {
	/// `all`'s own default field order, absent a built-in field order: sorted by
	/// label (`<output>`), while other `<sort-option>`s are per the defaults for
	/// string fields for `outputFormat`. Applied only if a command has not
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
				)
			},
			fieldOrder: fieldOrder,
			itemSort: itemSort,
		)
	}
}
