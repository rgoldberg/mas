//
// InstalledAppsOptionGroup.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation // TODO: Remove import

struct InstalledAppsOptionGroup: ParsableArguments {
	@OptionGroup
	private var forceBundleIDOptionGroup: ForceBundleIDOptionGroup // swiftformat:disable:this organizeDeclarations
	@Argument(help: .init("App ID", valueName: "app-id"), completion: installedAppIDCompletionKind)
	private(set) var appIDStrings = [String]()

	var appIDs: [AppID] {
		appIDStrings.map { .init(from: $0, forceBundleID: forceBundleIDOptionGroup.forceBundleID) }
	}

	func installedApps(withFullJSON: Bool) async -> [InstalledApp] {
		await mas::installedApps(withAppIDs: appIDs, withFullJSON: withFullJSON) { appID in
			MAS.printer.error("Failed to find installed app with \(appID)")
		}
	}
}

var installedAppIDCompletionKind: CompletionKind {
	// TODO: .custom(shellScript: associatedValueInsertionShellScript, installedAppIDCompletions)
	.custom(installedAppIDCompletions)
}

private func installedAppIDCompletions(_: [String], _: Int, _: String) async -> [String] {
	// TODO: filter using args
	let separator = CompletionShell.requesting == .fish ? "\t" : ":"
	return await installedApps(matching: .init(), withFullJSON: false).map { "\($0.adamID)\(separator)\($0.name)" }
	/* // swiftformat:disable indent
	let installedApps = await installedApps(matching: .init(), withFullJSON: false)
	let completions = installedApps.filter { $0.name.insensitivelyStarts(with: completionPrefix) }
	.sorted { $0.name.compareInsensitively(to: $1.name) == .orderedAscending }
	.map { "\($0.adamID):\($0.name)" }
	+ installedApps.filter { $0.bundleID.insensitivelyStarts(with: completionPrefix) }
	.sorted { $0.bundleID.compareInsensitively(to: $1.bundleID) == .orderedAscending }
	.map { "\($0.adamID):\($0.bundleID)" }
	+ installedApps.filter { String($0.adamID).hasPrefix(completionPrefix) }.map { "\($0.adamID):\($0.adamID)" }
	do {
		try completions.joined(separator: "\n").write(
			to: .init(filePath: "/Users/ross.goldberg/Downloads/upgrade-completion-test.txt", directoryHint: .notDirectory),
			atomically: true,
			encoding: .utf8,
		)
	} catch {
		// Do nothing
	}
	return completions
	*/
	// swiftformat:enable indent
}

/* // swiftformat:disable indent
// TODO: Remove
// swiftformat:disable:next unusedPrivateDeclarations
private func installedAppIDCompletionsTest(_: [String], _: Int, completionPrefix: String) -> [String] {
	/*
	// TODO: reinstate
	let installedApps = await installedApps()
	// swiftformat:disable indent
	let installedAppIDSet = installedApps.filter { installedApp in
		installedApp.name.insensitivelyStarts(with: completionPrefix)
		|| installedApp.bundleID.insensitivelyStarts(with: completionPrefix)
		|| String(installedApp.adamID).hasPrefix(completionPrefix)
	}
	.reduce(into: Set<AppID>()) { appIDSet, installedApp in
		appIDSet.insert(installedApp.adamID)
	}
	let completions = installedApps.filter { $0.name.insensitivelyStarts(with: completionPrefix) }
	let completions = switch installedAppIDSet.count {
	case 0:
		[String]()
	case 1:
		[installedAppIDSet.first?.description ?? ""]
	default:
		// swiftformat:disable indent
		installedApps.filter { $0.name.insensitivelyStarts(with: completionPrefix) }
		.sorted { $0.name.compareInsensitively(to: $1.name) == .orderedAscending }
		.map { "\($0.adamID):\($0.name)" } // OR…
		.map { "\($0.name):\($0.name)" }
		+ installedApps.filter { $0.bundleID.insensitivelyStarts(with: completionPrefix) }
		.sorted { $0.bundleID.compareInsensitively(to: $1.bundleID) == .orderedAscending }
		.map { "\($0.adamID):\($0.bundleID)" } // OR…
		.map { "\($0.bundleID):\($0.name)" }
		+ installedApps.filter { String($0.adamID).hasPrefix(completionPrefix) }
		.sorted { $0.adamID < $1.adamID }
		.map { "\($0.adamID):\($0.adamID)" } // OR…
		.map { "\($0.adamID):\($0.name)" }
	} // swiftformat:enable indent
	*/
	let completions =
		switch completionPrefix {
		case "1":
			["1", "11111111111"]
		case "11":
			["11", "11111111111"]
		case "2":
			["2", "22222222222"]
		default:
			[completionPrefix]
		}
	do {
		// try "\(installedApps.count) \(installedAppIDSet.count)\n\(installedAppIDSet)".write(
		try completions.joined(separator: "\n").write(
			to: .init(filePath: "/tmp/upgrade-completion-test.txt", directoryHint: .notDirectory),
			atomically: true,
			encoding: .utf8,
		)
		return completions
	} catch {
		return []
	}
}
*/
// swiftformat:enable indent
