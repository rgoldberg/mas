//
// Process.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import Foundation
private import ObjectiveC

func run(
	_ executablePath: String,
	_ args: String...,
	errorMessage: @autoclosure () -> String,
	runProcess run: (Process) throws -> Void = { try $0.run() },
) async throws -> (standardOutputString: String, standardErrorString: String) {
	let process = Process()
	process.executableURL = .init(nonFolderPath: executablePath)
	process.arguments = args

	let standardOutputPipe = Pipe()
	let standardErrorPipe = Pipe()

	process.standardOutput = standardOutputPipe
	process.standardError = standardErrorPipe

	let standardOutputTask = Task(priority: .background) {
		try standardOutputPipe.readToEnd()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
	}
	let standardErrorTask = Task(priority: .background) {
		try standardErrorPipe.readToEnd()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
	}

	do {
		try run(process)
	} catch {
		throw MASError.error(errorMessage(), cause: error)
	}
	process.waitUntilExit()

	let standardOutputString = try await standardOutputTask.value
	let standardErrorString = try await standardErrorTask.value

	guard process.terminationStatus == 0 else {
		throw MASError.error(
			"""
			\(errorMessage())
			Exit status: \(process.terminationStatus)\
			\(standardOutputString.ifNotEmptyPrepend("\n\nStandard output:\n"))\
			\(standardErrorString.ifNotEmptyPrepend("\n\nStandard error:\n"))
			""",
		)
	}

	return (standardOutputString, standardErrorString)
}

private extension String {
	func ifNotEmptyPrepend(_ prefix: String) -> Self {
		isEmpty ? self : prefix + self
	}
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
