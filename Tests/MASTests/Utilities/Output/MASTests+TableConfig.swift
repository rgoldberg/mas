//
// MASTests+TableConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `an empty --table value parses to all defaults`() throws {
		#expect(try parseTableConfig("") == .default)
	}

	@Test
	func `h & s explicitly turn off a header / separator that would otherwise be implied`() throws {
		#expect(try parseTableConfig("h").header == nil)
		#expect(try parseTableConfig("s").separator == nil)
		// Explicit off wins over an otherwise-implied default, regardless of order
		#expect(try parseTableConfig("bh").header == nil)
		#expect(try parseTableConfig("hb").header == nil)
	}

	@Test
	func `an uppercase H shows a header, plain by default, styled with an explicit SGR parameter list`() throws {
		#expect(try parseTableConfig("H") == .init(header: .init(sgrCodes: ""), separator: nil, columnSpacing: "  "))
		#expect(try parseTableConfig("H1") == .init(header: .init(sgrCodes: "1"), separator: nil, columnSpacing: "  "))
		#expect(
			try parseTableConfig("H1;4:").header
				== .init(sgrCodes: "1;4"),
		)
	}

	@Test
	func `an omitted trailing table-value terminator is only valid at the end of the value`() throws {
		// "H1" (no ':', end of value): fine, value is "1"
		#expect(try parseTableConfig("H1").header == .init(sgrCodes: "1"))
		// "H1S-" (no ':' before 'S'): "1S-" is swallowed whole as H's own value & fails
		// SGR validation, rather than silently treating 'S' as a 2nd option
		#expect(throws: TableConfigParsingError.invalidHeaderStyle("1S-")) {
			try parseTableConfig("H1S-")
		}
	}

	@Test
	func `an uppercase S shows a separator, blank by default, with an explicit pattern otherwise`() throws {
		#expect(try parseTableConfig("S").separator == .init(pattern: "", broken: false))
		#expect(try parseTableConfig("S-+:").separator == .init(pattern: "-+", broken: false))
	}

	@Test
	func `an uppercase S implies a header iff none was already set`() throws {
		#expect(try parseTableConfig("S").header == .init(sgrCodes: ""))
		// `S`'s own value-scan needs its own terminator before `H1:` starts, else
		// it swallows "H1" as its own (literal) pattern text instead
		#expect(try parseTableConfig("S:H1:").header == .init(sgrCodes: "1")) // explicit header wins over the implied 1
		#expect(try parseTableConfig("S:h").header == nil) // explicit "off" wins over the implied header too
	}

	@Test
	func `b & u each imply a dashed separator (not blank) iff none was already set, & set broken-ness`() throws {
		let broken = try parseTableConfig("b")
		#expect(broken.separator == .init(pattern: "-", broken: true))
		#expect(broken.header == .init(sgrCodes: "")) // transitively implied, via the implied separator
		let unbroken = try parseTableConfig("u")
		#expect(unbroken.separator == .init(pattern: "-", broken: false))
		// An explicit separator pattern is kept; only broken-ness & (if unset) header come from b / u
		#expect(try parseTableConfig("S=:b").separator == .init(pattern: "=", broken: true))
	}

	@Test
	func `last one wins per axis, ad hoc order`() throws {
		#expect(try parseTableConfig("bu").separator?.broken == false)
		#expect(try parseTableConfig("ub").separator?.broken == true)
		#expect(try parseTableConfig("H1:H2:").header == .init(sgrCodes: "2"))
	}

	@Test
	func `c resets column spacing to the built-in default; C sets a literal custom value, including empty`() throws {
		#expect(try parseTableConfig("c").columnSpacing == "  ")
		#expect(try parseTableConfig("C:").columnSpacing.isEmpty)
		#expect(try parseTableConfig("C....:").columnSpacing == "....")
		#expect(try parseTableConfig("C\t").columnSpacing == "\t")
	}

	@Test
	func `an invalid header style or unknown option is a parse error`() throws {
		#expect(throws: TableConfigParsingError.invalidHeaderStyle("bogus")) {
			try parseTableConfig("Hbogus:")
		}
		#expect(throws: TableConfigParsingError.invalidHeaderStyle(";1")) {
			try parseTableConfig("H;1:")
		}
		#expect(throws: TableConfigParsingError.invalidOption("z")) {
			try parseTableConfig("z")
		}
	}

	@Test
	func `table renders no header or separator by default, matching pre-existing behavior`() {
		let objects: [JSON.Object] = [["name": .string("Slack")]]
		let fieldSpecs = [FieldSpec(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)]
		#expect(objects.table(fieldSpecs: fieldSpecs, tableConfig: .default) == "Slack")
	}

	@Test
	func `table renders a header row when configured, styled with SGR codes when given`() throws {
		let objects: [JSON.Object] = [["name": .string("Slack")]]
		let fieldSpecs = [FieldSpec(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)]
		// A lone column is always padded to the column's own width (matching
		// every other row), so "Name" (width 4) gets 1 trailing space to match
		// "Slack" (width 5).
		#expect(
			objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("H"))
				== "Name \nSlack",
		)
		#expect(
			objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("H1:"))
				== "\u{1B}[1mName \u{1B}[0m\nSlack",
		)
	}

	@Test
	func `table renders a blank separator line as an empty row, distinct from no separator at all`() throws {
		let objects: [JSON.Object] = [["name": .string("Slack")]]
		let fieldSpecs = [FieldSpec(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil)]
		#expect(objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("S")) == "Name \n\nSlack")
	}

	@Test
	func `table renders an unbroken separator spanning the whole table width, truncating mid-pattern`() throws {
		let objects: [JSON.Object] = [["name": .string("A"), "version": .string("1.0")]]
		let fieldSpecs = [
			FieldSpec(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
			FieldSpec(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
		]
		// Total width: "Name" (4) + "  " (2) + "Version" (7) = 13; "-+" repeated & cut off mid-pair
		#expect(
			objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("S-+:"))
				== "Name  Version\n-+-+-+-+-+-+-\nA     1.0",
		)
	}

	@Test
	func `table renders a broken separator as 1 independently-filled segment per column`() throws {
		let objects: [JSON.Object] = [["name": .string("A"), "version": .string("1.0")]]
		let fieldSpecs = [
			FieldSpec(name: "name", label: "Name", format: .default(fieldName: "name"), sortSpec: nil),
			FieldSpec(name: "version", label: "Version", format: .default(fieldName: "version"), sortSpec: nil),
		]
		#expect(
			objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("S-+:b"))
				== "Name  Version\n-+-+  -+-+-+-\nA     1.0",
		)
	}

	@Test
	func `table uses a custom column-spacing string`() throws {
		let objects: [JSON.Object] = [["a": .string("1"), "b": .string("2")]]
		let fieldSpecs = [
			FieldSpec(name: "a", label: "a", format: .default(fieldName: "a"), sortSpec: nil),
			FieldSpec(name: "b", label: "b", format: .default(fieldName: "b"), sortSpec: nil),
		]
		#expect(objects.table(fieldSpecs: fieldSpecs, tableConfig: try parseTableConfig("C....:")) == "1....2")
	}
}
