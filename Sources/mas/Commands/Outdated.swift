//
// Outdated.swift
// mas
//
// Copyright © 2015 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation
private import JSONAST
private import JSONParsing

extension MAS {
	/// Outputs a list of installed apps which have updates available to be
	/// installed from the App Store.
	struct Outdated: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "List pending app updates from the App Store",
		)

		@OptionGroup
		private var outputFormatOptionGroup: OutputFormatOptionGroup
		@OptionGroup
		private var outdatedAppOptionGroup: OutdatedAppOptionGroup

		func run() async throws {
			await run(installedApps: try await installedApps.filter(!\.isTestFlight))
		}

		private func run(installedApps: [InstalledApp]) async {
			run(outdatedApps: await outdatedAppOptionGroup.outdatedApps(from: installedApps))
		}

		private func run(outdatedApps: [OutdatedApp]) {
			guard !outdatedApps.isEmpty else {
				return
			}

			outputFormatOptionGroup.info(
				outdatedApps.compactMap { installedApp, newVersion in
					do {
						let newVersionKey = "newVersion"
						var json = try JSON.Object(parsing: .init(describing: installedApp))
						json.fields.insert(
							(.init(rawValue: newVersionKey), .string(.init(newVersion))),
							at: json.fields.enumerated().first { newVersionKey < $1.key.rawValue }?.offset ?? json.fields.count,
						) // swiftlint:disable:previous unused_enumerated
						return .init(json)
					} catch {
						printer.error("Failed to parse outdated app JSON", installedApp, error: error, separator: "\n")
						return nil
					}
				}
				.joined(separator: "\n"),
			)
		}
	}
}
