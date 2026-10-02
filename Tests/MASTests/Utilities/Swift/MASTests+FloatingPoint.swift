//
// MASTests+FloatingPoint.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			(Float(0.5), Float(0.5)),
			(0, 0),
			(1, 1),
			(-0.5, 0),
			(1.5, 1),
			(-.infinity, 0),
			(.infinity, 1),
			(.nan, 0),
		],
	)
	func `a floating-point number clamped to the unit interval is within 0...1, with NaN as 0`(
		value: Float,
		clampedValue: Float,
	) {
		#expect(value.clampedToUnitInterval == clampedValue)
	}
}
