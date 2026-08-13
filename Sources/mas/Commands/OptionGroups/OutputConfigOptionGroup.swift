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
	private(set) var outputFormat = Config.defaultFormat

	var withFullJSON: Bool {
		outputFormat == .json
	}

	func output(_ objects: [JSON.Object]) {
		Config.output(objects, as: outputFormat)
	}
}
