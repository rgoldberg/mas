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
		/// Repeated (truncating mid-repetition if needed, never padded) to fill its
		/// line; never empty (`<separator-pattern>` defaults to `-`) & never
		/// contains a line terminator.
		let pattern: String
		/// - `true`: 1 segment per column, each independently filled to that
		///   column's width, joined by `columnSpacing` (matching every other row).
		/// - `false`: 1 continuous, column-unaware line spanning the whole table's
		///   width.
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

/// Parses `--table`'s value (`table.md`'s `<table-config>`):
/// `<table-setting>+`, last wins per axis. A defaulted (i.e., unset) axis with
/// a prerequisite is filled in per `table.md`'s "Implied Settings": `b` / `u`
/// imply a separator line (`S`, default `<separator-pattern>` `-`); any
/// separator line implies a header row (`H`, unstyled). A setting that
/// explicitly sets an axis (even to "off") always overrides an implied default
/// for that axis. Outer bare whitespace between settings is ignored.
func parseTableConfig(_ value: String) throws(TableConfigParsingError) -> TableConfig {
	var header = TableConfigAxis<String>.unset
	var headerStyling = TableConfig.HeaderStyling.terminalOnly
	var separatorPattern = TableConfigAxis<String>.unset
	var broken = TableConfigAxis<Bool>.unset
	var columnSpacing = String?.none
	var input = value[...]
	while case let trimmed = input.drop(while: \.isWhitespace), let setting = trimmed.first {
		input = trimmed.dropFirst()
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
			guard !pattern.contains(where: \.isNewline) else {
				throw .invalidSeparatorPattern(pattern)
			}
			separatorPattern = .set(pattern.isEmpty ? "-" : pattern)
		case "b":
			broken = .set(true)
		case "u":
			broken = .set(false)
		case "c":
			columnSpacing = TableConfig.default.columnSpacing
		case "C":
			let spacing = try parseTableSettingText(&input, setting: setting)
			guard !spacing.contains(where: \.isNewline) else {
				throw .invalidColumnSpacing(spacing)
			}
			columnSpacing = spacing
		default:
			throw .invalidSetting(setting)
		}
	}
	if !broken.isUnset, separatorPattern.isUnset {
		separatorPattern = .set("-")
	}
	if separatorPattern.setValue != nil, header.isUnset {
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
	case invalidColumnSpacing(String)
	case invalidHeaderStyle(String)
	case invalidSeparatorPattern(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --table's value"
		case let .invalidColumnSpacing(spacing):
			"Invalid column spacing (a line terminator would split each row): \(spacing.debugDescription)"
		case let .invalidHeaderStyle(sgrCodes):
			"Invalid header style (expected ANSI SGR parameters, e.g., \"1\" or \"1;4\"): \(sgrCodes)"
		case let .invalidSeparatorPattern(pattern):
			"Invalid separator pattern (a line terminator would split the separator line): \(pattern.debugDescription)"
		case let .invalidSetting(setting):
			"Invalid --table <table-setting>: \(setting)"
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

/// Parses an uppercase `<table-setting>`'s payload (`<sgr-parameters>`,
/// `<separator-pattern>`, or `<column-spacing>`) through its
/// `<table-setting-termination>` via `parseOutputConfigSettingPayload`;
/// `<sgr-parameters>` is not a `{text}` token, so it supports no escape
/// sequences (a `\` is invalid there) & ignores the outer bare whitespace
/// around each `<sgr-parameter>`.
private func parseTableSettingText(_ input: inout Substring, setting: Character)
throws(TableConfigParsingError) -> String {
	let text = try parseOutputConfigSettingPayload(
		&input,
		supportsEscapeSequences: setting != "H",
		danglingEscapeError: TableConfigParsingError.danglingEscape,
	)
	guard setting == "H" else {
		return text
	}
	guard let sgrParameters = normalizedSGRParameters(text) else {
		throw .invalidHeaderStyle(text)
	}
	return sgrParameters
}
