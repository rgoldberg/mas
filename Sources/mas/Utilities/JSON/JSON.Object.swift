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
	/// `table`, but driven by `--fields`-resolved field specs: a header row of
	/// labels, then a cell per field per item (fields.md: label is a field spec's
	/// "Header for table"). Every item gets a cell for every field, per
	/// fields.md's "Absent Values" (absent ⇒ empty string, via
	/// `Format.rendered`'s null-passthrough).
	func table(fieldSpecs: some Sequence<FieldSpec>) -> String {
		guard !isEmpty else {
			return ""
		}
		let columns = fieldSpecs.map { fieldSpec in
			reduce(into: (cells: [fieldSpec.label], maxWidth: fieldSpec.label.terminalWidth)) { column, object in
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
		guard let firstColumn = columns.first else {
			return ""
		}
		let trailingColumns = columns.dropFirst()
		guard let lastColumn = trailingColumns.last else {
			return (0...count)
				.map { index in
					firstColumn.cells[index].terminalJustify(.end, to: firstColumn.maxWidth)
				}
				.joined(separator: "\n")
		}
		let middleColumns = trailingColumns.dropLast()
		return (0...count)
			.map { index in
				firstColumn.cells[index].terminalJustify(.end, to: firstColumn.maxWidth)
					+ "  "
					+ middleColumns.map { $0.cells[index].terminalJustify(to: $0.maxWidth + 2) }.joined()
					+ lastColumn.cells[index]
			}
			.joined(separator: "\n")
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

private extension JSON.Node {
	var isNull: Bool {
		if case .null = self {
			true
		} else {
			false
		}
	}
}
