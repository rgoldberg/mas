//
// JSON.Object.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

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
	func keyValueRow(for fieldSpec: FieldSpec) -> (label: String, value: String)? {
		self[nodeKey: .init(rawValue: fieldSpec.name)].flatMap { node in
			node.isNull
				? nil
				: (
					fieldSpec.label,
					fieldSpec.format.rendered(value: node, label: fieldSpec.label, name: fieldSpec.name).stringValue ?? "",
				)
		}
	}

	/// `keyValue`, but driven by `--fields`-resolved field specs (label &
	/// rendered value per field) instead of a static key list.
	func keyValue(fieldSpecs: some Sequence<FieldSpec>) -> String {
		let rows = fieldSpecs.compactMap(keyValueRow(for:))
		guard !rows.isEmpty else {
			return ""
		}
		let maxLabelWidth = rows.map(\.label.terminalWidth).max() ?? 0
		return rows
			.map { label, value in
				"\(label) \(String(repeating: "▁", count: maxLabelWidth - label.terminalWidth + 1)) \(value)"
			}
			.joined(separator: "\n")
	}

	/// This item's JSON output object, per `--fields`-resolved field specs: keyed
	/// by each field's label, omitting a field entirely iff its raw value is
	/// absent (a `null` value, unlike key-value output, is still included).
	func jsonObject(fieldSpecs: some Sequence<FieldSpec>) -> Self {
		.init(
			fieldSpecs.compactMap { fieldSpec in
				self[nodeKey: .init(rawValue: fieldSpec.name)].map { raw in
					(
						.init(rawValue: fieldSpec.label),
						fieldSpec.format.rendered(value: raw, label: fieldSpec.label, name: fieldSpec.name),
					)
				}
			},
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
	func table(fieldSpecs: some Sequence<FieldSpec>, tableConfig: TableConfig) -> String {
		guard !isEmpty else {
			return ""
		}
		let showsHeader = tableConfig.header != nil
		let columns = fieldSpecs.map { fieldSpec in
			reduce(
				into: (
					label: fieldSpec.label,
					cells: [String](),
					maxWidth: showsHeader ? fieldSpec.label.terminalWidth : 0,
					justification: fieldSpec.justification,
				),
			) { column, object in
				let cell = fieldSpec.format
					.rendered(
						value: object[nodeKey: .init(rawValue: fieldSpec.name)],
						label: fieldSpec.label,
						name: fieldSpec.name,
					)
					.stringValue
					?? ""
				column.maxWidth = Swift::max(column.maxWidth, cell.terminalWidth)
				column.cells.append(cell)
			}
		}
		guard !columns.isEmpty else {
			return ""
		}
		let columnSpacing = tableConfig.columnSpacing
		let columnMetadata = columns.map { (maxWidth: $0.maxWidth, justification: $0.justification) }
		var rows = [String]()
		if let header = tableConfig.header {
			let headerRow = renderedTableRow(
				cells: columns.map(\.label),
				columns: columnMetadata,
				columnSpacing: columnSpacing,
			)
			rows.append(header.sgrCodes.isEmpty ? headerRow : "\u{1B}[\(header.sgrCodes)m\(headerRow)\u{1B}[0m")
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
						toWidth: columnMetadata.map(\.maxWidth).reduce(0, +)
							+ columnSpacing.terminalWidth * (columnMetadata.count - 1),
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
	func keyValue(fieldSpecs: some Sequence<FieldSpec>) -> String {
		map { $0.keyValue(fieldSpecs: fieldSpecs) }.joined(separator: "\n\n")
	}

	/// This item list's JSON output: 1 `JSON.Object` per item, per
	/// `--fields`-resolved field specs.
	func jsonObjects(fieldSpecs: some Sequence<FieldSpec>) -> [JSON.Object] {
		map { $0.jsonObject(fieldSpecs: fieldSpecs) }
	}
}

/// Justifies & joins 1 `table` row (header, separator, or data): each column's
/// cell to its own width, gapped by `columnSpacing` applied as a literal
/// suffix after each non-last column — never baked into a column's own
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
