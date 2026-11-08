//
// FieldOrder.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation
internal import JSONAST

// MARK: - Field ordering (fields.md)

enum FieldOrder: Equatable {
	/// `<source>` `"O"`: sorts by label, per the `<field-order-sort-option-set>`.
	case byLabel(SortOptionSet)
	/// `<source>` `"I"`: sorts by name, per the `<field-order-sort-option-set>`.
	case byName(SortOptionSet)
	/// `<document-order>` (`"D"`): each item's fields in the order of its own
	/// `JSON.Object`'s keys (`CatalogApp` / `InstalledApp` normalization only
	/// renames keys, never reorders them), per `optionSet` &
	/// `itemMembers(_:for:tiebreakDirection:)`.
	case document(OrderOptionSet)
	/// `<positional-order>` (`"P"`): the working fields config's field specs by
	/// position, per `optionSet`. Its `<descending>` reverses their positions
	/// while parsing, before `<field-spec-edits-section>`, but also orders
	/// unpositioned (i.e., visible unlisted) fields; see
	/// `applied(to:unlisted:tiebreakDirection:)`.
	case positional(OrderOptionSet)
}

/// A field order's kind (fields.md `<primary-field-order-kind>`).
enum PrimaryFieldOrderKind { // swiftlint:disable:this one_declaration_per_file
	/// `<document-order>` (`"D"`).
	case document
	/// `<output>` (`"O"`): sorted by label.
	case label
	/// `<input>` (`"I"`): sorted by name.
	case name
	/// `<positional-order>` (`"P"`).
	case positional
}

