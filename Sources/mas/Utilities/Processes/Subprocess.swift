//
// Subprocess.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import ArgumentParser
private import Foundation
internal import Subprocess
internal import System

/// Runs sudo, re-invoking the current mas command line as root & forwarding
/// `MAS_*` env vars via its stdin. Standard output & standard error are
/// inherited directly from this process, since the nested mas process reports
/// its own errors; only the exit status is checked here.
func nestedSudoMAS(platformOptions: PlatformOptions = .init(), input: CustomWriteInput = .inputWriter) async throws {
	guard let executablePath = Bundle.main.executablePath else {
		throw error("Failed to determine executable path")
	}
	let execResult = try await run(
		.path("/usr/bin/sudo"),
		arguments: .init(
			(
				(try? FileDescriptor.open(.init("/dev/tty"), .readWrite)).map { ttyFD in
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
			try await mas::writeFully(string, to: "sudo's stdin", using: stdin.write)
		}

		for (name, value) in ProcessInfo.processInfo.environment
		where name.hasPrefix("MAS_") && name != "MAS_NO_AUTO_INDEX" { // swiftformat:disable:this indent
			if name.contains("=") {
				throw error("Setting name contains illegal '=': \(name)")
			}
			if name.contains("\0") {
				throw error("Setting name contains illegal NUL: \(name)")
			}
			if value.contains("\0") {
				throw error("Setting value contains illegal NUL: \(value)")
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

/// Writes all of `string`'s UTF-8 bytes to `destination` via `write`, which
/// returns how many of the bytes it was given it wrote, so it's retried with
/// the remaining bytes after a partial write.
func writeFully(_ string: String, to destination: String, using write: ([UInt8]) async throws -> Int) async throws {
	var bytes = Array(string.utf8)[...]
	while !bytes.isEmpty {
		let writtenByteCount = try await write(.init(bytes))
		guard writtenByteCount > 0 else {
			throw error("Failed to write last \(bytes.count) bytes of \(string.quoted) to \(destination)")
		}
		bytes.removeFirst(writtenByteCount)
	}
}

func run<Encoding: Unicode.Encoding>(
	_ executableFilePath: FilePath,
	arguments: Arguments = .init(),
	platformOptions: PlatformOptions = .init(),
	input: some InputProtocol = .none,
	encoding: Encoding.Type = UTF8.self,
	maxCaptureByteCount: Int = .max,
	errorMessage: @autoclosure () -> String,
) async throws -> (outString: String, errString: String) {
	let execResult = try await run(
		.path(executableFilePath),
		arguments: arguments,
		platformOptions: platformOptions,
		input: input,
		output: .string(limit: maxCaptureByteCount, encoding: encoding),
		error: .string(limit: maxCaptureByteCount, encoding: encoding),
	)
	guard execResult.terminationStatus.isSuccess else {
		throw error(
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
