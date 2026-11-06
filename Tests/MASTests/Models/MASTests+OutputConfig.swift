//
// MASTests+OutputConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests { // swiftlint:disable:this file_types_order
	@Test(
		arguments: [
			(OutputFormat.table(.default), "1\n3\n"),
			(.keyValue(.default), "a ▁ 1\n\na ▁ 3\n"),
			(.json(.default), "{\"a\":1}\n{\"a\":3}\n"),
		],
	)
	func `an item error omits only its item`(outputFormat: OutputFormat, stdout: String) async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[.init([("a", .number(1))]), .init([("a", .string("x"))]), .init([("a", .number(3))])],
				outputFormat: outputFormat,
				fieldsOptionValue: "a:.round",
			),
		)
		#expect(actual == Consequences(nil, stdout, itemErrorMessage))
	}

	@Test
	func `an item error in an output sort key is reported once & omits its item`() async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[.init([("a", .number(3))]), .init([("a", .string("x"))]), .init([("a", .number(1))])],
				outputFormat: .table(.default),
				fieldsOptionValue: "a:.round/O",
			),
		)
		#expect(actual == Consequences(nil, "1\n3\n", itemErrorMessage))
	}

	@Test
	func `an item error in a hidden output sort key omits its item`() async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[.init([("a", .number(1)), ("b", .number(2))]), .init([("a", .string("x")), ("b", .number(4))])],
				outputFormat: .table(.default),
				fieldsOptionValue: "@none.+b,_a:.round/O",
			),
		)
		#expect(actual == Consequences(nil, "2\n", itemErrorMessage))
	}

	@Test(
		arguments: [
			(JSON.Object([("a", .number(1)), ("b", .string("x"))]), "@none.+a,_b:.round"),
			(.init([("a", .number(1)), ("b", .string("x"))]), "@none.+a,_b:.round/I"),
			(.init([("a", .string("x")), ("a", .number(1))]), "a:.round"),
		],
	)
	func `a format that is not evaluated has no item error`(item: JSON.Object, fieldsOptionValue: String) async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[item],
				outputFormat: .table(.default),
				fieldsOptionValue: fieldsOptionValue,
			),
		)
		#expect(actual == Consequences(nil, "1\n"))
	}

	@Test
	func `only an item's 1st item error is reported`() async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[.init([("a", .string("x")), ("b", .string("y"))])],
				outputFormat: .table(.default),
				fieldsOptionValue: "a:.round,b:.round",
			),
		)
		#expect(actual == Consequences(nil, "", itemErrorMessage))
	}

	@Test
	func `an item with an item error adds no column for its unlisted fields`() async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[.init([("a", .string("x")), ("b", .number(2))]), .init([("a", .number(1))])],
				outputFormat: .table(.default),
				fieldsOptionValue: "@all.a:.round",
			),
		)
		#expect(actual == Consequences(nil, "1\n", itemErrorMessage))
	}

	@Test(
		arguments: [
			(OutputFormat.table(.default), ""),
			(.keyValue(.default), ""),
			(.json(.default), ""),
			(.json(try parseJSONConfig("a")), "[]\n"),
		],
	)
	func `only item errors output as 0 items do`(outputFormat: OutputFormat, stdout: String) async throws {
		let actual = try await consequencesOf(
			try ItemErrorOutputConfig.output(
				[.init([("a", .string("x"))])],
				outputFormat: outputFormat,
				fieldsOptionValue: "a:.round",
			),
		)
		#expect(actual == Consequences(nil, stdout, itemErrorMessage))
	}
}

private let itemErrorMessage = "Error: Transform round requires an input of its input type: x\n"

private struct ItemErrorOutputConfig: OutputConfig {
	static let defaultFormat = OutputFormat.table(.default)
	static let standardFieldsConfig = SelectedFieldsConfig()
	static let allFieldsConfig = BaseIncludesAllFieldsConfig()
}
