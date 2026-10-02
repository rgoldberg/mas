//
// FloatingPoint.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

extension FloatingPoint {
	/// `self` clamped to the unit interval (0...1), with NaN as 0.
	var clampedToUnitInterval: Self {
		isNaN ? 0 : min(max(self, 0), 1)
	}
}
