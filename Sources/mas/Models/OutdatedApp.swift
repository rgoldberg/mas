//
// OutdatedApp.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import JSONAST

struct OutdatedApp {
	let installedApp: InstalledApp
	let newVersion: String // periphery:ignore

	private let lazyJSON: Lazy<String>

	init(installedApp: InstalledApp, newVersion: String) {
		self.installedApp = installedApp
		self.newVersion = newVersion
		var jsonObjectInstalled = installedApp.jsonObject
		jsonObjectInstalled.fields.insert(
			(newVersionKey, .string(newVersion)),
			at: jsonObjectInstalled.fields
				.map(\.key.rawValue)
				.lowerBound(of: newVersionKey.rawValue, using: NumericStringComparator.forward),
		)
		let jsonObject = jsonObjectInstalled
		lazyJSON = .init(.init(describing: jsonObject))
	}
}

extension OutdatedApp: CustomStringConvertible {
	var description: String {
		lazyJSON.value
	}
}

private let newVersionKey = JSON.Key("newVersion")
