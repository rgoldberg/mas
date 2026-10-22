//
// MAS.Lookup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation

extension MAS { // swiftlint:disable:this file_types_order
	/// Outputs app info from the App Store.
	///
	/// Uses the iTunes Lookup API:
	///
	/// https://performance-partners.apple.com/search-api
	struct Lookup: AsyncParsableCommand, RealDropping {
		static let configuration = CommandConfiguration(
			abstract: "Output app info from the App Store",
			usage: "mas lookup \(outputConfigUsage) [--bundle] <app-id> ...",
			aliases: ["info"],
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<KeyValueOutputConfig>
		@OptionGroup
		private var catalogAppsOptionGroup: CatalogAppsOptionGroup

		func run() async throws {
			try run(catalogApps: await catalogAppsOptionGroup.appIDs.catalogApps)
		}

		func run(catalogApps: [CatalogApp]) throws {
			try outputConfigOptionGroup.output(catalogApps.map(\.jsonObject))
		}
	}
}

private struct KeyValueOutputConfig: OutputConfig {
	static let defaultFormat = OutputFormat.keyValue(.default)
	static let standardFieldsConfig = SelectedFieldsConfig(
		fieldSpecs: [
			"name",
			"adamID",
			"bundleID",
			"version",
			"formattedPrice",
			"sellerName",
			"currentVersionReleaseDate",
			"minimumOSVersion",
			"fileSizeBytes",
			"appStorePageURL",
		]
			.map(builtInFieldSpec(forFieldNamed:)),
	)
	/// The field set is open-ended (dynamically-discovered API fields);
	/// `resolveBaseFieldsConfig(...)`'s generic default for `all` (sort
	/// alphabetically by label) applies here, absent a user-requested order,
	/// rather than showing them in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(fieldSpecs: standardFieldsConfig.fieldSpecs)
}
