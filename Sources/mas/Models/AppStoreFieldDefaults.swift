//
// AppStoreFieldDefaults.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

// MARK: - mas's own field-name defaults

// The generic `--fields` engine (`Models/FieldsOption/`) has no concept of
// "price" / "version" / "adamID", etc.; only mas's own built-in `standard` /
// `all` fields configs (& fields a user names via `--fields` text) care about
// these specific App Store / Spotlight field names. Keeping that knowledge
// here, rather than in `Models/FieldsOption/`, keeps the generic engine
// reusable independent of mas.

/// Maps a field name directly to the `interpretation` & boundary character
/// `SortSpec.default(interpretation:boundaryCharacter:outputFormat:)` needs to
/// compute the fields.md "Default Sort Options" row used to fill in an
/// otherwise-incomplete explicit `<sort>`. A field name this doesn't recognize
/// as price / version / path gets the generic (numeric-interpretation, no
/// explicit boundary) row.
func defaultSortSpec(forFieldNamed fieldName: String, outputFormat: OutputFormat) -> SortSpec {
	let interpretation = priceFieldNameSet.contains(fieldName)
		? SortSpec.Interpretation.price
		: versionFieldNameSet.contains(fieldName) ? .version : .numeric
	return .default(
		interpretation: interpretation,
		boundaryCharacter: pathFieldNameSet.contains(fieldName) ? "/" : nil,
		outputFormat: outputFormat,
	)
}

private let priceFieldNameSet = Set(["price", "formattedPrice"])
private let versionFieldNameSet = Set(["version", "newVersion", "minimumOSVersion"])
private let pathFieldNameSet = Set(["path"])

/// Maps a field name directly to its default table-column justification (mas's
/// own built-in `standard` / `all` fields configs' shared policy: a number, or
/// a value with a fixed textual suffix that reads better right-aligned, e.g.,
/// `fileSizeBytes`'s appended `" MB"`, is right-justified; everything else is
/// left-justified). Consulted only by each display command's own field-spec
/// construction, not applied generically elsewhere; a user's own `--fields`
/// justify transform (a `<format-transform-pipeline>`, see `parseFormat` in
/// `FieldSpec.swift`) overrides it per field spec.
func defaultJustification(forFieldNamed fieldName: String) -> Justification {
	rightJustifiedFieldNameSet.contains(fieldName) ? .end : .start
}

private let rightJustifiedFieldNameSet = Set(["adamID", "fileSizeBytes"])
