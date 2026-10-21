//
// OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
internal import JSONAST

struct OutputConfigOptionGroup<Config: OutputConfig>: ParsableArguments {
	@Flag(name: .customLong("json"), help: "Output format: JSON (json.md)")
	private var jsonFlagCount: Int
	@Option(
		name: .customLong("json-config"),
		help: .init(
			"Output format: JSON, configuring pretty-printing, an item array & non-ASCII escaping (json.md)",
			valueName: "json-config",
		),
	)
	private var jsonConfigOptionValues = [String]()
	@Flag(name: .customLong("key-value"), help: "Output format: key-value (key-value.md)")
	private var keyValueFlagCount: Int
	@Option(
		name: .customLong("key-value-config"),
		help: .init(
			"Output format: key-value, configuring keys, leaders, spacing & item separators (key-value.md)",
			valueName: "key-value-config",
		),
	)
	private var keyValueConfigOptionValues = [String]()
	@Flag(name: .customLong("table"), help: "Output format: table (table.md)")
	private var tableFlagCount: Int
	@Option(
		name: .customLong("table-config"),
		help: .init(
			"Output format: table, configuring headers, a separator line & column spacing (table.md)",
			valueName: "table-config",
		),
	)
	private var tableConfigOptionValues = [String]()
	@Option(
		name: .customLong("fields"),
		help: .init("Select, order, label & format output fields & sort items (fields.md)", valueName: "fields-config"),
	)
	private var fieldsOptionValues = [String]()

	/// The value of the sole given `--fields`, else an empty value.
	private var fieldsOptionValue: String {
		fieldsOptionValues.first ?? ""
	}

	/// Resolves the sole given output format flag / option (`validate()` reports
	/// an error for more than 1) into a single `OutputFormat`, falling back to
	/// `Config.defaultFormat` iff none was given. A flag is equivalent to its
	/// option with an empty value. Re-derived (cheaply: each option value is
	/// tiny) on every access, same as `fieldsOptionValue`, rather than stored, so
	/// there is only 1 source of truth to validate.
	private var outputFormat: OutputFormat {
		get throws {
			let json = try outputConfigOptionValue(jsonConfigOptionValues, flagCount: jsonFlagCount).map(parseJSONConfig)
			let keyValue = try outputConfigOptionValue(keyValueConfigOptionValues, flagCount: keyValueFlagCount)
				.map(parseKeyValueConfig)
			let table = try outputConfigOptionValue(tableConfigOptionValues, flagCount: tableFlagCount).map(parseTableConfig)
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
		if
			jsonFlagCount + jsonConfigOptionValues.count + keyValueFlagCount + keyValueConfigOptionValues.count
			+ tableFlagCount + tableConfigOptionValues.count > 1
		{
			throw ValidationError(
				"""
				Cannot specify more than 1 of --json, --json-config, --key-value, --key-value-config, --table & \
				--table-config
				""",
			)
		}
		if fieldsOptionValues.count > 1 {
			throw ValidationError("Cannot specify --fields more than once")
		}
		_ = try outputFormat
		_ = try fetchFieldNames()
	}

	func output(_ objects: [JSON.Object]) throws {
		try Config.output(objects, outputFormat: outputFormat, fieldsOptionValue: fieldsOptionValue)
	}
}

/// The usage of `OutputConfigOptionGroup`'s options, for each display command's
/// custom usage, because Swift Argument Parser's generated usage would mark
/// each counted flag & array option as repeatable (e.g., `[--json ...]`).
let outputConfigUsage = """
	[--json | --json-config <json-config> | --key-value | --key-value-config <key-value-config> | --table | \
	--table-config <table-config>] [--fields <fields-config>]
	"""

// swiftlint:disable:next todo
// TODO: Temp/todo.md "Swift Argument Parser Attached-Only Values": once a Swift
// Argument Parser release resolves apple/swift-argument-parser#992, replace
// each output format's flag & option (e.g., `--json` & `--json-config`) with 1
// option whose optional value is accepted only after `=` (e.g.,
// `--json[=<json-config>]`)

/// The value of the sole given output format option, else an empty value iff
/// its flag was given, else `nil`.
private func outputConfigOptionValue(_ optionValues: [String], flagCount: Int) -> String? {
	optionValues.first ?? (flagCount > 0 ? "" : nil)
}
