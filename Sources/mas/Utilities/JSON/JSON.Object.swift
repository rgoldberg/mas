//
// JSON.Object.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation
internal import JSONAST
internal import JSONDecoding

extension JSON.Object {
	subscript(nodeKey key: JSON.Key) -> JSON.Node? {
		fields.first { $0.key == key }?.value
	}

	/// The value of the last of field `key`'s members (fields.md "Members"), the
	/// one that a table cell & a sort key use; `nil` iff there is none.
	subscript(lastNodeKey key: JSON.Key) -> JSON.Node? {
		fields.last { $0.key == key }?.value
	}

	subscript(key: JSON.Key) -> JSON.FieldDecoder<JSON.Key>? {
		self[nodeKey: key].map { .init(key: key, value: $0) }
	}
}

extension JSON.Node {
	var stringValue: String? {
		switch self {
		case .null:
			nil
		case let .string(literal):
			literal.value
		default:
			.init(describing: self)
		}
	}
}

// MARK: - Field-spec-driven rendering (--fields; fields.md)

extension FieldSpec {
	/// This field spec's row for key-value output for a member's `value` (`nil`
	/// iff its field is absent): `(label, rendered value)`, or `nil` iff its
	/// formatted value is absent or `null` (per fields.md's "Absent Values":
	/// key-value omits both).
	func keyValueRow(for value: JSON.Node?) throws(FormattingError) -> (label: String, value: String)? {
		guard let node = try rendered(value: value), !node.isNull else {
			return nil
		}
		return (label, node.stringValue ?? "")
	}
}

extension JSON.Object {
	/// This item's key-value output rows, each with its unstyled width, driven by
	/// `--fields`-resolved field specs (label & rendered value per member, per
	/// fields.md's "Members") ordered by `fieldOrder` & `keyValueConfig`
	/// (key-value.md): each row is its key (styled per `keyValueConfig`), its
	/// leading spacing, its leader (iff any), its trailing spacing, then its
	/// value. A leader's width is the item's widest rendered key's width, less
	/// its own rendered key's width, plus the leader pattern's width. Each
	/// control character in a key renders as in a table cell (e.g., a line
	/// terminator as `⏎`), while each line terminator in a value renders as a
	/// newline (e.g., a CRLF as 1 LF), each such non-empty later line indented to
	/// the value's start by its row's unstyled text before the value, after that
	/// text's last line terminator (e.g., from its leading spacing), if any, with
	/// each tab retained & each other character replaced by as many spaces as its
	/// width, so each tab reaches the same tab stop as in the row, whatever the
	/// terminal's tab stops are. Each other control character in a value except a
	/// tab renders as in a key (e.g., an ESC as `␛`). Each row's width is that of
	/// its widest line.
	func keyValueRows(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder, keyValueConfig: KeyValueConfig)
	throws(FormattingError) -> [(row: String, width: Int)] {
		let rows = try fieldOrder.itemMembers(fieldSpecs, for: self)
			.map { fieldSpec, value throws(FormattingError) in try fieldSpec.keyValueRow(for: value) }
			.compactMap(\.self)
			.map { label, value in (label: label.controlCharactersSymbolized(), value: value) }
		let maxLabelWidth = rows.map(\.label.terminalWidth).max() ?? 0
		return rows.map { label, value in
			let labelWidth = label.terminalWidth
			let separation = keyValueConfig.leadingSpacing
				+ (
					keyValueConfig.leaderPattern.map { leaderPattern in
						repeatedPattern(leaderPattern, toWidth: maxLabelWidth - labelWidth + leaderPattern.terminalWidth)
					}
						?? ""
				)
				+ keyValueConfig.trailingSpacing
			let valueLines = value.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
				.map { line in String(line).controlCharactersSymbolized(preservingTabs: true) }
			let textBeforeValue = label + separation
			let lastLineBeforeValue = textBeforeValue.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
				.last
				?? textBeforeValue[...]
			let indentation = String(
				lastLineBeforeValue.flatMap { character in
					character == "\t" ? "\t" : String(repeating: " ", count: String(character).terminalWidth)
				},
			)
			let renderedValue = valueLines.dropFirst().reduce(into: valueLines[0]) { text, line in
				text += "\n" + (line.isEmpty ? "" : indentation + line)
			}
			return (
				styled(
					label,
					specifier: keyValueConfig.keyStyleSpecifier,
					sequences: keyValueConfig.keyStyleSequences,
					isAlwaysStyled: keyValueConfig.keyStyling == .always,
				)
					+ separation
					+ renderedValue,
				(textBeforeValue + renderedValue)
					.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
					.map(\.terminalWidth)
					.max()
					?? 0,
			)
		}
	}

