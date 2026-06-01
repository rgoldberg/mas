//
// MAS.Test.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Foundation

// swiftformat:disable unusedPrivateDeclarations
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable unused_declaration

extension MAS { // swiftlint:disable:this file_types_order
	struct Test: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Test",
			subcommands: [Open.self],
		)

		// @Flag(help: "Probably")
		// private var probably = true

		// @Flag(inversion: .prefixedNo, help: "Unlikely")
		// private var unlikely: Bool

		// @Option(help: "Maybe")
		// private var maybe: Bool

		// @Option(help: "The compression type to use.")
		// private var compression: CompressionType

		// @Option(help: "The compression number to use.")
		// private var compressionNumber: CompressionNumber

		// @Argument(help: "JPEG", completion: .file(extensions: ["jpeg", "jpg"]))
		// private var jpeg: String

		// @Argument(help: "misc", completion: .file())
		// private var misc: String

		// @Argument(help: "dir", completion: .directory)
		// private var dir: String

		// @Argument(help: .init("dir", valueName: "dir"), completion: .directory)
		// private var dir2: String

		@Flag
		private var allowedKinds = [Kind]()
		@Option
		private var kind: Kind

		@Argument(help: "info", completion: .custom(test))
		private var info: String

		@Argument(help: "The compression type to use.")
		private var compressionArg: CompressionType

		@Argument(help: "The compression number to use.")
		private var compressionNumberArg = CompressionNumber.abc

		// @Option(help: "Mirror", completion: .custom { $0 })
		// private var mirror: String

		@Option(help: "custom", completion: .custom(test))
		private var custom = "default"

		@Option(name: [.long, .customShort("p")], help: "App ID", completion: .custom(test))
		private var appIDString = "0"

		@Option(help: "dir", completion: .directory)
		private var dir = ""

		/* // swiftformat:disable indent
		// fish
		@Option(help: "JPEG", completion: .file(extensions: ["jpeg", "jpg", "jpg", "jpeg"]))
		@Option(
			help: "JPEG",
			completion: .file(extensions: ["ab'cd", "ef\\'gh", "ij,kl", "mn}op", "qr st", "uv|wx", "jpg", "jpeg"])
		)
		@Option(help: "exts", completion: .file(extensions: ["ij,kl", "mn}op", "qr st", "uv|wx", "jpg", "jpeg"]))
		*/
		// swiftformat:enable indent

		@Option(
			help: "exts",
			completion: // swiftformat:disable:next indent
				.file(extensions: ["01a", "02 b", "03,c", "04'd", "05|e", "06$f", "07\\g", "08\\'h", "09)i", "10}j", "11(k"]),
		)
		private var exts = ""
		@Option(help: "file", completion: .file())
		private var file: String

		/* // swiftformat:disable indent
		@Option(help: "list", completion: .list(["a", "b c", "", "\\\\d", "e\\f", "$g", ") h", "\"i", "''", "'"]))
		private var list = ""
		@Option(help: "Shell", completion: .shellCommand("XYZ=('a1 b2 c3' 'd4 e5 f6');printf $'%s\\n' \"${XYZ[@]}\""))
		private var shell = ""
		*/
		// swiftformat:enable indent

		@Option(name: .shortAndLong, help: "adhoc")
		private var adhoc = ""
		@Option(help: #"Escaped chars: '[]\."#)
		private var qwerty = ""

		func run() {
			/* // swiftformat:disable indent
			MAS.printer.info("E \(yn is any ExpressibleByArgument)")
			MAS.printer.info("C \(yn is any CaseIterable)")
			*/
			// swiftformat:enable indent

			run(lookupAppFromAppID: lookup(appID:))
		}

		private func run(lookupAppFromAppID _: (AppID) async throws -> CatalogApp) {
			/* // swiftformat:disable indent
			MAS.printer.info(maybe)
			let catalogApp = try await lookupAppFromAppID(appID: appID)

			guard let urlString = catalogApp.sellerURL else {
				throw MASError.error("noTestWebsite")
			}

			guard let url = URL(string: urlString) else {
				throw MASError.error("Unable to construct URL from: \(urlString)")
			}

			try url.open().wait()
			*/
			// swiftformat:enable indent
		}
	}
}

