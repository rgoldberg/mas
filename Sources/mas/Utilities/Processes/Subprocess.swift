//
// Subprocess.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import ArgumentParser
internal import Darwin
private import Foundation
internal import Subprocess
internal import System

/// Runs sudo, re-invoking the current mas command line as root & forwarding
/// `MAS_*` env vars via its stdin. Standard output & standard error are
/// inherited directly from this process, since the nested mas process reports
/// its own errors; only the exit status is checked here.
func nestedSudoMAS(platformOptions: PlatformOptions = .init(), input: CustomWriteInput = .inputWriter) async throws {
	guard let executablePath = Bundle.main.executablePath else {
		throw MASError.error("Failed to determine executable path")
	}
	let execResult = try await run(
		.path("/usr/bin/sudo"),
		arguments: .init(
			(
				(try? unsafe FileDescriptor.open("/dev/tty", .readWrite)).map { ttyFD in
					try? ttyFD.close()
					return ["--"]
				}
					?? ["-n", "--"]
			)
				+ [executablePath]
				+ CommandLine.arguments.dropFirst(),
		),
		platformOptions: platformOptions,
		input: input,
		output: .fileDescriptor(.standardOutput, closeAfterSpawningProcess: false),
		error: .fileDescriptor(.standardError, closeAfterSpawningProcess: false),
	) { execution in
		let stdin = execution.standardInputWriter
		func writeFully(_ string: String) async throws {
			var substring = Substring(string)
			while !substring.isEmpty {
				let writtenByteCount = try await stdin.write(substring)
				guard writtenByteCount > 0 else {
					throw MASError.error("Failed to write \(substring.quoted) from \(string.quoted) to sudo's stdin")
				}
				substring.removeFirst(writtenByteCount)
			}
		}

		for (name, value) in ProcessInfo.processInfo.environment
		where name.hasPrefix("MAS_") && name != "MAS_NO_AUTO_INDEX" { // swiftformat:disable:this indent
			if name.contains("=") {
				throw MASError.error("Setting name contains illegal '=': \(name)")
			}
			if name.contains("\0") {
				throw MASError.error("Setting name contains illegal NUL: \(name)")
			}
			if value.contains("\0") {
				throw MASError.error("Setting value contains illegal NUL: \(value)")
			}
			try await writeFully(name)
			try await writeFully("=")
			try await writeFully(value)
			try await writeFully("\0")
		}
		try await writeFully("MAS_NO_AUTO_INDEX=1\0\0")
	}
	guard execResult.terminationStatus.isSuccess else {
		throw ExitCode.failure
	}
}

func run<Encoding: Unicode.Encoding>(
	_ executableFilePath: FilePath,
	arguments: Arguments,
	platformOptions: PlatformOptions = .init(),
	input: some InputProtocol = .none,
	encoding: Encoding.Type = UTF8.self,
	errorMessage: @autoclosure () -> String,
) async throws -> (outString: String, errString: String) {
	let execResult = try await run(
		.path(executableFilePath),
		arguments: arguments,
		platformOptions: platformOptions,
		input: input,
		output: .string(limit: .max, encoding: encoding),
		error: .string(limit: .max, encoding: encoding),
	)
	guard execResult.terminationStatus.isSuccess else {
		throw MASError.error(
			"""
			\(errorMessage())

			Exit status: \(execResult.terminationStatus)\
			\(execResult.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines).ifNotEmptyPrepend("\n\nstdout:\n"))\
			\(execResult.standardError.trimmingCharacters(in: .whitespacesAndNewlines).ifNotEmptyPrepend("\n\nstderr:\n"))
			""",
		)
	}
	return (execResult.standardOutput, execResult.standardError)
}

let runAsRootAndWheel = {
	var platformOptions = PlatformOptions()
	platformOptions.userID = 0
	platformOptions.groupID = 0
	return platformOptions
}()
