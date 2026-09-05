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
private import System

struct InstalledApp {
	let adamID: ADAMID
	let bundleID: String
	let name: String
	let path: String
	let version: String

	private let lazyJSONObject: Lazy<JSON.Object>

	var jsonObject: JSON.Object {
		lazyJSONObject.value
	}

	fileprivate init(for valueByAttribute: [String: Any]) {
		adamID = valueByAttribute["kMDItemAppStoreAdamID"] as? ADAMID ?? 0
		bundleID = valueByAttribute[NSMetadataItemCFBundleIdentifierKey].map(String.init(describing:)) ?? ""
		name =
			valueByAttribute["_kMDItemDisplayNameWithExtensions"].map { .init(String(describing: $0).removingSuffix(".app")) }
				?? ""
		path = valueByAttribute[NSMetadataItemPathKey].map { pathAny in
			let path = String(describing: pathAny)
			return (try? URL(folderPath: path).resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath ?? path
		}
			?? ""
		version = valueByAttribute[NSMetadataItemVersionKey].map(String.init(describing:)) ?? ""

		// `valueByAttribute` is a `Dictionary`, whose iteration order is
		// unspecified, so there's no meaningful "original" field order to
		// preserve here, unlike `CatalogApp`'s ordered API response
		let jsonObject = JSON.Object(valueByAttribute.map { (.init(rawValue: $0.key), .init(for: $0.value)) })
		let name = name
		lazyJSONObject = .init(.init(jsonObject.normalized.fields + [("name", .string(name))]))
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
	/// Renames keys only; never reorders fields or changes non-key-name values.
	var normalized: Self {
		.init(fields.map { ($0.normalized, $1.normalized) })
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
	var installedAppURLs: [Self] {
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
					return try? url.appending(path: "Contents/_MASReceipt/receipt", directoryHint: .notDirectory)
						.resourceValues(forKeys: [.fileSizeKey])
						.fileSize
						.flatMap { $0 > 0 ? url : nil }
				}
			}
			?? .init()
	}
}

func installedApps(
	withAppIDs appIDs: [AppID],
	fields: [String],
	unresolvedAppIDHandler handleUnresolvedAppID: (AppID) -> Void,
) async -> [InstalledApp] {
	let installedApps = await installedApps(matching: appIDs, fields: fields)
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
			(appIDs.isEmpty ? installedApps : await mas::installedApps(matching: .init(), fields: ["path"])).map(\.path),
		)
		for installedAppPath in applicationsFolderURLs.flatMap(\.installedAppURLs).map(\.filePath)
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
						"/usr/bin/mdimport",
						arguments: [installedAppPath],
						errorMessage: "Failed to index Spotlight data for \(installedAppPath)",
					)
				} catch {
					MAS.printer.error(error: error)
				}
			}
		}
	}
	return appIDs.isEmpty ? installedApps.filter { $0.adamID != 0 } : installedApps // Remove TestFlight apps
}

func installedApps(matching appIDs: [AppID], fields: [String]) async -> [InstalledApp] {
	await unsortedInstalledApps(matching: appIDs, fields: fields)
		.sorted(using: KeyPathComparator(\.name, comparator: .localizedStandard))
}

@MainActor
private func unsortedInstalledApps(matching appIDs: [AppID], fields: [String]) async -> [InstalledApp] {
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
		.init(format: "kMDItemAppStoreAdamID LIKE '*'")
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
		(result as? NSMetadataItem)
			.flatMap { item in
				item.values(forAttributes: spotlightAttributeKeys(for: fields) ?? item.attributes + [NSMetadataItemPathKey])
			}
			.map(InstalledApp.init)
	}
}

/// Translates our normalized field names to the raw Spotlight attribute keys
/// `InstalledApp.init` needs, always including the core set it populates
/// unconditionally (`matches(_:)` / sorting / warnings depend on them
/// regardless of what's being displayed). Returns `nil` (meaning "fetch
/// everything") for an empty `fields`, or if any requested name isn't a
/// Spotlight attribute this handles: there's no complete reverse mapping for
/// arbitrary dynamic `all` field names; fetching everything is always correct,
/// just potentially slower.
private func spotlightAttributeKeys(for fields: [String]) -> [String]? {
	guard !fields.isEmpty else { // swiftlint:disable:previous discouraged_optional_collection
		return nil
	}
	var keySet = Set(coreSpotlightAttributeKeysByFieldName.values)
	for field in fields {
		guard let key = coreSpotlightAttributeKeysByFieldName[field] else {
			return nil
		}
		keySet.insert(key)
	}
	return .init(keySet)
}

private let coreSpotlightAttributeKeysByFieldName: [String: String] = [
	"adamID": "kMDItemAppStoreAdamID",
	"bundleID": NSMetadataItemCFBundleIdentifierKey,
	"name": "_kMDItemDisplayNameWithExtensions",
	"path": NSMetadataItemPathKey,
	"version": NSMetadataItemVersionKey,
]

// swiftformat:disable:next docComments
// editorconfig-checker-disable-next-line
private let keyRegex = /^_?kMDItem(?:(FS)|(?:AppStore)?(\p{Upper}(?=\p{Lower})|\p{Upper}+(?=$|\p{Upper}\p{Lower}))?)?/