private enum Kind: String, ExpressibleByArgument, EnumerableFlag {
	case one
	case two // swiftlint:disable:this sorted_enum_cases
	case three = "custom-three" // swiftlint:disable:this sorted_enum_cases
}

/* // swiftformat:disable indent
/// Testing.
private struct TestTime {
	/// Testing.
	var thing: String?
}
*/
// swiftformat:enable indent

private enum CompressionType: String, CaseIterable, ExpressibleByArgument {
	case gzip // swiftlint:disable:previous one_declaration_per_file
	case zip
}

private enum CompressionNumber: UInt32, CaseIterable, ExpressibleByArgument {
	case abc = 1 // swiftlint:disable:previous one_declaration_per_file
	case xyz = 2
}

extension Bool: @retroactive CaseIterable {
	public static let allCases = [true, false]
}

@Sendable
private func test(args: [String], completingArgumentIndex: Int, completingArgument: String) -> [String] {
	// swiftformat:disable indent
	// MAS.printer.info("ROSS\nROSS\nROSS \(args.joined(separator: " "))\nROSS\nROSS\nROSS\n")
	do {
		// CURRENT WORD: (\(args[completingArgumentIndex]))
		try """
		SHELL: \(CompletionShell.requesting?.rawValue ?? "unknown")
		VERSION: \(CompletionShell.requestingVersion ?? "unknown")
		WORD INDEX: \(completingArgumentIndex)
		COMPLETING ARGUMENT: (\(completingArgument))
		\(args.map { "(\($0))\n" }.joined())
		"""
			.write(to: .init(nonFolderPath: "/Users/ross.goldberg/Downloads/s.txt"), atomically: true, encoding: .utf8)

		if args.isEmpty {
			try "EMPTY_ARRAY\n"
				.write(to: .init(nonFolderPath: "/Users/ross.goldberg/Downloads/s.txt"), atomically: true, encoding: .utf8)
		}
	} catch {
		MAS.printer.error(error: error)
	}

	// return []

	// guard let countString = ProcessInfo.processInfo.environment["ROSS_COUNT"] else {
	// MAS.printer.error("\n\nA\n\n")
	// swiftformat:enable indent
	return [
		"",
		" ",
		"q",
		":a",
		" :b",
		"'':c",
		"a b:d",
		"option1:e:1",
		"option:2:f",
	]
	/* // swiftformat:disable indent
	}
	guard let count = Int(countString) else {
		// MAS.printer.error("\n\nB\n\n")
		return []
	}
	// MAS.printer.error("\n\nC \(count)\n\(Array(1...count).map { String($0) })\n\n")
	return count < 0 ? [String](repeating: "", count: -count) : count == 0 ? [] : Array(1...count).map { String($0) }
	["a bc", "", "def", " ", "ghi"]
	[CompletionShell.requesting?.rawValue ?? "unknown", CompletionShell.requestingVersion ?? "unknown"]
	MAS.printer.info("ROSS\nROSS\nROSS \(args.joined(separator: " "))\nROSS\nROSS\nROSS\n")
	let current = args[completingArgumentIndex]
	return args.map { "\(current)-\(completingArgumentIndex)-\($0)" }
	installedAppIDs(args, await installedApps)
	switch CompletionShell.requesting {
	case CompletionShell.zsh:
		["a", "b", "c"]
	case CompletionShell.bash:
		["A", "B", "C"]
	case CompletionShell.fish:
		["1", "2", "3"]
	default:
		[]
	}
	*/
	// swiftformat:enable indent
}

