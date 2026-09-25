//
// MASTests+UniversalSemVer.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `a universal SemVer splits its core, prerelease & build into dot-separated elements`() {
		let version = UniversalSemVer(rawValue: "1.2.3-beta.1+build.5")
		#expect(version.coreElements == ["1", "2", "3"])
		#expect(version.prereleaseElements == ["beta", "1"])
		#expect(version.buildElements == ["build", "5"])
		#expect(version.core == "1.2.3")
		#expect(version.prerelease == "beta.1")
		#expect(version.build == "build.5")
		#expect(version.rawValue == "1.2.3-beta.1+build.5")
	}

	@Test
	func `a universal SemVer keeps hyphens in its prerelease & plus signs in its build`() {
		let version = UniversalSemVer(rawValue: "1.2-rc-1+a+b")
		#expect(version.coreElements == ["1", "2"])
		#expect(version.prereleaseElements == ["rc-1"])
		#expect(version.buildElements == ["a+b"])
	}

	@Test
	func `a universal SemVer string literal without a prerelease or build has neither`() {
		let version: UniversalSemVer = "10.15"
		#expect(version.coreElements == ["10", "15"])
		#expect(version.prerelease == nil)
		#expect(version.build == nil)
	}

	@Test(
		arguments: [
			("1.2.3", "1.2.4", ComparisonResult.orderedAscending),
			("1.10", "1.9", .orderedDescending),
			("1.2", "1.2.0", .orderedSame),
			("1.99999999999999999999", "1.9", .orderedDescending),
			("1.a", "1.b", .orderedAscending),
			("1.0.0-alpha", "1.0.0", .orderedAscending),
			("1.0.0-alpha", "1.0.0-alpha.1", .orderedAscending),
			("1.0.0-alpha.1", "1.0.0-alpha.beta", .orderedAscending),
			("1.0.0-beta.2", "1.0.0-beta.11", .orderedAscending),
			("1.0.0-rc.1", "1.0.0-beta.11", .orderedDescending),
			("1.0.0+2", "1.0.0+1", .orderedSame),
		],
	)
	func `universal SemVers compare per SemVer precedence, ignoring builds`(
		lhs: String,
		rhs: String,
		result: ComparisonResult,
	) {
		#expect(UniversalSemVer(rawValue: lhs).compareSemVer(to: .init(rawValue: rhs)) == result)
	}

	@Test(
		arguments: [
			("1.0.0+1", "1.0.0+2", ComparisonResult.orderedAscending),
			("1.0.0+10", "1.0.0+9", .orderedDescending),
			("1.0.1+1", "1.0.0+2", .orderedDescending),
			("1.0.0-rc+2", "1.0.0+1", .orderedAscending),
			("1.0.0+a.1", "1.0.0+a.1", .orderedSame),
		],
	)
	func `universal SemVers compare builds iff their SemVers are equal`(
		lhs: String,
		rhs: String,
		result: ComparisonResult,
	) {
		#expect(UniversalSemVer(rawValue: lhs).compareSemVerAndBuild(to: .init(rawValue: rhs)) == result)
	}

	@Test
	func `an integer universal SemVer pads its core to major, minor & patch`() throws {
		let version = try #require(UniversalSemVerInt(rawValue: "14.2"))
		#expect(version.coreIntegers == [14, 2, 0])
		#expect(version.majorInteger == 14)
		#expect(version.minorInteger == 2)
		#expect(version.patchInteger == 0)
		#expect(version.coreElements == ["14", "2", "0"])
		#expect(version.major == "14")
		#expect(version.minor == "2")
		#expect(version.patch == "0")
		#expect(version.rawValue == "14.2")
	}

	@Test(
		arguments: [
			("", [0, 0, 0]),
			("7", [7, 0, 0]),
			("1.2.3.4", [1, 2, 3, 4]),
		],
	)
	func `an integer universal SemVer pads a short core with 0s but keeps a long core whole`(
		rawValue: String,
		coreIntegers: [Int],
	) throws {
		#expect(try #require(UniversalSemVerInt(rawValue: rawValue)).coreIntegers == coreIntegers)
	}

	@Test
	func `an integer universal SemVer keeps its prerelease & build elements`() throws {
		let version = try #require(UniversalSemVerInt(rawValue: "15.1.2-beta.3+4"))
		#expect(version.coreIntegers == [15, 1, 2])
		#expect(version.prereleaseElements == ["beta", "3"])
		#expect(version.buildElements == ["4"])
		#expect(version.rawValue == "15.1.2-beta.3+4")
	}

	@Test(arguments: ["14.x", "a", "1.2.99999999999999999999"])
	func `an integer universal SemVer rejects a core element that isn't an Int`(rawValue: String) {
		#expect(UniversalSemVerInt(rawValue: rawValue) == nil)
	}

	@Test
	func `an integer universal SemVer built from integers derives its raw value from its unpadded elements`() {
		let version = UniversalSemVerInt(coreIntegers: [1, 2], prereleaseElements: ["rc", "1"], buildElements: ["7"])
		#expect(version.coreIntegers == [1, 2, 0])
		#expect(version.rawValue == "1.2-rc.1+7")
		#expect(UniversalSemVerInt(coreIntegers: [3]).rawValue == "3")
	}
}
