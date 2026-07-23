//
// Consequences.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

private import Atomics
internal import Foundation
private import ObjectiveC

struct Consequences<Value> {
	let value: Value?
	let error: (any Error)?
	let stdout: String
	let stderr: String

	init(_ error: (any Error)? = nil, _ stdout: String = "", _ stderr: String = "") where Value == Void {
		self.init(nil, error, stdout, stderr)
	}

	init(_ value: Value?, _ error: (any Error)? = nil, _ stdout: String = "", _ stderr: String = "") {
		self.value = value
		self.error = error
		self.stdout = stdout
		self.stderr = stderr
	}
}

extension Consequences: Equatable where Value: Equatable { // swiftlint:disable:this file_types_order
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.value == rhs.value
			&& lhs.stdout == rhs.stdout
			&& lhs.stderr == rhs.stderr
			&& lhs.error as NSError? == rhs.error as NSError?
	}
}

extension Consequences where Value == Void { // swiftlint:disable:this file_types_order
	static func == (lhs: Self, rhs: Self) -> Bool {
		(lhs.value != nil) == (rhs.value != nil)
			&& lhs.stdout == rhs.stdout
			&& lhs.stderr == rhs.stderr
			&& lhs.error as NSError? == rhs.error as NSError?
	}
}

private struct StandardStreamCapture { // swiftlint:disable:this one_declaration_per_file
	private let outRedirector: StreamRedirector
	private let errRedirector: StreamRedirector

	init(encoding: String.Encoding) {
		outRedirector = .init(from: FileHandle.standardOutput.fileDescriptor, encoding: encoding)
		errRedirector = .init(from: FileHandle.standardError.fileDescriptor, encoding: encoding)
	}

	func consequences<Value>(value: Value? = nil, error: (any Error)? = nil) async throws -> Consequences<Value> {
		outRedirector.stop()
		errRedirector.stop()
		async let outString = outRedirector.string
		async let errString = errRedirector.string
		return .init(value, error, try await outString, try await errString)
	}
}

private struct StreamRedirector { // swiftlint:disable:this one_declaration_per_file
	private let originalFD: Int32
	private let duplicateFD: Int32
	private let encoding: String.Encoding
	private let pipe = Pipe()
	private let task: Task<Data, any Error>
	private let alreadyStopped = ManagedAtomic(false)

	var string: String {
		get async throws {
			.init(data: try await task.value, encoding: encoding) ?? ""
		}
	}

	init(from fileDescriptor: Int32, encoding: String.Encoding) {
		originalFD = fileDescriptor
		duplicateFD = dup(originalFD)
		dup2(pipe.fileHandleForWriting.fileDescriptor, originalFD)
		self.encoding = encoding
		let readHandle = pipe.fileHandleForReading
		task = .init { try await readHandle.bytes.reduce(into: .init()) { $0.append($1) } }
	}

	func stop() {
		guard !alreadyStopped.exchange(true, ordering: .acquiringAndReleasing) else {
			return
		}

		switch originalFD {
		case FileHandle.standardOutput.fileDescriptor:
			unsafe fflush(unsafe stdout)
		case FileHandle.standardError.fileDescriptor:
			unsafe fflush(unsafe stderr)
		default:
			fflush(nil)
		}
		dup2(duplicateFD, originalFD)
		try? pipe.fileHandleForWriting.close()
		close(duplicateFD)
	}
}

func consequencesOf(encoding: String.Encoding = .utf8, _ body: @autoclosure () async throws -> Void)
async throws -> Consequences<Void> { // swiftformat:disable:this indent
	let capture = StandardStreamCapture(encoding: encoding)
	do {
		try await body()
	} catch {
		return try await capture.consequences(error: error)
	}
	return try await capture.consequences()
}

func consequencesOf<Value>(encoding: String.Encoding = .utf8, _ body: @autoclosure () async throws -> Value?)
async throws -> Consequences<Value> { // swiftformat:disable:this indent
	let capture = StandardStreamCapture(encoding: encoding)
	let value: Value?
	do {
		value = try await body()
	} catch {
		return try await capture.consequences(error: error)
	}
	return try await capture.consequences(value: value)
}
