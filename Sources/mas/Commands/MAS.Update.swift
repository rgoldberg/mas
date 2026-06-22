//
// MAS.Update.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser

extension MAS {
	/// Updates outdated apps installed from the App Store.
	struct Update: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Update outdated apps installed from the App Store",
			discussion: requiresRootPrivilegesMessage(),
			aliases: ["upgrade"],
		)

		@OptionGroup
		private var forceOptionGroup: ForceOptionGroup
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		func run() async throws {
			try await run(installedApps: await installedApps().filter(!\.isTestFlight))
		}

		private func run(installedApps: [InstalledApp]) async throws {
			try await run(
				outdatedApps: forceOptionGroup.force
					? installedApps.filter(for: outdatedAppsOptionGroup.installedAppsOptionGroup.appIDs)
						.map { OutdatedApp(installedApp: $0, newVersion: "") }
					: await outdatedAppsOptionGroup.outdatedApps(from: installedApps),
			)
		}

		private func run(outdatedApps: [OutdatedApp]) async throws {
			try await AppStore.update.apps(withADAMIDs: outdatedApps.map(\.installedApp.adamID))
		}
	}
}
