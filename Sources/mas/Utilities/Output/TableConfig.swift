//
// TableConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--table`'s value (table.md). `nil` `header` / `separator`
/// means neither is shown.
struct TableConfig: Equatable {
	/// The header row: field labels, styled per `sgrCodes` (raw ANSI SGR
	/// parameters, e.g., `"1"` for bold, `"1;4"` for bold & underlined; empty
	/// means unstyled).
	struct Header: Equatable {
		let sgrCodes: String
	}

	/// The line between the header row & the 1st data row.
	struct Separator: Equatable {
		/// Repeated (truncating mid-repetition if needed, never padded) to fill
		/// its line; never empty (`<separator-pattern>` defaults to `-`).
		let pattern: String
		/// `true`: 1 segment per column, each independently filled to that
		/// column's width, joined by `columnSpacing` (matching every other row).
		/// `false`: 1 continuous, column-unaware line spanning the whole table's
		/// width.
		let broken: Bool
	}

	/// `<header-styling-setting>`: when `Header.sgrCodes` are applied.
	enum HeaderStyling: Equatable {
		/// `a`: always, even if standard output is not a terminal.
		case always
		/// `t`: iff standard output is a terminal.
		case terminalOnly
	}

	static let `default` = Self(header: nil, headerStyling: .terminalOnly, separator: nil, columnSpacing: "  ")

	let header: Header?
	let headerStyling: HeaderStyling
	let separator: Separator?
	let columnSpacing: String
}

/// Parses `--table`'s value (`table.md`'s `<table-config>`): `<table-setting>+`,
/// last wins per axis. A defaulted (i.e., unset) axis with a prerequisite is
/// filled in per `table.md`'s "Implied Settings": `b` / `u` imply a separator
/// line (`S`, default `<separator-pattern>` `-`); any separator line implies a
/// header row (`H`, unstyled). A setting that explicitly sets an axis (even to
/// "off") always overrides an implied default for that axis.
func parseTableConfig(_ value: String) throws(TableConfigParsingError) -> TableConfig {
	var header = TableConfigAxis<String>.unset
	var headerStyling = TableConfig.HeaderStyling.terminalOnly
	var separatorPattern = TableConfigAxis<String>.unset
	var broken = TableConfigAxis<Bool>.unset
	var columnSpacing = String?.none
	var input = value[...]
	while let setting = input.first {
		input.removeFirst()
		switch setting {
		case "h":
			header = .off
		case "H":
			header = .set(try parseTableSettingText(&input, setting: setting))
		case "t":
			headerStyling = .terminalOnly
		case "a":
			headerStyling = .always
		case "s":
			separatorPattern = .off
		case "S":
			// `<separator-pattern>` is a non-empty text token: absent, its default
			// `-` applies
			let pattern = try parseTableSettingText(&input, setting: setting)
			separatorPattern = .set(pattern.isEmpty ? "-" : pattern)
		case "b":
			broken = .set(true)
		case "u":
			broken = .set(false)
		case "c":
			columnSpacing = TableConfig.default.columnSpacing
		case "C":
			columnSpacing = try parseTableSettingText(&input, setting: setting)
		default:
			throw .invalidOption(setting)
		}
	}
	if !broken.isUnset, separatorPattern.isUnset {
		separatorPattern = .set("-")
	}
	if !separatorPattern.isUnset, header.isUnset {
		header = .set("")
	}
	return .init(
		header: header.setValue.map { .init(sgrCodes: $0) },
		headerStyling: headerStyling,
		separator: separatorPattern.setValue.map { .init(pattern: $0, broken: broken.setValue ?? false) },
		columnSpacing: columnSpacing ?? TableConfig.default.columnSpacing,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum TableConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidHeaderStyle(String)
	case invalidOption(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --table's value"
		case let .invalidHeaderStyle(sgrCodes):
			"Invalid header style (expected ANSI SGR parameters, e.g., \"1\" or \"1;4\"): \(sgrCodes)"
		case let .invalidOption(option):
			"Invalid --table option: \(option)"
		}
	}
}

/// An axis's parse state: not yet mentioned, explicitly off, or explicitly set
/// to a value. Distinguishing `.unset` from `.off` is what lets an implied
/// default apply only when an axis was never touched at all, per
/// `parseTableConfig(_:)`'s doc comment.
private enum TableConfigAxis<Value> { // swiftlint:disable:this one_declaration_per_file
	case off
	case set(Value)
	case unset

	var isUnset: Bool {
		if case .unset = self {
			true
		} else {
			false
		}
	}

	var setValue: Value? {
		if case let .set(value) = self {
			value
		} else {
			nil
		}
	}
}

/// Parses an uppercase `<table-setting>`'s text (`<sgr-parameters>`,
/// `<separator-pattern>`, or `<column-spacing>`): text up through (&
/// excluding) `<table-config-terminator>`, or through `<end-of-shell-word>` if
/// `<table-config-terminator>` is absent (only valid at the very end, since
/// omitting it anywhere else would swallow subsequent settings into this
/// text). Outer bare whitespace is significant (consumed). A `\` escapes the
/// next character (e.g., `\:`); an escape prefix at the end of the input is an
/// error. `setting`'s own validation (e.g., `H`'s `<sgr-parameters>` syntax)
/// happens at the call site.
private func parseTableSettingText(_ input: inout Substring, setting: Character)
throws(TableConfigParsingError) -> String {
	var text = ""
	while let char = input.first, char != tableConfigTerminator {
		input.removeFirst()
		guard char == escapePrefix else {
			text.append(char)
			continue
		}
		guard let escaped = input.first else {
			throw .danglingEscape
		}
		input.removeFirst()
		text.append(escaped)
	}
	if input.first == tableConfigTerminator {
		input.removeFirst()
	}
	if setting == "H" {
		guard
			text.isEmpty || text.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ";") })
			&& !text.hasPrefix(";") && !text.hasSuffix(";") && !text.contains(";;")
		else {
			throw .invalidHeaderStyle(text)
		}
	}
	return text
}

private let tableConfigTerminator = Character(":")
