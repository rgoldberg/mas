//
// InstalledAppsOptionGroup.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser

struct InstalledAppsOptionGroup: ParsableArguments {
	@OptionGroup
	private var forceBundleIDOptionGroup: ForceBundleIDOptionGroup
	@Argument(help: .init("App ID", valueName: "app-id"))
	private var appIDStrings = [String]()

	var appIDs: [AppID] {
		appIDStrings.map { .init(from: $0, forceBundleID: forceBundleIDOptionGroup.forceBundleID) }
	}
}
