//
// MAS.Uninstall.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation
private import OrderedCollections
private import Subprocess
private import System

extension MAS {
	/// Uninstalls apps already installed from the App Store.
	struct Uninstall: AsyncParsableCommand, PrivilegePreserving {
		static let configuration = CommandConfiguration(
			abstract: "Uninstall apps already installed from the App Store",
			discussion: requiresRootPrivilegesMessage(),
		)

		@Flag(name: .customLong("dry-run"), help: "Perform dry run")
		private var isPerformingDryRun = false
		@Flag(name: .customLong("all"), help: "Uninstall all App Store apps")
		private var isUninstallingAll = false
		@OptionGroup
		private var installedAppsOptionGroup: InstalledAppsOptionGroup

		func validate() throws(ValidationError) {
			if isUninstallingAll != installedAppsOptionGroup.appIDStrings.isEmpty {
				throw .init(
					isUninstallingAll
						? "Cannot specify both --all & app IDs"
						: "Must specify either --all or at least one app ID",
				)
			}
		}

		func run() async throws {
			let installedApps = await installedAppsOptionGroup.installedApps(fields: ["adamID", "bundleID", "path"])
			let appPathOrderedSet =
				(isUninstallingAll ? installedApps.map { .bundleID($0.bundleID) } : installedAppsOptionGroup.appIDs)
				.reduce(into: OrderedSet<String>()) { appPathOrderedSet, appID in
					appPathOrderedSet.formUnion(installedApps.compactMap { $0.matches(appID) ? $0.path : nil })
				}
			guard !appPathOrderedSet.isEmpty else {
				return
			}
			guard !isPerformingDryRun else {
				printer.notice("Dry run. A wet run would uninstall:\n")
				for appPath in appPathOrderedSet {
					printer.info(appPath)
				}
				return
			}
			guard runningAsRoot else {
				try await nestedSudoMAS()
				return
			}
			let uid = try ProcessInfo.processInfo.sudoUID
			guard setreuid(uid, 0) == 0 else {
				throw error("Failed to set ruid to \(uid) & euid to 0: \(Errno(rawValue: errno))")
			}
			for appPath in appPathOrderedSet {
				do {
					_ = try await mas::run(
						"/usr/bin/trash",
						arguments: [appPath],
						errorMessage: "Failed to uninstall \(appPath)",
					)
					printer.info("Uninstalled", appPath)
				} catch {
					printer.error("Failed to uninstall", appPath, error: error)
				}
			}
		}
	}
}
