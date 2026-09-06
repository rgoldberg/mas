//
// CatalogApp.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

private import Foundation
private import JSONAST
private import JSONDecoding
private import JSONParsing

struct CatalogApp {
	let adamID: ADAMID
	let appStorePageURLString: String
	let minimumOSVersion: String
	let name: String
	let sellerURLString: String?
	let version: String

	private let lazyJSON: Lazy<String>

	private init(
		adamID: ADAMID,
		appStorePageURLString: String,
		minimumOSVersion: String,
		name: String,
		sellerURLString: String?,
		version: String,
		jsonObject: JSON.Object,
	) {
		self.adamID = adamID
		self.appStorePageURLString = appStorePageURLString
		self.minimumOSVersion = minimumOSVersion
		self.name = name
		self.sellerURLString = sellerURLString
		self.version = version
		lazyJSON = .init(.init(jsonObject.normalized))
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

extension CatalogApp: JSONDecodable {
	fileprivate init(json: JSON.Node) throws {
		guard case let .object(object) = json else {
			throw MASError.invalidJSON(.init(json))
		}

		try self.init(object: object)
	}

	fileprivate init(object: JSON.Object) throws {
		self.init(
			adamID: try object["id"]?.decode() ?? 0,
			appStorePageURLString: try object["attributes.url"]?.decode() ?? "",
			minimumOSVersion: try object["attributes.minimumOsVersion"]?.decode() ?? "", // minimumMacOSVersion
			name: try object["attributes.name"]?.decode() ?? "",
			sellerURLString: try object["attributes.sellerUrl"]?.decode(),
			version: try object["attributes.version"]?.decode() ?? "",
			jsonObject: object,
		)
	}
}

private extension JSON.Node {
	var normalized: Self {
		switch self {
		case let .object(object):
			.object(object.normalized)
		case let .array(array):
			.array(array.normalized)
		default:
			self
		}
	}
}

private extension JSON.Array {
	var normalized: Self {
		.init(elements.map(\.normalized))
	}
}

private extension JSON.Object {
	var normalized: Self {
		.init(
			fields
				.map { ($0, $1.normalized) }
				.sorted(using: KeyPathComparator(\.0.rawValue, comparator: NumericStringComparator.forward)),
		)
	}
}

func lookup(appID: AppID) async throws -> CatalogApp {
	try await lookup(appID: appID, in: appStoreRegion) ?? { throw MASError.unknownAppID(appID) }()
}

private func lookup(appID: AppID, in region: Region) async throws -> CatalogApp? {
	switch appID {
	case let .adamID(adamID):
		try .init(
			json: .init(
				parsing: try await Environment.current
					.catalogData(
						from: Environment.current
							.catalogURL
							.appending(path: "/\(region.lowercased())/apps/\(adamID)")
							.appending(
								queryItems: [
									.init(name: "platform", value: "mac"),
									.init(name: "additionalPlatforms", value: "appletv,ipad,iphone,watch"),
								],
							),
					)
						.bytes, // swiftformat:disable:this indent
			),
		)
	case let .bundleID(bundleID):
		try parseSearchApps(
			from: try await Environment.current.catalogData(from: searchURL(for: bundleID, limit: 1, region: region)),
		)
		.first
	}
}

func search(for term: String) async throws -> [CatalogApp] {
	try await search(for: term, in: appStoreRegion)
}

private func search(for term: String, in region: Region) async throws -> [CatalogApp] {
	try parseSearchApps(
		from: try await Environment.current.catalogData(from: searchURL(for: term, limit: 20, region: region)),
	)
}

private func parseSearchApps(from data: Data) throws -> [CatalogApp] {
	[try .init(json: .init(parsing: data.bytes))]
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
