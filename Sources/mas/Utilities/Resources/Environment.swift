//
// Environment.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

struct Environment {
	@TaskLocal
	static var current = Self()

	@Required(URL(string: "https://itunes.apple.com/lookup"))
	var lookupURL
	@Required(URL(string: "https://itunes.apple.com/search"))
	var searchURL
	@Required(
		URL(string: "https://sf-api-token-service.itunes.apple.com/apiToken?clientClass=apple&clientId=appstore&os=macOS"),
	)
	var tokenURL
	@Required(URL(string: "https://amp-api.apps.apple.com/v1/catalog"))
	var catalogURL

	let dataFrom: @Sendable (URLRequest) async throws -> (data: Data, response: URLResponse)
	let lookupAppFromAppID: @Sendable (AppID) async throws -> CatalogApp
	let searchForAppsMatchingSearchTerm: @Sendable (String) async throws -> [CatalogApp]

	init(
		dataFrom: // swiftformat:disable:next indent
			@escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = URLSession(configuration: .ephemeral).data,
		lookupAppFromAppID: @escaping @Sendable (AppID) async throws -> CatalogApp = lookup,
		searchForAppsMatchingSearchTerm: @escaping @Sendable (String) async throws -> [CatalogApp] = search,
	) {
		self.dataFrom = dataFrom
		self.lookupAppFromAppID = lookupAppFromAppID
		self.searchForAppsMatchingSearchTerm = searchForAppsMatchingSearchTerm
	}
}
