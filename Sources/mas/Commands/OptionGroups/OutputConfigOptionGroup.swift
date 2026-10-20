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
		help: .init(
			"""
			Output format: JSON, optionally configuring (only after =) pretty-printing, an item array & non-ASCII escaping \
			(json.md)
			""",
			valueName: "json-config",
		),
	)
	private var jsonOptionValue: String?
	@Option(
		name: .customLong("key-value"),
		defaultAsFlag: "",
		parsing: .next,
		help: .init(
			"""
			Output format: key-value, optionally configuring (only after =) keys, leaders, spacing & item separators \
			(key-value.md)
			""",
			valueName: "key-value-config",
		),
	)
	private var keyValueOptionValue: String?
	@Option(
		name: .customLong("table"),
		defaultAsFlag: "",
		parsing: .next,
		help: .init(
			"""
			Output format: table, optionally configuring (only after =) headers, a separator line & column spacing \
			(table.md)
			""",
			valueName: "table-config",
		),
	)
	private var tableOptionValue: String?
	@Option(
		name: .customLong("fields"),
		help: .init("Select, order, label & format output fields & sort items (fields.md)", valueName: "fields-config"),
	)
	private var fieldsOptionValue = ""

	/// Resolves `jsonOptionValue` / `keyValueOptionValue` / `tableOptionValue`
	/// into a single `OutputFormat`, falling back to `Config.defaultFormat` iff
	/// none was given (`normalizingOutputOptions(in:)` leaves at most 1, the last
	/// one given). Re-derived (cheaply: each option value is tiny) on every
	/// access, same as `fieldsOptionValue`, rather than stored, so there is only
	/// 1 source of truth to validate.
	private var outputFormat: OutputFormat {
		get throws {
			let json = try jsonOptionValue.map(attachedOptionValue).map(parseJSONConfig)
			let keyValue = try keyValueOptionValue.map(attachedOptionValue).map(parseKeyValueConfig)
			let table = try tableOptionValue.map(attachedOptionValue).map(parseTableConfig)
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
			for: attachedOptionValue(fieldsOptionValue),
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
		try Config.output(objects, outputFormat: outputFormat, fieldsOptionValue: attachedOptionValue(fieldsOptionValue))
	}
}

/// The output options whose option value is optional.
private let optionalValueOutputOptionNameSet: Set = ["--json", "--key-value", "--table"]

/// The output option whose option value is required.
private let fieldsOptionName = "--fields"

// swiftlint:disable:next todo
// TODO: Temp/todo.md "Swift Argument Parser Empty Values": once a Swift
// Argument Parser release includes apple/swift-argument-parser#961, remove
// `attachedOptionValuePrefix` & `attachedOptionValue(_:)`, so that
// `normalizingOutputOptions(in:)` still keeps only the last optional-value
// output option, but gives it its value after `=` unprefixed (e.g., `--json`
// becomes `--json=`) & leaves a `--fields` value as is

// swiftlint:disable:next todo
// TODO: Temp/todo.md "Swift Argument Parser Attached-Only Values": once a Swift
// Argument Parser release resolves apple/swift-argument-parser#992, parse each
// optional-value output option with its attached-only strategy, so that
// `normalizingOutputOptions(in:)` stops giving a bare one a value after `=`

/// Prefixes each output option value after `=` in a normalized command line, so
/// that the value is never empty, because Swift Argument Parser takes an empty
/// value after `=` (e.g., `--json=`) as no value, then takes the next
/// command-line argument as the value. No command-line argument can contain a
/// NUL, so the prefix never starts an actual value.
private let attachedOptionValuePrefix = "\0"

/// `arguments` with only the last output option whose option value is optional
/// before any `--` terminator, because it overrides the preceding ones
/// (configs.md "Output Formats"). The last one is given its value after `=` (or
/// an empty value, absent one), prefixed with `attachedOptionValuePrefix`
/// (e.g., `--json` becomes `--json=\0` & `--json=P` becomes `--json=\0P`), so
/// that such an option value is only ever the rest of its option's command-line
/// argument after `=`, never the next command-line argument (configs.md "Option
/// Values"). A `--fields` value after `=` is likewise prefixed (e.g.,
/// `--fields=` becomes `--fields=\0`).
func normalizingOutputOptions(in arguments: some Sequence<String>) -> [String] {
	let arguments = Array(arguments)
	let terminatorIndex = arguments.firstIndex(of: "--") ?? arguments.endIndex
	let options = arguments[..<terminatorIndex]
	let lastOutputOptionIndex = options.lastIndex { optionalValueOutputOptionNameSet.contains(optionName(of: $0)) }
	return options.indices.compactMap { index in
		let option = options[index]
		let name = optionName(of: option)
		return if optionalValueOutputOptionNameSet.contains(name) {
			index == lastOutputOptionIndex ? "\(name)=\(attachedOptionValuePrefix)\(option.dropFirst(name.count + 1))" : nil
		} else if name == fieldsOptionName, option.count > name.count {
			"\(name)=\(attachedOptionValuePrefix)\(option.dropFirst(name.count + 1))"
		} else {
			option
		}
	}
		+ arguments[terminatorIndex...]
}

/// `argument`'s option name: its text before any `=`.
private func optionName(of argument: String) -> String {
	.init(argument.prefix { $0 != "=" })
}

/// `value` without any `attachedOptionValuePrefix`.
private func attachedOptionValue(_ value: String) -> String {
	.init(value.trimmingPrefix(attachedOptionValuePrefix))
}
