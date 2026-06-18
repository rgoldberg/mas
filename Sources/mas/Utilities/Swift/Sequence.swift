//
// Sequence.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import Foundation

extension Sequence {
	func forEach<E: Error>(attemptTo perform: String, _ body: (Element) async throws(E) -> Void) async {
		await forEach(body) { MAS.printer.error($1 is MASError ? .init() : ["Failed to", perform, $0], error: $1) }
	}

	private func forEach<E: Error>(
		_ body: (Element) async throws(E) -> Void,
		handlingErrors errorHandler: (Element, E) async -> Void,
	) async {
		for element in self {
			do {
				try await body(element)
			} catch {
				await errorHandler(element, error)
			}
		}
	}
}

extension Sequence {
	/// Merge two sequences by greedily selecting the element with the higher
	/// score.
	///
	/// Preserves the relative order of elements within their original sequences.
	func priorityMerge(_ secondary: some Sequence<Element>, score: (Element) -> Double) -> [Element] {
		var merged = [Element]()

		if let primary = self as? any Collection, let secondary = secondary as? any Collection {
			merged.reserveCapacity(primary.count + secondary.count)
		}

		var primaryIterator = makeIterator()
		var secondaryIterator = secondary.makeIterator()

		var primaryItemAndScore = primaryIterator.next().map { (item: $0, score: score($0)) }
		var secondaryItemAndScore = secondaryIterator.next().map { (item: $0, score: score($0)) }

		while let primaryInfo = primaryItemAndScore, let secondaryInfo = secondaryItemAndScore {
			if primaryInfo.score >= secondaryInfo.score {
				merged.append(primaryInfo.item)
				primaryItemAndScore = primaryIterator.next().map { ($0, score($0)) }
			} else {
				merged.append(secondaryInfo.item)
				secondaryItemAndScore = secondaryIterator.next().map { ($0, score($0)) }
			}
		}

		if let primaryItemAndScore {
			merged.append(primaryItemAndScore.item)
			merged.append(contentsOf: IteratorSequence(primaryIterator))
		} else if let secondaryItemAndScore {
			merged.append(secondaryItemAndScore.item)
			merged.append(contentsOf: IteratorSequence(secondaryIterator))
		}

		return merged
	}
}

extension Sequence {
	/// Transforms elements concurrently respecting backpressure while strictly preserving the original input order in the
	/// output stream.
	///
	/// - Parameters:
	///   - maxConcurrentTaskCount: The maximum number of concurrent tasks allowed to execute at any given time. Defaults
	///     to system configuration.
	///   - transform: The asynchronous, throwing closure to apply to each element.
	/// - Returns: An `OrderedConcurrentMapSequence` emitting the transformed elements in their original sequence order.
	func orderedConcurrentMap<T>( // swiftlint:disable:this unused_declaration
		maxConcurrentTaskCount: Int = ProcessInfo.processInfo.activeProcessorCount,
		_ transform: @escaping @Sendable (Element) async throws -> T,
	) -> OrderedConcurrentMapSequence<Self, T> { // periphery:ignore
		.init(base: self, maxConcurrentTaskCount: maxConcurrentTaskCount, transform: transform)
	}
}
