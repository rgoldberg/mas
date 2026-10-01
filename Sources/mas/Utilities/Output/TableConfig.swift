//
// TableConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--table`'s value (table.md). `nil` `header` / `separator`
/// means neither is shown.
struct TableConfig: Equatable {
	/// The header row: field labels, styled per `styleSpecifier` (e.g., with the
	/// default `StyleSequences`, `"1"` for bold, `"1;4"` for bold & underlined;
	/// empty means unstyled).
	struct Header: Equatable {
		let styleSpecifier: String
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

	/// `<header-styling-setting>`: when the header row is styled.
	enum HeaderStyling: Equatable {
		/// `a`: always, even if standard output is not a terminal.
		case always
		/// `t`: iff standard output is a terminal.
		case terminalOnly
	}

	static let `default` = Self(
		header: nil,
		headerStyling: .terminalOnly,
		headerStyleSequences: .default,
		separator: nil,
		columnSpacing: "  ",
	)

	let header: Header?
	let headerStyling: HeaderStyling
	let headerStyleSequences: StyleSequences
	let separator: Separator?
	let columnSpacing: String
}

/// Parses `--table`'s value (`table.md`'s `<table-config>`):
/// `[ <table-setting>+ ]`, last wins per axis. A defaulted (i.e., unset) axis
/// with a prerequisite is filled in per `table.md`'s "Implied Settings": `b` /
/// `u` imply a separator line (`S`, default `<separator-pattern>` `-`); any
/// separator line implies a header row (`H`, unstyled). A setting that
/// explicitly sets an axis (even to "off") always overrides an implied default
/// for that axis. Outer bare whitespace between settings is ignored.
func parseTableConfig(_ value: String) throws(TableConfigParsingError) -> TableConfig {
	var header = TableConfigAxis<String>.unset
	var headerStyling = TableConfig.HeaderStyling.terminalOnly
	var headerStylePrefix = TableConfig.default.headerStyleSequences.prefix
	var headerStyleSuffix = TableConfig.default.headerStyleSequences.suffix
	var headerStyleReset = TableConfig.default.headerStyleSequences.reset
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
			header = .set(
				try parseStyleSpecifier(
					&input,
					danglingEscapeError: TableConfigParsingError.danglingEscape,
					invalidStyleSpecifierError: TableConfigParsingError.invalidHeaderStyleSpecifier,
				),
			)
		case "t":
			headerStyling = .terminalOnly
		case "a":
			headerStyling = .always
		case "p":
			headerStylePrefix = TableConfig.default.headerStyleSequences.prefix
		case "P":
			headerStylePrefix = try parseTableSettingText(&input)
		case "x":
			headerStyleSuffix = TableConfig.default.headerStyleSequences.suffix
		case "X":
			headerStyleSuffix = try parseTableSettingText(&input)
		case "o":
			headerStyleReset = TableConfig.default.headerStyleSequences.reset
		case "O":
			headerStyleReset = try parseTableSettingText(&input)
		case "s":
			separatorPattern = .off
		case "S":
			// `<separator-pattern>` is a non-empty text token: absent, its default
			// `-` applies
			let pattern = try parseTableSettingText(&input)
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
			let spacing = try parseTableSettingText(&input)
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
		header: header.setValue.map { .init(styleSpecifier: $0) },
		headerStyling: headerStyling,
		headerStyleSequences: .init(prefix: headerStylePrefix, suffix: headerStyleSuffix, reset: headerStyleReset),
		separator: separatorPattern.setValue.map { .init(pattern: $0, broken: broken.setValue ?? false) },
		columnSpacing: columnSpacing ?? TableConfig.default.columnSpacing,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum TableConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidColumnSpacing(String)
	case invalidHeaderStyleSpecifier(String)
	case invalidSeparatorPattern(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --table's value"
		case let .invalidColumnSpacing(spacing):
			"Invalid column spacing (a line terminator would split each row): \(spacing.debugDescription)"
		case let .invalidHeaderStyleSpecifier(styleSpecifier):
			"Invalid header style specifier (escape each ASCII letter, e.g., \"\\b\"): \(styleSpecifier)"
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

/// Parses an uppercase `<table-setting>`'s `{text}` payload (`<style-prefix>`,
/// `<style-suffix>`, `<style-reset>`, `<separator-pattern>`, or
/// `<column-spacing>`) through its `<table-setting-termination>` via
/// `parseOutputConfigSettingPayload`.
private func parseTableSettingText(_ input: inout Substring) throws(TableConfigParsingError) -> String {
	try parseOutputConfigSettingPayload(&input, danglingEscapeError: TableConfigParsingError.danglingEscape)
}
