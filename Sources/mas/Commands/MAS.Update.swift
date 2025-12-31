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

		// TODO: Begin remove
		// swiftformat:disable unusedPrivateDeclarations
		// swiftlint:disable unused_declaration
		// @Argument(help: .init("Other", valueName: "other"), completion: .file())
		// var others = [String]()
		// @Argument(help: "Other", completion: .file())
		// private var other = "" // periphery:ignore
		@Option(help: .init("Test", valueName: "test"), completion: installedAppIDCompletionKind)
		private var tests = [String]() // periphery:ignore
		@Flag(name: .shortAndLong, help: "counter")
		private var counter: Int // periphery:ignore
		@Option(help: .init("Dir", valueName: "dir"), completion: .directory)
		private var dir = "" // periphery:ignore

		// swiftlint:enable unused_declaration
		// swiftformat:enable unusedPrivateDeclarations
		// TODO: End remove

		@OptionGroup
		private var forceOptionGroup: ForceOptionGroup
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		func run() async {
			await AppStore.update.apps(
				withADAMIDs: await outdatedAppsOptionGroup
					.outdatedApps(considerAllOutdated: forceOptionGroup.force, withFullJSON: false)
					.map(\.installedApp.adamID),
			)
		}
	}
}
