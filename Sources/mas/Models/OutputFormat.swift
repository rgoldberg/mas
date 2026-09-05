//
// OutputFormat.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

enum OutputFormat: Equatable {
	case json
	case keyValue
	case table(TableConfig)
}
