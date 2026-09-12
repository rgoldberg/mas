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

	var core: String { get } // periphery:ignore
	var prerelease: String? { get } // periphery:ignore
	var build: String? { get } // periphery:ignore
} // swiftlint:enable unused_declaration

extension Version {
	func compareSemVer(to that: Self) -> ComparisonResult {
		let coreComparison = coreElements.compareSemVerElements(to: that.coreElements)
		return coreComparison != .orderedSame
			? coreComparison
			: prereleaseElements.isEmpty != that.prereleaseElements.isEmpty // swiftformat:disable:next wrap wrapArguments
				? prereleaseElements.isEmpty ? .orderedDescending : .orderedAscending
				: prereleaseElements.compareSemVerElements(to: that.prereleaseElements)
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
	func compareSemVerElements(to that: Self) -> ComparisonResult {
		zip(self, that).first { $0 != $1 }.map { $0.compareSemVerElement(to: $1) }
			?? ComparableComparator().compare(dropLast { $0 == "0" }.count, that.dropLast { $0 == "0" }.count)
	}
}
