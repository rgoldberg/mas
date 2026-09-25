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
			try fieldSpec.format.rendered(value: node, label: fieldSpec.label, name: fieldSpec.name).stringValue ?? "",
		)
	}

	/// `keyValue`, but driven by `--fields`-resolved field specs (label &
	/// rendered value per field) instead of a static key list.
	func keyValue(fieldSpecs: some Sequence<FieldSpec>) throws(FormattingError) -> String {
		let rows = try fieldSpecs.map { fieldSpec throws(FormattingError) in try keyValueRow(for: fieldSpec) }
			.compactMap(\.self)
		guard !rows.isEmpty else {
			return ""
		}
		let maxLabelWidth = rows.map(\.label.terminalWidth).max() ?? 0
		return rows
			.map { "\($0) \(String(repeating: "▁", count: maxLabelWidth - $0.terminalWidth + 1)) \($1)" }
			.joined(separator: "\n")
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
							try fieldSpec.format.rendered(value: raw, label: fieldSpec.label, name: fieldSpec.name),
						)
					}
				}
				.compactMap(\.self),
		)
	}
}

extension [JSON.Object] {
	/// `table`, but driven by `--fields`-resolved field specs & `tableConfig`
	/// (table.md): an optional header row of labels, an optional separator
	/// line, then a cell per field per item (fields.md: label is a field spec's
	/// "Header for table"). Every item gets a cell for every field, per
	/// fields.md's "Absent Values" (absent ⇒ empty string, via
	/// `Format.rendered`'s null-passthrough).
	func table(fieldSpecs: some Sequence<FieldSpec>, tableConfig: TableConfig) throws(FormattingError) -> String {
		guard !isEmpty else {
			return ""
		}
		let showsHeader = tableConfig.header != nil
		let columns = try fieldSpecs.map { fieldSpec throws(FormattingError) in
			let cells = try map { object throws(FormattingError) in
				try fieldSpec.format
					.rendered(
						value: object[nodeKey: .init(rawValue: fieldSpec.name)],
						label: fieldSpec.label,
						name: fieldSpec.name,
					)
					.stringValue
					?? ""
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
			let isStyled =
				!header.sgrCodes.isEmpty && (tableConfig.headerStyling == .always || FileHandle.standardOutput.isTerminal)
			rows.append(isStyled ? "\u{1B}[\(header.sgrCodes)m\(headerRow)\u{1B}[0m" : headerRow)
		}
		if let separator = tableConfig.separator {
			rows.append(
				separator.broken
					? renderedTableRow(
						cells: columnMetadata.map { repeatedTablePattern(separator.pattern, toWidth: $0.maxWidth) },
						columns: columnMetadata,
						columnSpacing: columnSpacing,
					)
					: repeatedTablePattern(
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

	/// `keyValue`, but driven by `--fields`-resolved field specs.
	func keyValue(fieldSpecs: some Sequence<FieldSpec>) throws(FormattingError) -> String {
		try map { object throws(FormattingError) in try object.keyValue(fieldSpecs: fieldSpecs) }.joined(separator: "\n\n")
	}

	/// This item list's JSON output: 1 `JSON.Object` per item, per
	/// `--fields`-resolved field specs.
	func jsonObjects(fieldSpecs: some Sequence<FieldSpec>) throws(FormattingError) -> [JSON.Object] {
		try map { object throws(FormattingError) in try object.jsonObject(fieldSpecs: fieldSpecs) }
	}
}

/// Justifies & joins 1 `table` row (header, separator, or data): each column's
/// cell to its own width, gapped by `columnSpacing` applied as a literal
/// suffix after each non-last column, never baked into a column's own
/// justify width, since that only produces a real trailing gap for `.start`
/// justification (`.end` / `.centerStart` / `.centerEnd` would place some or
/// all of it as leading / split padding instead, eliminating or shrinking the
/// visible gap). The last column is padded only if it isn't `.start`-justified
/// (matching every other column), since nothing follows it to gap from.
private func renderedTableRow(
	cells: [String],
	columns: [(maxWidth: Int, justification: Justification)],
	columnSpacing: String,
) -> String {
	guard let firstCell = cells.first, let firstColumn = columns.first else {
		return ""
	}
	let trailingCells = cells.dropFirst()
	guard let lastCell = trailingCells.last, let lastColumn = columns.dropFirst().last else {
		return firstCell.terminalJustify(firstColumn.justification, to: firstColumn.maxWidth)
	}
	let middleCells = trailingCells.dropLast()
	let middleColumns = columns.dropFirst().dropLast()
	return firstCell.terminalJustify(firstColumn.justification, to: firstColumn.maxWidth)
		+ columnSpacing
		+ zip(middleCells, middleColumns)
		.map { cell, column in cell.terminalJustify(column.justification, to: column.maxWidth) + columnSpacing }
		.joined()
		+ (lastColumn.justification == .start
			? lastCell
			: lastCell.terminalJustify(lastColumn.justification, to: lastColumn.maxWidth))
}

/// Repeats `pattern` to fill `targetWidth`, truncating mid-repetition (never
/// padding) if `pattern`'s width doesn't evenly divide `targetWidth` (table.md:
/// a separator line's repetition cuts off immediately, even mid-character-
/// group, rather than rounding to a whole number of repetitions).
private func repeatedTablePattern(_ pattern: String, toWidth targetWidth: Int) -> String {
	guard !pattern.isEmpty, targetWidth > 0 else {
		return ""
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

private extension JSON.Node {
	var isNull: Bool {
		if case .null = self {
			true
		} else {
			false
		}
	}
}
