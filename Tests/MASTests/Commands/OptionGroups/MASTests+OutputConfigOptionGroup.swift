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
		("--fields=", "--fields=\0"),
		("--fields=name", "--fields=\0name"),
		("--json-config=", "--json-config=\0"),
		("--key-value-config=s", "--key-value-config=\0s"),
		("--table-config=S", "--table-config=\0S"),
	])
	func `normalizing prefixes a value after = with a NUL`(option: String, normalized: String) {
		#expect(normalizingOutputOptions(in: [option, "1"]) == [normalized, "1"])
	}

	@Test
	func `normalizing retains other options`() {
		#expect(normalizingOutputOptions(in: ["--json", "1", "--fields", "name"]) == ["--json", "1", "--fields", "name"])
	}

	@Test
	func `normalizing removes every output format flag & option that a later one overrides`() {
		#expect(
			normalizingOutputOptions(in: ["--json-config", "P", "1", "--table", "--key-value-config=s", "--json"])
				== ["1", "--json"],
		)
	}

	@Test
	func `normalizing removes an overridden option's next argument iff Swift Argument Parser takes it as a value`() {
		#expect(normalizingOutputOptions(in: ["--json-config", "-", "--table"]) == ["--table"])
		#expect(normalizingOutputOptions(in: ["--json-config", "--fields", "name", "--table"]) == [
			"--json-config",
			"--fields",
			"name",
			"--table",
		])
	}

	@Test(arguments: [["--json-config", "--table"], ["--json-config"], ["--json=P", "--table"]])
	func `normalizing retains an invalid output format flag or option`(arguments: [String]) {
		#expect(normalizingOutputOptions(in: arguments) == arguments)
	}

	@Test
	func `normalizing retains every argument after a -- terminator`() {
		#expect(normalizingOutputOptions(in: ["--json", "--", "--table"]) == ["--json", "--", "--table"])
	}

	@Test(arguments: [["--fields=-x", "1"], ["--fields", "-", "1"]])
	func `an option takes a value that starts with - only after = or as -`(arguments: [String]) throws {
		_ = try MAS.Lookup.parse(normalizingOutputOptions(in: arguments))
	}

	@Test
	func `an option never takes a next argument that starts with - as its value`() {
		#expect(throws: (any Error).self) { try MAS.Lookup.parse(normalizingOutputOptions(in: ["--fields", "-x", "1"])) }
	}

	@Test
	func `no option or argument uses a parsing strategy that could take another option as its value`() {
		let parsingStrategySet = Set(
			MAS._dumpHelp().matches(of: /"parsingStrategy" *: *"(\w+)"/).map { String($0.output.1) },
		)
		#expect(parsingStrategySet == ["default"])
	}

	@Test(arguments: [
		"[--json]",
		"[--json-config <json-config>]",
		"[--key-value]",
		"[--key-value-config <key-value-config>]",
		"[--table]",
		"[--table-config <table-config>]",
		"[--fields <fields-config>]",
	])
	func `help shows each output option's usage`(usage: String) {
		#expect(MAS.Lookup.helpMessage(columns: 1000).contains(usage))
	}
}
