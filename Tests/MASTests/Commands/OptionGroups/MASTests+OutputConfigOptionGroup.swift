//
// MASTests+OutputConfigOptionGroup.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import ArgumentParser
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: [
		["--json", "--json"],
		["--json-config", "P", "--json-config", "P"],
		["--json", "--json-config", "P"],
		["--json-config", "P", "--table"],
		["--table", "--key-value-config", "s"],
		["--key-value", "--table-config=S"],
	])
	func `more than 1 output format flag or option is an error`(arguments: [String]) {
		#expect(throws: (any Error).self) { try MAS.Lookup.parse(arguments + ["1"]) }
	}

	@Test
	func `more than 1 --fields is an error`() {
		#expect(throws: (any Error).self) { try MAS.Lookup.parse(["--fields", "name", "--fields", "name", "1"]) }
	}

	@Test(arguments: [
		["--json"],
		["--json-config", "P"],
		["--key-value"],
		["--key-value-config", "s"],
		["--table"],
		["--table-config", "S"],
		["--table", "--fields", "name"],
	])
	func `a sole output format flag or option is valid`(arguments: [String]) throws {
		_ = try MAS.Lookup.parse(arguments + ["1"])
	}

	@Test(arguments: [["--fields=-x", "1"], ["--fields", "-", "1"]])
	func `an option takes a value that starts with - only after = or as -`(arguments: [String]) throws {
		_ = try MAS.Lookup.parse(arguments)
	}

	@Test
	func `an option never takes a next argument that starts with - as its value`() {
		#expect(throws: (any Error).self) { try MAS.Lookup.parse(["--fields", "-x", "1"]) }
	}

	@Test
	func `an option without a next argument is an error`() {
		#expect(throws: (any Error).self) { try MAS.Lookup.parse(["1", "--fields"]) }
	}

	@Test(arguments: [
		(MAS.Config.helpMessage(columns: 1000), "mas config \(outputConfigUsage)\n"),
		(MAS.List.helpMessage(columns: 1000), "mas list \(outputConfigUsage) [--bundle] [<app-id> ...]\n"),
		(MAS.Lookup.helpMessage(columns: 1000), "mas lookup \(outputConfigUsage) [--bundle] <app-id> ...\n"),
		(MAS.Search.helpMessage(columns: 1000), "mas search \(outputConfigUsage) <search-term> ...\n"),
	])
	func `help shows each display command's output options as mutually exclusive`(helpMessage: String, usage: String) {
		#expect(helpMessage.contains("USAGE: \(usage)"))
	}

	@Test(arguments: [
		MAS.Config.helpMessage(columns: 1000),
		MAS.List.helpMessage(columns: 1000),
		MAS.Lookup.helpMessage(columns: 1000),
		MAS.Outdated.helpMessage(columns: 1000),
		MAS.Search.helpMessage(columns: 1000),
	])
	func `help never shows an output option as repeatable`(helpMessage: String) {
		#expect(!helpMessage.contains(/--(json|key-value|table)(-config <[\w-]+>)? \.\.\.|<fields-config> \.\.\./))
	}
}
