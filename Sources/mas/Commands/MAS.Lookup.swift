//
// MAS.Lookup.swift
// mas
//
// Copyright © 2016 mas-cli. All rights reserved.
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
			aliases: ["info"],
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<KeyValueConfig>
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

private struct KeyValueConfig: OutputConfig {
	static let defaultFormat = OutputFormat.keyValue
	static let standardFieldsConfig = SelectedFieldsConfig(
		fieldSpecs: [
			.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
			.init(
				name: "adamID",
				label: "ADAM ID",
				format: .default(fieldName: "adamID"),
				sortSpec: nil,
				justification: defaultJustification(forFieldNamed: "adamID"),
			),
			.init(name: "bundleID", label: "Bundle ID", format: .default(fieldName: "bundleID"), sortSpec: nil),
			.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
			.init(name: "formattedPrice", label: "Price", format: .default(fieldName: "formattedPrice"), sortSpec: nil),
			.init(name: "sellerName", label: "By", format: .default(fieldName: "sellerName"), sortSpec: nil),
			.init(
				name: "currentVersionReleaseDate",
				label: "Released",
				// `%D.dateOnly++`: the release date, date-only, in the local time zone
				format: // swiftformat:disable:next indent
					.parts([.placeholder(.date(negated: false, success: .init(outputTransforms: [.dateOnly]), failure: nil))]),
				sortSpec: nil,
			),
			.init(
				name: "minimumOSVersion",
				label: "Minimum OS",
				format: .default(fieldName: "minimumOSVersion"),
				sortSpec: nil,
			),
			.init(
				name: "fileSizeBytes",
				label: "Size",
				// A byte count as whole, comma-grouped decimal megabytes, with an
				// appended " MB". JSON gets the raw byte count instead: `--json`
				// resolves through `defaultedForJSON(outputFormat:)`, which discards
				// this format (& the label above) for a built-in default fields
				// config, per fields.md's Labeling section.
				format: .parts(
					[
						.placeholder(
							.number(
								negated: false,
								coerced: true,
								success: .reference(
									.init(
										namedFormat: nil,
										transforms: [
											.scale(radix: 10, exponent: 6, significantDigits: nil, fractionalDigits: 0),
											.group(locale: .current),
										],
									),
								),
								failure: nil,
							),
						),
						.text(" MB"),
					],
				),
				sortSpec: nil,
				justification: defaultJustification(forFieldNamed: "fileSizeBytes"),
			),
			.init(name: "appStorePageURL", label: "From", format: .default(fieldName: "appStorePageURL"), sortSpec: nil),
		],
	)
	/// The field set is open-ended (dynamically-discovered API fields);
	/// `resolveBaseFieldsConfig(...)`'s generic default for `all` (sort
	/// alphabetically by label) applies here, absent a user-requested order,
	/// rather than showing them in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(fieldSpecs: standardFieldsConfig.fieldSpecs)
}
