//
// OutputFormat.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

enum OutputFormat: Equatable {
	case json(JSONConfig)
	case keyValue(KeyValueConfig)
	case table(TableConfig)

	var isJSON: Bool {
		if case .json = self {
			true
		} else {
			false
		}
	}
}