/// A fields config's field order, its saved field order of each primary field
/// order kind (the field order's included) & its field order tiebreaker
/// (fields.md "Field Order").
struct FieldOrders: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// The field order.
	private(set) var fieldOrder: FieldOrder

	/// The effective `<field-order-tiebreaker>`'s `<direction>`, independent of
	/// `fieldOrder`'s kind.
	var tiebreakDirection = SortOptionSet.Direction.ascending

	/// Each kind's saved field order; a missing kind's is the app's default field
	/// order of that kind (see `savedFieldOrder(of:outputFormat:)`).
	private var savedFieldOrderByKind: [PrimaryFieldOrderKind: FieldOrder]

	init(_ fieldOrder: FieldOrder = .positional(.init())) {
		self.fieldOrder = fieldOrder
		savedFieldOrderByKind = [fieldOrder.kind: fieldOrder]
	}

	/// The saved field order of `kind`, else the app's default field order of
	/// `kind` for `outputFormat`, which every built-in fields config saves.
	func savedFieldOrder(of kind: PrimaryFieldOrderKind, outputFormat: OutputFormat) -> FieldOrder {
		savedFieldOrderByKind[kind] ?? defaultFieldOrder(of: kind, outputFormat: outputFormat)
	}

	/// Saves `fieldOrder` as the field order & as its kind's saved field order.
	mutating func save(_ fieldOrder: FieldOrder) {
		self.fieldOrder = fieldOrder
		savedFieldOrderByKind[fieldOrder.kind] = fieldOrder
	}

	/// `fieldOrder.applied(to:unlisted:tiebreakDirection:)`, tiebreaking per
	/// `tiebreakDirection`.
	func applied(to fieldSpecs: [FieldSpec], unlisted: [FieldSpec]) -> [FieldSpec] {
		fieldOrder.applied(to: fieldSpecs, unlisted: unlisted, tiebreakDirection: tiebreakDirection)
	}

	/// `fieldOrder.itemMembers(_:for:tiebreakDirection:)`, tiebreaking per
	/// `tiebreakDirection`.
	func itemMembers(_ fieldSpecs: [FieldSpec], for object: JSON.Object)
	-> [(fieldSpec: FieldSpec, value: JSON.Node?)] {
		fieldOrder.itemMembers(fieldSpecs, for: object, tiebreakDirection: tiebreakDirection)
	}
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
	var kind: PrimaryFieldOrderKind {
		switch self {
		case .byLabel:
			.label
		case .byName:
			.name
		case .document:
			.document
		case .positional:
			.positional
		}
	}

	/// The `<positional-order-option-set>`'s or `<document-order-option-set>`'s
	/// options, else `nil`.
	var orderOptionSet: OrderOptionSet? {
		switch self {
		case let .document(optionSet), let .positional(optionSet):
			optionSet
		case .byLabel, .byName:
			nil
		}
	}

	/// The `<field-order-sort-option-set>`'s options, else `nil`.
	var sortOptionSet: SortOptionSet? {
		switch self {
		case let .byLabel(optionSet), let .byName(optionSet):
			optionSet
		case .document, .positional:
			nil
		}
	}

	/// Reorders `fieldSpecs`, followed by `unlisted` (the field specs of visible
	/// unlisted fields, in order of their 1st occurrence in the input), per this
	/// order. `.document` (which orders each item's fields independently; see
	/// `itemMembers(_:for:tiebreakDirection:)`) is identity. `.positional` orders
	/// `unlisted`, as unpositioned fields, reversed iff `.descending`, 1st iff
	/// `isUnpositionedFieldFirst`, else last. `.byName` / `.byLabel` sort per
	/// their `<field-order-sort-option-set>` (direction included:
	/// `SortOptionSet.compare(_:_:)` already accounts for it), ordering ties by
	/// position, or by reverse position iff `tiebreakDirection` is `.descending`.
	func applied(to fieldSpecs: [FieldSpec], unlisted: [FieldSpec], tiebreakDirection: SortOptionSet.Direction)
	-> [FieldSpec] {
		switch self {
		case .document:
			fieldSpecs + unlisted
		case let .positional(optionSet) where optionSet.isUnpositionedFieldFirst:
			unlisted.ordered(optionSet.direction) + fieldSpecs
		case let .positional(optionSet):
			fieldSpecs + unlisted.ordered(optionSet.direction)
		case let .byName(optionSet):
			(fieldSpecs + unlisted).sorted(by: \.name, optionSet: optionSet, tiebreakDirection: tiebreakDirection)
		case let .byLabel(optionSet):
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
	func itemMembers(
		_ fieldSpecs: [FieldSpec],
		for object: JSON.Object,
		tiebreakDirection: SortOptionSet.Direction,
	) -> [(fieldSpec: FieldSpec, value: JSON.Node?)] {
		let members = fieldSpecs.enumerated().flatMap { offset, fieldSpec in
			let fieldMembers = object.fields.enumerated().filter { $0.element.key.rawValue == fieldSpec.name }
			return fieldMembers.isEmpty
				? [(offset: offset, documentPosition: Int?.none, fieldSpec: fieldSpec, value: JSON.Node?.none)]
				: fieldMembers.map { member in
					(offset: offset, documentPosition: member.offset, fieldSpec: fieldSpec, value: member.element.value)
				}
		}
		guard case let .document(optionSet) = self else {
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

// MARK: - Field order parsing primitives (fields.md "Field Order")

/// Parses a `<field-order-tiebreaker>` after its section's
/// `<field-order-section-prefix>` iff `input` starts with
/// `<field-order-tiebreaker-prefix>`, returning its `<direction>`, else `nil`;
/// its `<direction>` must end its section.
func parseFieldOrderTiebreaker(_ input: inout Substring) throws(ParsingError) -> SortOptionSet.Direction? {
	guard input.first == fieldOrderTiebreakerPrefix else {
		return nil
	}
	input = input.dropFirst().drop(while: \.isWhitespace)
	guard let direction = input.first.flatMap(SortOptionSet.Direction.init(rawValue:)) else {
		throw .missingFieldOrderTiebreakerDirection
	}
	input = input.dropFirst().drop(while: \.isWhitespace)
	if let char = input.first, char != fieldSpecSeparator, !itemSortAndFieldSpecEditsPrefixSet.contains(char) {
		throw .unexpectedCharacter(char)
	}
	return direction
}

/// The `<order>` letter (`P` / `D`) of `input`'s
/// `<primary-field-order-option-set>` (up to, but not including, its
/// terminating `<field-spec-separator>` / `<item-sort-section-prefix>` /
/// `<field-spec-edits-section-prefix>`) iff it is a
/// `<positional-order-option-set>` / `<document-order-option-set>`: every
/// top-level character is a `<direction>`, an
/// `<unpositioned-field-comparison>`, an `<unpositioned-field-placement>`, or
/// an `<order>`, with at least 1 `<order>` (last wins); or iff it is a
/// `<field-order-adjustment-set>` (every top-level character is a
/// `<adjustment-sort-option>`: a `<direction>`, a `<nonconforming-comparison>`,
/// or a `<nonconforming-placement>`) & `inheritedFieldOrder` is `.positional` /
/// `.document`, as whose alternative it is parsed. `nil` means it is a
/// `<field-order-sort-option-set>`, or a `<field-order-adjustment-set>` parsed
/// as one, instead: the alternatives share no valid text (a sequence with no
/// `<order>` & a `<non-adjustment-sort-option>` can only be
/// `<field-order-sort-option-set>`, as can one with an `<order>` &
/// `<all-conforming>`), so checking without consuming `input` is safe.
func orderOptionSetOrder(_ input: Substring, inheriting inheritedFieldOrder: FieldOrder) -> Character? {
	var order = Character?.none
	var hasAllConforming = false
	for char in input {
		if char == fieldSpecSeparator || itemSortAndFieldSpecEditsPrefixSet.contains(char) {
			break
		}
		if orderOptionSet.contains(char) {
			order = char
		} else if char == SortOptionSet.NonconformingComparison.allConforming.rawValue {
			hasAllConforming = true
		} else if
			!char.isWhitespace,
			SortOptionSet.Direction(rawValue: char) == nil,
			OrderOptionSet.UnpositionedFieldComparison(rawValue: char) == nil,
			OrderOptionSet.UnpositionedFieldPlacement(rawValue: char) == nil
		{
			return nil
		}
	}
	return switch (order, inheritedFieldOrder) {
	case (nil, .document):
		documentOrderOption
	case (nil, .positional):
		positionalOrderOption
	default:
		hasAllConforming ? nil : order
	}
}

let positionalOrderOption = Character("P")
let documentOrderOption = Character("D")
private let orderOptionSet = Set([positionalOrderOption, documentOrderOption])
