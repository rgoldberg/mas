//
// MASTests+MAS.Config.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `config accepts a field of its item`() throws {
		_ = try MAS.Config.parse(["--fields", "mas"])
	}

	@Test
	func `config reports any other field as nonexistent`() {
		#expect(throws: (any Error).self) {
			try MAS.Config.parse(["--fields", "name"])
		}
	}
}
