//
// MASTests+Group.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Darwin
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(.enabled(if: geteuid() != 0))
	func `setting groups fails without root privileges`() {
		#expect(throws: MASError.self) { try set(groupsOfUID: getuid(), gid: getgid()) }
	}

	@Test
	func `setting groups fails for an unknown uid`() {
		#expect(throws: MASError.self) { try set(groupsOfUID: 3_999_999_999, gid: getgid()) }
	}
}
