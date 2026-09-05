//
// MAS.Update.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser

extension MAS {
	/// Updates outdated apps already installed from the App Store.
	struct Update: AsyncParsableCommand, EffectiveDropping {
		static let configuration = CommandConfiguration(
			abstract: "Update outdated apps already installed from the App Store",
			discussion: requiresRootPrivilegesMessage(),
			aliases: ["upgrade"],
		)

		@OptionGroup
		private var forceOptionGroup: ForceOptionGroup
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		func run() async throws {
			try await AppStore.update.apps(
				withADAMIDs: await outdatedAppsOptionGroup
					.outdatedApps(considerAllOutdated: forceOptionGroup.force, fields: ["adamID"])
					.map(\.installedApp.adamID),
			)
		}
	}
}
