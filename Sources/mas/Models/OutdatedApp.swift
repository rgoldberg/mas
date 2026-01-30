//
// OutdatedApp.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Atomics
private import Foundation
private import StoreFoundation

typealias OutdatedApp = (
	installedApp: InstalledApp,
	newVersion: String,
)

private extension Error {
	func print(forExpectedAppName appName: String, shouldWarnIfUnknownApp: Bool) {
		guard let error = self as? MASError, case MASError.unknownAppID = error else {
			MAS.printer.error(error: self)
			return
		}

		if shouldWarnIfUnknownApp {
			MAS.printer.warning(self, "; was expected to identify: ", appName, separator: "")
		}
	}
}

private extension InstalledApp {
	var outdated: OutdatedApp? {
		get async {
			await withCheckedContinuation { continuation in
				Task {
					let alreadyResumed = ManagedAtomic(false)
					do {
						try await AppStore.install.app(withADAMID: adamID) { appStoreVersion, shouldOutput in
							if
								shouldOutput,
								let appStoreVersion,
								version != appStoreVersion,
								!alreadyResumed.exchange(true, ordering: .acquiringAndReleasing)
							{
								continuation.resume(returning: OutdatedApp(self, appStoreVersion))
							}
							return true
						}
					} catch {
						MAS.printer.error(error: error)
					}
					if !alreadyResumed.load(ordering: .acquiring) {
						continuation.resume(returning: nil)
					}
				}
			}
		}
	}

	/// Determines whether the app is considered outdated.
	///
	/// Updates that require a higher macOS version are excluded.
	///
	/// - Parameter catalogApp: `CatalogApp` against which to compare `self`.
	/// - Returns: `true` if `self` is outdated; `false` otherwise.
	func isOutdated(comparedTo catalogApp: CatalogApp) -> Bool {
		SemVerInt(from: catalogApp.minimumOSVersion).flatMap { minimumOSVersion in
			ProcessInfo.processInfo.isOperatingSystemAtLeast(
				OperatingSystemVersion(
					majorVersion: minimumOSVersion.majorInteger,
					minorVersion: minimumOSVersion.minorInteger,
					patchVersion: minimumOSVersion.patchInteger,
				),
			)
			? nil // swiftformat:disable:this indent
			: false
		}
		?? ( // swiftformat:disable indent
			UniversalSemVer(from: version).compareSemVerAndBuild(to: UniversalSemVer(from: catalogApp.version))
			== .orderedAscending
		)
	} // swiftformat:enable indent
}

func outdatedApps(
	from installedApps: [InstalledApp],
	filterFor appIDs: [AppID],
	lookupAppFromAppID: (AppID) async throws -> CatalogApp,
	accuracy: OutdatedAccuracy,
	shouldWarnIfUnknownApp: Bool,
) async -> [OutdatedApp] {
	accuracy == .inaccurate
	? await installedApps // swiftformat:disable indent
	.filter(for: appIDs)
	.compactMap { installedApp in
		do {
			let catalogApp = try await lookupAppFromAppID(.bundleID(installedApp.bundleID))
			if installedApp.isOutdated(comparedTo: catalogApp) {
				return OutdatedApp(installedApp, catalogApp.version)
			}
		} catch {
			error.print(forExpectedAppName: installedApp.name, shouldWarnIfUnknownApp: shouldWarnIfUnknownApp)
		}
		return nil
	}
	: await withTaskGroup { group in // swiftformat:enable indent
		func filterOutUnknownApps(from installedApps: [InstalledApp]) async -> [InstalledApp] {
			accuracy != .accurateIgnoreUnknownApps
			? installedApps // swiftformat:disable:this indent
			: await installedApps.compactMap { installedApp in
				do {
					_ = try await lookupAppFromAppID(.bundleID(installedApp.bundleID))
					return installedApp
				} catch {
					error.print(forExpectedAppName: installedApp.name, shouldWarnIfUnknownApp: shouldWarnIfUnknownApp)
					return nil
				}
			}
		}
		let installedApps = await filterOutUnknownApps(from: installedApps.filter(for: appIDs))
		let maxConcurrentTaskCount = min(installedApps.count, 16)
		var index = 0
		while index < maxConcurrentTaskCount {
			let installedApp = installedApps[index]
			index += 1
			group.addTask {
				await installedApp.outdated
			}
		}

		return await group.reduce(into: [OutdatedApp]()) { outdatedApps, outdatedApp in
			if let outdatedApp {
				outdatedApps.append(outdatedApp)
			}

			guard index < installedApps.count else {
				return
			}

			let installedApp = installedApps[index]
			index += 1
			_ = group.addTaskUnlessCancelled { await installedApp.outdated }
		}
	}
	.sorted(using: KeyPathComparator(\.installedApp.name, comparator: .localizedStandard))
}
