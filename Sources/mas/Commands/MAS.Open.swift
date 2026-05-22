//
// MAS.Open.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

private import AppKit
internal import ArgumentParser
private import Foundation
private import ObjectiveC

extension MAS {
	/// Opens app page in 'App Store.app'.
	///
	/// Uses the iTunes Lookup API:
	///
	/// https://performance-partners.apple.com/search-api
	struct Open: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Open app page in 'App Store.app'",
		)

		@OptionGroup
		private var forceBundleIDOptionGroup: ForceBundleIDOptionGroup
		@Argument(help: .init("App ID", valueName: "app-id"))
		private var appIDString: String?

		func run() async throws {
			try await run(
				appStorePageURLString: appIDString.map { appIDString in
					try await Environment.current
						.lookupAppFromAppID(.init(from: appIDString, forceBundleID: forceBundleIDOptionGroup.forceBundleID))
						.appStorePageURLString
				},
			)
		}

		private func run(appStorePageURLString: String?) async throws {
			guard let appStorePageURLString else {
				// If no App Store Page URL was given, open the App Store
				guard let macAppStoreSchemeURL = URL(string: "\(masScheme):") else {
					throw MASError.error("Failed to create URL from \(masScheme) scheme")
				}

				let workspace = NSWorkspace.shared
				guard let appURL = workspace.urlForApplication(toOpen: macAppStoreSchemeURL) else {
					throw MASError.error("Failed to find app to open \(masScheme) URLs")
				}

				try await workspace.openApplication(at: appURL, configuration: .init())
				return
			}

			try await openMacAppStorePage(for: appStorePageURLString)
		}
	}
}

private func openMacAppStorePage(for appStorePageURLString: String) async throws {
	guard var urlComponents = URLComponents(string: appStorePageURLString) else {
		throw MASError.invalidURL(appStorePageURLString)
	}

	urlComponents.scheme = masScheme
	guard let url = urlComponents.url else {
		throw MASError.invalidURL(.init(describing: urlComponents))
	}

	_ = try await url.open()
}

private let masScheme = "macappstore"
