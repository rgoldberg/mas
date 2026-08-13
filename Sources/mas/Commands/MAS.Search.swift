//
// MAS.Search.swift
// mas
//
// Copyright © 2016 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import JSONAST

extension MAS { // swiftlint:disable:this file_types_order
	/// Searches for apps in the App Store.
	///
	/// Uses the iTunes Search API:
	///
	/// https://performance-partners.apple.com/search-api
	struct Search: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Search for apps in the App Store",
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<TableConfig>
		@Flag(help: "Output the price of each app")
		private var price = false
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

			if price {
				OutputConfigOptionGroup<PriceTableConfig>(outputFormat: outputConfigOptionGroup.outputFormat)
					.output(catalogApps.map(\.jsonObject))
			} else {
				outputConfigOptionGroup.output(catalogApps.map(\.jsonObject))
			}
		}
	}
}

private struct TableConfig: OutputConfig, Keyed { // swiftlint:disable:this file_types_order
	static let defaultFormat = OutputFormat.table
	static let keys = [JSON.Key("adamID"), "name", "version"]
}

private struct PriceTableConfig: OutputConfig, Keyed { // swiftlint:disable:this one_declaration_per_file
	static let defaultFormat = OutputFormat.table
	static let keys = [JSON.Key("adamID"), "name", "version", "price"]
}
