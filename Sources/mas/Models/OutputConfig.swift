//
// OutputConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST

/// A display command's `--fields` configuration: its `standard` fields
/// (selected, static; the `standardFieldsConfig` associated type varies per
/// command since some commands' `standard` is itself all-inclusive, e.g.,
/// `config`'s) & its `all` fields (a field spec per listed field; every other
/// field of an item is unlisted, see fields.md's "Unlisted Fields" &
/// `FieldsConfig.unlistedFieldSpecs(in:)`).
protocol OutputConfig {
	associatedtype Standard: FieldsConfig

	static var defaultFormat: OutputFormat { get }
	static var standardFieldsConfig: Standard { get }
	static var allFieldsConfig: BaseIncludesAllFieldsConfig { get }
	/// Every field that may exist in any item, iff determinable up front (see
	/// fields.md's "Nonexistent Fields"), else `nil`.
	static var fieldNameSet: Set<String>? { get } // swiftlint:disable:this discouraged_optional_collection
}

extension OutputConfig { // swiftlint:disable:this file_types_order
	static var fieldNameSet: Set<String>? { // swiftlint:disable:this discouraged_optional_collection
		nil
	}
}

extension OutputConfig { // swiftlint:disable:this file_types_order
	static func output(_ objects: [JSON.Object], outputFormat: OutputFormat, fieldsOptionValue: String)
	throws(OutputError) {
		guard !objects.isEmpty else {
			// json.md: an item array renders `[]` for 0 items; every other output
			// renders nothing
			if case let .json(jsonConfig) = outputFormat, jsonConfig.topLevelStructure == .itemArray {
				MAS.printer.info("[]")
			}
			return
		}
		let resolved: any FieldsConfig
		do {
			resolved = try resolvedFieldsConfig(
				from: fieldsOptionValue,
				standard: standardFieldsConfig,
				all: allFieldsConfig,
				outputFormat: outputFormat,
				fieldNameSet: fieldNameSet,
			)
		} catch {
			throw .parsing(error)
		}
		do {
			try output(objects, resolved: resolved, outputFormat: outputFormat)
		} catch {
			throw .formatting(error)
		}
	}

	private static func output(_ objects: [JSON.Object], resolved: any FieldsConfig, outputFormat: OutputFormat)
	throws(FormattingError) {
		// Each sort key's values, per item
		let sortValues = try resolved.itemSort.keys.map { key throws(FormattingError) in
			try objects.map { object throws(FormattingError) in
				try key.fieldSpec.sortValues(
					input: object[lastNodeKey: .init(rawValue: key.fieldSpec.name)],
					source: key.sortSpec.optionSet.source,
				)
			}
		}
		let sortedObjects = resolved.itemSort
			.sortedIndices(count: objects.count) { index, keyIndex in sortValues[keyIndex][index] }
			.map { objects[$0] }
		let displayFieldSpecs = resolved.fieldOrder
			.applied(to: resolved.fieldSpecs, unlisted: resolved.unlistedFieldSpecs(in: objects))
			.filter { !$0.isHidden }
		switch outputFormat {
		case let .json(jsonConfig):
			MAS.printer.info(
				try sortedObjects.json(fieldSpecs: displayFieldSpecs, fieldOrder: resolved.fieldOrder, jsonConfig: jsonConfig),
			)
		case let .keyValue(keyValueConfig):
			// Nothing is output iff no item has a row
			if
				let keyValue = try sortedObjects.keyValue(
					fieldSpecs: displayFieldSpecs,
					fieldOrder: resolved.fieldOrder,
					keyValueConfig: keyValueConfig,
				)
			{
				MAS.printer.info(keyValue)
			}
		case let .table(tableConfig):
			// Nothing is output iff no field spec is visible
			if let table = try sortedObjects.table(fieldSpecs: displayFieldSpecs, tableConfig: tableConfig) {
				MAS.printer.info(table)
			}
		}
	}
}

/// An error reported while outputting items per `--fields`.
enum OutputError: Error, CustomStringConvertible { // swiftlint:disable:this one_declaration_per_file
	case formatting(FormattingError)
	case parsing(ParsingError)

	var description: String {
		switch self {
		case let .formatting(error):
			error.description
		case let .parsing(error):
			error.description
		}
	}
}
