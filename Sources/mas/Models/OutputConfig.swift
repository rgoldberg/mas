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
		// Each item without an item error in a sort key's value, with those values
		let sortableItems = objects.compactMap { object in
			reportingItemError { () throws(FormattingError) in
				(
					object: object,
					sortValues: try resolved.itemSort.keys.map { key throws(FormattingError) in
						try key.fieldSpec.sortValues(
							input: object[lastNodeKey: .init(rawValue: key.fieldSpec.name)],
							source: key.sortSpec.optionSet.source,
						)
					},
				)
			}
		}
		let sortedObjects = resolved.itemSort
			.sortedIndices(count: sortableItems.count) { index, keyIndex in sortableItems[index].sortValues[keyIndex] }
			.map { sortableItems[$0].object }
		// An item with an item error is as if not in the input, so the field specs
		// are resolved again, for only the items that remain
		let sortedFieldSpecs = resolved.displayFieldSpecs(for: sortedObjects)
		let outputObjects = sortedObjects.filter { object in
			reportingItemError { () throws(FormattingError) in
				try resolved.renderMembers(of: object, fieldSpecs: sortedFieldSpecs, outputFormat: outputFormat)
			} != nil
		}
		let displayFieldSpecs = resolved.displayFieldSpecs(for: outputObjects)
		switch outputFormat {
		case let .json(jsonConfig):
			// json.md: an item array renders `[]` for 0 items; an item stream renders
			// nothing
			if !outputObjects.isEmpty || jsonConfig.topLevelStructure == .itemArray {
				MAS.printer.info(
					try outputObjects.json(
						fieldSpecs: displayFieldSpecs,
						fieldOrder: resolved.fieldOrder,
						jsonConfig: jsonConfig,
					),
				)
			}
		case let .keyValue(keyValueConfig):
			// Nothing is output iff no item has a row
			if
				let keyValue = try outputObjects.keyValue(
					fieldSpecs: displayFieldSpecs,
					fieldOrder: resolved.fieldOrder,
					keyValueConfig: keyValueConfig,
				)
			{
				MAS.printer.info(keyValue)
			}
		case let .table(tableConfig):
			// Nothing is output iff no field spec is visible
			if let table = try outputObjects.table(fieldSpecs: displayFieldSpecs, tableConfig: tableConfig) {
				MAS.printer.info(table)
			}
		}
	}
}

private extension FieldsConfig { // swiftlint:disable:this file_types_order
	/// The visible field specs, in field order, given `objects`' unlisted fields.
	func displayFieldSpecs(for objects: [JSON.Object]) -> [FieldSpec] {
		fieldOrder.applied(to: fieldSpecs, unlisted: unlistedFieldSpecs(in: objects)).filter { !$0.isHidden }
	}

	/// Renders each of `object`'s members that `outputFormat` outputs, which
	/// throws `object`'s 1st item error, if any: the last member of each field
	/// for table output (fields.md "Members"), else every member.
	func renderMembers(of object: JSON.Object, fieldSpecs: [FieldSpec], outputFormat: OutputFormat)
	throws(FormattingError) {
		let members =
			if case .table = outputFormat {
				fieldSpecs.map { fieldSpec in
					(fieldSpec: fieldSpec, value: object[lastNodeKey: .init(rawValue: fieldSpec.name)])
				}
			} else {
				fieldOrder.itemMembers(fieldSpecs, for: object)
			}
		for member in members {
			_ = try member.fieldSpec.rendered(value: member.value)
		}
	}
}

/// `body`'s value, else `nil` after reporting its item error (configs.md
/// "Output Formats").
private func reportingItemError<Value>(_ body: () throws(FormattingError) -> Value) -> Value? {
	do {
		return try body()
	} catch {
		MAS.printer.error(error: error)
		return nil
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
