//
// ComparisonResult.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

extension ComparisonResult {
	var reversed: Self {
		switch self {
		case .orderedAscending:
			.orderedDescending
		case .orderedDescending:
			.orderedAscending
		case .orderedSame:
			.orderedSame
		}
	}
}
