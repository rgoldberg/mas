//
// CatalogAppsOptionGroup.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation // TODO: Remove import

struct CatalogAppsOptionGroup: ParsableArguments {
	@OptionGroup
	private var forceBundleIDOptionGroup: ForceBundleIDOptionGroup
	@Argument(help: .init("App ID", valueName: "app-id"), completion: catalogAppIDCompletionKind)
	private var appIDStrings: [String]

	var appIDs: [AppID] {
		appIDStrings.map { .init(from: $0, forceBundleID: forceBundleIDOptionGroup.forceBundleID) }
	}
}

var catalogAppIDCompletionKind: CompletionKind {
	// TODO: .custom(shellScript: associatedValueInsertionShellScript, catalogAppIDCompletions)
	.custom(catalogAppIDCompletions)
}

private func catalogAppIDCompletions(_: [String], _: Int, completingPrefix: String) async -> [String] {
	do {
		let completions = try await search(for: completingPrefix) // swiftformat:disable:next indent
		.map { "\($0.adamID)\(CompletionShell.requesting == .fish ? "\t" : ":")\($0.name)" }
		try completions.joined(separator: "\n").write(
			to: .init(filePath: "/Users/ross.goldberg/Downloads/completion-test.txt", directoryHint: .notDirectory),
			atomically: true,
			encoding: .utf8,
		)
		return completions
	} catch {
		return []
	}
}
