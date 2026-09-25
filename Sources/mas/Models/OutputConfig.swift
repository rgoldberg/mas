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
}

extension OutputConfig { // swiftlint:disable:this file_types_order
	static func output(_ objects: [JSON.Object], outputFormat: OutputFormat, fieldsOptionValue: String)
	throws(OutputError) {
		guard !objects.isEmpty else {
			return
		}
		let resolved: any FieldsConfig
		do {
			resolved = try resolvedFieldsConfig(
				from: fieldsOptionValue,
				standard: standardFieldsConfig,
				all: allFieldsConfig.mergingDynamicFields(from: objects),
				outputFormat: outputFormat,
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
		let orderedFieldSpecs = resolved.fieldOrder.applied(to: resolved.fieldSpecs)
		// Duplicate field names (e.g., the same field inserted twice with different
		// formats) share 1 entry here; a sort key on such a name uses whichever of
		// those field specs' formats happens to win, a rare enough scenario that
		// it isn't worth carrying a format alongside each `ItemSortKey` to
		// disambiguate
		let fieldSpecByName = Dictionary(orderedFieldSpecs.map { ($0.name, $0) }) { first, _ in first }
		let sortValuesByName = try Dictionary(
			resolved.itemSort.keys.map { key throws(FormattingError) in
				(
					key.name,
					try objects.map { object throws(FormattingError) in
						let input = object[nodeKey: .init(rawValue: key.name)]
						let fieldSpec = fieldSpecByName[key.name]
						return SortValues(
							input: input,
							output: SortOptionSet.anyHasOutputSource(key.sortSpec.optionSets)
								? try fieldSpec?.format.rendered(value: input, label: fieldSpec?.label ?? "", name: key.name)
								: nil,
						)
					},
				)
			},
		) { first, _ in first }
		let sortedObjects = resolved.itemSort
			.sortedIndices(count: objects.count) { index, key in
				sortValuesByName[key.name]?[index] ?? .init(input: nil, output: nil)
			}
			.map { objects[$0] }
		let displayFieldSpecs = orderedFieldSpecs.filter { !$0.isHidden }
		switch outputFormat {
		case .json:
			MAS.printer.info(
				try sortedObjects.jsonObjects(fieldSpecs: displayFieldSpecs, fieldOrder: resolved.fieldOrder) as [Any],
				separator: "\n",
			)
		case .keyValue:
			MAS.printer.info(try sortedObjects.keyValue(fieldSpecs: displayFieldSpecs, fieldOrder: resolved.fieldOrder))
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
	/// across `objects` not already named in `fieldSpecs`, in first-seen order
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
