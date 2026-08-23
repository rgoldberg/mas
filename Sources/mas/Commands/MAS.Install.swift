//
// MAS.Install.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser

extension MAS {
	/// Installs already owned apps from the App Store.
	struct Install: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Install already owned apps from the App Store",
			discussion: requiresRootPrivilegesMessage(),
		)

		@OptionGroup
		private var forceOptionGroup: ForceOptionGroup
		@OptionGroup
		private var catalogAppsOptionGroup: CatalogAppsOptionGroup

		func run() async {
			await AppStore.install.apps(withAppIDs: catalogAppsOptionGroup.appIDs, force: forceOptionGroup.force)
		}
	}
}
