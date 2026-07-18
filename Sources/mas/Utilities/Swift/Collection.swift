//
// Collection.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import Foundation

extension Collection where Element: Sendable {
	func concurrentMap<T: Sendable>(
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async -> T,
	) async -> [T] {
		await concurrentTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform)
	}

	func concurrentMap<T: Sendable>( // swiftlint:disable:this unused_declaration
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async throws -> T,
	) async rethrows -> [T] { // periphery:ignore
		try await concurrentTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform)
	}

	func concurrentCompactMap<T: Sendable>(
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async -> T?,
	) async -> [T] {
		await concurrentCompactTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform)
	}

	func concurrentCompactMap<T: Sendable>(
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async throws -> T?,
	) async rethrows -> [T] {
		try await concurrentCompactTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform)
	}

	func concurrentFlatMap<SegmentOfResult: Sequence & Sendable>( // swiftlint:disable:this unused_declaration
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async -> SegmentOfResult,
	) async -> [SegmentOfResult.Element] where SegmentOfResult.Element: Sendable { // periphery:ignore
		await concurrentTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform).flatMap(\.self)
	}

	func concurrentFlatMap<SegmentOfResult: Sequence & Sendable>(
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async throws -> SegmentOfResult,
	) async rethrows -> [SegmentOfResult.Element] where SegmentOfResult.Element: Sendable {
		try await concurrentTransform(maxConcurrentTaskCount: maxConcurrentTaskCount, transform).flatMap(\.self)
	}

	func concurrentCompactMap<T: Sendable>(
		attemptingTo perform: String,
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
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

	private func concurrentTransform<T: Sendable>(
		maxConcurrentTaskCount: Int,
		_ transform: @escaping @Sendable (Element) async throws -> T,
	) async rethrows -> [T] {
		try await withThrowingTaskGroup(of: (index: Int, result: T).self) { taskGroup in
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
				results[indexedResult.index] = .some(indexedResult.result)
				addNextTask()
			}
			.map { $0! } // swiftlint:disable:this force_unwrapping
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
