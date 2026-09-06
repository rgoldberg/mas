//
// CatalogApp.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

private import Foundation

struct CatalogApp {
	let adamID: ADAMID
	let appStorePageURLString: String
	let minimumOSVersion: String
	let name: String
	let sellerURLString: String?
	let version: String

	private let lazyJSON: Lazy<String>
}

extension CatalogApp: CustomStringConvertible {
	var description: String {
		lazyJSON.value
	}
}

extension CatalogApp: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.adamID == rhs.adamID
	}
}

extension CatalogApp: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(adamID)
	}
}

extension CatalogApp {
	static func lookup(appID: AppID) async throws -> Self {
		try await lookup(appID: appID, in: appStoreRegion) ?? { throw MASError.unknownAppID(appID) }()
	}

	static func lookup(appID: AppID, in region: Region) async throws -> Self? {
		switch appID {
		case let .adamID(adamID):
			try parseApp(
				from:
					try await data(from: "https://amp-api.apps.apple.com/v1/catalog/\(region.lowercased())/apps/\(adamID)?platform=mac&additionalPlatforms=appletv,ipad,iphone,watch"),
			)
		case let .bundleID(bundleID):
			try parseSearchApps(
				from: try await data(
					from:
						"https://amp-api.apps.apple.com/v1/catalog/\(region.lowercased())/search?types=apps&platform=mac&limit=1&term=\(bundleID)",
				),
			)
			.first
		}
	}

	static func search(for term: String) async throws -> [Self] {
		try await search(for: term, in: appStoreRegion)
	}

	static func search(for term: String, in region: Region) async throws -> [Self] {
		try parseSearchApps(
			from: try await Environment.current
				.dataFrom(
					.init(
						url: .init(
							string: "https://amp-api.apps.apple.com/v1/catalog/\(region.lowercased())/search?types=apps&platform=mac&limit=20"
						)!
							.appending(queryItems: [.init(name: "term", value: term)]),
						headers: ["Authorization": "Bearer \(token)", "Origin": "https://apps.apple.com"]
					),
				)
				.data,
		)
	}
}

private extension CatalogApp {
	static func parseApp(from data: Data) throws -> CatalogApp? {
		try (
			(try JSONSerialization.jsonObject(with: data) as? [String: Any])?["data"] as? [[String: Any]])?.first
			.flatMap(makeCatalogApp(from:)
		)
	}

	static func parseSearchApps(from data: Data) throws -> [CatalogApp] {
		guard
			let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
			let results = json["results"] as? [String: Any],
			let apps = results["apps"] as? [String: Any],
			let dataArray = apps["data"] as? [[String: Any]]
		else {
			return .init()
		}

		return try dataArray.compactMap(makeCatalogApp)
	}

	static func makeCatalogApp(from appDict: [String: Any]) throws -> CatalogApp? {
		guard
			let idString = appDict["id"] as? String,
			let attributes = appDict["attributes"] as? [String: Any],
			let name = attributes["name"] as? String,
			let urlString = attributes["url"] as? String,
			let version = attributes["version"] as? String,
			let idInt = Int(idString)
		else {
			return nil
		}

		// Fallbacks handling variations across desktop platforms and universal apps
		let minimumOSVersion = (attributes["minimumMacOSVersion"] as? String)
			?? (attributes["minimumOSVersion"] as? String)
			?? "0.0"

		let sellerURLString = attributes["sellerUrl"] as? String ?? (attributes["artistUrl"] as? String)

		// Re-serialize keys uniformly to maintain downstream safety (e.g. `mas info` formatting)
		let normalizedDict: [String: Any] = [
			"adamID": idInt,
			"appStorePageURL": urlString,
			"minimumOSVersion": minimumOSVersion,
			"name": name,
			"sellerURL": sellerURLString as Any,
			"version": version,
		]
		let jsonString = String(
			data: try JSONSerialization.data(withJSONObject: normalizedDict, options: [.sortedKeys, .prettyPrinted]),
			encoding: .utf8,
		)
			?? "{}"
		return CatalogApp(
			adamID: .init(idInt),
			appStorePageURLString: urlString,
			minimumOSVersion: minimumOSVersion,
			name: name,
			sellerURLString: sellerURLString,
			version: version,
			lazyJSON: .init { jsonString },
		)
	}
}

private extension CatalogApp {
	static let token = try await fetchToken()

	private static func fetchToken() async throws -> String {
		struct TokenResponse: Decodable {
			let token: String
		}

		return try JSONDecoder()
		.decode(
			TokenResponse.self,
			from: try await Environment.current.dataFrom(
				.init(
					url: .init(string: "https://sf-api-token-service.itunes.apple.com/apiToken?clientClass=apple&clientId=appstore&os=macOS")!
				)
			)
			.data
		)
		.token
	}
}

private func data(from urlString: String) async throws -> Data {
	try await Environment.current.dataFrom(
		.init(
			url: .init(string: urlString)!,
			headers: ["Authorization": "Bearer \(CatalogApp.token)", "Origin": "https://apps.apple.com"],
		),
	)
		.data
}