	/// This item's JSON output object, per `--fields`-resolved field specs
	/// ordered by `fieldOrder`: a member per member of each field (fields.md
	/// "Members"), keyed by its field spec's label, even if keys repeat, omitting
	/// a member iff its formatted value is absent (a `null` value, unlike
	/// key-value output, is still included).
	func jsonObject(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder) throws(FormattingError) -> Self {
		.init(
			try fieldOrder.itemMembers(fieldSpecs, for: self)
				.map { fieldSpec, value throws(FormattingError) in
					try fieldSpec.rendered(value: value).map { node in (JSON.Key(rawValue: fieldSpec.label), node) }
				}
				.compactMap(\.self),
		)
	}
}

extension [JSON.Object] {
	/// `table`, but driven by `--fields`-resolved field specs & `tableConfig`
	/// (table.md): an optional header row of labels, an optional separator line
	/// (only with a header row), then a cell per field per item, for its field's
	/// last member (fields.md "Members"; label is a field spec's "Header for
	/// table"). Every item gets a cell for every field, per fields.md's "Absent
	/// Values" (absent ⇒ empty string, unless its format renders it otherwise,
	/// e.g., via a `<failure-block>`). Each line terminator in a cell renders as
	/// `⏎`, so each row is 1 line, while each other C0 control character or DEL
	/// renders as its Control Pictures symbol & each other C1 control character
	/// as its ECMA-48 7-bit equivalent, with that equivalent's ESC rendered as
	/// `␛`. `nil` iff there are no items or no field specs, so there is nothing
	/// to output.
	func table(fieldSpecs: some Sequence<FieldSpec>, tableConfig: TableConfig) throws(FormattingError) -> String? {
		guard !isEmpty else {
			return nil
		}
		let showsHeader = tableConfig.header != nil
		let columns = try fieldSpecs.map { fieldSpec throws(FormattingError) in
			let label = fieldSpec.label.controlCharactersSymbolized()
			let cells = try map { object throws(FormattingError) in
				try (fieldSpec.rendered(value: object[lastNodeKey: .init(rawValue: fieldSpec.name)])?.stringValue ?? "")
					.controlCharactersSymbolized()
			}
			return (
				label: label,
				cells: cells,
				maxWidth: cells.map(\.terminalWidth).reduce(showsHeader ? label.terminalWidth : 0, Swift::max),
				alignment: fieldSpec.alignment,
			)
		}
		guard !columns.isEmpty else {
			return nil
		}
		let columnSpacing = tableConfig.columnSpacing
		let columnMetadata = columns.map { (maxWidth: $0.maxWidth, alignment: $0.alignment) }
		var rows = [String]()
		if let header = tableConfig.header {
			let headerRow =
				renderedTableRow(cells: columns.map(\.label), columns: columnMetadata, columnSpacing: columnSpacing)
			rows.append(
				styled(
					headerRow,
					specifier: header.styleSpecifier,
					sequences: tableConfig.headerStyleSequences,
					isAlwaysStyled: tableConfig.headerStyling == .always,
				),
			)
		}
		if let separator = tableConfig.separator {
			rows.append(
				separator.broken
					? renderedTableRow(
						cells: columnMetadata.map { repeatedPattern(separator.pattern, toWidth: $0.maxWidth) },
						columns: columnMetadata,
						columnSpacing: columnSpacing,
					)
					: continuousSeparatorLine(
						pattern: separator.pattern,
						columnWidths: columnMetadata.map(\.maxWidth),
						columnSpacing: columnSpacing,
					),
			)
		}
		rows.append(
			contentsOf: (0..<count)
				.map { index in
					renderedTableRow(
						cells: columns.map { $0.cells[index] },
						columns: columnMetadata,
						columnSpacing: columnSpacing,
					)
				},
		)
		return rows.joined(separator: "\n")
	}

	/// This item list's key-value output, per `--fields`-resolved field specs
	/// ordered per item by `fieldOrder` & per `keyValueConfig` (key-value.md):
	/// each item's rows (none for an item without any), with an item separator
	/// line (iff any) between each pair of adjacent items. `nil` iff no item has
	/// a row, so there is nothing to output.
	func keyValue(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder, keyValueConfig: KeyValueConfig)
	throws(FormattingError) -> String? {
		let itemRows = try map { object throws(FormattingError) in
			try object.keyValueRows(fieldSpecs: fieldSpecs, fieldOrder: fieldOrder, keyValueConfig: keyValueConfig)
		}
		return itemRows.allSatisfy(\.isEmpty)
			? nil
			: itemRows
				.lazy
				.map { $0.map(\.row) }
				.joined(separator: keyValueConfig.itemSeparatorLine.map { [$0] } ?? .init())
				.joined(separator: "\n")
	}

