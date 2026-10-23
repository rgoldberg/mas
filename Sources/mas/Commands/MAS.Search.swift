//
// MAS.Search.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import ArgumentParser

extension MAS { // swiftlint:disable:this file_types_order
	/// Searches for apps in the App Store.
	///
	/// Uses the iTunes Search API:
	///
	/// https://performance-partners.apple.com/search-api
	struct Search: AsyncParsableCommand, RealDropping {
		static let configuration = CommandConfiguration(
			abstract: "Search for apps in the App Store",
			usage: "mas search \(outputConfigUsage) <search-term> ...",
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<TableOutputConfig>
		@OptionGroup
		private var searchTermOptionGroup: SearchTermOptionGroup

		func run() async throws {
			try run(
				catalogApps: try await Environment.current.searchForAppsMatchingSearchTerm(searchTermOptionGroup.searchTerm),
			)
		}

		func run(catalogApps: [CatalogApp]) throws {
			guard !catalogApps.isEmpty else {
				throw MASError.noCatalogAppsFound(for: searchTermOptionGroup.searchTerm)
			}
			try outputConfigOptionGroup.output(catalogApps.map(\.jsonObject))
		}
	}
}

private struct TableOutputConfig: OutputConfig {
	static let defaultFormat = OutputFormat.table(.default)
	static let standardFieldsConfig =
		SelectedFieldsConfig(fieldSpecs: ["adamID", "name", "version"].map(builtInFieldSpec(forFieldNamed:)))
	/// The field set is open-ended (API fields), so every field without a field
	/// spec here is unlisted (fields.md "Unlisted Fields");
	/// `resolveBaseFieldsConfig(...)`'s generic default for `all` (sort
	/// alphabetically by label) applies here, absent a user-requested order,
	/// rather than showing fields in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(fieldSpecs: standardFieldsConfig.fieldSpecs)
}
