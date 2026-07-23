//
// BidirectionalCollection.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

extension BidirectionalCollection {
	func dropLast(while predicate: (Element) throws -> Bool) rethrows -> SubSequence {
		try indices.reversed().first { try !predicate(self[$0]) }.map { self[...$0] } ?? self[endIndex...]
	}
}
