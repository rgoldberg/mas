//
// MASTests+CatalogAppResults.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `parses catalog app results from BBEdit JSON`() async throws {
		let actual = try await consequencesOf(try decode(CatalogAppResults.self, fromResource: "bbedit").resultCount)
		let expected = Consequences(1)
		#expect(actual == expected)
	}

	@Test
	func `parses catalog app results from Things JSON`() async throws {
		let actual = try await consequencesOf(try decode(CatalogAppResults.self, fromResource: "things").resultCount)
		let expected = Consequences(12)
		#expect(actual == expected)
	}
}