	/// This item list's JSON output: 1 `JSON.Object` per item, per
	/// `--fields`-resolved field specs ordered per item by `fieldOrder`,
	/// structured & rendered per `jsonConfig` (json.md): each item as a top-level
	/// JSON value, or every item in a single top-level JSON array, each top-level
	/// JSON value on its own line(s).
	func json(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder, jsonConfig: JSONConfig) throws(FormattingError)
	-> String {
		let nodes = try map { object throws(FormattingError) in
			JSON.Node.object(try object.jsonObject(fieldSpecs: fieldSpecs, fieldOrder: fieldOrder))
		}
		let topLevelNodes =
			switch jsonConfig.topLevelStructure {
			case .itemArray:
				[JSON.Node.array(.init(nodes))]
			case .itemStream:
				nodes
			}
		return topLevelNodes.map { $0.rendered(jsonConfig: jsonConfig) }.joined(separator: "\n")
	}
}

/// Aligns & joins 1 `table` row (header, separator, or data): each column's
/// cell to its own width, gapped by `columnSpacing` applied as a literal suffix
/// after each non-last column, never baked into a column's own aligned width,
/// since that only produces a real trailing gap for `.start` alignment (`.end`
/// / `.centerStart` / `.centerEnd` would place some or all of it as leading /
/// split padding instead, eliminating or shrinking the visible gap). The last
/// column's cell gets only its leading padding, since nothing follows it.
private func renderedTableRow(
	cells: [String],
	columns: [(maxWidth: Int, alignment: Alignment)],
	columnSpacing: String,
) -> String {
	guard let lastCell = cells.last, let lastColumn = columns.last else {
		return ""
	}
	return zip(cells.dropLast(), columns.dropLast())
		.map { cell, column in cell.terminalAlign(column.alignment, to: column.maxWidth) + columnSpacing }
		.joined()
		+ String(
			repeating: " ",
			count: lastCell.terminalPaddingWidths(lastColumn.alignment, to: lastColumn.maxWidth).leading,
		)
		+ lastCell
}

private extension String {
	/// This string with each line terminator (configs.md, e.g., a CRLF as a
	/// whole) rendered as `⏎`, so it occupies 1 line, each other C0 control
	/// character or DEL rendered as its Control Pictures symbol (e.g., a tab as
	/// `␉`) & each other C1 control character rendered as its ECMA-48 7-bit
	/// equivalent, with that equivalent's ESC rendered as `␛` (e.g., U+009B as
	/// `␛[`), per table.md, so it neither misaligns a column or a leader nor
	/// modifies the terminal's state; each tab is kept iff `preservingTabs`
	/// (key-value.md: a tab in a value misaligns nothing).
	func controlCharactersSymbolized(preservingTabs: Bool = false) -> Self {
		.init(
			UnicodeScalarView(
				String(map { character in character.isNewline ? "⏎" : character })
					.unicodeScalars
					.flatMap { scalar -> [Unicode.Scalar] in
						switch scalar.value {
						case 0x09 where preservingTabs:
							[scalar]
						case 0..<0x20:
							[Unicode.Scalar(0x2400 + scalar.value) ?? scalar]
						case 0x7f:
							["\u{2421}"]
						case 0x80..<0xa0:
							["\u{241B}", Unicode.Scalar(scalar.value - 0x40) ?? scalar]
						default:
							[scalar]
						}
					},
			),
		)
	}
}

/// A `u` (unbroken) separator line: `pattern` repeated to fill the table width,
/// except that each tab of each column spacing is retained in place, with each
/// run between tabs filled independently (table.md "Broken"), because a tab's
/// rendered width depends on the terminal's tab stops, which an app cannot
/// determine.
private func continuousSeparatorLine(pattern: String, columnWidths: [Int], columnSpacing: String) -> String {
	columnWidths.dropFirst()
		.reduce(into: [columnWidths.first ?? 0]) { runWidths, columnWidth in
			for character in columnSpacing {
				if character == "\t" {
					runWidths.append(0)
				} else {
					runWidths[runWidths.count - 1] += String(character).terminalWidth
				}
			}
			runWidths[runWidths.count - 1] += columnWidth
		}
		.lazy
		.map { repeatedPattern(pattern, toWidth: $0) }
		.joined(separator: "\t")
}

/// Repeats `pattern` to fill `targetWidth`, truncating mid-repetition before
/// the 1st character that would exceed `targetWidth`, then filling any
/// remaining width (e.g., after a truncated wide character, such as `中`) with
/// spaces (table.md & key-value.md: a separator line's or leader's repetition
/// cuts off immediately, even mid-character-group, rather than rounding to a
/// whole number of repetitions). Returns a 0-width `pattern` (e.g., a tab)
/// once, with no space-fill, because no number of repetitions can fill any
/// width.
private func repeatedPattern(_ pattern: String, toWidth targetWidth: Int) -> String {
	guard pattern.terminalWidth > 0 else {
		return pattern
	}
	let patternCharacters = Array(pattern)
	var result = ""
	var width = 0
	var index = 0
	while
		case let character = patternCharacters[index % patternCharacters.count],
		case let characterWidth = String(character).terminalWidth,
		width + characterWidth <= targetWidth
	{
		result.append(character)
		width += characterWidth
		index += 1
	}
	return result + .init(repeating: " ", count: targetWidth - width)
}

