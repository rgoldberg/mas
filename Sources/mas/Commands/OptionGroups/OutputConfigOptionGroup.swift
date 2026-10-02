//
// OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
internal import JSONAST

struct OutputConfigOptionGroup<Config: OutputConfig>: ParsableArguments {
	@Option(
		name: .customLong("json"),
		defaultAsFlag: "",
		parsing: .next,
		help: "Output format: JSON, optionally configuring pretty-printing, an item array & non-ASCII escaping (json.md)",
	)
	private var jsonOptionValue: String?
	@Option(
		name: .customLong("key-value"),
		defaultAsFlag: "",
		parsing: .next,
		help: "Output format: key-value, optionally configuring keys, leaders, spacing & item separators (key-value.md)",
	)
	private var keyValueOptionValue: String?
	@Option(
		name: .customLong("table"),
		defaultAsFlag: "",
		parsing: .next,
		help: "Output format: table, optionally configuring headers, a separator line & column spacing (table.md)",
	)
	private var tableOptionValue: String?
	@Option(name: .customLong("fields"), help: "Select, order, label, format & sort output fields")
	private var fieldsOptionValue = ""

	/// Resolves `jsonOptionValue` / `keyValueOptionValue` / `tableOptionValue`
	/// into a single `OutputFormat`, falling back to `Config.defaultFormat` iff
	/// none was given. Re-derived (cheaply: each option value is tiny) on every
	/// access, same as `fieldsOptionValue`, rather than stored, so there's only 1
	/// source of truth to validate.
	private var outputFormat: OutputFormat {
		get throws {
			let json = try jsonOptionValue.map(parseJSONConfig)
			let keyValue = try keyValueOptionValue.map(parseKeyValueConfig)
			let table = try tableOptionValue.map(parseTableConfig)
			guard [json != nil, keyValue != nil, table != nil].count(where: \.self) <= 1 else {
				throw ValidationError("At most 1 of '--json', '--key-value', or '--table' may be given.")
			}
			return if let json {
				.json(json)
			} else if let keyValue {
				.keyValue(keyValue)
			} else if let table {
				.table(table)
			} else {
				Config.defaultFormat
			}
		}
	}

	/// The field names that must be fetched for `fieldsOptionValue` to be fully
	/// resolvable: empty means "fetch everything". Computed eagerly (& validated)
	/// in `validate()`, then re-derived (cheaply, `fieldsOptionValue` is tiny) by
	/// callers that need it before fetching data.
	func fetchFieldNames() throws -> [String] {
		try mas::fetchFieldNames(
			for: fieldsOptionValue,
			standard: Config.standardFieldsConfig,
			all: Config.allFieldsConfig,
			outputFormat: try outputFormat,
			fieldNameSet: Config.fieldNameSet,
		)
	}

	mutating func validate() throws {
		_ = try outputFormat
		_ = try fetchFieldNames()
	}

	func output(_ objects: [JSON.Object]) throws {
		try Config.output(objects, outputFormat: outputFormat, fieldsOptionValue: fieldsOptionValue)
	}
}
