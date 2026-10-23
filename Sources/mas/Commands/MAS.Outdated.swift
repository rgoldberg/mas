//
// MAS.Outdated.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import ArgumentParser

extension MAS { // swiftlint:disable:this file_types_order
	/// Outputs a list of already installed apps that have pending updates from
	/// the App Store.
	struct Outdated: AsyncParsableCommand, RealDropping {
		static let configuration = CommandConfiguration(
			abstract: "Output pending app updates from the App Store",
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<TableOutputConfig>
		@OptionGroup
		private var outdatedAppsOptionGroup: OutdatedAppsOptionGroup

		func run() async throws {
			try outputConfigOptionGroup.output(
				await outdatedAppsOptionGroup.outdatedApps(fields: try outputConfigOptionGroup.fetchFieldNames())
					.map(\.jsonObject),
			)
		}
	}
}

private struct TableOutputConfig: OutputConfig {
	static let defaultFormat = OutputFormat.table(.default)
	static let standardFieldsConfig =
		SelectedFieldsConfig(fieldSpecs: ["adamID", "name", "version", "newVersion"].map(builtInFieldSpec(forFieldNamed:)))
	/// The field set is open-ended (Spotlight attributes), so every field without
	/// a field spec here is unlisted (fields.md "Unlisted Fields");
	/// `resolveBaseFieldsConfig(...)`'s generic default for `all` (sort
	/// alphabetically by label) applies here, absent a user-requested order,
	/// rather than showing fields in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(fieldSpecs: standardFieldsConfig.fieldSpecs)
}
