//
// MAS.Lookup.swift
// mas
//
// Copyright © 2016 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation
private import JSONAST

extension MAS { // swiftlint:disable:this file_types_order
	/// Outputs app info from the App Store.
	///
	/// Uses the iTunes Lookup API:
	///
	/// https://performance-partners.apple.com/search-api
	struct Lookup: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Output app info from the App Store",
			aliases: ["info"],
		)

		@OptionGroup
		private var outputConfigOptionGroup: OutputConfigOptionGroup<KeyValueConfig>
		@OptionGroup
		private var catalogAppsOptionGroup: CatalogAppsOptionGroup

		func run() async {
			run(catalogApps: await catalogAppsOptionGroup.appIDs.catalogApps)
		}

		func run(catalogApps: [CatalogApp]) {
			outputConfigOptionGroup.output(catalogApps.map(\.jsonObject))
		}
	}
}

private struct KeyValueConfig: OutputConfig, FieldConfigured {
	static let defaultFormat = OutputFormat.keyValue

	static let fieldConfigs = [
		(key: JSON.Key("name"), label: "App", transform: defaultTransform),
		(key: "version", label: "Version", transform: defaultTransform),
		(key: "formattedPrice", label: "Price", transform: defaultTransform),
		(key: "sellerName", label: "By", transform: defaultTransform),
		(
			key: "currentVersionReleaseDate",
			label: "Released",
			transform: { @Sendable (string: String?) in string?.isoLocalDate ?? "" },
		),
		(key: "minimumOSVersion", label: "Minimum OS", transform: defaultTransform),
		(key: "fileSizeBytes", label: "Size", transform: { (string: String?) in string?.megabyteCount ?? "" }),
		(key: "appStorePageURL", label: "From", transform: defaultTransform),
	]
}

private extension String {
	var megabyteCount: Self {
		Int64(self).map { size in
			((size + 500_000) / 1_000_000 * 1_000_000)
				.formatted(.byteCount(style: .file, allowedUnits: .mb, spellsOutZero: false))
		}
			?? self
	}

	var isoLocalDate: Self {
		(try? Date(self, strategy: .iso8601).formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day()))
			?? self
	}
}
