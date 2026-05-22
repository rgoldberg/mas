//
// MASTests+CatalogApp.swift
// mas
//
// Copyright © 2020 mas-cli. All rights reserved.
//

private import Foundation // swiftlint:disable:this unused_import
@testable private import mas
private import ObjectiveC
internal import Testing

private extension MASTests {
	@Test
	func `parses catalog app from things that go bump JSON`() {
		let actual = consequencesOf(try decode(CatalogApp.self, fromResource: "things-lookup").adamID)
		let expected = Consequences(ADAMID(1_472_954_003))
		#expect(actual == expected)
	}

	@Test
	func `iTunes searches for slack`() async {
		let actual = await consequencesOf(
			try await Environment.$current.withValue(.init { _ in (try .init(fromResource: "slack"), .init()) }) {
				try await search(for: "slack").count
			},
		)
		let expected = Consequences(39)
		#expect(actual == expected)
	}

	@Test
	func `looks up slack`() async throws {
		let adamID = ADAMID(803_453_959)
		let actual = await consequencesOf(
			try await Environment.$current.withValue(.init { _ in (try .init(fromResource: "slack-lookup"), .init()) }) {
				try await lookup(appID: .adamID(adamID))
			},
		)
		#expect(actual.error == nil)
		#expect(actual.stdout.isEmpty)
		#expect(actual.stderr.isEmpty)
		let catalogApp = try #require(actual.value)
		#expect(catalogApp.adamID == adamID)
		#expect(catalogApp.appStorePageURLString == "https://apps.apple.com/us/app/slack-for-desktop/id803453959?mt=12")
		#expect(catalogApp.minimumOSVersion == "10.9")
		#expect(catalogApp.name == "Slack")
		#expect(catalogApp.sellerURLString == "https://slack.com")
		#expect(catalogApp.version == "3.3.3")
	}
}
