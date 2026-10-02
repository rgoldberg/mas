//
// MASTests+User.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Darwin
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `a known uid has a name`() {
		#expect(uid_t(0).name == "root")
	}

	@Test
	func `an unknown uid has no name`() {
		#expect(uid_t(3_999_999_999).name == nil)
	}

	@Test
	func `a known uid's name & uid quote its name`() {
		#expect(uid_t(0).nameAndUID == "'root' (0)")
	}

	@Test
	func `an unknown uid's name & uid is only its uid`() {
		#expect(uid_t(3_999_999_999).nameAndUID == "(3999999999)")
	}
}
