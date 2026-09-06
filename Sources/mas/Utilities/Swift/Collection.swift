//
// Collection.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

extension Collection where Element: Sendable {
	func concurrentCompactMap<T: Sendable>(
		maxConcurrentTaskCount: Int = defaultMaxConcurrentTaskCount,
		_ transform: @escaping @Sendable (Element) async -> T?,
	) async -> [T] {
		await concurrentCompactTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform)
	}

	func concurrentCompactMap<T: Sendable>(
		attemptingTo perform: String,
		maxConcurrentTaskCount: Int = defaultMaxConcurrentTaskCount,
		_ transform: @escaping @Sendable (Element) async throws -> T?,
	) async -> [T] {
		await concurrentCompactMap(maxConcurrentTaskCount: maxConcurrentTaskCount) { element in
			do {
				return try await transform(element)
			} catch {
				MAS.printer.error(error is MASError ? .init() : ["Failed to", perform, element], error: error)
				return nil
			}
		}
	}

	private func concurrentCompactTransform<T: Sendable>(
		maxConcurrentTaskCount: Int,
		_ transform: @escaping @Sendable (Element) async throws -> T?,
	) async rethrows -> [T] {
		try await withThrowingTaskGroup(of: (index: Int, result: T?).self) { taskGroup in
			var iterator = enumerated().makeIterator()
			func addNextTask() {
				if let next = iterator.next() {
					taskGroup.addTask { (next.offset, try await transform(next.element)) }
				}
			}

			let count = count
			for _ in 0..<Swift::min(count, maxConcurrentTaskCount) {
				addNextTask()
			}

			return try await taskGroup.reduce(into: Array(repeating: T?.none, count: count)) { results, indexedResult in
				results[indexedResult.index] = indexedResult.result
				addNextTask()
			}
			.compactMap(\.self)
		}
	}
}

private let defaultMaxConcurrentTaskCount = 16
