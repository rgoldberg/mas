//
// MAS.Search.swift
// mas
//
// Copyright © 2016 mas-cli. All rights reserved.
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
	/// The field set is open-ended (dynamically-discovered API fields), so,
	/// absent a user-requested order, sort alphabetically by label rather than
	/// showing them in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(
		fieldSpecs: standardFieldsConfig.fieldSpecs,
		fieldOrder: .byLabel(.fieldOrderDefault),
	)
}
