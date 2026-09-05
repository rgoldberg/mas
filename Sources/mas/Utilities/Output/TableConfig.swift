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
		/// its line; empty means a blank line.
		let pattern: String
		/// `true`: 1 segment per column, each independently filled to that
		/// column's width, joined by `columnSpacing` (matching every other row).
		/// `false`: 1 continuous, column-unaware line spanning the whole table's
		/// width.
		let broken: Bool
	}

	static let `default` = Self(header: nil, separator: nil, columnSpacing: "  ")

	let header: Header?
	let separator: Separator?
	let columnSpacing: String
}

/// Parses `--table`'s value (`table.md`): an ad hoc (order-insensitive)
/// sequence of options, last 1 wins per axis. A defaulted (i.e., unset) axis
/// with a prerequisite is filled in per `table.md`'s "Implied Options": `b` /
/// `u` imply a separator (default pattern: `-`, since a blank 1 would defeat
/// the point of `broken` / not); any separator implies a header (default:
/// unstyled). An option that explicitly sets an axis (even to "off") always
/// wins over an implied default for that axis.
func parseTableConfig(_ value: String) throws(TableConfigParsingError) -> TableConfig {
	var header = TableConfigAxis<String>.unset
	var separatorPattern = TableConfigAxis<String>.unset
	var broken = TableConfigAxis<Bool>.unset
	var columnSpacing = String?.none
	var input = value[...]
	while let option = input.first {
		input.removeFirst()
		switch option {
		case "h":
			header = .off
		case "H":
			header = .set(try parseTableOptionValue(&input, option: option))
		case "s":
			separatorPattern = .off
		case "S":
			separatorPattern = .set(try parseTableOptionValue(&input, option: option))
		case "b":
			broken = .set(true)
		case "u":
			broken = .set(false)
		case "c":
			columnSpacing = TableConfig.default.columnSpacing
		case "C":
			columnSpacing = try parseTableOptionValue(&input, option: option)
		default:
			throw .invalidOption(option)
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
		separator: separatorPattern.setValue.map { .init(pattern: $0, broken: broken.setValue ?? false) },
		columnSpacing: columnSpacing ?? TableConfig.default.columnSpacing,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum TableConfigParsingError: Equatable, Error, CustomStringConvertible {
	case invalidHeaderStyle(String)
	case invalidOption(Character)

	var description: String {
		switch self {
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

/// Parses a verbose (uppercase) `--table` option's value: text up through (&
/// excluding) `<table-value-terminator>`, or through the end of `input` if
/// `<table-value-terminator>` is absent (only valid at the very end, since
/// omitting it anywhere else would swallow subsequent options into this
/// value). `option`'s own validation (e.g., `H`'s SGR-parameter syntax)
/// happens at the call site.
private func parseTableOptionValue(_ input: inout Substring, option: Character)
throws(TableConfigParsingError) -> String {
	let value = input.prefix { $0 != tableValueTerminator }
	input.removeFirst(value.count)
	if input.first == tableValueTerminator {
		input.removeFirst()
	}
	if option == "H" {
		guard
			value.isEmpty || value.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ";") })
			&& !value.hasPrefix(";") && !value.hasSuffix(";") && !value.contains(";;")
		else {
			throw .invalidHeaderStyle(.init(value))
		}
	}
	return .init(value)
}

private let tableValueTerminator = Character(":")
