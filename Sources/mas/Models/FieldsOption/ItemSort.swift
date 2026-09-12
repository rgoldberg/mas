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
	let tiebreakDirection: SortSpec.Direction

	/// Sorts `objects`' indices per `keys` (highest-priority first), falling
	/// back to `tiebreakDirection` for objects left unordered by every key.
	/// `stringValue(index:key:)` reads a field's rendered value for a given
	/// object & sort key, letting the caller decide, e.g., how absent values are
	/// treated, & which of the field's input / output values to read for
	/// `key.sortSpec.source`.
	func sortedIndices(count: Int, stringValue: (_ index: Int, _ key: ItemSortKey) -> String?) -> [Int] {
		guard !keys.isEmpty else {
			return tiebreakDirection == .ascending ? .init(0..<count) : .init((0..<count).reversed())
		}
		let orderedKeys = keys.sorted(using: KeyPathComparator(\.sortSpec.priority))
		return (0..<count).sorted { lhsIndex, rhsIndex in
			for key in orderedKeys {
				switch key.sortSpec.compare(stringValue(lhsIndex, key), stringValue(rhsIndex, key)) {
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
/// applies its sort.
struct ItemSortKey: Equatable { // swiftlint:disable:this one_declaration_per_file
	let name: String
	let sortSpec: SortSpec
}
