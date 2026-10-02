//
// MASTests+DecimalNumber.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: ["", ".", "-", "e5", "1e", "1x", "0x1", " 1", "1,000"])
	func `rejects a string that isn't a canonical number`(string: String) {
		#expect(DecimalNumber(string) == nil)
	}

	@Test(
		arguments: [
			("1", "1.0"),
			("0.5", ".5"),
			("+12", "12"),
			("0", "-0.0e7"),
			("1500", "1.5e3"),
			("0.001", "1E-3"),
			("00120.0", "1.2e+2"),
		],
	)
	func `equal numbers parse equally, regardless of notation`(lhs: String, rhs: String) {
		#expect(DecimalNumber(lhs) == DecimalNumber(rhs))
	}

	@Test(
		arguments: [
			("-2", "-1"),
			("-1", "0"),
			("0", "0.5"),
			("0.5", "0.51"),
			("0.9", "1"),
			("1.25", "1.5"),
			("99999999999999999999", "100000000000000000000"),
			("12345678901234567890.1", "12345678901234567890.10000000000000000001"),
			("1e400", "1e401"),
			("-1e401", "-1e400"),
		],
	)
	func `compares numbers exactly`(lesser: String, greater: String) throws {
		let lesser = try #require(DecimalNumber(lesser))
		let greater = try #require(DecimalNumber(greater))
		#expect(lesser < greater)
		#expect(!(greater < lesser))
	}
}
