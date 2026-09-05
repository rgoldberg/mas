//
// MAS.Outdated.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
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
			.init(
				name: "newVersion",
				label: "New Version",
				format: .default(fieldName: "newVersion"),
				sortSpec: nil,
				isSynthesized: true,
			),
		],
	)
	/// The field set is open-ended (dynamically-discovered Spotlight
	/// attributes); `resolveBaseFieldsConfig(...)`'s generic default for `all`
	/// (sort alphabetically by label) applies here, absent a user-requested
	/// order, rather than showing them in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(fieldSpecs: standardFieldsConfig.fieldSpecs)
}
