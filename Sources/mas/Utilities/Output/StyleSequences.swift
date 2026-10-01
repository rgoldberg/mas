//
// StyleSequences.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// The literal strings (table.md's `<style-prefix>`, `<style-suffix>` &
/// `<style-reset>`) that, with a `<style-specifier>`, style a string.
struct StyleSequences: Equatable {
	static let `default` = Self(prefix: "\u{1B}[", suffix: "m", reset: "\u{1B}[0m")

	/// Precedes the `<style-specifier>`.
	let prefix: String
	/// Follows the `<style-specifier>`, preceding the styled string.
	let suffix: String
	/// Follows the styled string.
	let reset: String
}
