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

	@Required(URL(string: "https://amp-api.apps.apple.com/v1/catalog"))
	var catalogURL

	let dataFrom: @Sendable (URLRequest) async throws -> (data: Data, response: URLResponse)
	let lookupAppFromAppID: @Sendable (AppID) async throws -> CatalogApp
	let searchForAppsMatchingSearchTerm: @Sendable (String) async throws -> [CatalogApp]
	let token: AsyncLazy<Result<String, any Error>>

	init(
		dataFrom: // swiftformat:disable:next indent
			@escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = URLSession(configuration: .ephemeral).data,
		lookupAppFromAppID: @escaping @Sendable (AppID) async throws -> CatalogApp = lookup,
		searchForAppsMatchingSearchTerm: @escaping @Sendable (String) async throws -> [CatalogApp] = search,
	) {
		self.dataFrom = dataFrom
		self.lookupAppFromAppID = lookupAppFromAppID
		self.searchForAppsMatchingSearchTerm = searchForAppsMatchingSearchTerm

		token = .init {
			do {
				struct TokenResponse: Decodable {
					let token: String
				}
				@Required(
					URL(
						string: // swiftformat:disable:next indent
							"https://sf-api-token-service.itunes.apple.com/apiToken?clientClass=apple&clientId=appstore&os=macOS",
					),
				)
				var tokenURL
				return
					.success(try JSONDecoder().decode(TokenResponse.self, from: try await dataFrom(.init(url: tokenURL)).0).token)
			} catch {
				return .failure(error)
			}
		}
	}

	func catalogData(from url: URL) async throws -> Data {
		try await dataFrom(
			.init(
				url: url,
				headers: ["Authorization": "Bearer \(token.value)", "Origin": "https://apps.apple.com"],
			),
		)
		.data
	}
}
