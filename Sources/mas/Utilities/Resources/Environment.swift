//
// Environment.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
private import os

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

	private let tokenProvider: TokenProvider

	var token: String {
		get async throws {
			try await tokenProvider.token(using: dataFrom, tokenURL: tokenURL)
		}
	}

	init(
		dataFrom: // swiftformat:disable:next indent
			@escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = URLSession(configuration: .ephemeral).data,
		lookupAppFromAppID: @escaping @Sendable (AppID) async throws -> CatalogApp = lookup,
		searchForAppsMatchingSearchTerm: @escaping @Sendable (String) async throws -> [CatalogApp] = search,
	) {
		self.dataFrom = dataFrom
		self.lookupAppFromAppID = lookupAppFromAppID
		self.searchForAppsMatchingSearchTerm = searchForAppsMatchingSearchTerm
		tokenProvider = .init()
	}
}

private final class TokenProvider: Sendable { // swiftlint:disable:this one_declaration_per_file
	private let taskGate = OSAllocatedUnfairLock(initialState: Task<String, any Error>?.none)

	deinit {
		// Empty
	}

	func token(
		using dataFrom: @escaping @Sendable (URLRequest) async throws -> (data: Data, response: URLResponse),
		tokenURL: URL,
	) async throws -> String {
		let task = taskGate.withLock { task in
			if let existing = task {
				return existing
			}
			let newTask = Task {
				struct TokenResponse: Decodable {
					let token: String
				}
				let (data, _) = try await dataFrom(.init(url: tokenURL))
				return try JSONDecoder().decode(TokenResponse.self, from: data).token
			}
			task = newTask
			return newTask
		}
		return try await task.value
	}
}
