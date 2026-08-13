//
// OutdatedApp.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST

struct OutdatedApp {
	let installedApp: InstalledApp
	let newVersion: String // periphery:ignore

	private let lazyJSONObject: Lazy<JSON.Object>

	var jsonObject: JSON.Object {
		lazyJSONObject.value
	}

	init(installedApp: InstalledApp, newVersion: String) {
		self.installedApp = installedApp
		self.newVersion = newVersion
		lazyJSONObject = .init {
			var jsonObject = installedApp.jsonObject
			jsonObject.fields.insert(
				(newVersionKey, .string(newVersion)),
				at: jsonObject.fields
					.map(\.key.rawValue)
					.lowerBound(of: newVersionKey.rawValue, using: NumericStringComparator.forward),
			)
			return jsonObject
		}
	}
}

private let newVersionKey = JSON.Key("newVersion")
