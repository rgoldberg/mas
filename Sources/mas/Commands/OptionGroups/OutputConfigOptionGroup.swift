//
// OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
internal import JSONAST

struct OutputConfigOptionGroup<Config: OutputConfig>: ParsableArguments {
	@Flag(name: .customLong("json"), help: "Output format: JSON")
	private var isJSON = false
	@Flag(name: .customLong("key-value"), help: "Output format: key-value")
	private var isKeyValue = false
	@Option(
		name: .customLong("table"),
		defaultAsFlag: "",
		parsing: .next,
		help: "Output format: table, optionally configuring headers, a separator line, & column spacing (table.md)",
	)
	private var tableOptionValue: String?
	@Option(name: .customLong("fields"), help: "Select, order, label, format, & sort output fields")
	private var fieldsOptionValue = ""

	/// Resolves `isJSON` / `isKeyValue` / `tableOptionValue` into a single
	/// `OutputFormat`, falling back to `Config.defaultFormat` iff none was
	/// given. Re-derived (cheaply: `tableOptionValue` is tiny) on every access,
	/// same as `fieldsOptionValue`, rather than stored, so there's only 1
	/// source of truth to validate.
	private var outputFormat: OutputFormat {
		get throws {
			let table = try tableOptionValue.map(parseTableConfig)
			guard [isJSON, isKeyValue, table != nil].count(where: \.self) <= 1 else {
				throw ValidationError("At most 1 of '--json', '--key-value', or '--table' may be given.")
			}
			return if isJSON {
				.json
			} else if isKeyValue {
				.keyValue
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
