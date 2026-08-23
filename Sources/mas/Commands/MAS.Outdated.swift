//
// MAS.Outdated.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser

extension MAS {
	/// Outputs a list of already installed apps that have pending updates from
	/// the App Store.
	struct Outdated: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Output pending app updates from the App Store",
		)

		@OptionGroup
		private var outputFormatOptionGroup: OutputFormatOptionGroup
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		func run() async {
			let outdatedApps =
				await outdatedAppsOptionGroup.outdatedApps(withFullJSON: outputFormatOptionGroup.shouldOutputJSON)
			if !outdatedApps.isEmpty {
				outputFormatOptionGroup.info(outdatedApps.lazy.map { .init(describing: $0) }.joined(separator: "\n"))
			}
		}
	}
}
