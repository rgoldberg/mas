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

extension JSON.Object {
	/// A field spec's row for key-value output: `(label, rendered value)`, or
	/// `nil` if the field's raw value is absent or `null` (per fields.md's
	/// "Absent Values": key-value omits both).
	func keyValueRow(for fieldSpec: FieldSpec) throws(FormattingError) -> (label: String, value: String)? {
		guard let node = self[nodeKey: .init(rawValue: fieldSpec.name)], !node.isNull else {
			return nil
		}
		return (
			fieldSpec.label,
			try fieldSpec.rendered(value: node).stringValue ?? "",
		)
	}

	/// This item's key-value output rows, each with its unstyled width, driven by
	/// `--fields`-resolved field specs (label & rendered value per field) &
	/// `keyValueConfig` (key-value.md): each row is its key (styled per
	/// `keyValueConfig`), its leading spacing, its leader (iff any), its trailing
	/// spacing, then its value. A leader's width is the item's widest key's
	/// width, less its own key's width, plus the leader pattern's width.
	func keyValueRows(fieldSpecs: some Sequence<FieldSpec>, keyValueConfig: KeyValueConfig)
	throws(FormattingError) -> [(row: String, width: Int)] {
		let rows = try fieldSpecs.map { fieldSpec throws(FormattingError) in try keyValueRow(for: fieldSpec) }
			.compactMap(\.self)
		let maxLabelWidth = rows.map(\.label.terminalWidth).max() ?? 0
		return rows.map { label, value in
			let labelWidth = label.terminalWidth
			let suffix = keyValueConfig.leadingSpacing
				+ (
					keyValueConfig.leaderPattern.map { leaderPattern in
						repeatedPattern(leaderPattern, toWidth: maxLabelWidth - labelWidth + leaderPattern.terminalWidth)
					}
						?? ""
				)
				+ keyValueConfig.trailingSpacing
				+ value
			return (
				styled(
					label,
					specifier: keyValueConfig.keyStyleSpecifier,
					sequences: keyValueConfig.keyStyleSequences,
					isAlwaysStyled: keyValueConfig.keyStyling == .always,
				)
					+ suffix,
				labelWidth + suffix.terminalWidth,
			)
		}
	}

	/// This item's JSON output object, per `--fields`-resolved field specs: keyed
	/// by each field's label, omitting a field entirely iff its raw value is
	/// absent (a `null` value, unlike key-value output, is still included).
	func jsonObject(fieldSpecs: some Sequence<FieldSpec>) throws(FormattingError) -> Self {
		.init(
			try fieldSpecs
				.map { fieldSpec throws(FormattingError) in
					try self[nodeKey: .init(rawValue: fieldSpec.name)].map { raw throws(FormattingError) in
						(
							JSON.Key(rawValue: fieldSpec.label),
							try fieldSpec.rendered(value: raw),
						)
					}
				}
				.compactMap(\.self),
		)
	}
}

