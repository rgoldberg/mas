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
private import Sextant
private import SwiftSoup

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

extension CatalogApp: JSONDecodable {
	fileprivate init(json: JSON.Node) throws {
		guard case let .object(object) = json else {
			throw MASError.invalidJSON(.init(json))
		}

		try self.init(object: object)
	}

	fileprivate init(object: JSON.Object) throws {
		self.init(
			adamID: try object["trackId"]?.decode() ?? 0,
			appStorePageURLString: try object["trackViewUrl"]?.decode() ?? "",
			minimumOSVersion: try object[minimumOSVersionKey]?.decode() ?? "",
			name: try object["trackName"]?.decode() ?? "",
			sellerURLString: try object["sellerUrl"]?.decode(),
			version: try object["version"]?.decode() ?? "",
			jsonObject: object,
		)
	}

	fileprivate init(nonMacOSApp object: JSON.Object) async throws {
		guard
			let appStorePageURLString = try object["trackViewUrl"]?.decode(to: String?.self),
			let minimumOSVersion = try? await URL(string: appStorePageURLString)
				.flatMap(
					{ url in
						try parse(try await Environment.current.dataFrom(url).data, appStorePageURLString)
							.getElementById("serialized-server-data")? // swiftformat:disable:this acronyms
							.data()
							.query(
								string: """
									$.data[0].data.shelfMapping.information.items[?(@.title == 'Compatibility')].items[?(@.heading == 'Mac')].text
									""",
							)?
							.firstMatch(of: minimumOSVersionRegex)
							.map { String($0.version) }
					},
				)
		else {
			try self.init(object: object)
			return
		}

		var object = object
		if try object[minimumOSVersionKey]?.decode() != minimumOSVersion {
			if let index = object.fields.firstIndex(where: { $0.key == minimumOSVersionKey }) {
				object.fields[index] = (minimumOSVersionKey, .string(minimumOSVersion))
			} else {
				object.fields.append((minimumOSVersionKey, .string(minimumOSVersion)))
			}
		}

		self.init(
			adamID: try object["trackId"]?.decode() ?? 0,
			appStorePageURLString: appStorePageURLString,
			minimumOSVersion: minimumOSVersion,
			name: try object["trackName"]?.decode() ?? "",
			sellerURLString: try object["sellerUrl"]?.decode(),
			version: try object["version"]?.decode() ?? "",
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
		var kind = String?.none
		var supportedDevicesJSON = JSON.Node?.none
		var fields = fields.map { key, value in
			switch key {
			case "kind":
				kind = value.as(String.self)
			case "supportedDevices":
				supportedDevicesJSON = value
			default:
				break
			}
			return (key.normalized, value.normalized)
		}
		if let platform = try? Platform(kind: kind, supportedDevicesJSON: supportedDevicesJSON) {
			fields.append(("platform", .string(.init(describing: platform))))
		}
		return .init(fields.sorted(using: KeyPathComparator(\.0.rawValue, comparator: NumericStringComparator.forward)))
	}
}

private extension JSON.Key {
	var normalized: Self {
		switch rawValue {
		case "appletvScreenshotUrls":
			"appleTVScreenshotURLs"
		case "artistId":
			"developerID"
		case "artistName":
			"developerName"
		case "artistViewUrl":
			"developerAppStorePageURL"
		case "artworkUrl60":
			"icon60URL"
		case "artworkUrl100":
			"icon100URL"
		case "artworkUrl512":
			"icon512URL"
		case "bundleId":
			"bundleID"
		case "genreIds":
			"categoryIDs"
		case "genres":
			"categories"
		case "ipadScreenshotUrls":
			"iPadScreenshotURLs"
		case "isVppDeviceBasedLicensingEnabled":
			"isVPPDeviceBasedLicensingEnabled"
		case minimumOSVersionKey.rawValue:
			"minimumOSVersion"
		case "primaryGenreId":
			"primaryCategoryID"
		case "primaryGenreName":
			"primaryCategoryName"
		case "releaseDate":
			"originalVersionReleaseDate"
		case "screenshotUrls":
			"screenshotURLs"
		case "sellerUrl":
			"sellerURL"
		case "trackCensoredName":
			"censoredName"
		case "trackContentRating":
			"contentRating"
		case "trackId":
			"adamID"
		case "trackName":
			"name"
		case "trackViewUrl":
			"appStorePageURL"
		case
			"advisories",
			"averageUserRating",
			"averageUserRatingForCurrentVersion",
			"contentAdvisoryRating",
			"currency",
			"currentVersionReleaseDate",
			"description",
			"features",
			"fileSizeBytes",
			"formattedPrice",
			"isGameCenterEnabled",
			"kind",
			"languageCodesISO2A",
			"price",
			"releaseNotes",
			"sellerName",
			"supportedDevices",
			"userRatingCount",
			"userRatingCountForCurrentVersion",
			"version",
			"wrapperType"
		: // swiftformat:disable:this indent
			self
		default:
			.init(
				rawValue: rawValue.replacing(artworkURLRegex) { match in
					let output = match.output
					guard let first = output.0.first else {
						return ""
					}

					return first.isLowercase ? "icon\(output.1)URL" : "Icon\(output.1)URL"
				}
					.replacing(trackRegex) { match in // swiftformat:disable indent
						func track(_ prefix: String) -> String {
							output.3.first.map { $0.isUppercase ? $0.lowercased() : "\(prefix)\(output.2)\($0)" }
								?? "\(prefix)\(output.2)"
						}

						let output = match.output
						return switch output.1 {
						case "track":
							track("app")
						case "Track":
							track("App")
						case "trackId":
							"adamID\(output.2)\(output.3)"
						case "TrackId":
							"ADAMID\(output.2)\(output.3)"
						default:
							String(output.0)
						}
					}
					.replacing(manyRegex) { match in
						let output = match.output
						return switch output.1 {
						case "appletv":
							"appleTV\(output.2)"
						case "Appletv":
							"AppleTV\(output.2)"
						case "artist":
							"developer\(output.2)"
						case "Artist":
							"Developer\(output.2)"
						case "artwork":
							"icon\(output.2)"
						case "Artwork":
							"Icon\(output.2)"
						case "genre":
							output.2.isEmpty ? "category" : "categories"
						case "Genre":
							output.2.isEmpty ? "Category" : "Categories"
						case "Id":
							"ID\(output.2)"
						case "ipad":
							"iPad\(output.2)"
						case "Ipad":
							"IPad\(output.2)"
						case "Os":
							output.2.isEmpty ? "OS" : .init(output.0)
						case "releaseDate":
							"originalVersionReleaseDate\(output.2)"
						case "Url":
							"URL\(output.2)"
						case "view":
							"appStorePage\(output.2)"
						case "View":
							"AppStorePage\(output.2)"
						case "Vpp":
							"VPP\(output.2)"
						default:
							String(output.0)
						}
					},
			) // swiftformat:enable indent
		}
	}
}

func lookup(appID: AppID) async throws -> CatalogApp {
	try await lookup(appID: appID, for: .macOS)
}

private func lookup(appID: AppID, for platform: Platform, in region: Region = appStoreRegion)
async throws -> CatalogApp { // swiftformat:disable:this indent
	let queryItem = switch appID {
	case let .adamID(adamID):
		URLQueryItem(name: "id", value: .init(adamID))
	case let .bundleID(bundleID):
		URLQueryItem(name: "bundleId", value: bundleID)
	}
	let lookupURL = Environment.current.lookupURL.appending(queryItems: [queryItem])
	return if // swiftformat:disable:this wrap wrapArguments
		let catalogAppJSONObject = try await catalogAppJSONObjects(
			from: lookupURL.appending(queryItems: [.init(name: "entity", value: platform.iTunesSearchEntity)]),
			in: region,
		)
		.first
	{
		try .init(object: catalogAppJSONObject)
	} else {
		try await catalogAppJSONObjects(from: lookupURL, in: region).first.map(CatalogApp.init)
			?? { throw MASError.unknownAppID(appID) }()
	}
}

func search(for term: String) async throws -> [CatalogApp] {
	try await search(for: term, for: .macOS)
}

private func search(for term: String, for platform: Platform, in region: Region = appStoreRegion)
async throws -> [CatalogApp] { // swiftformat:disable:this indent
	// Search for apps for compatible platforms, in order of preference.
	// Macs with Apple Silicon can run iPad & iPhone apps.
	// TODO: .macCatalyst
	#if arch(arm64)
	let platforms = [Platform.macOS, .iPadOS, .iOS]
	#else
	let platforms = [Platform.macOS]
	#endif
	return try await platforms.concurrentFlatMap { platform in
		let searchURL = Environment.current.searchURL.appending(queryItems: [.init(name: "term", value: term)])
		async let macCatalogAppsTask = catalogAppJSONObjects(
			from: searchURL.appending(queryItems: [.init(name: "entity", value: platform.iTunesSearchEntity)]),
			in: region,
		)
		.map(CatalogApp.init)
		async let anyCatalogAppsTask = catalogAppJSONObjects(from: searchURL, in: region)
		let macCatalogApps = try await macCatalogAppsTask
		let adamIDSet = Set(macCatalogApps.map(\.adamID))
		return macCatalogApps.priorityMerge(
			try await anyCatalogAppsTask.concurrentCompactMap { catalogAppJSONObject in
				try catalogAppJSONObject["trackId"]?.decode(to: ADAMID?.self).map(adamIDSet.contains) == false
					? try await .init(nonMacOSApp: catalogAppJSONObject)
					: nil
			},
		) { $0.name.similarity(to: term) }
	}
	.reduce(into: (catalogApps: [CatalogApp](), seenIDs: Set<ADAMID>())) { state, catalogApp in
		if state.seenIDs.insert(catalogApp.adamID).inserted {
			state.catalogApps.append(catalogApp)
		}
	}
	.catalogApps
}

private func catalogAppJSONObjects(from url: URL, in region: Region) async throws -> [JSON.Object] {
	try await unsafe Environment.current
		.dataFrom(
			url.appending(queryItems: [.init(name: "media", value: "software"), .init(name: "country", value: region)]),
		)
		.data
		.withUnsafeBytes { bufferPointer in
			try CatalogAppResults(json: try .init(parsing: unsafe RawSpan(_unsafeBytes: unsafe bufferPointer))).resultObjects
		}
}

private let minimumOSVersionKey = JSON.Key("minimumOsVersion")
private let artworkURLRegex = /(?:^artworkUrl|ArtworkUrl)(\d+)/
private let trackRegex = /((?:^track|Track)(?:Id)?)(s?)($|[\d\p{Upper}])/ // editorconfig-checker-disable-next-line
private let manyRegex = /(^appletv|Appletv|^artist|Artist|^artwork|Artwork|^genre|Genre|Id|^ipad|Ipad|Os|^releaseDate|Url|^view|View|Vpp)(s?)(?=$|[\d\p{Upper}])/
private let minimumOSVersionRegex = /macOS\s*(?<version>\S+)/
