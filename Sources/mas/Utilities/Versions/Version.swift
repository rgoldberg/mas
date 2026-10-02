//
// Version.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import BigInt
internal import Foundation

protocol Version: RawRepresentable<String> {
	var coreElements: [String] { get }
	var prereleaseElements: [String] { get }
	var buildElements: [String] { get } // swiftlint:disable unused_declaration

	var core: String { get }
	var prerelease: String? { get }
	var build: String? { get } // swiftlint:enable unused_declaration
}

extension Version {
	func compareSemVer(to that: Self) -> ComparisonResult {
		let coreComparison = coreElements.compareSemVerElements(to: that.coreElements)
		return coreComparison != .orderedSame
			? coreComparison
			: prereleaseElements.isEmpty != that.prereleaseElements.isEmpty // swiftformat:disable:next wrap wrapArguments
				? prereleaseElements.isEmpty ? .orderedDescending : .orderedAscending
				: prereleaseElements.compareSemVerElements(to: that.prereleaseElements, countedBy: \.count)
	}

	func compareSemVerAndBuild(to that: Self) -> ComparisonResult {
		let semVerComparison = compareSemVer(to: that)
		return semVerComparison == .orderedSame
			? buildElements.compareSemVerElements(to: that.buildElements)
			: semVerComparison
	}
}

private extension String {
	func compareSemVerElement(
		to that: Self,
		options mask: CompareOptions = .init(),
		range: Range<Self.Index>? = nil,
		locale: Locale? = nil,
	) -> ComparisonResult {
		let thatInteger = BigUInt(that)
		return BigUInt(self).map { thisInteger in
			thatInteger.map { ComparableComparator().compare(thisInteger, $0) } ?? .orderedAscending
		}
			?? thatInteger.map { _ in .orderedDescending }
			?? compare(that, options: mask, range: range, locale: locale)
	}
}

private extension [String] {
	/// The element count, ignoring each trailing all-`0` element (e.g., `0` or
	/// `00`) that follows an all-digit element (SemVer ranks a prerelease with
	/// more elements higher, so a prerelease is counted by `count` instead).
	var significantCount: Int {
		indices.last { index in
			index == startIndex
				|| self[index].isEmpty
				|| self[index].contains { $0 != "0" }
				|| !self[index - 1].allSatisfy(\.isASCIIDigit)
		}
		.map { $0 + 1 }
		?? 0
	}

	func compareSemVerElements(to that: Self, countedBy count: KeyPath<Self, Int> = \.significantCount)
	-> ComparisonResult {
		zip(self, that).lazy.map { $0.compareSemVerElement(to: $1) }.first { $0 != .orderedSame }
			?? ComparableComparator().compare(self[keyPath: count], that[keyPath: count])
	}
}