extension [JSON.Object] {
	/// `table`, but driven by `--fields`-resolved field specs & `tableConfig`
	/// (table.md): an optional header row of labels, an optional separator line,
	/// then a cell per field per item (fields.md: label is a field spec's "Header
	/// for table"). Every item gets a cell for every field, per fields.md's
	/// "Absent Values" (absent ⇒ empty string, unless its format renders it
	/// otherwise, e.g., via a `<failure-block>`).
	func table(fieldSpecs: some Sequence<FieldSpec>, tableConfig: TableConfig) throws(FormattingError) -> String {
		guard !isEmpty else {
			return ""
		}
		let showsHeader = tableConfig.header != nil
		let columns = try fieldSpecs.map { fieldSpec throws(FormattingError) in
			let cells = try map { object throws(FormattingError) in
				try fieldSpec.rendered(value: object[nodeKey: .init(rawValue: fieldSpec.name)]).stringValue ?? ""
			}
			return (
				label: fieldSpec.label,
				cells: cells,
				maxWidth: cells.map(\.terminalWidth).reduce(showsHeader ? fieldSpec.label.terminalWidth : 0, Swift::max),
				justification: fieldSpec.justification,
			)
		}
		guard !columns.isEmpty else {
			return ""
		}
		let columnSpacing = tableConfig.columnSpacing
		let columnMetadata = columns.map { (maxWidth: $0.maxWidth, justification: $0.justification) }
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
					: repeatedPattern(
						separator.pattern,
						toWidth: // swiftformat:disable:next indent
							columnMetadata.map(\.maxWidth).reduce(0, +) + columnSpacing.terminalWidth * (columnMetadata.count - 1),
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
	/// each item's rows, with an item separator line (iff any) between each pair
	/// of adjacent items, filled to the width of the widest row of any item.
	func keyValue(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder, keyValueConfig: KeyValueConfig)
	throws(FormattingError) -> String {
		let itemRows = try map { object throws(FormattingError) in
			try object.keyValueRows(
				fieldSpecs: fieldOrder.itemFieldSpecs(fieldSpecs, for: object),
				keyValueConfig: keyValueConfig,
			)
		}
		return itemRows
			.lazy
			.map { $0.map(\.row).joined(separator: "\n") }
			.joined(
				separator: keyValueConfig.itemSeparatorPattern.map { itemSeparatorPattern in
					"\n\(repeatedPattern(itemSeparatorPattern, toWidth: itemRows.joined().map(\.width).max() ?? 0))\n"
				}
					?? "\n",
			)
	}

	/// This item list's JSON output: 1 `JSON.Object` per item, per
	/// `--fields`-resolved field specs ordered per item by `fieldOrder`,
	/// structured & rendered per `jsonConfig` (json.md): each item as a top-level
	/// JSON value, or every item in a single top-level JSON array, each top-level
	/// JSON value on its own line(s).
	func json(fieldSpecs: [FieldSpec], fieldOrder: FieldOrder, jsonConfig: JSONConfig) throws(FormattingError)
	-> String {
		let nodes = try map { object throws(FormattingError) in
			JSON.Node.object(try object.jsonObject(fieldSpecs: fieldOrder.itemFieldSpecs(fieldSpecs, for: object)))
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

/// Justifies & joins 1 `table` row (header, separator, or data): each column's
/// cell to its own width, gapped by `columnSpacing` applied as a literal suffix
/// after each non-last column, never baked into a column's own justify width,
/// since that only produces a real trailing gap for `.start` justification
/// (`.end` / `.centerStart` / `.centerEnd` would place some or all of it as
/// leading / split padding instead, eliminating or shrinking the visible gap).
/// The last column is padded only if it is not `.start`-justified (matching
/// every other column), since nothing follows it to gap from.
private func renderedTableRow(
	cells: [String],
	columns: [(maxWidth: Int, justification: Justification)],
	columnSpacing: String,
) -> String {
	guard let lastCell = cells.last, let lastColumn = columns.last else {
		return ""
	}
	return zip(cells.dropLast(), columns.dropLast())
		.map { cell, column in cell.terminalJustify(column.justification, to: column.maxWidth) + columnSpacing }
		.joined()
		+ (lastColumn.justification == .start
			? lastCell
			: lastCell.terminalJustify(lastColumn.justification, to: lastColumn.maxWidth))
}

/// Repeats `pattern` to fill `targetWidth`, truncating mid-repetition (never
/// padding) if `pattern`'s width does not evenly divide `targetWidth` (table.md
/// & key-value.md: a separator line's or leader's repetition cuts off
/// immediately, even mid-character-group, rather than rounding to a whole
/// number of repetitions). Returns a 0-width `pattern` (e.g., a tab) once,
/// since no number of repetitions can fill any width.
private func repeatedPattern(_ pattern: String, toWidth targetWidth: Int) -> String {
	guard pattern.terminalWidth > 0 else {
		return pattern
	}
	let patternCharacters = Array(pattern)
	var result = ""
	var width = 0
	var index = 0
	while width < targetWidth {
		let character = patternCharacters[index % patternCharacters.count]
		result.append(character)
		width += String(character).terminalWidth
		index += 1
	}
	return result
}

extension JSON.Node {
	/// This node's JSON text per `jsonConfig` (json.md): compact or
	/// pretty-printed, with non-ASCII characters verbatim or escaped.
	func rendered(jsonConfig: JSONConfig) -> String {
		let text = jsonConfig.indentation.map { prettyPrinted(indentation: $0, depth: 0) } ?? description
		return switch jsonConfig.nonASCIIRendering {
		case .escaped:
			text.unicodeScalars.reduce(into: "") { result, scalar in
				result += scalar.isASCII
					? String(scalar)
					: String(scalar)
						.utf16
						.map { codeUnit in
							let hexDigits = String(codeUnit, radix: 16)
							return "\\u\(String(repeating: "0", count: 4 - hexDigits.count))\(hexDigits)"
						}
						.joined()
			}
		case .verbatim:
			text
		}
	}

	/// This node's pretty-printed JSON text, at nesting level `depth`: each
	/// non-empty object's members & each non-empty array's elements on their own
	/// lines, indented by `indentation` per nesting level, with 1 space after
	/// each `:` between a key & its value.
	private func prettyPrinted(indentation: String, depth: Int) -> String {
		let memberIndentation = String(repeating: indentation, count: depth + 1)
		let closingIndentation = String(repeating: indentation, count: depth)
		return switch self {
		case let .array(array) where !array.elements.isEmpty:
			"[\n"
				+ array.elements
				.map { memberIndentation + $0.prettyPrinted(indentation: indentation, depth: depth + 1) }
				.joined(separator: ",\n")
				+ "\n\(closingIndentation)]"
		case let .object(object) where !object.fields.isEmpty:
			"{\n"
				+ object.fields
				.map { key, value in
					"\(memberIndentation)\(Self.string(key.rawValue)): "
						+ value.prettyPrinted(indentation: indentation, depth: depth + 1)
				}
				.joined(separator: ",\n")
				+ "\n\(closingIndentation)}"
		default:
			description
		}
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
