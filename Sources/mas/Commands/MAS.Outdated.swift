//
// MAS.Outdated.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import JSONAST

extension MAS { // swiftlint:disable:this file_types_order
	/// Outputs a list of already installed apps that have pending updates from
	/// the App Store.
	struct Outdated: AsyncParsableCommand, RealDropping {
		static let configuration = CommandConfiguration(
			abstract: "Output pending app updates from the App Store",
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<TableConfig>
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		func run() async {
			outputConfigOptionGroup.output(
				await outdatedAppsOptionGroup.outdatedApps(withFullJSON: outputConfigOptionGroup.withFullJSON)
					.map(\.jsonObject),
			)
		}
	}
}

private struct TableConfig: OutputConfig, Keyed {
	static let defaultFormat = OutputFormat.table
	static let keys = [JSON.Key("adamID"), "name", "version", "newVersion"]
}
