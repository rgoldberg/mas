//
// MASTests+Install.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

private import ArgumentParser
@testable private import mas
internal import Testing

extension MASTests {
	@Test(.disabled())
	func doesNotInstallAppsWhenNoAppIDs() async {
		let actual = await consequencesOf(
			try await MAS.main(try MAS.Install.parse([])) { try await $0.run(installedApps: [], adamIDs: []) }
		)
		let expected = Consequences()
		#expect(actual == expected)
	}
}
