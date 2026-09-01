//
// Subprocess.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import Foundation
internal import Subprocess
internal import System

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
