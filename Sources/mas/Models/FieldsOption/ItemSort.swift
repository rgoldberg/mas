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
	/// `values(index:keyIndex:)` provides an item's values for the sort key at
	/// `keyIndex` in `keys`.
	func sortedIndices(count: Int, values: (_ index: Int, _ keyIndex: Int) -> SortValues) -> [Int] {
		guard !keys.isEmpty else {
			return tiebreakDirection == .ascending ? .init(0..<count) : .init((0..<count).reversed())
		}
		let orderedKeyIndices = keys.indices.sorted { keys[$0].sortSpec.priority < keys[$1].sortSpec.priority }
		return (0..<count).sorted { lhsIndex, rhsIndex in
			for keyIndex in orderedKeyIndices {
				let key = keys[keyIndex]
				switch key.sortSpec.compare(
					values(lhsIndex, keyIndex),
					values(rhsIndex, keyIndex),
					typeDeterminant: key.fieldSpec.format.typeDeterminant,
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

/// 1 member of `ItemSort.keys`: a field spec, paired with the `SortSpec` that
/// applies its sort.
struct ItemSortKey: Equatable { // swiftlint:disable:this one_declaration_per_file
	let fieldSpec: FieldSpec
	let sortSpec: SortSpec
}

extension [FieldSpec] {
	/// The sort keys of these field specs' enabled `<sort>`s: a `<sort-priority>`
	/// of `0` disables a field spec's sort, retaining its `<sort-option-set>`
	/// without sorting items.
	var enabledSortKeys: [ItemSortKey] {
		compactMap { fieldSpec in
			fieldSpec.sortSpec.flatMap { sortSpec in
				sortSpec.priority == 0 ? nil : .init(fieldSpec: fieldSpec, sortSpec: sortSpec)
			}
		}
	}
}

extension FieldSpec {
	/// This field spec unchanged if it has no `sortSpec` (nothing to disable);
	/// otherwise, its `sortSpec`'s `<sort-priority>` set to `0` (disabled),
	/// retaining its `<sort-option-set>`.
	var withSortDisabled: Self {
		sortSpec.map { sortSpec in
			.init(
				name: name,
				label: label,
				format: format,
				sortSpec: sortSpec.withPriority(0),
				isHidden: isHidden,
				isSynthesized: isSynthesized,
				justification: justification,
				outputsInput: outputsInput,
			)
		}
			?? self
	}
}
