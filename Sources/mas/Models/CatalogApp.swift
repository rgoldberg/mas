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
		let token = try await fetchToken()
		let regionCode = region.lowercased()
		switch appID {
		case let .adamID(adamID):
			var components = URLComponents(string: "https://amp-api.apps.apple.com/v1/catalog/\(regionCode)/apps/\(adamID)")!
			components.queryItems = [
				.init(name: "platform", value: "mac"),
				.init(name: "additionalPlatforms", value: "appletv,ipad,iphone,watch"),
			]
			guard let url = components.url else {
				return nil
			}

			return try parseApp(
				from: try await Environment.current
					.dataFrom(
						.init(url: url, headers: ["Authorization": "Bearer \(token)", "Origin": "https://apps.apple.com"]),
					)
					.data,
			)
		case let .bundleID(bundleID):
			var components = URLComponents(string: "https://amp-api.apps.apple.com/v1/catalog/\(regionCode)/search")!
			components.queryItems = [
				.init(name: "term", value: bundleID),
				.init(name: "types", value: "apps"),
				.init(name: "platform", value: "mac"),
				.init(name: "limit", value: "1"),
			]
			guard let url = components.url else {
				return nil
			}

			return try parseSearchApps(
				from: try await Environment.current
					.dataFrom(
						.init(url: url, headers: ["Authorization": "Bearer \(token)", "Origin": "https://apps.apple.com"]),
					)
					.data,
			)
			.first
		}
	}

	static func search(for term: String) async throws -> [Self] {
		try await search(for: term, in: appStoreRegion)
	}

	static func search(for term: String, in region: Region) async throws -> [Self] {
		let token = try await fetchToken()
		let regionCode = region.lowercased()
		var components = URLComponents(string: "https://amp-api.apps.apple.com/v1/catalog/\(regionCode)/search")!
		components.queryItems = [
			.init(name: "term", value: term),
			.init(name: "types", value: "apps"),
			.init(name: "platform", value: "mac"),
			.init(name: "limit", value: "20"),
		]
		guard let url = components.url else {
			return .init()
		}

		return try parseSearchApps(
			from: try await Environment.current
				.dataFrom(
					.init(url: url, headers: ["Authorization": "Bearer \(token)", "Origin": "https://apps.apple.com"]),
				)
				.data,
		)
	}
}

private extension CatalogApp {
	static func fetchToken() async throws -> String {
		var components = URLComponents(string: "https://sf-api-token-service.itunes.apple.com/apiToken")!
		components.queryItems = [
			.init(name: "clientClass", value: "apple"),
			.init(name: "clientId", value: "appstore"),
			.init(name: "os", value: "macOS"),
		]
		guard let url = components.url else {
			return ""
		}

		struct TokenResponse: Decodable {
			let token: String
		}

		return try JSONDecoder()
			.decode(TokenResponse.self, from: try await Environment.current.dataFrom(.init(url: url)).data)
			.token
	}

	static func parseApp(from data: Data) throws -> CatalogApp? {
		guard
			let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
			let dataArray = json["data"] as? [[String: Any]],
			let firstApp = dataArray.first
		else {
			return nil
		}

		return try makeCatalogApp(from: firstApp)
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
