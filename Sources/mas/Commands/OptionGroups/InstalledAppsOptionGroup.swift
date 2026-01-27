//
// InstalledAppsOptionGroup.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation // TODO: Remove import

struct InstalledAppsOptionGroup<Completion: CompletionProvider>: ParsableArguments {
	@OptionGroup
	private var forceBundleIDOptionGroup: ForceBundleIDOptionGroup // swiftformat:disable:this organizeDeclarations
	@Argument(help: .init("App ID", valueName: "app-id"), completion: Completion.kind)
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

protocol CompletionProvider { // swiftlint:disable:this one_declaration_per_file
	static var kind: CompletionKind { get }
}

enum All: CompletionProvider { // swiftlint:disable:this one_declaration_per_file
	static let kind = installedAppIDCompletionKind
}

enum Outdated: CompletionProvider { // swiftlint:disable:this one_declaration_per_file
	static let kind = outdatedAppIDCompletionKind
}

var installedAppIDCompletionKind: CompletionKind {
	// TODO: .custom(shellScript: associatedValueInsertionShellScript, installedAppIDCompletions)
	.custom(installedAppIDCompletions)
}

var outdatedAppIDCompletionKind: CompletionKind {
	// TODO: .custom(shellScript: associatedValueInsertionShellScript, outdatedAppIDCompletions)
	.custom(outdatedAppIDCompletions)
}

private func installedAppIDCompletions(arguments: [String], _: Int, completionPrefix: String) async -> [String] {
	appIDCompletions(
		installedApps: await installedApps(matching: .init(), withFullJSON: false),
		arguments: arguments,
		completionPrefix: completionPrefix,
	)
}

private func outdatedAppIDCompletions(arguments: [String], _: Int, completionPrefix: String) async -> [String] {
	let shouldOfferAllInstalledApps = arguments.contains { $0 == "--accurate" || $0 == "--force" }
	let installedApps = await installedApps(matching: .init(), withFullJSON: false)
	return appIDCompletions(
		installedApps: shouldOfferAllInstalledApps ? installedApps : await installedApps.filter { installedApp in
			do {
				let catalogApp = try await lookup(appID: .bundleID(installedApp.bundleID))
				return catalogApp.isInstallable != false && installedApp.isOutdated(comparedTo: catalogApp)
			} catch {
				return true
			}
		},
		arguments: arguments,
		completionPrefix: completionPrefix,
	)
}

private func appIDCompletions(installedApps: [InstalledApp], arguments: [String], completionPrefix: String)
-> [String] { // swiftformat:disable:this indent
	let completions = installedApps
		.filter { $0.name.insensitivelyStarts(with: completionPrefix) }
		.map(completionFromInstalledApp(forceBundleID: arguments.contains("--bundle")))
	// try? completions.joined(separator: "\n").write(
	// try? installedApps.map(\.bundleID).joined(separator: "\n").write(
	try? "(\(completionPrefix)) \(completionPrefix.count)\n\(completions.joined(separator: "\n"))".write(
		to: URL(filePath: "/Users/ross.goldberg/Downloads/completions.log", directoryHint: .notDirectory),
		atomically: true,
		encoding: .utf8,
	)
	return completions
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
<<<<<<< HEAD:Sources/mas/Commands/OptionGroups/InstalledAppsOptionGroup.swift
		try completions.joined(separator: "\n").write(
			to: .init(filePath: "/Users/ross.goldberg/Downloads/upgrade-completion-test.txt", directoryHint: .notDirectory),
			atomically: true,
			encoding: .utf8,
		)
=======
		let installedApps = try await installedApps()
		let completions = installedApps.filter { $0.name.insensitivelyStarts(with: completionPrefix) }
		.sorted { $0.name.compareInsensitively(to: $1.name) == .orderedAscending }
		.map { "\($0.adamID):\($0.name)" }
		+ installedApps.filter { $0.bundleID.insensitivelyStarts(with: completionPrefix) }
		.sorted { $0.bundleID.compareInsensitively(to: $1.bundleID) == .orderedAscending }
		.map { "\($0.adamID):\($0.bundleID)" }
		+ installedApps.filter { String($0.adamID).hasPrefix(completionPrefix) }.map { "\($0.adamID):\($0.adamID)" }
		do {
			try completions.joined(separator: "\n").write(
				to: URL(filePath: "/Users/ross.goldberg/Downloads/upgrade-completion-test.txt", directoryHint: .notDirectory),
				atomically: true,
				encoding: .utf8,
			)
		} catch {
			// Do nothing
		}
		return completions
>>>>>>> 41721706f (Remove commented swiftformat directives.):Sources/mas/Commands/OptionGroups/InstalledAppIDsOptionGroup.swift
	} catch {
		// Do nothing
	}
	return completions
	*/
	// swiftformat:enable indent
}

/* // swiftformat:disable indent
// TODO: Remove
private func installedAppIDCompletionsTest(_: [String], _: Int, completionPrefix: String) -> [String] {
	/*
	// TODO: reinstate
	let installedApps = await installedApps()
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
	}
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

private func completionFromInstalledApp(forceBundleID: Bool) -> (InstalledApp) -> String {
	func completionValue(for installedApp: InstalledApp) -> String {
		forceBundleID || ADAMID(installedApp.bundleID) == nil ? installedApp.bundleID : String(installedApp.adamID)
	}

	func completionDescription(for installedApp: InstalledApp) -> String {
		"\(installedApp.name)\(ADAMID(installedApp.bundleID) == nil ? "" : (forceBundleID ? " (bundle ID)" : " (ADAM ID)"))"
	}

	return switch CompletionShell.requesting {
	case .fish:
		{ "\(completionValue(for: $0))\t\(completionDescription(for: $0))" }
	case .zsh:
		{ "\(completionValue(for: $0)):\(completionDescription(for: $0))" }
	default:
		{ completionValue(for: $0) }
	}
}
