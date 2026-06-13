//
// Consequences.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

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

	func consequences<Value>(value: Value? = nil, error: (any Error)? = nil) -> Consequences<Value> {
		.init(value, error, outRedirector.stop(), errRedirector.stop())
	}
}

private struct StreamRedirector { // swiftlint:disable:this one_declaration_per_file
	private let originalFD: Int32
	private let duplicateFD: Int32
	private let encoding: String.Encoding
	private let pipe = Pipe()

	init(from fileDescriptor: Int32, encoding: String.Encoding) {
		originalFD = fileDescriptor
		duplicateFD = dup(originalFD)
		dup2(pipe.fileHandleForWriting.fileDescriptor, originalFD)
		self.encoding = encoding
	}

	func stop() -> String {
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
		close(duplicateFD) // swiftlint:disable:next force_try
		return try! pipe.fileHandleForReading.readToEnd().flatMap { .init(data: $0, encoding: encoding) } ?? ""
	}
}

func consequencesOf(encoding: String.Encoding = .utf8, _ body: @autoclosure () throws -> Void) -> Consequences<Void> {
	let capture = StandardStreamCapture(encoding: encoding)
	do {
		try body()
		return capture.consequences()
	} catch {
		return capture.consequences(error: error)
	}
}

func consequencesOf(encoding: String.Encoding = .utf8, _ body: @autoclosure () async throws -> Void)
async -> Consequences<Void> { // swiftformat:disable:this indent
	let capture = StandardStreamCapture(encoding: encoding)
	do {
		try await body()
		return capture.consequences()
	} catch {
		return capture.consequences(error: error)
	}
}

func consequencesOf<Value>(encoding: String.Encoding = .utf8, _ body: @autoclosure () throws -> Value?)
-> Consequences<Value> { // swiftformat:disable:this indent
	let capture = StandardStreamCapture(encoding: encoding)
	do {
		return capture.consequences(value: try body())
	} catch {
		return capture.consequences(error: error)
	}
}

func consequencesOf<Value>(encoding: String.Encoding = .utf8, _ body: @autoclosure () async throws -> Value?)
async -> Consequences<Value> { // swiftformat:disable:this indent
	let capture = StandardStreamCapture(encoding: encoding)
	do {
		return capture.consequences(value: try await body())
	} catch {
		return capture.consequences(error: error)
	}
}
