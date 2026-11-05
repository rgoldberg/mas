//
// MASTests+TableConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: ["", " \t"])
	func `an empty or whitespace-only --table-config value parses to all defaults`(value: String) throws {
		#expect(try parseTableConfig(value) == .default)
	}

	@Test
	func `h & s explicitly turn off a header / separator that would otherwise be implied`() throws {
		#expect(try parseTableConfig("h").header == nil)
		#expect(try parseTableConfig("s").separator == nil)
		// Explicit off overrides an implied alternative, regardless of order
		#expect(try parseTableConfig("bh").header == nil)
		#expect(try parseTableConfig("hb").header == nil)
	}

	@Test
	func `an uppercase H shows a header, plain by default, styled with an explicit style specifier`() throws {
		#expect(
			try parseTableConfig("H")
				== .init(
					header: .init(styleSpecifier: ""),
					styling: .terminalOnly,
					styleSequences: .default,
					separator: nil,
					columnSpacing: "  ",
				),
		)
		#expect(
			try parseTableConfig("H1")
				== .init(
					header: .init(styleSpecifier: "1"),
					styling: .terminalOnly,
					styleSequences: .default,
					separator: nil,
					columnSpacing: "  ",
				),
		)
		#expect(try parseTableConfig("H1;4:").header == .init(styleSpecifier: "1;4"))
		#expect(try parseTableConfig("H\\b").header == .init(styleSpecifier: "b"))
	}

	@Test
	func `an omitted trailing setting terminator is only valid at the end of the value`() throws {
		// "H1" (no ':', end of value): fine, value is "1"
		#expect(try parseTableConfig("H1").header == .init(styleSpecifier: "1"))
		// "H1S-" (no ':' before 'S'): "1S-" is swallowed whole as H's own value &
		// fails style specifier validation (a bare ASCII letter), rather than
		// silently treating 'S' as a 2nd setting
		#expect(throws: TableConfigParsingError.invalidHeaderStyleSpecifier("1S-")) { try parseTableConfig("H1S-") }
	}

	@Test(arguments: [("S", "-"), ("S:", "-"), ("S-+:", "-+")])
	func `an uppercase S shows a separator, dashed by default, with an explicit pattern otherwise`(
		value: String,
		pattern: String,
	) throws {
		#expect(try parseTableConfig(value).separator == .init(pattern: pattern, broken: false))
	}

	@Test(
		arguments: [
			("H1:", Styling.terminalOnly),
			("H1:a", .always),
			("aH1:t", .terminalOnly),
		],
	)
	func `t & a set header styling, last wins`(value: String, styling: Styling) throws {
		#expect(try parseTableConfig(value).styling == styling)
	}

	@Test(
		arguments: [
			("", StyleSequences.default),
			("P<:X>:O</>:", .init(prefix: "<", suffix: ">", reset: "</>")),
			("P:X:O", .init(prefix: "", suffix: "", reset: "")),
			("P < :X\\::", .init(prefix: " < ", suffix: ":", reset: "\u{1B}[0m")),
			("P<:X>:O</>:pxo", .default),
			("pxoP<:X>:O</>:", .init(prefix: "<", suffix: ">", reset: "</>")),
		],
	)
	func `header style sequences: P, X & O set literal ones, including empty; p, x & o restore defaults; last wins`(
		value: String,
		styleSequences: StyleSequences,
	) throws {
		#expect(try parseTableConfig(value).styleSequences == styleSequences)
	}

	@Test(arguments: ["\t", "-\t", "\t\u{301}=", "\n", "-\r\n-", "\u{85}", "\u{2028}"])
	func `a separator pattern may contain a tab or a line terminator`(pattern: String) throws {
		#expect(try parseTableConfig("S\(pattern):").separator?.pattern == pattern)
	}

	@Test(arguments: ["\n", " \r\n ", "\u{85}", "\u{2029}"])
	func `a column spacing may contain a line terminator`(spacing: String) throws {
		#expect(try parseTableConfig("C\(spacing):").columnSpacing == spacing)
	}

	@Test
	func `a header style specifier or sequence may contain a line terminator`() throws {
		#expect(try parseTableConfig("H1\n2:").header?.styleSpecifier == "1\n2")
		#expect(
			try parseTableConfig("P\u{2028}:X\r:O\r\n:").styleSequences
				== .init(prefix: "\u{2028}", suffix: "\r", reset: "\r\n"),
		)
	}

	@Test
	func `a backslash escapes the next character in a setting's text`() throws {
		#expect(try parseTableConfig("S\\::").separator?.pattern == ":")
		#expect(try parseTableConfig("C\\\\:").columnSpacing == "\\")
		#expect(try parseTableConfig("C \\: :").columnSpacing == " : ")
		#expect(throws: TableConfigParsingError.danglingEscape) { try parseTableConfig("S-\\") }
	}

	@Test(arguments: [(" h s ", "hs"), ("H 1;4 : S", "H1;4:S"), ("H :", "H"), ("H : a", "H:a")])
	func `outer bare whitespace between settings & around a style specifier is ignored`(
		value: String,
		equivalent: String,
	) throws {
		#expect(try parseTableConfig(value) == parseTableConfig(equivalent))
	}

	@Test
	func `an uppercase S implies a header iff none was already set`() throws {
		#expect(try parseTableConfig("S").header == .init(styleSpecifier: ""))
		// `S`'s own value-scan needs its own terminator before `H1:` starts, else
		// it swallows "H1" as its own (literal) pattern text instead
		#expect(try parseTableConfig("S:H1:")
			.header == .init(styleSpecifier: "1")) // explicit header wins over the implied 1
		#expect(try parseTableConfig("S:h").header == nil) // explicit "off" wins over the implied header, too
	}

	@Test(arguments: ["S:h", "S=:h", "hS", "hb", "bh"])
	func `a separator line is shown only with a header row`(value: String) throws {
		#expect(try parseTableConfig(value).separator == nil)
	}

	@Test
	func `b & u each imply a dashed separator (not blank) iff none was already set & set broken-ness`() throws {
		let broken = try parseTableConfig("b")
		#expect(broken.separator == .init(pattern: "-", broken: true))
		#expect(broken.header == .init(styleSpecifier: "")) // transitively implied, via the implied separator
		let unbroken = try parseTableConfig("u")
		#expect(unbroken.separator == .init(pattern: "-", broken: false))
		// An explicit separator pattern is kept; only broken-ness & (if unset)
		// header come from b / u
		#expect(try parseTableConfig("S=:b").separator == .init(pattern: "=", broken: true))
	}

	@Test
	func `last one wins per setting, ad hoc order`() throws {
		#expect(try parseTableConfig("bu").separator?.broken == false)
		#expect(try parseTableConfig("ub").separator?.broken == true)
		#expect(try parseTableConfig("H1:H2:").header == .init(styleSpecifier: "2"))
	}

	@Test(arguments: [("c", "  "), ("C:", ""), ("C....:", "...."), ("C\t", "\t")])
	func `c resets column spacing to the built-in default; C sets a literal custom value, including empty`(
		value: String,
		columnSpacing: String,
	) throws {
		#expect(try parseTableConfig(value).columnSpacing == columnSpacing)
	}

	@Test(
		arguments: [
			("Hbogus:", TableConfigParsingError.invalidHeaderStyleSpecifier("bogus")),
			("Hb", .invalidHeaderStyleSpecifier("b")),
			("z", .invalidSetting("z")),
			("H1\\", .danglingEscape),
		],
	)
	func `an invalid header style specifier, unknown setting, or dangling escape is a parse error`(
		value: String,
		error: TableConfigParsingError,
	) throws {
		#expect(throws: error) { try parseTableConfig(value) }
	}

	@Test
	func `table renders no header or separator by default, matching pre-existing behavior`() throws {
		let table = try [JSON.Object([("name", .string("Slack"))])]
			.table(
				fieldSpecs: [.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)],
				tableConfig: .default,
			)
		#expect(table == "Slack")
	}

	@Test
	func `table outputs nothing without any field spec, even with a header row`() throws {
		let objects = [JSON.Object([("name", .string("Slack"))])]
		#expect(try objects.table(fieldSpecs: [], tableConfig: parseTableConfig("S")) == nil)
	}

	@Test
	func `table renders an absent value as an empty string, unless its format renders it otherwise`() throws {
		let table = try [JSON.Object([("a", .string("1"))])]
			.table(
				fieldSpecs: [
					.init(name: "a", label: "a", format: .default(fieldName: "a"), sortSpec: nil),
					.init(name: "b", label: "b", format: .default(fieldName: "b"), sortSpec: nil),
					.init(
						name: "c",
						label: "c",
						format: .template(
							[
								.placeholder(
									.conditional(
										.init(predicate: .number, coercion: nil),
										.binary(
											success: .template([.blockPlaceholder(pipeline: .init())]),
											failure: .template([.text("none")]),
										),
									),
								),
							],
						),
						sortSpec: nil,
					),
				],
				tableConfig: .default,
			)
		#expect(table == "1    none")
	}

	@Test
	func `table renders a header row when configured`() throws {
		let table = try [JSON.Object([("name", .string("Slack"))])]
			.table(
				fieldSpecs: [.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)],
				tableConfig: try parseTableConfig("H"),
			)
		#expect(table == "Name\nSlack")
	}

	@Test
	func `table renders a header row styled with a given style specifier`() throws {
		let table = try [JSON.Object([("name", .string("Slack"))])]
			.table(
				fieldSpecs: [.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)],
				tableConfig: try parseTableConfig("H1:a"),
			)
		#expect(table == "\u{1B}[1mName\u{1B}[0m\nSlack")
	}

	@Test
	func `table renders a header row styled with custom style sequences`() throws {
		let table = try [JSON.Object([("name", .string("Slack"))])]
			.table(
				fieldSpecs: [.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)],
				tableConfig: try parseTableConfig("H1:P<:X>:O</>:a"),
			)
		#expect(table == "<1>Name</>\nSlack")
	}

	@Test
	func `table renders a blank separator line as an empty row, distinct from no separator at all`() throws {
		let table = try [JSON.Object([("name", .string("Slack"))])]
			.table(
				fieldSpecs: [.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)],
				tableConfig: try parseTableConfig("S\\ :"),
			)
		#expect(table == "Name\n     \nSlack")
	}

	@Test
	func `table styles a header row for a non-terminal only with always-styling`() throws {
		let fieldSpecs = [FieldSpec(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)]
		let objects = [JSON.Object([("name", .string("Slack"))])]
		let alwaysStyled = try objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("H1:a"))
		#expect(alwaysStyled == "\u{1B}[1mName\u{1B}[0m\nSlack")
		let terminalOnly = try objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("H1:t"))
		#expect(terminalOnly == (FileHandle.standardOutput.isTerminal ? alwaysStyled : "Name\nSlack"))
	}

	@Test
	func `table renders an unbroken separator spanning the whole table width, truncating mid-pattern`() throws {
		let table = try [JSON.Object([("name", .string("A")), ("version", .string("1.0"))])]
			.table(
				fieldSpecs: [
					.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
				],
				tableConfig: try parseTableConfig("S-+:"),
			)
		// Total width: "Name" (4) + "  " (2) + "Version" (7) = 13; "-+" repeated &
		// cut off mid-pair
		#expect(table == "Name  Version\n-+-+-+-+-+-+-\nA     1.0")
	}

	@Test
	func `table renders each line terminator in a header or data cell as a return symbol`() throws {
		let table = try [JSON.Object([("notes", .string("a\r\nb\\nc\u{2028}d"))])]
			.table(
				fieldSpecs: [.init(name: "notes", label: "No\ntes", format: .default(fieldName: "notes"), sortSpec: nil)],
				tableConfig: try parseTableConfig("S"),
			)
		#expect(table == "No⏎tes\n--------\na⏎b\\nc⏎d")
	}

	@Test
	func `table renders each other control character in a cell as Control Pictures symbols`() throws {
		let table = try [JSON.Object([("notes", .string("a\tb\u{1B}[1mc\u{7F}\u{0}d\u{85}e\u{9B}2Jf\u{80}"))])]
			.table(
				fieldSpecs: [.init(name: "notes", label: "N\to", format: .default(fieldName: "notes"), sortSpec: nil)],
				tableConfig: try parseTableConfig("H"),
			)
		#expect(table == "N␉o\na␉b␛[1mc␡␀d⏎e␛[2Jf␛@")
	}

	@Test
	func `table renders no separator line without a header row`() throws {
		let table = try [JSON.Object([("name", .string("A")), ("version", .string("1.0"))])]
			.table(
				fieldSpecs: [
					.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
				],
				tableConfig: try parseTableConfig("hS"),
			)
		#expect(table == "A  1.0")
	}

	@Test
	func `table renders a broken separator as 1 independently-filled segment per column`() throws {
		let table = try [JSON.Object([("name", .string("A")), ("version", .string("1.0"))])]
			.table(
				fieldSpecs: [
					.init(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
					.init(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
				],
				tableConfig: try parseTableConfig("S-+:b"),
			)
		#expect(table == "Name  Version\n-+-+  -+-+-+-\nA     1.0")
	}

	@Test
	func `table uses a custom column-spacing string`() throws {
		let table = try [JSON.Object([("a", .string("1")), ("b", .string("2"))])]
			.table(
				fieldSpecs: [
					.init(name: "a", label: "a", format: .default(fieldName: "a"), sortSpec: nil),
					.init(name: "b", label: "b", format: .default(fieldName: "b"), sortSpec: nil),
				],
				tableConfig: try parseTableConfig("C....:"),
			)
		#expect(table == "1....2")
	}
}
