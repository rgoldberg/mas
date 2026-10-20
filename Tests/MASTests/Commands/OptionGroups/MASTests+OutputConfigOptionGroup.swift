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
	@Test(arguments: [("--json", "--json=\0"), ("--key-value=", "--key-value=\0"), ("--table=P", "--table=\0P")])
	func `normalizing gives an optional-value output option its value after = with a NUL prefix`(
		option: String,
		normalized: String,
	) {
		#expect(normalizingOutputOptions(in: [option, "1"]) == [normalized, "1"])
	}

	@Test
	func `normalizing retains other options`() {
		#expect(
			normalizingOutputOptions(in: ["--json", "1", "--fields", "name"]) == ["--json=\0", "1", "--fields", "name"],
		)
	}

	@Test(arguments: [("--fields=", "--fields=\0"), ("--fields=name", "--fields=\0name")])
	func `normalizing prefixes a --fields value after = with a NUL`(option: String, normalized: String) {
		#expect(normalizingOutputOptions(in: [option, "1"]) == [normalized, "1"])
	}

	@Test
	func `normalizing removes every output option that a later one overrides`() {
		#expect(
			normalizingOutputOptions(in: ["--json=P", "1", "--table", "--json=a"]) == ["1", "--json=\0a"],
		)
	}

	@Test
	func `normalizing retains every argument after a -- terminator`() {
		#expect(normalizingOutputOptions(in: ["--json", "--", "--table"]) == ["--json=\0", "--", "--table"])
	}

	@Test(arguments: [
		"--json [<json-config>]",
		"--key-value [<key-value-config>]",
		"--table [<table-config>]",
		"--fields <fields-config>",
	])
	func `help names each output option value by its config`(usage: String) {
		#expect(MAS.Lookup.helpMessage().contains(usage))
	}

	@Test(arguments: ["JSON", "key-value", "table"])
	func `help says that an optional output option value is only after =`(outputFormat: String) {
		#expect(
			MAS.Lookup.helpMessage(columns: 1000)
				.contains("Output format: \(outputFormat), optionally configuring (only after =)"),
		)
	}
}
