//
// Subprocess.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import Foundation
internal import Subprocess

private extension String {
	func ifNotEmptyPrepend(_ prefix: String) -> Self {
		isEmpty ? self : prefix + self
	}
}

func run<Encoding: Unicode.Encoding>(
	_ executable: Executable,
	_ args: String...,
	platformOptions: PlatformOptions = .init(),
	encoding: Encoding.Type = UTF8.self,
	maxCaptureByteCount: Int = 1024 * 1024,
	errorMessage: @autoclosure () -> String,
) async throws -> (outString: String, errString: String) {
	let executionResult = try await run(
		executable,
		arguments: .init(args),
		platformOptions: platformOptions,
		output: .string(limit: maxCaptureByteCount, encoding: encoding),
		error: .string(limit: maxCaptureByteCount, encoding: encoding),
	)
	let outString = executionResult.standardOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
	let errString = executionResult.standardError?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
	guard executionResult.terminationStatus.isSuccess else {
		throw MASError.error(
			"""
			\(errorMessage())
			Exit status: \(executionResult.terminationStatus)\
			\(outString.ifNotEmptyPrepend("\n\nStandard output:\n"))\
			\(errString.ifNotEmptyPrepend("\n\nStandard error:\n"))
			""",
		)
	}

	return (outString, errString)
}

func runAsRoot<T>(_ body: () throws -> T) throws -> T {
	try run(asEffectiveUID: 0, andEffectiveGID: 0, body)
}

func run<T>(asEffectiveUID uid: uid_t, andEffectiveGID gid: gid_t, _ body: () throws -> T) throws -> T {
	let originalEffectiveUID = geteuid()
	let originalEffectiveGID = getegid()
	guard originalEffectiveUID == 0 else {
		try set(effectiveUID: uid)
		defer { reset(effectiveUID: originalEffectiveUID) }
		try set(effectiveGID: gid)
		defer { reset(effectiveGID: originalEffectiveGID) }
		return try body()
	}

	try set(effectiveGID: gid)
	defer { reset(effectiveGID: originalEffectiveGID) }
	try set(effectiveUID: uid)
	defer { reset(effectiveUID: originalEffectiveUID) }
	return try body()
}

private func reset(effectiveUID uid: uid_t) {
	do {
		try set(effectiveUID: uid)
	} catch {
		MAS.printer.warning(error: error)
	}
}

private func reset(effectiveGID gid: gid_t) {
	do {
		try set(effectiveGID: gid)
	} catch {
		MAS.printer.warning(error: error)
	}
}

let runAsRootAndWheel = {
	var platformOptions = PlatformOptions()
	platformOptions.userID = 0
	platformOptions.groupID = 0
	return platformOptions
}()
