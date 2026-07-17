//
// InstalledApp.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

private import CoreFoundation
private import Foundation
internal import JSONAST
private import JSONParsing
private import ObjectiveC
private import Subprocess
private import System // swiftlint:disable:this unused_import

struct InstalledApp {
	let adamID: ADAMID
	let bundleID: String
	let name: String
	let path: String
	let version: String

	private let jsonObjectRaw: JSON.Object
	private let lazyJSONObject: Lazy<JSON.Object>
	private let lazyJSON: Lazy<String>

	var jsonObject: JSON.Object {
		lazyJSONObject.value
	}

	fileprivate init(for valueByAttribute: [String: Any]) {
		bundleID = .init(describing: valueByAttribute[NSMetadataItemCFBundleIdentifierKey] ?? "")
		name = .init(describing: valueByAttribute["_kMDItemDisplayNameWithExtensions"] ?? "").removingSuffix(".app")
		path = valueByAttribute[NSMetadataItemPathKey].map { pathAny in
			let path = String(describing: pathAny)
			return (try? URL(folderPath: path).resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath ?? path
		}
			?? ""
		version = .init(describing: valueByAttribute[NSMetadataItemVersionKey] ?? "")

		let url = URL(folderPath: path)
		let (adamID, adamIDKeyValue) = if let adamID = valueByAttribute["kMDItemAppStoreAdamID"] as? ADAMID {
			(adamID, [JSON.Object.Key: JSON.Node]())
		} else if
			let adamID = url
				.appending(path: "Wrapper/iTunesMetadata.plist", directoryHint: .notDirectory)
				.iTunesMetadata?
				.adamID
		{
			(adamID, ["adamID": .number(adamID)])
		} else {
			(0, .init())
		}
		self.adamID = adamID

		jsonObjectRaw = .init(valueByAttribute.map { (.init(rawValue: $0.key), .init(for: $0.value)) } + adamIDKeyValue)
		let jsonObjectRaw = jsonObjectRaw
		let name = name
		let isNeitherMacNorCatalyst = valueByAttribute["kMDItemAppStoreHasMetadataPlist"] as? Int == 1
		lazyJSONObject = .init(
			.init(
				(
					jsonObjectRaw.fields.map { ($0.normalized, $1) }
						+ [("name", .string(name))]
						+ [("platform", .string(.init(describing: url.platform(isNeitherMacNorCatalyst: isNeitherMacNorCatalyst))))]
				)
				.sorted(using: KeyPathComparator(\.0.rawValue, comparator: NumericStringComparator.forward)),
			),
		)
		let lazyJSONObject = lazyJSONObject
		lazyJSON = .init(.init(lazyJSONObject.value))
	}

	func matches(_ appID: AppID) -> Bool {
		switch appID {
		case let .adamID(adamID):
			self.adamID == adamID
		case let .bundleID(bundleID):
			self.bundleID == bundleID
		}
	}
}

extension InstalledApp: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		lazyJSON.value
	}
}

private struct ITunesMetadata: Decodable { // swiftlint:disable:this one_declaration_per_file
	enum CodingKeys: String, CodingKey {
		case adamID = "itemId" // swiftformat:disable:this acronyms
		case bundleID = "softwareVersionBundleId"
	}

	let adamID: ADAMID
	let bundleID: String
}

private extension JSON.Node {
	init(for value: Any?) {
		self = switch value {
		case let jsonNode as Self:
			jsonNode
		case let number as NSNumber: // swiftlint:disable:this legacy_objc_type
			number === kCFBooleanTrue || number === kCFBooleanFalse
				? .bool(number.boolValue)
				: .init(.init(describing: number)) ?? .null
		case let date as Date:
			.string(date.formatted(.iso8601))
		case let data as Data:
			data.isEmpty // swiftlint:disable:next void_function_in_ternary
				? .string("")
				: {
					var hex = "0x"
					hex.reserveCapacity(2 + data.count * 2)
					return .string(
						data.reduce(into: hex) { hex, byte in
							let byteHex = String(byte, radix: 16)
							if byteHex.count < 2 {
								hex += "0"
							}
							hex += byteHex
						},
					)
				}()
		case let array as [Any?]:
			.array(.init(array.map { .init(for: $0) }))
		default:
			value.map { .string(.init(describing: $0)) } ?? .null
		}
	}
}

