//
// Lazy.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Synchronization

final class Lazy<Value>: Sendable {
	private enum State {
		case uninitialized(@Sendable () -> Value)
		case initialized(Value)
	}

	private let stateMutex: Mutex<State>

	var value: Value {
		stateMutex.withLock { state in
			switch state {
			case let .uninitialized(initialize):
				let value = initialize()
				state = .initialized(value)
				return value
			case let .initialized(value):
				return value
			}
		}
	}

	init(_ initialize: @escaping @Sendable () -> Value) {
		stateMutex = .init(.uninitialized(initialize))
	}

	convenience init(_ initialize: @autoclosure @escaping @Sendable () -> Value) {
		self.init(initialize)
	}

	deinit {}
}
