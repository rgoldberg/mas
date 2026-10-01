//
// ItemSort.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

/// The resolved `<item-sort-section>`, as modified by any per-field
/// `<sort-modifier>`s.
struct ItemSort: Equatable {
	static let empty = Self(keys: .init(), tiebreakDirection: .ascending)

	/// Ascending `sortSpec.priority` = higher sort precedence.
	let keys: [ItemSortKey]
	/// `<item-sort-option-set>`'s `<direction>`: tiebreaks items with no
	/// distinguishing sort key by input order (`.ascending`) or reverse input
	/// order (`.descending`).
	let tiebreakDirection: SortOptionSet.Direction

	/// Sorts `count` items' indices per `keys` (highest-priority 1st), falling
	/// back to `tiebreakDirection` for items left unordered by every key.
	/// `values(index:key:)` provides an item's values for a sort key.
	func sortedIndices(count: Int, values: (_ index: Int, _ key: ItemSortKey) -> SortValues) -> [Int] {
		guard !keys.isEmpty else {
			return tiebreakDirection == .ascending ? .init(0..<count) : .init((0..<count).reversed())
		}
		let orderedKeys = keys.sorted(using: KeyPathComparator(\.sortSpec.priority))
		return (0..<count).sorted { lhsIndex, rhsIndex in
			for key in orderedKeys {
				switch key.sortSpec.compare(
					values(lhsIndex, key),
					values(rhsIndex, key),
					typeDeterminant: key.typeDeterminant,
				) {
				case .orderedAscending:
					return true
				case .orderedDescending:
					return false
				case .orderedSame:
					continue
				}
			}
			return tiebreakDirection == .ascending ? lhsIndex < rhsIndex : lhsIndex > rhsIndex
		}
	}
}

/// 1 member of `ItemSort.keys`: a field name paired with the `SortSpec` that
/// applies its sort & its field's type determinant.
struct ItemSortKey: Equatable { // swiftlint:disable:this one_declaration_per_file
	let name: String
	let sortSpec: SortSpec
	let typeDeterminant: TypeDeterminant
}

extension [FieldSpec] {
	/// The sort keys of these field specs' enabled `<sort>`s: a `<sort-priority>`
	/// of `0` disables a field spec's sort, retaining its `<sort-option-set>`
	/// without sorting items.
	var enabledSortKeys: [ItemSortKey] {
		compactMap { fieldSpec in
			fieldSpec.sortSpec.flatMap { sortSpec in
				sortSpec.priority == 0
					? nil
					: .init(name: fieldSpec.name, sortSpec: sortSpec, typeDeterminant: fieldSpec.format.typeDeterminant)
			}
		}
	}
}
