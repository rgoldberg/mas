//
// MASTests+Preset.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import BigInt
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			(".bundleID%%end", ParsingError.invalidPresetName("")),
			(".bundleID%end%", .invalidPresetName("")),
			(".bundleID%a b", .invalidPresetName("a b")),
			(".bundleID%+-end", .invalidPresetName("-end")),
			(".bundleID%-bytes", .unknownPreset("bytes")),
			(".bundleID%bytes", .unknownPreset("bytes")),
			(".bundleID%endJustify", .unknownPreset("endJustify")),
			("bundleID%End", .unknownPreset("End")),
		],
	)
	func `reports an invalid or unknown preset`(value: String, error: ParsingError) {
		#expect(throws: error) { try parseFieldSpecs(value) }
	}

	@Test(arguments: [".bundleID%end%-start", ".bundleID%+end%start"])
	func `reports mixed absolute & relative presets`(value: String) {
		#expect(throws: ParsingError.mixedAbsoluteAndRelativePresets) { try parseFieldSpecs(value) }
	}

	@Test(
		arguments: [
			("@all", ["default"]),
			("@all.bundleID%", []),
			("@all.bundleID %end % start", ["end", "start"]),
			("@all.bundleID%end%start%end", ["start", "end"]),
			("@all.bundleID%+end", ["default", "end"]),
			("@all.bundleID%-default%+end", ["end"]),
			("@all.bundleID%-end", ["default"]),
			("@all.bundleID%start%end,bundleID%+start", ["end", "start"]),
			("@all.bundleID%end,bundleID=ID", ["end"]),
			("@all.+bundleID%+end", ["default", "end"]),
			("@none.+foo", ["default"]),
			("@none.+foo%+end", ["default", "end"]),
			("foo%end", ["end"]),
		],
	)
	func `a preset-modifier replaces or edits the attached presets, which are otherwise retained`(
		value: String,
		presetNames: [String],
	) throws {
		#expect(try parseFieldSpecs(value).first { $0.name == "bundleID" || $0.name == "foo" }?.presetNames == presetNames)
	}

	@Test
	func `a field name must escape a preset-prefix`() throws {
		let specs = try parseFieldSpecs("@all.+a\\%b")
		#expect(specs[0].name == "a%b")
	}
}

private func parseFieldSpecs(_ value: String) throws(ParsingError) -> [FieldSpec] {
	try resolvedFieldsConfig(from: value, standard: standardFixture, all: allFixture, outputFormat: .table(.default))
		.fieldSpecs
}

private let adamIDFieldSpec = FieldSpec(
	name: "adamID",
	label: "adamID",
	format: .default(fieldName: "adamID"),
	sortSpec: .init(priority: 1000, isEnabled: true, optionSet: .default),
)
private let bundleIDFieldSpec =
	FieldSpec(name: "bundleID", label: "bundleID", format: .default(fieldName: "bundleID"), sortSpec: nil)

private let standardFixture = SelectedFieldsConfig(fieldSpecs: [adamIDFieldSpec])
private let allFixture = BaseIncludesAllFieldsConfig(fieldSpecs: [adamIDFieldSpec, bundleIDFieldSpec])
