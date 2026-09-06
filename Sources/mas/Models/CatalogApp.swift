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

private extension CatalogApp {
	init?(from appDict: [String: Any]) throws {
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
		self.init(
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

func lookup(appID: AppID) async throws -> CatalogApp {
	try await lookup(appID: appID, in: appStoreRegion) ?? { throw MASError.unknownAppID(appID) }()
}

func lookup(appID: AppID, in region: Region) async throws -> CatalogApp? {
	switch appID {
	case let .adamID(adamID):
		try parseApp(
			from: try await Environment.current.catalogData(
				from: Environment.current
					.catalogURL
					.appending(path: "/\(region.lowercased())/apps/\(adamID)")
					.appending(
						queryItems: [
							.init(name: "platform", value: "mac"),
							.init(name: "additionalPlatforms", value: "appletv,ipad,iphone,watch"),
						],
					),
			),
		)
	case let .bundleID(bundleID):
		try parseSearchApps(
			from: try await Environment.current.catalogData(from: searchURL(for: bundleID, limit: 1, region: region)),
		)
		.first
	}
}

private func searchURL(for term: String, limit: UInt, region: Region) -> URL {
	Environment.current
		.catalogURL
		.appending(path: "/\(region.lowercased())/search")
		.appending(
			queryItems: [
				.init(name: "types", value: "apps"),
				.init(name: "platform", value: "mac"),
				.init(name: "limit", value: .init(limit)),
				.init(name: "term", value: term),
			],
		)
}

func search(for term: String) async throws -> [CatalogApp] {
	try await search(for: term, in: appStoreRegion)
}

func search(for term: String, in region: Region) async throws -> [CatalogApp] {
	try parseSearchApps(
		from: try await Environment.current.catalogData(from: searchURL(for: term, limit: 20, region: region)),
	)
}

private func parseApp(from data: Data) throws -> CatalogApp? {
	try ((try JSONSerialization.jsonObject(with: data) as? [String: Any])?["data"] as? [[String: Any]])?
		.first
		.flatMap(CatalogApp.init)
}

private func parseSearchApps(from data: Data) throws -> [CatalogApp] {
	guard
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
		let results = json["results"] as? [String: Any],
		let apps = results["apps"] as? [String: Any],
		let dataArray = apps["data"] as? [[String: Any]]
	else {
		return .init()
	}

	return try dataArray.compactMap(CatalogApp.init)
}
