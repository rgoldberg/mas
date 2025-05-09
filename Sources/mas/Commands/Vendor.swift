//
// Vendor.swift
// mas
//
// Created by Ben Chatelain on 2018-12-29.
// Copyright © 2018 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation

extension MAS {
	/// Opens vendor's app page in a browser. Uses the iTunes Lookup API:
	/// https://performance-partners.apple.com/search-api
	struct Vendor: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Open vendor's app web page in the default web browser"
		)

		@Argument(help: ArgumentHelp("App ID", valueName: "app-id"))
		var appIDs: [AppID]

		/// Runs the command.
		func run() async throws {
			try await run(searcher: ITunesSearchAppStoreSearcher())
		}

		func run(searcher: AppStoreSearcher) async throws {
			for appID in appIDs {
				let result = try await searcher.lookup(appID: appID)

				guard let urlString = result.sellerUrl else {
					throw MASError.noVendorWebsite
				}

				guard let url = URL(string: urlString) else {
					throw MASError.urlParsing(urlString)
				}

				try await url.open()
			}
		}
	}
}
