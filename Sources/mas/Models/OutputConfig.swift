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
/// `config`'s) & its `all` fields (selected entries only; the dynamic field
/// set, for schemaless data sources, is merged in from the actual fetched data
/// at render time, see `mergingDynamicFields(from:)`).
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
				all: allFieldsConfig.mergingDynamicFields(from: objects),
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
				let input = object[nodeKey: .init(rawValue: key.fieldSpec.name)]
				return SortValues(
					input: input,
					output: SortOptionSet.anyHasOutputSource(key.sortSpec.optionSets)
						? try key.fieldSpec.rendered(value: input)
						: nil,
				)
			}
		}
		let sortedObjects = resolved.itemSort
			.sortedIndices(count: objects.count) { index, keyIndex in sortValues[keyIndex][index] }
			.map { objects[$0] }
		let displayFieldSpecs = resolved.fieldOrder.applied(to: resolved.fieldSpecs).filter { !$0.isHidden }
		switch outputFormat {
		case let .json(jsonConfig):
			MAS.printer.info(
				try sortedObjects.json(fieldSpecs: displayFieldSpecs, fieldOrder: resolved.fieldOrder, jsonConfig: jsonConfig),
			)
		case let .keyValue(keyValueConfig):
			MAS.printer.info(
				try sortedObjects.keyValue(
					fieldSpecs: displayFieldSpecs,
					fieldOrder: resolved.fieldOrder,
					keyValueConfig: keyValueConfig,
				),
			)
		case let .table(tableConfig):
			MAS.printer.info(try sortedObjects.table(fieldSpecs: displayFieldSpecs, tableConfig: tableConfig))
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

extension BaseIncludesAllFieldsConfig {
	/// Finishes what `all` means for a schemaless data source: appends a
	/// bare-default `FieldSpec` (label = name, no sort) for every real JSON key
	/// across `objects` not already named in `fieldSpecs`, in 1st-seen order
	/// (each item's own `JSON.Object` is normalized, i.e., renamed, but not
	/// reordered, so this is each object's own original key order).
	func mergingDynamicFields(from objects: [JSON.Object]) -> Self {
		var seenNameSet = Set(fieldSpecs.map(\.name))
		var extra = [FieldSpec]()
		for object in objects {
			for field in object.fields where !seenNameSet.contains(field.key.rawValue) {
				seenNameSet.insert(field.key.rawValue)
				extra.append(
					.init(
						name: field.key.rawValue,
						label: field.key.rawValue,
						format: defaultFieldFormat(forFieldNamed: field.key.rawValue),
						sortSpec: nil,
					),
				)
			}
		}
		return .init(fieldSpecs: fieldSpecs + extra, fieldOrder: fieldOrder, itemSort: itemSort)
	}
}