extension JSON.Node {
	/// This node's JSON text per `jsonConfig` (json.md): compact or
	/// pretty-printed, with each key & string value escaped per json.md "JSON
	/// Config" & its non-ASCII characters verbatim or escaped.
	func rendered(jsonConfig: JSONConfig) -> String {
		rendered(
			indentation: jsonConfig.indentation,
			escapingNonASCII: jsonConfig.nonASCIIRendering == .escaped,
			depth: 0,
		)
	}

	/// This node's JSON text, at nesting level `depth`: compact iff `indentation`
	/// is `nil`; otherwise, each non-empty object's members & each non-empty
	/// array's elements on their own lines, indented by `indentation` per nesting
	/// level, with 1 space after each `:` between a key & its value.
	private func rendered(indentation: String?, escapingNonASCII: Bool, depth: Int) -> String {
		let memberIndentation = indentation.map { "\n" + String(repeating: $0, count: depth + 1) } ?? ""
		let closingIndentation = indentation.map { "\n" + String(repeating: $0, count: depth) } ?? ""
		let keyValueSeparator = indentation == nil ? ":" : ": "
		return switch self {
		case let .array(array) where !array.elements.isEmpty:
			"["
				+ array.elements
				.map { element in
					memberIndentation
						+ element.rendered(indentation: indentation, escapingNonASCII: escapingNonASCII, depth: depth + 1)
				}
				.joined(separator: ",")
				+ closingIndentation
				+ "]"
		case let .number(number):
			"\(number)".jsonNumberText
		case let .object(object) where !object.fields.isEmpty:
			"{"
				+ object.fields
				.map { key, value in
					memberIndentation
						+ key.rawValue.jsonStringLiteral(escapingNonASCII: escapingNonASCII)
						+ keyValueSeparator
						+ value.rendered(indentation: indentation, escapingNonASCII: escapingNonASCII, depth: depth + 1)
				}
				.joined(separator: ",")
				+ closingIndentation
				+ "}"
		case let .string(string):
			string.value.jsonStringLiteral(escapingNonASCII: escapingNonASCII)
		default:
			description
		}
	}
}

private extension String {
	/// This number's text as JSON number syntax, modified only as that syntax
	/// requires (json.md "JSON Config"): no `+` sign & an integer part of at
	/// least 1 digit, with no `0` before another digit.
	var jsonNumberText: Self {
		let unsigned = hasPrefix("-") || hasPrefix("+") ? dropFirst() : self[...]
		let integerPart = unsigned.prefix(while: \.isASCIIDigit)
		let significantIntegerPart = integerPart.drop { $0 == "0" }
		return "\(hasPrefix("-") ? "-" : "")\(significantIntegerPart.isEmpty ? "0" : significantIntegerPart)"
			+ unsigned[integerPart.endIndex...]
	}

	/// This string as a quoted JSON string (json.md "JSON Config"): each `"` &
	/// `\` escaped by a `\`, each backspace, tab, LF, form feed & CR as its short
	/// escape sequence (e.g., `\n`), and each other C0 control character, each
	/// DEL, each C1 control character & (iff `escapingNonASCII`) each other
	/// non-ASCII character as a `\u` escape sequence per UTF-16 code unit, with
	/// lowercase hex digits (e.g., `\u009b` for U+009B).
	func jsonStringLiteral(escapingNonASCII: Bool) -> Self {
		"\""
			+ unicodeScalars
			.map { scalar in
				switch scalar {
				case "\"":
					#"\""#
				case "\\":
					#"\\"#
				case "\u{08}":
					#"\b"#
				case "\t":
					#"\t"#
				case "\n":
					#"\n"#
				case "\u{0C}":
					#"\f"#
				case "\r":
					#"\r"#
				case _ where scalar.value < 0x20 || (0x7f..<0xa0).contains(scalar.value) || escapingNonASCII && !scalar.isASCII:
					String(scalar)
						.utf16
						.map { codeUnit in
							let hexDigits = String(codeUnit, radix: 16)
							return "\\u\(String(repeating: "0", count: 4 - hexDigits.count))\(hexDigits)"
						}
						.joined()
				default:
					String(scalar)
				}
			}
			.joined()
			+ "\""
	}
}

private extension JSON.Node {
	var isNull: Bool {
		if case .null = self {
			true
		} else {
			false
		}
	}
}
