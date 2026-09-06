//
// AsyncLazy.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import os

final class AsyncLazy<Value: Sendable>: Sendable { // periphery:ignore
	private enum State { // swiftlint:disable:previous unused_declaration
		case uninitialized(@Sendable () async -> Value)
		case initializing(Task<Value, Never>)
		case initialized(Value)
	}

	private enum Action {
		case `await`(Task<Value, Never>)
		case `return`(Value)
	}

	private let stateGate: OSAllocatedUnfairLock<State>

	var value: Value { // swiftlint:disable:this unused_declaration
		get async {
			let action = stateGate.withLock { state in
				switch state {
				case let .uninitialized(initialize):
					let task = Task { [weak self] in
						let value = await initialize()
						self?.stateGate.withLock { $0 = .initialized(value) }
						return value
					}
					state = .initializing(task)
					return Action.await(task)
				case let .initializing(task):
					return .await(task)
				case let .initialized(value):
					return .return(value)
				}
			}

			return switch action {
			case let .await(task):
				await task.value
			case let .return(value):
				value
			}
		}
	}

	init(_ initialize: @escaping @Sendable () async -> Value) {
		stateGate = .init(initialState: .uninitialized(initialize))
	}

	/*
	convenience init(_ initialize: @autoclosure @escaping @Sendable () async -> Value) async {
		self.init(initialize)
	}
	*/

	deinit {
		// Empty
	}
}