/* // swiftformat:disable indent
private func test(_: [String]) -> [String] {
	// MAS.printer.info("ROSS\nROSS\nROSS \(args.joined(separator: " "))\nROSS\nROSS\nROSS\n")
	[]
	["a bc", "", "def", " ", "ghi"]
	[CompletionShell.requesting?.rawValue ?? "unknown", CompletionShell.requestingVersion ?? "unknown"]
	var position = -1
	do {
		try """
		\(
			args.map { arg in
				position += 1
				return "\(String(position)): (\(arg))\n"
			}
			.joined()
		)
		"""
		.write(to: .init(nonFolderPath: "/tmp/swift-custom-completion-args.txt"), atomically: true, encoding: .utf8)
	} catch {
		MAS.printer.error(error: error)
	}
	return args
}

private func installedAppIDs(args _: [String], completingArgumentIndex _: Int, completingArgument _: Int)
async throws -> [String] { // swiftformat:disable:this indent
	try await installedApps.map { String($0.adamID) }
}

private func installedAppIDs(_ args: [String]) -> [String] {
	do {
		var position = -1
		try """
		SHELL: \(CompletionShell.requesting?.rawValue ?? "unknown")
		VERSION: \(CompletionShell.requestingVersion ?? "unknown")
		\(
			args.map { arg in
				position += 1
				return "(\(arg))\n"
				// return "\(String(position)): (\(arg))\n"
			}
			.joined()
		)
		"""
		let s = CompletionShell.requesting?.rawValue ?? "unknown"
		try s.write(to: .init(nonFolderPath: "/Users/ross.goldberg/Downloads/s.txt"), atomically: true, encoding: .utf8)

		if args.isEmpty {
			try "EMPTY_ARRAY\n"
				.write(to: .init(nonFolderPath: "/Users/ross.goldberg/Downloads/s.txt"), atomically: true, encoding: .utf8)
		}
	} catch {
		MAS.printer.error(String(describing: error))
	}

	// return []

	guard let countString = ProcessInfo.processInfo.environment["ROSS_COUNT"] else {
		// MAS.printer.error("\n\nA\n\n")
		return [
			"",
			" ",
			"q",
			":a",
			" :b",
			"'':c",
			"a b:d",
			"option1:e:1",
			"option:2:f",
		]
	}
	guard let count = Int(countString) else {
		// MAS.printer.error("\n\nB\n\n")
		return []
	}
	// MAS.printer.error("\n\nC \(count)\n\(Array(1...count).map { String($0) })\n\n")
	return count < 0 ? [String](repeating: "", count: -count) : count == 0 ? [] : Array(1...count).map { String($0) }
	await installedApps.map { String($0.id) }
	MAS.printer.info("ROSS\nROSS\nROSS \(args.joined(separator: " "))\nROSS\nROSS\nROSS\n")
	args.map {
		"XYZ-\($0.prefix(min(2, $0.count)))-OPTION-\($0[$0.index($0.startIndex, offsetBy: min(2, $0.count))...])-ABC"
	}
	let semaphore = DispatchSemaphore(value: 0)
	var appIDs: [String] = []
	Task {
		appIDs = await installedAppIDs(args)
		semaphore.signal()
	}
	semaphore.wait()
	return appIDs
}

private func installedAppIDs(_ args: [String]) async -> [String] {
	installedAppIDs(args, await installedApps)
	switch CompletionShell.requesting {
	case CompletionShell.zsh:
		["a", "b", "c"]
	case CompletionShell.bash:
		["A", "B", "C"]
	case CompletionShell.fish:
		["1", "2", "3"]
	default:
		[]
	}
}

private func installedAppIDs(_: [String], _ installedApps: [InstalledApp]) -> [String] {
	installedApps.map { "\($0.id):\($0.name.replacing(":", with: "\\:"))" }
}

private func outdatedAppIDs(args: [String], completingArgumentIndex _: Int, completingArgument _: String) -> [String] {
	outdatedAppIDs(args)
}

private func outdatedAppIDs(_: [String]) -> [String] {
	// await outdatedAppIDs(args, try await installedApps, lookup(appID:))
	[]
}

private func outdatedAppIDs(
	_: [String],
	_ installedApps: [InstalledApp],
	_ lookupAppFromAppID: @Sendable @escaping (AppID) async throws -> CatalogApp,
) async -> [String] {
	await withTaskGroup { group in
		for installedApp in installedApps {
			group.addTask {
				do {
					return installedApp.isOutdated(comparedTo: try await lookupAppFromAppID(.adamID(installedApp.adamID)))
					? "\(installedApp.adamID):\(installedApp.name.replacing(":", with: "\\:"))" // swiftformat:disable:this indent
					: nil
				} catch {
					return nil
				}
			}
		}

		return await group.compactMap(\.self).reduce(into: []) { $0.append($1) }
	}
}
*/
// swiftformat:enable indent
