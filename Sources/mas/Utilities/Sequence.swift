//
// Sequence.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

extension Sequence {
	func forEach<E: Error>(attemptTo effect: String, _ body: (Element) async throws(E) -> Void) async {
		await forEach(body) { MAS.printer.error($1 is MASError ? [] : ["Failed to", effect, $0], error: $1) }
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
	/// Merge two sequences by greedily selecting the element with the higher score.
	/// Preserves the relative order of elements within their original sequences.
	func priorityMerge(_ secondary: some Sequence<Element>, score: (Element) -> Double) -> [Element] {
		var merged = [Element]()

		if let primary = self as? any Collection, let secondary = secondary as? any Collection {
			merged.reserveCapacity(primary.count + secondary.count)
		}

		var primaryIterator = makeIterator()
		var secondaryIterator = secondary.makeIterator()

		var primaryItemAndScore: (item: Element, score: Double)? = primaryIterator.next().map { ($0, score($0)) }
		var secondaryItemAndScore: (item: Element, score: Double)? = secondaryIterator.next().map { ($0, score($0)) }

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
			while let item = primaryIterator.next() {
				merged.append(item)
			}
		} else if let secondaryItemAndScore {
			merged.append(secondaryItemAndScore.item)
			while let item = secondaryIterator.next() {
				merged.append(item)
			}
		}

		return merged
	}
}
