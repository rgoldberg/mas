//
// OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
internal import JSONAST

struct OutputConfigOptionGroup<Config: OutputConfig>: ParsableArguments {
	@Flag(help: "Output format")
	private var outputFormat = Config.defaultFormat
	@Option(name: .customLong("fields"), help: "Select, order, label, format, & sort output fields")
	private var fieldsOptionValue = ""

	/// The field names that must be fetched for `fieldsOptionValue` to be fully
	/// resolvable: empty means "fetch everything". Computed eagerly (& validated)
	/// in `validate()`, then re-derived (cheaply, `fieldsOptionValue` is tiny) by
	/// callers that need it before fetching data.
	func fetchFieldNames() throws -> [String] {
		try mas::fetchFieldNames(
			for: fieldsOptionValue,
			standard: Config.standardFieldsConfig,
			all: Config.allFieldsConfig,
			outputFormat: outputFormat,
		)
	}

	mutating func validate() throws {
		_ = try fetchFieldNames()
	}

	func output(_ objects: [JSON.Object]) throws {
		try Config.output(objects, outputFormat: outputFormat, fieldsOptionValue: fieldsOptionValue)
	}
}
