//
// MAS.swift
// mas
//
// Copyright © 2021 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Darwin
internal import Foundation

@main
struct MAS: AsyncParsableCommand, RealDropping {
	static let configuration = CommandConfiguration(
		abstract: "Mac App Store command-line interface",
		version: Self.version,
		subcommands: [
			Config.self,
			Get.self,
			Home.self,
			Install.self,
			List.self,
			Lookup.self,
			Lucky.self,
			Open.self,
			Outdated.self,
			Reset.self,
			Search.self,
			Seller.self,
			SignOut.self,
			Uninstall.self,
			Update.self,
			Version.self,
		],
	)

	static let printer = Printer()

	static var _errorPrefix: String { // swiftlint:disable:this identifier_name
		"\(errorPrefix.formatted(with: errorFormat, for: FileHandle.standardError)) "
	}

	private static func main() async { // swiftlint:disable:this unused_declaration
		await main(nil)
	}

	private static func main(_ arguments: [String]?) async { // swiftlint:disable:this discouraged_optional_collection
		do {
			let envVars = try envVars(from: .standardInput)
			if let envVars, let (name, value) = envVars.first(where: { unsafe setenv($0, $1, 1) != 0 }) {
				throw MASError.error("Failed to set environment variable \(name) to \(value)")
			}
			let command = try await asyncParseAsRoot(arguments)
			if let command = cast(command, as: (any PrivilegeModifying).self) {
				try command.modifyPrivileges()
			} else {
				let commandTypeName = String(reflecting: type(of: command))
				if commandTypeName.prefix(while: { $0 != "." }) != "ArgumentParser" {
					throw MASError.error("\(commandTypeName) does not declare privilege-modifying behavior")
				}
			}
			if let command = cast(command, as: (any AsyncParsableCommand & Sendable).self) {
				try await main(command)
			} else {
				try main(command)
			}
			let errorCount = printer.errorCount
			if errorCount > 0 {
				throw ExitCode(errorCount >= .init(Int32.max) ? .max : .init(errorCount))
			}
		} catch {
			exit(withError: error)
		}
	}
}

extension MAS {
	static func main(_ command: some ParsableCommand) throws {
		try main(command) { command in
			var command = command
			try command.run()
		}
	}

	static func main(_ command: some AsyncParsableCommand & Sendable) async throws {
		try await main(command) { command in
			var command = command
			try await command.run()
		}
	}

	static func main<Command: ParsableCommand>(_ command: Command, _ body: (Command) throws -> Void) throws {
		do {
			try body(command)
		} catch {
			printer.error(error: try error.failure)
		}
	}

	static func main<Command: AsyncParsableCommand>(_ command: Command, _ body: (Command) async throws -> Void)
	async throws {
		do {
			try await body(command)
		} catch {
			printer.error(error: try error.failure)
		}
	}
}

private extension Error {
	var failure: Self {
		get throws {
			guard !MAS.exitCode(for: self).isSuccess else {
				throw self
			}
			return self
		}
	}
}

extension ParsableCommand {
	static func requiresRootPrivilegesMessage(to action: String = .init(describing: Self.self).lowercased()) -> String {
		"Requires root privileges to \(action) apps"
	}
}

private func cast<T>(_ instance: Any, as _: T.Type) -> T? {
	instance as? T
}

// swiftlint:disable:next discouraged_optional_collection
private func envVars(from fileHandle: FileHandle) throws -> [(name: String, value: String)]? {
	func nextByte() -> UInt8? {
		try? fileHandle.read(upToCount: 1)?.first
	}

	guard fcntl(fileHandle.fileDescriptor, F_GETFL) != -1, !fileHandle.isTerminal else {
		return nil
	}
	guard var byte = nextByte() else {
		return nil
	}
	var envVars = [(name: String, value: String)]()
	var data = Data()
	while true {
		if byte != 0 {
			data.append(byte)
		} else {
			if data.isEmpty {
				return envVars
			}
			guard let token = String(data: data, encoding: .utf8) else {
				throw MASError.error("Failed to parse input")
			}
			let components = token.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
			guard components.count == 2, components[0].hasPrefix("MAS_") else {
				throw MASError.error("Failed to find a 'MAS_'-prefixed assignment in \(token)")
			}
			envVars.append((.init(components[0]), .init(components[1])))
			data.removeAll(keepingCapacity: true)
		}
		guard let nextByte = nextByte() else {
			break
		}
		byte = nextByte
	}
	guard data.isEmpty else {
		throw MASError.error("Unterminated setting in stdin\(String(data: data, encoding: .utf8).map { ": \($0)" } ?? "")")
	}
	return envVars
}

let applicationsFolderURLs = UserDefaults(suiteName: "com.apple.appstored")?
	.dictionary(forKey: "PreferredVolume")?["name"]
	.map { [applicationsFolderURL, .init(folderPath: "/Volumes/\($0)\(applicationsFolderPath)")] }
	?? [applicationsFolderURL]

private let applicationsFolderPath = "/Applications"
private let applicationsFolderURL = URL(folderPath: applicationsFolderPath)
