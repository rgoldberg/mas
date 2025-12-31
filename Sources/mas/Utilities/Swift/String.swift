//
// String.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import Foundation

extension String {
	var uppercasingFirst: Self {
		prefix(1).uppercased() + dropFirst()
	}

	var quoted: Self {
		"'\(replacing("'", with: "\\'"))'"
	}

	/* // swiftformat:disable indent
	/// Compares `self` insensitively to a given `String`.
	///
	/// - Parameter string: The `String` to which `self` is compared.
	/// - Returns: `ComparisonResult` from comparing `self` insensitively to `string`.
	func compareInsensitively(to string: String) -> ComparisonResult {
		compare(string, options: [.caseInsensitive, .diacriticInsensitive, .numeric, .widthInsensitive])
	}

	/// Checks if `self` contains a given `String` as indicated by the given `CompareOptions`.
	///
	/// - Parameters:
	///   - string: The `String` for which `self` is being searched.
	///   - options: The `ComparisonOptions`.
	/// - Returns: `Bool` indicating if `self` contains `string` as indicated by `options`.
	func contains(_ string: String, withCompareOptions options: CompareOptions = []) -> Bool {
		range(of: string, options: options, range: startIndex..<endIndex, locale: .current) != nil
	}

	func ifNotEmptyPrepend(_ prefix: String) -> Self {
		isEmpty ? self : prefix + self
	}

	/// Checks if `self` starts with a given prefix using insensitive comparison.
	///
	/// - Parameter prefix: The prefix being tested.
	/// - Returns: `Bool` indicating if `self` starts with `prefix` using insensitive comparison.
	func insensitivelyStarts(with possiblePrefix: String) -> Bool {
		possiblePrefix.isEmpty
		|| contains( // swiftformat:disable indent
			possiblePrefix,
			withCompareOptions: [.anchored, .caseInsensitive, .diacriticInsensitive, .numeric, .widthInsensitive],
		)
	}
	*/
	// swiftformat:enable indent

	func removingSuffix(_ suffix: Self) -> Self {
		hasSuffix(suffix) ? .init(dropLast(suffix.count)) : self
	}

	func similarity(to that: Self) -> Double {
		func score(_ string: Self) -> ([ScoredCharacter], Double) {
			string.precomposedStringWithCanonicalMapping
				.reduce(into: (.init(reservedCapacity: string.count), 0)) { result, character in
					let scoredCharacter = ScoredCharacter(character)
					result.0.append(scoredCharacter)
					result.1 += scoredCharacter.cost
				}
		}

		let (thisChars, thisCost) = score(self)
		let (thatChars, thatCost) = score(that)
		let thisLength = thisChars.count
		let thatLength = thatChars.count
		guard thisLength > 0 else {
			return thatLength == 0 ? 1 : 0
		}
		guard thatLength > 0 else {
			return 0
		}

		let columnCount = thatLength + 1
		var rowTwoPrevious = [Double](repeating: 0, count: columnCount)
		var rowPrevious = (0...thatLength).map(Double.init)
		var rowCurrent = [Double](repeating: 0, count: columnCount)
		for i in 1...thisLength { // swiftlint:disable:this identifier_name
			let thisChar = thisChars[i - 1]
			func cost(of thatChar: ScoredCharacter, at thatIndex: Int) -> Double {
				Swift::min(
					rowPrevious[thatIndex] + thisChar.cost, // Deletion
					rowCurrent[thatIndex - 1] + thatChar.cost, // Insertion
					rowPrevious[thatIndex - 1] + thisChar.cost(substitutingFor: thatChar),
				)
			}

			rowCurrent[0] = .init(i)
			if i > 1 {
				let previousThisChar = thisChars[i - 2]
				for j in 1...thatLength { // swiftlint:disable:this identifier_name
					let thatChar = thatChars[j - 1]
					guard thisChar != thatChar else {
						rowCurrent[j] = rowPrevious[j - 1]
						continue
					}

					let cost = cost(of: thatChar, at: j)
					// Damerau-Levenshtein transposition check
					rowCurrent[j] = j > 1 && thisChar == thatChars[j - 2] && previousThisChar == thatChar
						? min(cost, rowTwoPrevious[j - 2] + 0.4)
						: cost
				}
			} else {
				for j in 1...thatLength { // swiftlint:disable:this identifier_name
					let thatChar = thatChars[j - 1]
					rowCurrent[j] = thisChar == thatChar ? rowPrevious[j - 1] : cost(of: thatChar, at: j)
				}
			}
			swap(&rowTwoPrevious, &rowPrevious)
			swap(&rowPrevious, &rowCurrent)
		}

		let maxCost = max(thisCost, thatCost)
		return maxCost == 0 ? 1 : max(0, 1 - rowPrevious[thatLength] / maxCost)
	}
}

private struct ScoredCharacter: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.character == rhs.character
	}

	let character: Character
	let lowercased: String
	let folded: String
	let cost: Double

	init(_ character: Character) {
		self.character = character
		let string = String(character)
		lowercased = string.lowercased()
		folded = character.isASCII ? string : string.folding(options: .diacriticInsensitive, locale: .current)
		cost = character.isWhitespace || character.isPunctuation || character.isSymbol ? 0.25 : 1
	}

	func cost(substitutingFor that: Self) -> Double {
		folded == that.folded ? 0.1 : lowercased == that.lowercased ? 0.2 : 1
	}
}
