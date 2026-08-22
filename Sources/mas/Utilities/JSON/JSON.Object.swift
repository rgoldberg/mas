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

	subscript(key: JSON.Key) -> JSON.OptionalDecoder<JSON.Key> {
		.init(key: key, value: self[nodeKey: key])
	}

	subscript(key: JSON.Key) -> JSON.FieldDecoder<JSON.Key>? {
		self[nodeKey: key].map { .init(key: key, value: $0) }
	}

	func keyValue(keys: some Sequence<JSON.Key>) -> String {
		keyValue(fieldConfigs: keys.map { ($0, $0.rawValue, defaultTransform(_:)) })
	}

	func keyValue(fieldConfigs: some Sequence<(key: JSON.Key, label: String, transform: @Sendable (String?) -> String)>)
	-> String {
		guard !isEmpty else {
			return ""
		}
		let data = fieldConfigs.reduce(
			into: (
				fieldConfigAndLabelWidths: [(key: JSON.Key, label: String, labelWidth: Int, transform: (String?) -> String)](
					reservedCapacity: fieldConfigs.underestimatedCount,
				),
				maxLabelWidth: 0,
			),
		) { data, fieldConfig in
			let labelWidth = fieldConfig.label.terminalWidth
			data.maxLabelWidth = Swift::max(data.maxLabelWidth, labelWidth)
			data.fieldConfigAndLabelWidths.append((fieldConfig.key, fieldConfig.label, labelWidth, fieldConfig.transform))
		}
		return data.fieldConfigAndLabelWidths
			.map { key, label, labelWidth, transform in
				"""
				\(label) \
				\(String(repeating: "▁", count: data.maxLabelWidth - labelWidth + 1)) \
				\(transform(self[nodeKey: key]?.stringValue))
				"""
			}
			.joined(separator: "\n")
	}
}

extension [JSON.Object] {
	func keyValue(keys: some Sequence<JSON.Key>) -> String {
		map { $0.keyValue(keys: keys) }.joined(separator: "\n\n")
	}

	func keyValue(fieldConfigs: some Sequence<(key: JSON.Key, label: String, transform: @Sendable (String?) -> String)>)
	-> String {
		map { $0.keyValue(fieldConfigs: fieldConfigs) }.joined(separator: "\n\n")
	}

	func table(keys: some Sequence<JSON.Key>) -> String {
		guard !isEmpty else {
			return ""
		}
		let columns = keys.map { key in
			reduce(into: (cells: [String](reservedCapacity: count), maxWidth: 0)) { column, object in
				column.cells.append(
					object[key].value.map { node in
						let cell = node.stringValue ?? ""
						column.maxWidth = Swift::max(column.maxWidth, cell.terminalWidth)
						return cell
					}
						?? "",
				)
			}
		}
		guard let firstColumn = columns.first else {
			return ""
		}
		let trailingColumns = columns.dropFirst()
		guard let lastColumn = trailingColumns.last else {
			return (0..<count)
				.map { index in
					firstColumn.cells[index].terminalJustify(.end, to: firstColumn.maxWidth)
				}
				.joined(separator: "\n")
		}
		let middleColumns = trailingColumns.dropLast()
		return (0..<count)
			.map { index in
				firstColumn.cells[index].terminalJustify(.end, to: firstColumn.maxWidth)
					+ "  "
					+ middleColumns.map { $0.cells[index].terminalJustify(to: $0.maxWidth + 2) }.joined()
					+ lastColumn.cells[index]
			}
			.joined(separator: "\n")
	}
}

private extension JSON.Node {
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

func defaultTransform(_ value: String?) -> String {
	value ?? ""
}
