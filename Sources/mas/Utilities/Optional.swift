//
// Optional.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

extension Optional {
	// periphery:ignore
	func map<E: Error, U: ~Copyable>(_ transform: (Wrapped) async throws(E) -> U) async throws(E) -> U? {
		guard let self else { // swiftlint:disable:previous unused_declaration
			return nil
		}

		return try await transform(self)
	}

	func flatMap<E: Error, U: ~Copyable>(_ transform: (Wrapped) async throws(E) -> U?) async throws(E) -> U? {
		guard let self else {
			return nil
		}

		return try await transform(self)
	}
}
