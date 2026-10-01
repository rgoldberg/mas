//
// Environment.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

struct Environment {
	@TaskLocal
	static var current = Self()

	@Required(URL(string: "https://itunes.apple.com/lookup"))
	var lookupURL
	@Required(URL(string: "https://itunes.apple.com/search"))
	var searchURL
	let dataFrom: @Sendable (URL) async throws -> (data: Data, response: URLResponse)
	let lookupAppFromAppID: @Sendable (AppID) async throws -> CatalogApp
	let searchForAppsMatchingSearchTerm: @Sendable (String) async throws -> [CatalogApp]
	/// The time zone that `<time-zone-code>` `system` identifies, in which
	/// chronologic values are rendered by default.
	let systemTimeZone: TimeZone
	/// The current date & time, whose date in the system time zone is the default
	/// `<reference-date>`.
	let now: @Sendable () -> Date

	init(
		dataFrom: // swiftformat:disable:next indent
			@escaping @Sendable (URL) async throws -> (Data, URLResponse) = URLSession(configuration: .ephemeral).data,
		lookupAppFromAppID: @escaping @Sendable (AppID) async throws -> CatalogApp = lookup,
		searchForAppsMatchingSearchTerm: @escaping @Sendable (String) async throws -> [CatalogApp] = search,
		systemTimeZone: TimeZone = .autoupdatingCurrent,
		now: @escaping @Sendable () -> Date = Date.init,
	) {
		self.dataFrom = dataFrom
		self.lookupAppFromAppID = lookupAppFromAppID
		self.searchForAppsMatchingSearchTerm = searchForAppsMatchingSearchTerm
		self.systemTimeZone = systemTimeZone
		self.now = now
	}
}
