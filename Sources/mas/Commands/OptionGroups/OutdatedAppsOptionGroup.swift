//
// OutdatedAppsOptionGroup.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation

struct OutdatedAppsOptionGroup: ParsableArguments {
	@Flag
	private var accuracy = OutdatedAccuracy.inaccurate
	@Flag(
		name: .customLong("check-min-os"),
		inversion: .prefixedNo,
		help: "Check if macOS can install latest app version",
	)
	private var shouldCheckMinimumOSVersion = true
	@Flag(name: .customLong("verbose"), help: "Warn about app IDs unknown to the App Store")
	private var shouldWarnIfUnknownApp = false
	@OptionGroup
	private var installedAppsOptionGroup: InstalledAppsOptionGroup

	func outdatedApps(considerAllOutdated: Bool, withFullJSON: Bool = false) async -> [OutdatedApp] {
		considerAllOutdated
			? await installedAppsOptionGroup.installedApps(withFullJSON: withFullJSON)
				.map { .init(installedApp: $0, newVersion: "") }
			: await outdatedApps(withFullJSON: withFullJSON)
	}

	func outdatedApps(withFullJSON: Bool) async -> [OutdatedApp] {
		let lookupAppFromAppID = Environment.current.lookupAppFromAppID
		@Sendable
		func installableCatalogApp(from installedApp: InstalledApp) async -> CatalogApp? {
			do {
				let catalogApp = try await lookupAppFromAppID(.bundleID(installedApp.bundleID))
				return shouldCheckMinimumOSVersion
					&& UniversalSemVerInt(rawValue: catalogApp.minimumOSVersion).map { minimumOSVersion in
						ProcessInfo.processInfo.isOperatingSystemAtLeast(
							.init(
								majorVersion: minimumOSVersion.majorInteger,
								minorVersion: minimumOSVersion.minorInteger,
								patchVersion: minimumOSVersion.patchInteger,
							),
						)
					}
					== false ? nil : catalogApp
			} catch {
				if case MASError.unknownAppID = error {
					if shouldWarnIfUnknownApp {
						MAS.printer.warning(error, "; was expected to identify: ", installedApp.name, separator: "")
					}
				} else {
					MAS.printer.error(error: error)
				}
				return nil
			}
		}

		return await installedAppsOptionGroup.installedApps(withFullJSON: withFullJSON).concurrentCompactMap(
			accuracy == .accurate
				? { @Sendable installedApp in
					if shouldCheckMinimumOSVersion, await installableCatalogApp(from: installedApp) == nil {
						nil
					} else {
						await AsyncStream { continuation in
							let task = Task {
								do {
									try await AppStore.install.app(withADAMID: installedApp.adamID) { appStoreVersion, shouldOutput in
										if shouldOutput, let appStoreVersion, installedApp.version != appStoreVersion {
											continuation.yield(.init(installedApp: installedApp, newVersion: appStoreVersion))
											continuation.finish()
										}
										return true
									}
								} catch {
									MAS.printer.error(error: error)
								}
								continuation.finish()
							}
							continuation.onTermination = { _ in task.cancel() }
						}
						.first { _ in true }
					}
				}
				: { @Sendable installedApp in
					await installableCatalogApp(from: installedApp).flatMap { catalogApp in
						UniversalSemVer(rawValue: installedApp.version)
							.compareSemVerAndBuild(to: .init(rawValue: catalogApp.version))
							== .orderedAscending ? .init(installedApp: installedApp, newVersion: catalogApp.version) : nil
					}
				},
		)
	}
}
