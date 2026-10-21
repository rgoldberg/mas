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
	/// `<document-order>` (`"D"`): each item's fields in the order of its own
	/// `JSON.Object`'s keys (`CatalogApp` / `InstalledApp` normalization only
	/// renames keys, never reorders them), per `optionSet` &
	/// `itemMembers(_:for:)`, ties ordered per `tiebreakDirection`.
	case document(DocumentOrderOptionSet, tiebreakDirection: SortOptionSet.Direction)
	/// `<field-order-section>` absent: substituted, by
	/// `resolvedFieldsConfig(from:standard:all:outputFormat:)`, with the resolved
	/// base fields config's own `fieldOrder`.
	case inherited
	/// `<positional-order>` (`"P"`): the working fields config's field specs by
	/// position. Its `<descending>` reverses their positions while parsing,
	/// before `<field-spec-edits-section>`, so it needs no direction here.
	case positional
}

/// A `<document-order-option-set>`'s options other than its `<order>`s.
struct DocumentOrderOptionSet: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `<absent-field-comparison>`.
	enum AbsentFieldComparison: Character {
		/// `<absent-fields-greatest>`.
		case greatest = "z"
		/// `<absent-fields-least>`.
		case least = "a"
	}

	/// `<absent-field-placement>`: whether `<descending>` reverses the location
	/// of a field spec whose field an item lacks.
	enum AbsentFieldPlacement: Character {
		/// `<fixed-absent-fields>`.
		case fixed = "f"
		/// `<relative-absent-fields>`.
		case relative = "r"
	}

	var direction = SortOptionSet.Direction.ascending
	var absentFieldComparison = AbsentFieldComparison.greatest
	var absentFieldPlacement = AbsentFieldPlacement.relative

	/// Whether a field spec whose field an item lacks precedes every member.
	var isAbsentFieldFirst: Bool {
		(absentFieldComparison == .least) != (absentFieldPlacement == .relative && direction == .descending)
	}
}

extension FieldOrder {
	/// Reorders `fieldSpecs` per this order. `.inherited`, `.document` (which
	/// orders each item's fields independently; see `itemMembers(_:for:)`) &
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
	/// `fieldSpecs`' members in `object` (fields.md "Members"), each with its
	/// value (`nil` for a field spec whose field `object` lacks, which formats
	/// its absent value once), each field spec's members in input order: for
	/// `<document-order>`, each member at its own position among `object`'s keys,
	/// reversed iff `.descending`, and field specs for absent fields 1st iff
	/// `isAbsentFieldFirst`, else last, ties ordered by position, or by reverse
	/// position iff `tiebreakDirection` is `.descending`; otherwise, in
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
		return (optionSet.isAbsentFieldFirst ? absentMembers + presentMembers : presentMembers + absentMembers)
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
