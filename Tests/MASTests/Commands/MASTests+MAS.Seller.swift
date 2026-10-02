//
// MASTests+MAS.Seller.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `cannot find seller URL for unknown app ID`() async throws {
		let actual =
			try await consequencesOf(try await MAS.main(try MAS.Seller.parse(["1"])) { await $0.run(catalogApps: .init()) })
		let expected = Consequences()
		#expect(actual == expected)
	}

	@Test
	func `does not open non-web seller URL`() async throws {
		let url = "file:///nonexistent.app"
		let actual = try await consequencesOf(
			try await MAS.main(try MAS.Seller.parse(["1"])) { command in
				await command.run(catalogApps: [try decode(fromJSON: #"{"trackId":1,"sellerUrl":"\#(url)"}"#)])
			},
		)
		let expected = Consequences(nil, "", "Error: \(MASError.invalidURL(url))\n")
		#expect(actual == expected)
	}
}
