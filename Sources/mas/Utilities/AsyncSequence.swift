//
// AsyncSequence.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

extension AsyncSequence where Self: Sendable {
	var array: [Element] {
		get async throws {
			try await reduce(into: [Element]()) { $0.append($1) }
		}
	}
}
