//
//  Purchase.swift
//  mas
//
//  Created by Jakob Rieck on 24/10/2017.
//  Copyright (c) 2017 Jakob Rieck. All rights reserved.
//

import ArgumentParser
import Foundation

extension MAS {
    struct Purchase: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "\"Purchase\" and install free apps from the Mac App Store"
        )

        @Argument(help: ArgumentHelp("App ID", valueName: "app-id"))
        var appIDs: [AppID]

        /// Runs the command.
        func run() async throws {
            try await run(appLibrary: SoftwareMapAppLibrary(), searcher: ITunesSearchAppStoreSearcher())
        }

        func run(appLibrary: AppLibrary, searcher: AppStoreSearcher) async throws {
            // Try to download applications with given identifiers and collect results
            let appIDs = appIDs.filter { appID in
                if let displayName = appLibrary.installedApps(withAppID: appID).first?.displayName {
                    printWarning("\(displayName) has already been purchased.")
                    return false
                }

                return true
            }

            do {
                try await downloadApps(withAppIDs: appIDs, verifiedBy: searcher, purchasing: true)
            } catch {
                throw error as? MASError ?? .downloadFailed(error: error as NSError)
            }
        }
    }
}
