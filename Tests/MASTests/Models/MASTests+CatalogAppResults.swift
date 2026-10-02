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

	@Test
	func `a non-object catalog app result reports only that result & its RFC 9535 normalized path`() {
		let error = #expect(throws: MASError.self) {
			try decode(CatalogAppResults.self, fromJSON: #"{"resultCount":2,"results":[{},[1,2]]}"#)
		}
		#expect(error?.description == "Failed to parse JSON value at $['results'][1]:\n[1,2]")
	}
}
