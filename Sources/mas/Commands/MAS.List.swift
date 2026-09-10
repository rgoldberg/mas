//
// MAS.List.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser

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

		func run() async throws {
			try run(
				installedApps: await installedAppsOptionGroup
					.installedApps(fields: try outputConfigOptionGroup.fetchFieldNames()),
			)
		}

		func run(installedApps: [InstalledApp]) throws {
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
			try outputConfigOptionGroup.output(installedApps.map(\.jsonObject))
		}
	}
}

private struct TableConfig: OutputConfig {
	static let defaultFormat = OutputFormat.table
	static let standardFieldsConfig = SelectedFieldsConfig(
		fieldSpecs: [
			.init(
				name: "adamID",
				label: "ADAM ID",
				format: .default(fieldName: "adamID"),
				sortSpec: nil, // no default item sort: preserve today's natural (unsorted) output order unless requested
				justification: defaultJustification(forFieldNamed: "adamID"),
			),
			.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
			.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
		],
	)
	/// The field set is open-ended (dynamically-discovered Spotlight attributes),
	/// so, absent a user-requested order, sort alphabetically by label rather
	/// than showing them in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(
		fieldSpecs: standardFieldsConfig.fieldSpecs,
		fieldOrder: .byLabel(.ascending),
	)
}
