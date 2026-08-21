//
// MAS.List.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import JSONAST

extension MAS { // swiftlint:disable:this file_types_order
	/// Outputs apps already installed from the App Store.
	struct List: AsyncParsableCommand, RealDropping {
		static let configuration = CommandConfiguration(
			abstract: "Output apps already installed from the App Store",
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<TableConfig>
		@OptionGroup
		private var installedAppsOptionGroup: InstalledAppsOptionGroup

		func run() async {
			run(
				installedApps: // swiftformat:disable:next indent
					await installedAppsOptionGroup.installedApps(withFullJSON: outputConfigOptionGroup.withFullJSON),
			)
		}

		func run(installedApps: [InstalledApp]) {
			guard !installedApps.isEmpty else {
				printer.warning( // editorconfig-checker-disable
					"""
					Failed to find any installed apps

					If this is unexpected, index apps in Spotlight (which might take some time):

					# Individual app (if the omitted apps are known). e.g., for Xcode:
					mdimport /Applications/Xcode.app

					# All apps:
					vol="$(/usr/libexec/PlistBuddy -c "Print :PreferredVolume:name" ~/Library/Preferences/com.apple.appstored.plist 2>/dev/null)"
					mdimport /Applications ${vol:+"/Volumes/${vol}/Applications"}

					# All volumes:
					sudo mdutil -Eai on
					""", // editorconfig-checker-enable
				)
				return
			}

			outputConfigOptionGroup.output(installedApps.map(\.jsonObject))
		}
	}
}

private struct TableConfig: OutputConfig, Keyed {
	static let defaultFormat = OutputFormat.table
	static let keys = [JSON.Key("adamID"), "name", "version"]
}
