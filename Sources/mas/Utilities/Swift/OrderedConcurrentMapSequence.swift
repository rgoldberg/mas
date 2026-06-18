//
// OrderedConcurrentMapSequence.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import AsyncAlgorithms
private import Foundation
private import os

/// A concurrent map sequence that preserves input order & respects downstream
/// backpressure.
struct OrderedConcurrentMapSequence<Base: Sequence & Sendable, Element: Sendable>: AsyncSequence
where Base.Element: Sendable { // swiftformat:disable:this indent
	private let base: Base
	private let maxConcurrentTaskCount: Int
	private let transform: @Sendable (Base.Element) async throws -> Element
	private let taskByIndexGate = OSAllocatedUnfairLock(initialState: [Int: Task<Result<Element, any Error>, Never>]())

	init(
		base: Base,
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		transform: @escaping @Sendable (Base.Element) async throws -> Element,
	) {
		self.base = base
		self.maxConcurrentTaskCount = maxConcurrentTaskCount
		self.transform = transform
	}

	func makeAsyncIterator() -> AsyncThrowingChannel<Element, any Error>.Iterator {
		let channel = AsyncThrowingChannel<Element, any Error>()
		Task {
			await withTaskGroup(of: (Int, Result<Element, any Error>).self) { taskGroup in
				var iterator = base.makeIterator()
				var inputIndex = 0
				var nextYieldIndex = 0
				var earliestFailureIndex = Int?.none
				var activeTaskCount = 0
				var resultByIndex = [Int: Result<Element, any Error>]()

				while true {
					while earliestFailureIndex == nil, (inputIndex - nextYieldIndex) < maxConcurrentTaskCount {
						guard let element = iterator.next() else {
							break
						}

						// Wrap transform in an inner Task to manage individual cancellation
						let task = Task {
							do {
								return Result<Element, any Error>.success(try await transform(element))
							} catch {
								return .failure(error)
							}
						}
						taskByIndexGate.withLock { [inputIndex] in $0[inputIndex] = task }
						taskGroup.addTask { [inputIndex] in
							await withTaskCancellationHandler {
								let result = await task.value
								taskByIndexGate.withLock { _ = $0.removeValue(forKey: inputIndex) }
								return (inputIndex, result)
							} onCancel: {
								task.cancel()
							}
						}
						activeTaskCount += 1
						inputIndex += 1
					}

					if activeTaskCount == 0, resultByIndex.isEmpty {
						break
					}

					// Collect out-of-order results
					if let (index, result) = await taskGroup.next() {
						activeTaskCount -= 1
						if case .failure = result, earliestFailureIndex.map({ index < $0 }) != false {
							earliestFailureIndex = index
							taskByIndexGate.withLock { taskByIndex in
								for (currentIndex, task) in taskByIndex where currentIndex > index {
									task.cancel()
								}
							}
						}
						guard index == nextYieldIndex else {
							resultByIndex[index] = result
							continue
						}

						// Flush sequential results down the channel in strict order
						var result = Result<Element, any Error>?.some(result)
						while let currentResult = result {
							switch currentResult {
							case let .success(value):
								await channel.send(value)
								nextYieldIndex += 1
								result = resultByIndex.removeValue(forKey: nextYieldIndex)
							case let .failure(error):
								channel.fail(error)
								return
							}
						}
					}
				}
				channel.finish()
			}
		}

		return channel.makeAsyncIterator()
	}
}