private extension JSON.Key {
	var normalized: Self {
		switch rawValue {
		case NSMetadataItemCFBundleIdentifierKey:
			"bundleID"
		case "_kMDItemDisplayNameWithExtensions":
			"displayNameWithExtensions"
		case "_kMDItemEngagementData":
			"engagementData"
		case "_kMDItemRecentOutOfSpotlightEngagementDates":
			"recentOutOfSpotlightEngagementDates"
		case "kMDItemAlternateNames":
			"alternateNames"
		case "kMDItemAppStoreAdamID":
			"adamID"
		case "kMDItemAppStoreCategory":
			"category"
		case "kMDItemAppStoreCategoryType":
			"categoryType"
		case "kMDItemAppStoreHasMetadataPlist":
			"hasMetadataPlist"
		case "kMDItemAppStoreHasReceipt":
			"hasReceipt"
		case "kMDItemAppStoreInstallerVersionID":
			"installerVersionID"
		case "kMDItemAppStoreIsAppleSigned":
			"isAppleSigned"
		case "kMDItemAppStoreParentalControls":
			"parentalControls"
		case "kMDItemAppStorePurchaseDate":
			"purchaseDate"
		case "kMDItemAppStoreReceiptIsMachineLicensed":
			"receiptIsMachineLicensed"
		case "kMDItemAppStoreReceiptIsRevoked":
			"receiptIsRevoked"
		case "kMDItemAppStoreReceiptIsVPPLicensed":
			"receiptIsVPPLicensed"
		case "kMDItemAppStoreReceiptType":
			"receiptType"
		case NSMetadataItemContentCreationDateKey:
			"contentCreationDate"
		case "kMDItemContentCreationDate_Ranking":
			"contentCreationDate_Ranking"
		case NSMetadataItemContentModificationDateKey:
			"contentModificationDate"
		case NSMetadataItemContentTypeKey:
			"contentType"
		case NSMetadataItemContentTypeTreeKey:
			"contentTypeTree"
		case NSMetadataItemCopyrightKey:
			"copyright"
		case NSMetadataItemDateAddedKey:
			"dateAdded"
		case NSMetadataItemDescriptionKey:
			"description"
		case NSMetadataItemDisplayNameKey:
			"displayName"
		case "kMDItemDocumentIdentifier":
			"documentIdentifier"
		case NSMetadataItemExecutableArchitecturesKey:
			"executableArchitectures"
		case NSMetadataItemExecutablePlatformKey:
			"executablePlatform"
		case NSMetadataItemFSContentChangeDateKey:
			"fileSystemContentChangeDate"
		case NSMetadataItemFSCreationDateKey:
			"fileSystemCreationDate"
		case "kMDItemFSCreatorCode":
			"fileSystemCreatorCode"
		case "kMDItemFSFinderFlags":
			"fileSystemFinderFlags"
		case "kMDItemFSHasCustomIcon":
			"fileSystemHasCustomIcon"
		case "kMDItemFSInvisible":
			"fileSystemInvisible"
		case "kMDItemFSIsExtensionHidden":
			"fileSystemIsExtensionHidden"
		case "kMDItemFSIsStationery":
			"fileSystemIsStationery"
		case "kMDItemFSLabel":
			"fileSystemLabel"
		case NSMetadataItemFSNameKey:
			"fileSystemName"
		case "kMDItemFSNodeCount":
			"fileSystemNodeCount"
		case "kMDItemFSOwnerGroupID":
			"fileSystemOwnerGroupID"
		case "kMDItemFSOwnerUserID":
			"fileSystemOwnerUserID"
		case NSMetadataItemFSSizeKey:
			"fileSystemSize"
		case "kMDItemFSTypeCode":
			"fileSystemTypeCode"
		case "kMDItemInterestingDate_Ranking":
			"interestingDate_Ranking"
		case NSMetadataItemKeywordsKey:
			"keywords"
		case NSMetadataItemKindKey:
			"kind"
		case NSMetadataItemLastUsedDateKey:
			"lastUsedDate"
		case "kMDItemLastUsedDate_Ranking":
			"lastUsedDate_Ranking"
		case "kMDItemLogicalSize":
			"logicalSize"
		case "kMDItemPhysicalSize":
			"physicalSize"
		case "kMDItemUseCount":
			"useCount"
		case "kMDItemUsedDates":
			"usedDates"
		case NSMetadataItemVersionKey:
			"version"
		default:
			.init(
				rawValue: rawValue.replacing(keyRegex) { match in
					let output = match.output
					return output.1?.isEmpty == false ? "fileSystem" : output.2?.lowercased() ?? ""
				},
			)
		}
	}
}

