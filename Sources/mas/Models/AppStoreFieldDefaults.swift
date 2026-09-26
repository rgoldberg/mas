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

/// A field's default format: per mas.md, typed for price fields (`%_N+%i+`) &
/// version fields (`%V+%i+`), so they compare per type, while rendering an
/// untyped value (e.g., `Free`) as is; `%i` for any other field.
func defaultFieldFormat(forFieldNamed fieldName: String) -> Format {
	let predicate: Predicate? =
		if priceFieldNameSet.contains(fieldName) {
			.number
		} else if versionFieldNameSet.contains(fieldName) {
			.version
		} else {
			nil
		}
	return predicate.map { predicate in
		.template(
			[
				.placeholder(
					.conditional(
						.init(predicate: predicate, coercion: predicate == .number ? .lenient : nil),
						.binary(success: nil, failure: .default(fieldName: fieldName)),
					),
				),
			],
		)
	}
		?? .default(fieldName: fieldName)
}

private let priceFieldNameSet = Set(["formattedPrice", "price"])
private let versionFieldNameSet = Set(["minimumOSVersion", "newVersion", "version"])

/// mas.md's "Default Sort Options" for string fields, for `outputFormat`: the
/// path row iff `fieldName` is a path field's name, else the non-path row (also
/// used for sorting field names & labels, for which `fieldName` is `nil`).
func defaultSortOptionSet(forFieldNamed fieldName: String?, outputFormat: OutputFormat) -> SortOptionSet {
	let isPath = fieldName.map(pathFieldNameSet.contains) ?? false
	var optionSet = SortOptionSet.default
	optionSet.numbersInStrings = .groupedNumeric
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
