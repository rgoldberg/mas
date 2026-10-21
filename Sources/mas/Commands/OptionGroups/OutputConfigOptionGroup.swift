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
	private var isJSON = false
	@Option(
		name: .customLong("json-config"),
		help: .init(
			"Output format: JSON, configuring pretty-printing, an item array & non-ASCII escaping (json.md)",
			valueName: "json-config",
		),
	)
	private var jsonConfigOptionValue: String?
	@Flag(name: .customLong("key-value"), help: "Output format: key-value (key-value.md)")
	private var isKeyValue = false
	@Option(
		name: .customLong("key-value-config"),
		help: .init(
			"Output format: key-value, configuring keys, leaders, spacing & item separators (key-value.md)",
			valueName: "key-value-config",
		),
	)
	private var keyValueConfigOptionValue: String?
	@Flag(name: .customLong("table"), help: "Output format: table (table.md)")
	private var isTable = false
	@Option(
		name: .customLong("table-config"),
		help: .init(
			"Output format: table, configuring headers, a separator line & column spacing (table.md)",
			valueName: "table-config",
		),
	)
	private var tableConfigOptionValue: String?
	@Option(
		name: .customLong("fields"),
		help: .init("Select, order, label & format output fields & sort items (fields.md)", valueName: "fields-config"),
	)
	private var fieldsOptionValue = ""

	/// Resolves the output format flags & options into a single `OutputFormat`,
	/// falling back to `Config.defaultFormat` iff none was given
	/// (`normalizingOutputOptions(in:)` leaves at most 1, the last one given). A
	/// flag is equivalent to its option with an empty value. Re-derived (cheaply:
	/// each option value is tiny) on every access, same as `fieldsOptionValue`,
	/// rather than stored, so there is only 1 source of truth to validate.
	private var outputFormat: OutputFormat {
		get throws {
			let json = try outputConfigOptionValue(jsonConfigOptionValue, isFlagged: isJSON).map(parseJSONConfig)
			let keyValue =
				try outputConfigOptionValue(keyValueConfigOptionValue, isFlagged: isKeyValue).map(parseKeyValueConfig)
			let table = try outputConfigOptionValue(tableConfigOptionValue, isFlagged: isTable).map(parseTableConfig)
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

/// The flags that each select an output format with its `default` config.
private let outputFormatFlagNameSet: Set = ["--json", "--key-value", "--table"]

/// The options that each select an output format with a config.
private let outputFormatOptionNameSet: Set = ["--json-config", "--key-value-config", "--table-config"]

/// The options whose value after `=` is prefixed with
/// `attachedOptionValuePrefix`.
private let prefixedOptionNameSet = outputFormatOptionNameSet.union(["--fields"])

// swiftlint:disable:next todo
// TODO: Temp/todo.md "Swift Argument Parser Empty Values": once a Swift
// Argument Parser release includes apple/swift-argument-parser#961, remove
// `prefixedOptionNameSet`, `attachedOptionValuePrefix` &
// `attachedOptionValue(_:)`, so that `normalizingOutputOptions(in:)` only
// removes every output format flag / option that a later one overrides

// swiftlint:disable:next todo
// TODO: Temp/todo.md "Swift Argument Parser Attached-Only Values": once a Swift
// Argument Parser release resolves apple/swift-argument-parser#992, replace
// each output format's flag & option (e.g., `--json` & `--json-config`) with 1
// option whose optional value is accepted only after `=` (e.g.,
// `--json[=<json-config>]`)

/// Prefixes each `prefixedOptionNameSet` option value after `=` in a normalized
/// command line, so that the value is never empty, because Swift Argument
/// Parser takes an empty value after `=` (e.g., `--fields=`) as no value, then
/// takes the next command-line argument as the value. No command-line argument
/// can contain a NUL, so the prefix never starts an actual value.
private let attachedOptionValuePrefix = "\0"

/// `arguments` with only the last output format flag / option before any `--`
/// terminator, because it overrides the preceding ones (configs.md "Output
/// Formats"), and with each `prefixedOptionNameSet` option value after `=`
/// prefixed with `attachedOptionValuePrefix` (e.g., `--fields=` becomes
/// `--fields=\0`).
///
/// An overridden option is removed with its value, iff that value is the next
/// command-line argument. An option whose next command-line argument is not a
/// value is retained, so that Swift Argument Parser reports its missing value.
/// Every removed command-line argument is an output format flag / option, never
/// another option's value, because no mas option or argument uses a parsing
/// strategy that takes a command-line argument starting with `-` as a value, or
/// that skips ahead for a value.
func normalizingOutputOptions(in arguments: some Sequence<String>) -> [String] {
	let arguments = Array(arguments)
	let terminatorIndex = arguments.firstIndex(of: "--") ?? arguments.endIndex
	let options = arguments[..<terminatorIndex]
	let outputFormatIndexRanges = options.indices.compactMap { index -> Range<Int>? in
		let option = options[index]
		return if
			outputFormatFlagNameSet.contains(option)
			|| option.contains("=") && outputFormatOptionNameSet.contains(optionName(of: option))
		{
			index..<(index + 1)
		} else if outputFormatOptionNameSet.contains(option), index + 1 < options.endIndex, isValue(options[index + 1]) {
			index..<(index + 2)
		} else {
			nil
		}
	}
	let overriddenIndexSet = Set(outputFormatIndexRanges.dropLast().joined())
	return options.indices.compactMap { index in
		let option = options[index]
		let name = optionName(of: option)
		return if overriddenIndexSet.contains(index) {
			nil
		} else if prefixedOptionNameSet.contains(name), option.count > name.count {
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

/// Whether Swift Argument Parser takes `argument` as a value, rather than as an
/// option or a terminator.
private func isValue(_ argument: String) -> Bool {
	argument == "-" || !argument.hasPrefix("-")
}

/// `value` without any `attachedOptionValuePrefix`.
private func attachedOptionValue(_ value: String) -> String {
	.init(value.trimmingPrefix(attachedOptionValuePrefix))
}

/// The value of an output format option, without any
/// `attachedOptionValuePrefix`, else an empty value iff its flag was given,
/// else `nil`.
private func outputConfigOptionValue(_ optionValue: String?, isFlagged: Bool) -> String? {
	optionValue.map(attachedOptionValue) ?? (isFlagged ? "" : nil)
}
