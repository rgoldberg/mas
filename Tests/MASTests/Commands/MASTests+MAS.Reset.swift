//
// MASTests+MAS.Reset.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Darwin
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `the running process IDs include this process's but no unfilled entries`() throws {
		let processIDs = try runningProcessIDs
		#expect(processIDs.contains(getpid()))
		#expect(processIDs.count { $0 == 0 } <= 1) // Only kernel_task's pid is 0
	}
}
