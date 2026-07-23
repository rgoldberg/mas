//
// Required.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@propertyWrapper
struct Required<Value> {
	let wrappedValue: Value

	init(
		_ value: @autoclosure () -> Value?,
		message: String = "Required value cannot be nil",
		file: StaticString = #fileID,
		line: UInt = #line,
	) {
		wrappedValue = value() ?? { preconditionFailure(message, file: file, line: line) }()
	}
}

extension Required: Sendable where Value: Sendable {}
