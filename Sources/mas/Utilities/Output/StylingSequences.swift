//
// StylingSequences.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// The literal strings (table.md's `<styling-prefix>`, `<styling-suffix>` &
/// `<styling-reset>`) that, with a `<styling-specifier>`, style a string.
struct StylingSequences: Equatable {
	/// ANSI SGR styling defaults (`Specs/command-line.md` "Styling Defaults").
	static let `default` = Self(prefix: "\u{1B}[", suffix: "m", reset: "\u{1B}[0m")

	/// Precedes the `<styling-specifier>`.
	let prefix: String
	/// Follows the `<styling-specifier>`, preceding the styled string.
	let suffix: String
	/// Follows the styled string.
	let reset: String
}
