//
// TableConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--table-config`'s value (table.md). `nil` `header` /
/// `separator` means neither is shown; `separator` is `nil` whenever `header`
/// is, because a separator line is rendered iff a header row is.
struct TableConfig: Equatable {
	/// The header row: field labels, styled per `stylingSpecifier` (e.g., with
	/// the default `StylingSequences`, `"1"` for bold, `"1;4"` for bold &
	/// underlined; empty means unstyled).
	struct Header: Equatable {
		let stylingSpecifier: String
	}

	/// The line between the header row & the 1st data row.
	struct Separator: Equatable {
		/// Repeated (truncating mid-repetition if needed, then space-filling any
		/// remaining width) to fill its line; never empty (`<separator-pattern>`
		/// defaults to `-`).
		let pattern: String
		/// - `true`: 1 segment per column, each independently filled to that
		///   column's width, joined by `columnSpacing` (matching every other row).
		/// - `false`: 1 continuous, column-unaware line spanning the whole table's
		///   width.
		let broken: Bool
	}

	static let `default` = Self(
		header: nil,
		styling: .supportedOnly,
		stylingSequences: .default,
		separator: nil,
		columnSpacing: "  ",
	)

	let header: Header?
	let styling: Styling
	let stylingSequences: StylingSequences
	let separator: Separator?
	let columnSpacing: String
}

/// Parses `--table-config`'s value, which, iff non-empty, is `table.md`'s
/// `<table-config>` (`<table-setting>+`), last wins per setting. A defaulted
/// (i.e., unset) setting with a prerequisite is filled in per `table.md`'s
/// "Implied Alternatives": `b` / `u` imply a separator line (`S`, default
/// `<separator-pattern>` `-`); any separator line implies a header row (`H`,
/// unstyled). An explicit alternative of a setting (even "off") always
/// overrides that setting's implied alternative. A separator line without a
/// header row is not rendered. Outer bare whitespace between settings is
/// ignored.
func parseTableConfig(_ value: String) throws(TableConfigParsingError) -> TableConfig {
	var header = TableConfigSetting<String>.unset
	var styling = Styling.supportedOnly
	var stylingPrefix = TableConfig.default.stylingSequences.prefix
	var stylingSuffix = TableConfig.default.stylingSequences.suffix
	var stylingReset = TableConfig.default.stylingSequences.reset
	var separatorPattern = TableConfigSetting<String>.unset
	var broken = TableConfigSetting<Bool>.unset
	var columnSpacing = String?.none
	var input = value[...]
	while case let trimmed = input.drop(while: \.isWhitespace), let setting = trimmed.first {
		input = trimmed.dropFirst()
		switch setting {
		case "h":
			header = .off
		case "H":
			header = .set(
				try parseStylingSpecifier(
					&input,
					danglingEscapeError: TableConfigParsingError.danglingEscape,
					invalidStylingSpecifierError: TableConfigParsingError.invalidHeaderStylingSpecifier,
				),
			)
		case "t":
			styling = .supportedOnly
		case "a":
			styling = .always
		case "p":
			stylingPrefix = TableConfig.default.stylingSequences.prefix
		case "P":
			stylingPrefix = try parseTableSettingText(&input)
		case "x":
			stylingSuffix = TableConfig.default.stylingSequences.suffix
		case "X":
			stylingSuffix = try parseTableSettingText(&input)
		case "o":
			stylingReset = TableConfig.default.stylingSequences.reset
		case "O":
			stylingReset = try parseTableSettingText(&input)
		case "s":
			separatorPattern = .off
		case "S":
			// `<separator-pattern>` is a non-empty variable token: absent, its
			// default `-` applies
			let pattern = try parseTableSettingText(&input)
			separatorPattern = .set(pattern.isEmpty ? "-" : pattern)
		case "b":
			broken = .set(true)
		case "u":
			broken = .set(false)
		case "c":
			columnSpacing = TableConfig.default.columnSpacing
		case "C":
			columnSpacing = try parseTableSettingText(&input)
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
		header: header.setValue.map { .init(stylingSpecifier: $0) },
		styling: styling,
		stylingSequences: .init(prefix: stylingPrefix, suffix: stylingSuffix, reset: stylingReset),
		separator: header.setValue == nil
			? nil
			: separatorPattern.setValue.map { .init(pattern: $0, broken: broken.setValue ?? false) },
		columnSpacing: columnSpacing ?? TableConfig.default.columnSpacing,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum TableConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidHeaderStylingSpecifier(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --table-config's value"
		case let .invalidHeaderStylingSpecifier(stylingSpecifier):
			"Invalid header styling specifier (expected each ASCII letter escaped, e.g., \"\\b\"): \(stylingSpecifier)"
		case let .invalidSetting(setting):
			"Invalid --table-config <table-setting>: \(setting)"
		}
	}
}

/// A setting's parse state: not yet mentioned, explicitly off, or explicitly
/// set to a value. Distinguishing `.unset` from `.off` is what lets an implied
/// default apply only when a setting was never touched at all, per
/// `parseTableConfig(_:)`'s doc comment.
private enum TableConfigSetting<Value> { // swiftlint:disable:this one_declaration_per_file
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

/// Parses an uppercase `<table-setting>`'s `{string}` payload
/// (`<styling-prefix>`, `<styling-suffix>`, `<styling-reset>`,
/// `<separator-pattern>`, or `<column-spacing>`) through its
/// `<setting-termination>` via `parseOutputConfigSettingPayload`.
private func parseTableSettingText(_ input: inout Substring) throws(TableConfigParsingError) -> String {
	try parseOutputConfigSettingPayload(&input, danglingEscapeError: TableConfigParsingError.danglingEscape)
}
