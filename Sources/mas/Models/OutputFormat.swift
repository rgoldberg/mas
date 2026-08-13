//
// OutputFormat.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser

enum OutputFormat: EnumerableFlag {
	case json
	case keyValue
	case table
}