private extension URL {
	var iTunesMetadata: ITunesMetadata? { // TODO: async?
		try? propertyListDecoder.decode(ITunesMetadata.self, from: try .init(contentsOf: self, options: .mappedIfSafe))
	}

	func platform(isNeitherMacNorCatalyst: Bool) -> Platform { // TODO: async?
		guard // swiftformat:disable:this wrap wrapArguments
			let supportedDeviceFamilyIDs = Bundle(url: self)?.infoDictionary?["UIDeviceFamily"] as? [Int],
			!supportedDeviceFamilyIDs.isEmpty
		else {
			return .macOS
		}

		return !isNeitherMacNorCatalyst ? .macCatalyst : supportedDeviceFamilyIDs.contains(2) ? .iPadOS : .iOS
	}

	func appSubpathURLs(for subpath: String) -> [Self] {
		FileManager.default
			.enumerator(at: self, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
			.map { enumerator in
				enumerator.compactMap { item in
					guard
						let url = item as? Self,
						url.pathExtension == "app",
						(try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
					else {
						return Self?.none
					}

					enumerator.skipDescendants()
					let queryURL = url.appending(path: subpath)
					return try? queryURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.flatMap { $0 > 0 ? queryURL : nil }
				}
			}
			?? .init()
	}
}

func installedApps(
	withAppIDs appIDs: [AppID],
	onlyDeployable: Bool,
	withFullJSON: Bool,
	unresolvedAppIDHandler handleUnresolvedAppID: (AppID) -> Void,
) async -> [InstalledApp] {
	let installedApps = await installedApps(matching: appIDs, onlyDeployable: onlyDeployable, withFullJSON: withFullJSON)
	let unresolvedAppIDs = appIDs.filter { appID in
		if installedApps.contains(where: { $0.matches(appID) }) {
			return false
		}
		handleUnresolvedAppID(appID)
		return true
	}
	if
		appIDs.isEmpty || !unresolvedAppIDs.isEmpty,
		!["1", "true", "yes"].contains(ProcessInfo.processInfo.environment["MAS_NO_AUTO_INDEX"]?.lowercased())
	{
		let installedAppPathSet = Set(
			(
				appIDs.isEmpty
					? installedApps
					: await mas::installedApps(matching: .init(), onlyDeployable: onlyDeployable, withFullJSON: false)
			)
				.map(\.path), // swiftformat:disable:this indent
		) // TODO: What about iPadOS & iOS in next line?
		for installedAppPath in applicationsFolderURLs.flatMap({ $0.appSubpathURLs(for: "Contents/_MASReceipt/receipt") })
			.map({ $0.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().filePath })
		where !installedAppPathSet.contains(installedAppPath) { // swiftformat:disable:this indent
			MAS.printer.warning(
				"Found a likely App Store app that is not indexed in Spotlight in ",
				installedAppPath,
				"""


				Indexing now; will likely complete sometime after mas exits

				Disable auto-indexing via: export MAS_NO_AUTO_INDEX=1
				""",
				separator: "",
			)
			Task {
				do {
					_ = try await run(
						.path("/usr/bin/mdimport"),
						installedAppPath,
						errorMessage: "Failed to index the Spotlight data for \(installedAppPath)",
					)
				} catch {
					MAS.printer.error(error: error)
				}
			}
		}
	}
	return appIDs.isEmpty ? installedApps.filter { $0.adamID != 0 } : installedApps // Remove TestFlight apps
}

func installedApps(matching appIDs: [AppID], onlyDeployable: Bool, withFullJSON: Bool) async -> [InstalledApp] {
	let installedApps =
		await installedAppDictionaries(matching: appIDs, onlyDeployable: onlyDeployable, withFullJSON: withFullJSON)
			.concurrentMap(InstalledApp.init)
	return await (
		installedApps + unsortedInstalledApps(
			matching: .init(
				appIDs.compactMap { appID in
					if case let .adamID(adamID) = appID, !installedApps.contains(where: { $0.adamID == adamID }) {
						adamID
					} else {
						nil
					}
				},
			),
			withFullJSON: withFullJSON,
		)
	)
	.sorted(using: KeyPathComparator(\.name, comparator: .localizedStandard))
}

private func unsortedInstalledApps(matching unresolvedADAMIDSet: Set<ADAMID>, withFullJSON: Bool)
async -> [InstalledApp] { // swiftformat:disable:this indent
	guard !unresolvedADAMIDSet.isEmpty else {
		return .init()
	}

	let adamIDByBundleAppID = await applicationsFolderURLs
		.flatMap { $0.appSubpathURLs(for: "Wrapper/iTunesMetadata.plist") }
		.concurrentCompactMap { iTunesMetadataURL in
			iTunesMetadataURL.iTunesMetadata
				.flatMap { unresolvedADAMIDSet.contains($0.adamID) ? (AppID.bundleID($0.bundleID), $0.adamID) : nil }
		}
		.reduce(into: [AppID: ADAMID]()) { $0[$1.0] = $1.1 }
	return adamIDByBundleAppID.isEmpty
		? .init()
		: await installedAppDictionaries(
			matching: adamIDByBundleAppID.keys,
			onlyDeployable: false,
			withFullJSON: withFullJSON,
		)
		.concurrentMap { installedAppDictionary in
			.init(
				for: (installedAppDictionary[NSMetadataItemCFBundleIdentifierKey] as? String)
					.flatMap { bundleID in
						adamIDByBundleAppID[.bundleID(bundleID)]
							.map { installedAppDictionary.merging(["kMDItemAppStoreAdamID": $0]) { $1 } }
					}
					?? installedAppDictionary,
			)
		}
}

@MainActor
private func installedAppDictionaries(matching appIDs: some Sequence<AppID>, onlyDeployable: Bool, withFullJSON: Bool)
async -> [[String: any Sendable]] { // swiftformat:disable:this indent
	let query = NSMetadataQuery()
	let predicates = appIDs.map { appID in
		switch appID {
		case let .adamID(adamID): // swiftlint:disable:next legacy_objc_type
			NSPredicate(format: "kMDItemAppStoreAdamID = %@", NSNumber(value: adamID))
		case let .bundleID(bundleID):
			NSPredicate(format: "kMDItemCFBundleIdentifier = %@", bundleID)
		}
	}
	query.predicate = switch predicates.count {
	case 0:
		.init(format: "kMDItemAppStoreAdamID LIKE '*'\(onlyDeployable ? "" : " || kMDItemAppStoreHasMetadataPlist = 1")")
	case 1:
		predicates[0]
	default:
		NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
	}
	query.searchScopes = applicationsFolderURLs
	let notifications = NotificationCenter.default.notifications(named: .NSMetadataQueryDidFinishGathering, object: nil)
	query.start()
	for await notification in notifications where (notification.object as? NSMetadataQuery) === query {
		break
	}
	query.stop()
	return query.results.compactMap { result in
		(result as? NSMetadataItem).flatMap { item in
			item.values(
				forAttributes: withFullJSON
					? item.attributes + [NSMetadataItemPathKey]
					: [
						"kMDItemAppStoreAdamID",
						NSMetadataItemCFBundleIdentifierKey,
						"_kMDItemDisplayNameWithExtensions",
						NSMetadataItemPathKey,
						NSMetadataItemVersionKey,
						"kMDItemAppStoreHasMetadataPlist",
					],
			)
		}
	}
}

// swiftformat:disable:next docComments
// editorconfig-checker-disable-next-line
private let keyRegex = /^_?kMDItem(?:(FS)|(?:AppStore)?(\p{Upper}(?=\p{Lower})|\p{Upper}+(?=$|\p{Upper}\p{Lower}))?)?/
private let propertyListDecoder = PropertyListDecoder()
