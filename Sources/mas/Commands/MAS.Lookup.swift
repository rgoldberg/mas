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
			.init(name: "name", label: "Name", format: defaultFieldFormat(forFieldNamed: "name"), sortSpec: nil),
			.init(
				name: "adamID",
				label: "ADAM ID",
				format: defaultFieldFormat(forFieldNamed: "adamID"),
				sortSpec: nil,
				justification: defaultJustification(forFieldNamed: "adamID"),
			),
			.init(name: "bundleID", label: "Bundle ID", format: defaultFieldFormat(forFieldNamed: "bundleID"), sortSpec: nil),
			.init(name: "version", label: "Version", format: defaultFieldFormat(forFieldNamed: "version"), sortSpec: nil),
			.init(
				name: "formattedPrice",
				label: "Price",
				format: defaultFieldFormat(forFieldNamed: "formattedPrice"),
				sortSpec: nil,
			),
			.init(name: "sellerName", label: "By", format: defaultFieldFormat(forFieldNamed: "sellerName"), sortSpec: nil),
			.init(
				name: "currentVersionReleaseDate",
				label: "Released",
				// `%C.dateOnly++`: the release date, date-only, in the system time zone
				format: .template(
					[
						.placeholder(
							.conditional(
								.init(predicate: .chronologic, coercion: nil),
								.binary(success: .pipeline([.init(transform: .dateOnly, isCoerced: false)]), failure: nil),
							),
						),
					],
				),
				sortSpec: nil,
			),
			.init(
				name: "minimumOSVersion",
				label: "Minimum OS",
				format: defaultFieldFormat(forFieldNamed: "minimumOSVersion"),
				sortSpec: nil,
			),
			.init(
				name: "fileSizeBytes",
				label: "Size",
				// `%+.N.scale:10,6,,0:.group+ MB`: a byte count as whole, grouped
				// decimal megabytes, with an appended " MB". JSON gets the raw byte
				// count instead: `--json` resolves to the machine-facing `@json`
				// variant (see `machineFacingVariant()`), which labels & formats each
				// field spec by its name, per mas.md
				format: .template(
					[
						.placeholder(
							.conditional(
								.init(predicate: .number, coercion: .strict),
								.abortOnFailure(
									success: .pipeline(
										[
											.init(
												transform: .scale(radix: 10, exponent: 6, significantDigits: nil, fractionalDigits: 0),
												isCoerced: false,
											),
											.init(transform: .group(locale: .current), isCoerced: false),
										],
									),
								),
							),
						),
						.text(" MB"),
					],
				),
				sortSpec: nil,
				justification: defaultJustification(forFieldNamed: "fileSizeBytes"),
			),
			.init(
				name: "appStorePageURL",
				label: "From",
				format: defaultFieldFormat(forFieldNamed: "appStorePageURL"),
				sortSpec: nil,
			),
		],
	)
	/// The field set is open-ended (dynamically-discovered API fields);
	/// `resolveBaseFieldsConfig(...)`'s generic default for `all` (sort
	/// alphabetically by label) applies here, absent a user-requested order,
	/// rather than showing them in their arbitrary discovery order.
	static let allFieldsConfig = BaseIncludesAllFieldsConfig(fieldSpecs: standardFieldsConfig.fieldSpecs)
}
