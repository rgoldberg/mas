//
// SlowLazy.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Dispatch
private import Synchronization

final class SlowLazy<Value: Sendable>: Sendable { // periphery:ignore
	private enum State { // swiftlint:disable:previous unused_declaration
		case uninitialized(@Sendable () -> Value)
		case initializing(DispatchGroup)
		case initialized(Value)
	}

	private enum Action {
		case initialize(() -> Value, DispatchGroup)
		case `await`(DispatchGroup)
		case `return`(Value)
	}

	private let stateMutex: Mutex<State>

	var value: Value { // swiftlint:disable:this unused_declaration
		let action = stateMutex.withLock { state in
			switch state {
			case let .uninitialized(initialize):
				let dispatchGroup = DispatchGroup()
				dispatchGroup.enter()
				state = .initializing(dispatchGroup)
				return Action.initialize(initialize, dispatchGroup)
			case let .initializing(dispatchGroup):
				return .await(dispatchGroup)
			case let .initialized(value):
				return .return(value)
			}
		}

		switch action {
		case let .initialize(initialize, dispatchGroup):
			let value = initialize()
			stateMutex.withLock { $0 = .initialized(value) }
			dispatchGroup.leave()
			return value
		case let .await(dispatchGroup):
			dispatchGroup.wait()
			return stateMutex.withLock { state in
				guard case let .initialized(value) = state else {
					fatalError("SlowLazy value missing")
				}

				return value
			}
		case let .return(value):
			return value
		}
	}

	init(_ initialize: @escaping @Sendable () -> Value) {
		stateMutex = .init(.uninitialized(initialize))
	}

	convenience init(_ initialize: @autoclosure @escaping @Sendable () -> Value) {
		self.init(initialize)
	}

	deinit {
		// Empty
	}
}
