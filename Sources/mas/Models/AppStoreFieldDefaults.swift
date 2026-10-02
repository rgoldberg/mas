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

/// A field's default format: per mas.md, typed for price fields
/// (`%.:<App Store locale>,,,,.*,.*:N%i+%i+`, whose number coercion is mas.md's
/// "Price Coercion") & version fields (`%V+%i+`), so they compare per type,
/// while rendering a value as is (e.g., `Free`, or a price retaining its digit
/// group separators); `%i` for any other field.
func defaultFieldFormat(forFieldNamed fieldName: String) -> Format {
	let matcher: Matcher? =
		if priceFieldNameSet.contains(fieldName) {
			.init(
				predicate: .number,
				coercion: .init(
					numberConventions: .init(locale: appStoreLocale),
					triviaPrefixRegex: .any,
					triviaSuffixRegex: .any,
				),
			)
		} else if versionFieldNameSet.contains(fieldName) {
			.init(predicate: .version, coercion: nil)
		} else {
			nil
		}
	return matcher.map { matcher in
		.template(
			[
				.placeholder(
					.conditional(
						matcher,
						.binary(
							success: matcher.predicate == .number ? .default(fieldName: fieldName) : nil,
							failure: .default(fieldName: fieldName),
						),
					),
				),
			],
		)
	}
		?? .default(fieldName: fieldName)
}

private let priceFieldNameSet = Set(["formattedPrice", "price"])
private let versionFieldNameSet = Set(["minimumOSVersion", "newVersion", "version"])

/// mas.md's App Store locale: the App Store's own locale cannot be determined
/// programmatically, so the likely locale of the App Store region that mas
/// guesses from the macOS region.
private let appStoreLocale = Locale(identifier: Locale.Language(identifier: "und-\(appStoreRegion)").maximalIdentifier)

/// mas.md's "Default Sort Options" for string fields, for `outputFormat`: the
/// path row iff `fieldName` is a path field's name, else the non-path row (also
/// used for sorting field names & labels, for which `fieldName` is `nil`), plus
/// `y` for `formattedPrice`, per mas.md's "Price Coercion".
func defaultSortOptionSet(forFieldNamed fieldName: String?, outputFormat: OutputFormat) -> SortOptionSet {
	let isPath = fieldName.map(pathFieldNameSet.contains) ?? false
	var optionSet = SortOptionSet.default
	optionSet.numbersInStrings = .groupedNumeric
	if fieldName == leastNonconformingFieldName {
		optionSet.nonconformingComparison = .least
	}
	if outputFormat == .json {
		// `Iascgb` / `IascgB/+`
		optionSet.boundaries = isPath ? .uncollapsed([.init(boundaries: [.character("/")])]) : .noBoundaries
	} else {
		// `Iailg` / `IailgB/_:space:+`
		optionSet.caseSensitivity = .insensitive
		optionSet.localization = .localized(.current)
		if isPath {
			optionSet.boundaries =
				.uncollapsed([.init(boundaries: [.character("/")])] + SortOptionSet.defaultBoundaryGroups)
		}
	}
	return optionSet
}

private let pathFieldNameSet = Set(["path"])

/// The field whose nonconforming values (almost always `Free` or a translation
/// of it, which equals 0) compare as less than its conforming ones.
private let leastNonconformingFieldName = "formattedPrice"

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
