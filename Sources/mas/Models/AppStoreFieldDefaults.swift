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

/// mas.md's "Default Sort Options" for `outputFormat`: the path row iff
/// `fieldName` is a path field's name, else the non-path row (also used for
/// sorting field names & labels, for which `fieldName` is `nil`), but comparing
/// versions for a version field & grouped numbers per the App Store locale's
/// conventions plus `a` for `formattedPrice`, per mas.md's "Price Sorting".
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

/// Maps a field name directly to its default table-column justification (mas's
/// own built-in `standard` / `all` fields configs' shared policy: a number, or
/// a value with a fixed textual suffix that reads better end-aligned, e.g.,
/// `fileSizeBytes`'s appended `" MB"`, is end-justified; everything else is
/// start-justified). Consulted only by each display command's own field-spec
/// construction, not applied generically elsewhere; a user's own `--fields`
/// justify transform (a `<format-transform-pipeline>`, see `parseFormat` in
/// `FieldSpec.swift`) overrides it per field spec.
func defaultJustification(forFieldNamed fieldName: String) -> Justification {
	endJustifiedFieldNameSet.contains(fieldName) ? .end : .start
}

private let endJustifiedFieldNameSet = Set(["adamID", "fileSizeBytes"])
