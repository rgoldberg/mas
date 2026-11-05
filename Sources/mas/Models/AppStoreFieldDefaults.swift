//
// AppStoreFieldDefaults.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

// MARK: - mas's own field-name defaults

// The generic `--fields` engine (`Models/FieldsOption/`) has no concept of
// "price" / "version" / "adamID", etc.; only mas's own built-in `standard` /
// `all` fields configs (& fields a user names via `--fields` text) care about
// these specific App Store / Spotlight field names. Keeping that knowledge
// here, rather than in `Models/FieldsOption/`, keeps the generic engine
// reusable independent of mas

private let versionFieldNameSet = Set(["minimumOSVersion", "newVersion", "version"])

/// mas.md's App Store locale: the App Store's own locale cannot be determined
/// programmatically, so the likely locale of the App Store region that mas
/// guesses from the macOS region.
private let appStoreLocale = Locale(identifier: Locale.Language(identifier: "und-\(appStoreRegion)").maximalIdentifier)

/// mas.md's "Default Sort Options" for `outputFormat`: the `path` row iff
/// `fieldName` is `path`, else the `Other` row (also used for sorting field
/// names & labels, for which `fieldName` is `nil`), but comparing versions for
/// a version field & grouped numbers per the App Store locale's conventions
/// plus `a` for `formattedPrice`, per mas.md's "Price Sorting".
func defaultSortOptionSet(forFieldNamed fieldName: String?, outputFormat: OutputFormat) -> SortOptionSet {
	let isPath = fieldName.map(pathFieldNameSet.contains) ?? false
	var optionSet = SortOptionSet.default
	optionSet.numberSegments = .groupedNumeric(.default)
	if outputFormat.isJSON {
		// `I+sN:B:` / `I+sN:B/:`
		optionSet.boundaries = .uncollapsed(isPath ? [.init(boundaries: [.character("/")])] : .init())
	} else {
		// `I+iL:N:` / `I+iL:N:B/_+space+:`
		optionSet.caseSensitivity = .insensitive
		optionSet.locale = .current
		if isPath {
			optionSet.boundaries =
				.uncollapsed([.init(boundaries: [.character("/")])] + SortOptionSet.defaultBoundaryGroups)
		}
	}
	if let fieldName, versionFieldNameSet.contains(fieldName) {
		optionSet.numberSegments = .versions
	} else if fieldName == formattedPriceFieldName {
		optionSet.numberSegments = .groupedNumeric(
			.init(
				baseConventions: .init(locale: appStoreLocale),
				digitGroupSeparator: nil,
				digitGroupSize: nil,
				secondaryDigitGroupSize: nil,
				decimalSeparator: nil,
				signs: .wordInitialSigns,
			),
		)
		optionSet.nonconformingComparison = .least
	}
	return optionSet
}

private let pathFieldNameSet = Set(["path"])

/// The field whose number segments are grouped per the App Store locale's
/// conventions & whose nonconforming values (almost always `Free` or a
/// translation of it, which equals 0) compare as less than its conforming ones.
private let formattedPriceFieldName = "formattedPrice"

/// Maps a field name directly to its default table-column alignment (mas's own
/// built-in `standard` / `all` fields configs' shared policy: a number, or a
/// value with a fixed textual suffix that reads better end-aligned, e.g.,
/// `fileSizeBytes`'s appended `" MB"`, is end-aligned; everything else is
/// start-aligned). Consulted only by each display command's own field-spec
/// construction, not applied generically elsewhere; an attached alignment
/// preset (see `parsePresetModifier(_:attached:)` in `Preset.swift`) overrides
/// it per field spec.
func defaultAlignment(forFieldNamed fieldName: String) -> Alignment {
	endAlignedFieldNameSet.contains(fieldName) ? .end : .start
}

private let endAlignedFieldNameSet = Set(["adamID", "fileSizeBytes"])

/// `fieldName`'s field spec in every mas built-in fields config's user-facing
/// variants, per mas.md's "Built-In Field Specs": its table row's label &
/// format iff the table lists `fieldName`, else labeled by `fieldName` &
/// formatted as `%i`; aligned per `defaultAlignment(forFieldNamed:)`.
func builtInFieldSpec(forFieldNamed fieldName: String) -> FieldSpec {
	let (label, format) = listedLabelAndFormatByFieldName[fieldName] ?? (fieldName, .default(fieldName: fieldName))
	return .init(
		name: fieldName,
		label: label,
		format: format,
		sortSpec: nil,
		isSynthesized: synthesizedFieldNameSet.contains(fieldName),
		alignment: defaultAlignment(forFieldNamed: fieldName),
	)
}

/// mas.md's "Built-In Field Specs" table's labels & formats, by field name.
private let listedLabelAndFormatByFieldName = [
	"adamID": ("ADAM ID", Format.default(fieldName: "adamID")),
	"appStorePageURL": ("From", .default(fieldName: "appStorePageURL")),
	"bundleID": ("Bundle ID", .default(fieldName: "bundleID")),
	"currentVersionReleaseDate": (
		"Released",
		// `%+D.dateOnly+`: the release date, date-only, in the system time zone;
		// formatting aborts for a non-date
		.template(
			[
				.placeholder(
					.conditional(
						.init(predicate: .date, coercion: nil),
						.abortOnFailure(
							success: .pipeline(.init(calls: [.init(transform: .dateOnly, coercion: nil)])),
						),
					),
				),
			],
		),
	),
	"fileSizeBytes": (
		"Size",
		// `%+.N.scale:6,,0:.numberFormat+ MB`: a byte count as whole, grouped
		// decimal megabytes, with an appended " MB". JSON gets the raw byte count
		// instead: JSON output resolves to the machine-facing `@json` variant (see
		// `machineFacingVariant()`), which labels each field spec by its name &
		// formats its output as `%i`, per mas.md
		.template(
			[
				.placeholder(
					.conditional(
						.init(predicate: .number, coercion: .default),
						.abortOnFailure(
							success: .pipeline(
								.init(
									calls: [
										.init(
											transform: .scale(exponent: 6, significantDigits: nil, fractionalDigits: 0),
											coercion: nil,
										),
										.init(transform: .numberFormat(.init(locale: .current)), coercion: nil),
									],
								),
							),
						),
					),
				),
				.text(" MB"),
			],
		),
	),
	"formattedPrice": ("Price", .default(fieldName: "formattedPrice")),
	"minimumOSVersion": ("Minimum OS", .default(fieldName: "minimumOSVersion")),
	"name": ("Name", .default(fieldName: "name")),
	"newVersion": ("New Version", .default(fieldName: "newVersion")),
	"sellerName": ("By", .default(fieldName: "sellerName")),
	"version": ("Version", .default(fieldName: "version")),
]

/// The fields whose values are computed after a display command's own fetch
/// (see `FieldSpec.isSynthesized`).
private let synthesizedFieldNameSet = Set(["newVersion"])
