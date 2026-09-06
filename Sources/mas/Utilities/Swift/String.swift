//
// String.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

extension String {
	var uppercasingFirst: Self {
		prefix(1).uppercased() + dropFirst()
	}

	var quoted: Self {
		"'\(replacing("'", with: "\\'"))'"
	}

	func ifNotEmptyPrepend(_ prefix: String) -> Self {
		isEmpty ? self : prefix + self
	}

	func removingSuffix(_ suffix: Self) -> Self {
		hasSuffix(suffix) ? .init(dropLast(suffix.count)) : self
	}
}
