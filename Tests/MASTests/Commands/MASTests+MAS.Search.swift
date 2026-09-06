//
// MASTests+MAS.Search.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

private import ArgumentParser
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `cannot search for nonexistent app`() async throws {
		let searchTerm = "nonexistent"
		let actual =
			try await consequencesOf(try MAS.main(try MAS.Search.parse([searchTerm])) { try $0.run(catalogApps: .init()) })
		let expected = Consequences(nil, "", "Error: \(MASError.noCatalogAppsFound(for: searchTerm))\n")
		#expect(actual == expected)
	}
}
