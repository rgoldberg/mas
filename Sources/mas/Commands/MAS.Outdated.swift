//
// MAS.Outdated.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser
internal import ArgumentParserConfiguration

extension MAS {
	/// Outputs a list of installed apps which have updates available to be
	/// installed from the App Store.
	@ConfigDefaults
	struct Outdated: AsyncParsableCommand {
		// TODO: @ConfigDefaults(reader: Environment.current.configReader)
		static let configuration = CommandConfiguration(
			abstract: "List pending app updates from the App Store",
		)

		@ParentCommand // swiftlint:disable:next unused_declaration
		private var parent: MAS
		@OptionGroup
		private var outputFormatOptionGroup: OutputFormatOptionGroup
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		init() {
			// Empty
		}

		func run() async {
			let outdatedApps =
				await outdatedAppsOptionGroup.outdatedApps(withFullJSON: outputFormatOptionGroup.shouldOutputJSON)
			if !outdatedApps.isEmpty {
				outputFormatOptionGroup.info(outdatedApps.map { .init(describing: $0) }.joined(separator: "\n"))
			}
		}
	}
}
