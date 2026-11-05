//
// Styling.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// table.md's `<styling-setting>`: when a stylable string is styled.
enum Styling: Equatable {
	/// `a`: always, even if standard output is not a terminal.
	case always
	/// `t`: iff standard output is a terminal.
	case terminalOnly
}
