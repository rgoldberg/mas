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
	@Option(name: .customLong("fields"), help: "Select, order, label & format output fields & sort items (fields.md)")
	private var fieldsOptionValue = ""

	/// Resolves `jsonOptionValue` / `keyValueOptionValue` / `tableOptionValue`
	/// into a single `OutputFormat`, falling back to `Config.defaultFormat` iff
	/// none was given. Re-derived (cheaply: each option value is tiny) on every
	/// access, same as `fieldsOptionValue`, rather than stored, so there is only
	/// 1 source of truth to validate.
	private var outputFormat: OutputFormat {
		get throws {
			let json = try jsonOptionValue.map(optionalOptionValue).map(parseJSONConfig)
			let keyValue = try keyValueOptionValue.map(optionalOptionValue).map(parseKeyValueConfig)
			let table = try tableOptionValue.map(optionalOptionValue).map(parseTableConfig)
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

/// The output options whose option value is optional.
private let optionalValueOutputOptionNameSet: Set = ["--json", "--key-value", "--table"]

/// Prefixes each optional output option value in a normalized command line, so
/// that the value is never empty, because Swift Argument Parser takes an empty
/// value after `=` (e.g., `--json=`) as no value, then takes the next
/// command-line argument as the value. No command-line argument can contain a
/// NUL, so the prefix never starts an actual value.
private let optionalOptionValuePrefix = "\0"

/// `arguments`, with each output option whose option value is optional, before
/// any `--` terminator, given its value after `=` (or an empty value, absent
/// one), prefixed with `optionalOptionValuePrefix` (e.g., `--json` becomes
/// `--json=\0` & `--json=P` becomes `--json=\0P`), so that such an option value
/// is only ever the rest of its option's command-line argument after `=`, never
/// the next command-line argument (configs.md "Option Values").
func normalizingOutputOptions(in arguments: some Sequence<String>) -> [String] {
	let arguments = Array(arguments)
	let terminatorIndex = arguments.firstIndex(of: "--") ?? arguments.endIndex
	return arguments[..<terminatorIndex].map { argument in
		let parts = argument.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
		return optionalValueOutputOptionNameSet.contains(String(parts[0]))
			? "\(parts[0])=\(optionalOptionValuePrefix)\(parts.dropFirst().first ?? "")"
			: argument
	}
		+ arguments[terminatorIndex...]
}

/// `value` without any `optionalOptionValuePrefix`.
private func optionalOptionValue(_ value: String) -> String {
	.init(value.trimmingPrefix(optionalOptionValuePrefix))
}
