# Progress

## Step 1: Gap List (2026-09-18 10:18 UTC)

Spec production → existing code → keep / change / missing. Existing code was
written against older drafts; nonterminal names in comments are stale
throughout, e.g.:

- `<field-specs-section>` → `<field-spec-edits-section>`
- `<original-order-option-set>` → `<order-option-set>`
- `<pipeline-terminator>` → `<block-terminator>`
- `<format>` → `<format-block>`

### ebnf.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production / rule                  | Existing code                                              | Verdict |
|:-----------------------------------|:-----------------------------------------------------------|:--------|
| Escaping (`\` + any character)     | `parseEscapedText` in `FieldSpec.swift`                    | keep    |
| Dangling escape prefix is an error | `ParsingError.danglingEscape`                              | keep    |
| Outer bare whitespace treatment    | Only leading whitespace of the entire value is dropped     | change  |
| Longest syntax literal wins        | Ad hoc per section (`//` vs `/` checked by `hasPrefix`)    | keep    |
| Transitive default = working value | `existing` / `defaults:` parameters                        | keep    |
| Direct default resets              | `name=` / `name:` / `name/` reset via empty-payload checks | keep    |
| `(* last wins *)`                  | Per-axis last-wins in `parseOptions`                       | keep    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### fields.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production                                | Existing code                                            | Verdict |
|:------------------------------------------|:---------------------------------------------------------|:--------|
| Positions & indices                       | `effectivePosition(forIndex:length:)`                    | keep    |
| Hidden field specs                        | `Format.isHidden` (a format flag, not a field spec flag) | change  |
| `<fields-config>` absolute vs relative    | `resolvedFieldsConfig` switch on 1st character           | keep    |
| `<absolute-config>`                       | `parseAbsoluteConfig`                                    | keep    |
| `<base-fields-config-section>` (`@name`)  | `resolveBaseFieldsConfig`                                | keep    |
| Output format suffix `@json` etc.         | `outputFormatSuffixSet`                                  | keep    |
| `@none` reference suffix                  | handled in `resolveBaseFieldsConfig`                     | keep    |
| `default` → `standard` (+ suffix)         | handled                                                  | keep    |
| `<field-order-section>` `/`               | `parseFieldOrderSection`                                 | change  |
| `<order-option-set>`: `w` / `o` + dirs    | Only `o` (`isOriginalOrderOptionSet`); `w` missing       | change  |
| `<sort-option-set>` field order           | `.byName` / `.byLabel`                                   | keep    |
| Bare `/` (`.workingOrder`)                | Present; spec has no such state (`/` alone is an error)  | change  |
| `<item-sort-section>` `//`                | `parseItemSortSection`                                   | change  |
| `<disable-all-sorts>` `r`                 | `r` / `R` reset options to contextual defaults           | change  |
| Item sort `<direction>` tiebreak          | `ItemSort.tiebreakDirection`                             | keep    |
| `<field-spec-reference>` (`name@i`, `@i`) | `parseFieldSpecReference`                                | keep    |
| Reference config `null` on removal        | `referenceFieldSpecs[...] = nil`                         | keep    |
| `<field-spec-edits-section>` `.`          | `parseFieldSpecsSection`                                 | change  |
| `<field-spec-insertion>` `+`              | `.insert` (by name only; `+@i` / `+name@i` missing)      | change  |
| `<field-spec-overlay>`                    | `.overlay` (does not unhide)                             | change  |
| `<field-spec-move>` `%`                   | `.move` (does not unhide)                                | change  |
| `<field-spec-hide>` `_`                   | none (`_` currently a format flag)                       | missing |
| `<field-spec-removal>` `-`                | `.remove`                                                | keep    |
| `<field-modifiers>` order `= : /`         | `parseLabel`, `parseFormat`, `parseSortSpecModifier`     | keep    |
| `<label-modifier>` `=` default `""`       | `parseLabel` (`name=` → `""`)                            | keep    |
| `<sort-modifier>` `/` + `<sort>`          | `SortSpec.init(from:...)`                                | change  |
| Multiple `<sort-option-set>`s (`/1I/O`)   | none                                                     | missing |
| `<sort-priority>` `0` disables            | priority stored; `0` semantics unclear                   | change  |
| `<source>` `I` / `O`                      | `SortSpec.Source`                                        | keep    |
| `<direction>` `a` / `d`                   | `SortSpec.Direction`                                     | keep    |
| `<case-sensitivity>` `s` / `i`            | `SortSpec.CaseSensitivity`                               | keep    |
| `<localization>` `c` / `l` / `L…+`        | `Localization`; `L` fence via `localeNameFence`          | keep    |
| `<numbers-in-strings>` `x` / `n` / `g`    | `Interpretation` (`x n p v`) + `Grouping` (`u g`)        | change  |
| `<boundaries>` `b` / `B…+` / `C…+`        | `b` prefix + `%` collapse + `_`/`+` fences (old draft)   | change  |
| `<boundary-groups>` default `:space:`     | `WhitespacePlacement` (old draft)                        | change  |
| `<character-class>` `:name:`              | `CharacterClass`                                         | keep    |
| `<multi-character-boundary>` `%…%`        | `Boundary.characters`                                    | keep    |
| `<nonconforming-location>` `f` / `e`      | none                                                     | missing |
| `<trivia-order>` `t` / `h` / `p` / `q`    | none                                                     | missing |
| Version comparison                        | `Interpretation.version`                                 | change  |
| Sort by type (chronologic / number / …)   | Sort by `Interpretation`, not by format type             | change  |
| Appendix: Escaping table                  | Terminator sets roughly match; whitespace rows do not    | change  |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### fields-format.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production                                            | Existing code                                      | Verdict |
|:------------------------------------------------------|:---------------------------------------------------|:--------|
| `<format-modifier>` `:` + `<format-block>`            | `parseFormat`                                      | keep    |
| `<pipeline>` (named / format / value)                 | `parseFormat` 4 branches                           | keep    |
| `<format-template>` / `<template-text>`               | `parseTemplate`, `FormatPart.text`                 | keep    |
| `template-text = ~^{text}^~` whitespace               | not implemented                                    | change  |
| `<named-format>` `:name`                              | `FormatReference`; no persisted formats            | keep    |
| `<string-transform>` names                            | `Transform` (check `initialTitlecase`)             | change  |
| `<number-transform>`, `absoluteValue`, etc.           | `Transform`                                        | keep    |
| `group` / `scale` arguments `:…:`                     | `groupTransform`, `scaleTransform`                 | keep    |
| `<chronologic-transform>` `dateOnly` etc.             | `DateSpec` (old draft with `,` / `_` separators)   | change  |
| `<strict-coercion>` `.` on transforms                 | `placeholderCoercion`                              | keep    |
| `<format-transform>` justify names                    | `Justification`                                    | keep    |
| `<placeholder>` prefix `%`                            | `PlaceholderParser`                                | keep    |
| `<abort-on-success>` `-` / `<abort-on-failure>` `+`   | `placeholderNegation` only                         | change  |
| `<lenient-coercion>` `_`                              | none                                               | missing |
| Standard predicates `u`, `e`, `w`, `b`, `t`, `f`, `s` | `StandardKind` uses `o` for boolean; spec uses `b` | change  |
| Nullary / non-nullary (case) forms                    | present                                            | keep    |
| `<block-terminator>` `+`                              | `formatDelimiter`                                  | keep    |
| Number / version / chronologic `n v c`                | `Placeholder` cases                                | keep    |
| Match placeholders `m` / `M` + branches               | `Branches`, `Branch`                               | keep    |
| Type determinant / conformance                        | none                                               | missing |
| Abort semantics (empty output)                        | `renderedParts` returns `nil`                      | keep    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### table.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production                            | Existing code                 | Verdict |
|:--------------------------------------|:------------------------------|:--------|
| `<table-config>` (last wins per axis) | `parseTableConfig`            | keep    |
| `h` / `H[sgr](:\|end)`                | handled                       | keep    |
| `<header-styling-setting>` `t` / `a`  | none                          | missing |
| `s` / `S[pattern](:\|end)`            | handled                       | keep    |
| `b` / `u`                             | handled                       | keep    |
| `c` / `C[spacing](:\|end)`            | handled                       | keep    |
| Implied settings                      | `TableConfigAxis`             | keep    |
| Whitespace consumed in `S` / `C` text | handled (no trimming)         | keep    |
| Escaping `:` in text                  | check `parseTableOptionValue` | change  |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### configs.md & mas.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Rule                                      | Existing code                               | Verdict |
|:------------------------------------------|:--------------------------------------------|:--------|
| Context stack lookup                      | none (only built-ins per command)           | missing |
| Custom named configs                      | none (Temp/todo.md: massive effort)         | missing |
| `standard@json` → `all`                   | `appliesJSONSubstitution`                   | keep    |
| Built-in `none` / `all` / `standard`      | `resolveBaseFieldsConfig`                   | keep    |
| Machine-facing `@json` label = name, `%i` | `defaultedForJSON`                          | keep    |
| Default sort options table                | `AppStoreFieldDefaults.swift` (old letters) | change  |
| Per-command default output format         | `OutputConfig.defaultFormat`                | keep    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Step 2a: Field Order & Item Sort Sections (2026-09-18 10:22 UTC)

`<field-order-section>` now follows fields.md: `<field-order-option-set>` is
required after `/` (a bare `/` reports `missingFieldOrderOptionSet`);
`<order-option-set>` supports `<base-fields-config-order>` (`w`, new
`FieldOrder.base`) & `<original-input-order>` (`o`), with `<direction>` last
wins; a `<sort-option-set>` defaults its `<source>` to `<output>` (sort by
label). `<item-sort-section>`'s `<disable-all-sorts>` (`r`) now sets each field
spec's `<sort-priority>` to `0` (retaining its `<sort-option-set>`) instead of
resetting options to contextual defaults, and `R` is gone; sort keys with
priority `0` are excluded from `ItemSort.keys` (`[FieldSpec].enabledSortKeys`),
so a later `<field-spec-edit>` such as `.adamID/1` re-enables a sort. Remaining
for step 2:

- `<field-spec-hide>` (`_`).
- Unhiding on overlay / move.
- `+@i` / `+name@i` insertion references.
- Outer bare whitespace treatment per ebnf.md.

## Step 2b: Hide, Unhide & Base-Sourced Insertion (2026-09-18 10:25 UTC)

`FieldSpec` gains a stored `isHidden`; `<field-spec-hide>` (`_`) overlays its
`<field-modifiers>` onto `source` & hides it, inserting a new hidden field spec
iff its `<named-field-spec-reference>` resolves to no field spec (e.g.,
`_size/1d`); `<field-spec-overlay>` & `<field-spec-move>` unhide `source`.
`<field-spec-insertion>` now takes a full `<field-spec-reference>` (`+name`,
`+name@i`, `+@i`) resolved against the immutable base fields config
(`FieldSpecsBuilder.baseFieldSpecs`), selecting default settings iff a named
reference matches nothing. Output filters hidden field specs. The old `:hidden`
named format still exists alongside (see Temp/todo.md); `none` is still an empty
fields config rather than `all` with every field spec hidden.

Revised (2026-09-25): named references now resolve against the reference fields
config's immutable positions (`referencePositions(forName:)`), so a field spec
removed earlier in the section keeps its position as `null` (referencing it is
an error), and a `<field-spec-hide>` of such a field inserts a hidden copy of
its base field spec, as `<field-spec-insertion>` would.

## Step 4 (partial): Table Config (2026-09-18 10:27 UTC)

`parseTableConfig` now supports `<header-styling-setting>` (`t` terminal-only /
`a` always, stored as `TableConfig.headerStyling`; table rendering applies
`<sgr-parameters>` iff `a` or standard output is a terminal), defaults an absent
`<separator-pattern>` to `-` (a `{text}` token is never empty, so `S` / `S:` are
dashed) & handles escaping (`\:`, `\\`, dangling `\` is an error) in
`<sgr-parameters>` / `<separator-pattern>` / `<column-spacing>` text via
`parseTableSettingText`. Comments now use table.md's vocabulary (setting,
`<table-config-terminator>`, `<end-of-shell-word>`). Steps 3 (sort options,
format modifiers) & 5 / 6 (named config contexts, mas defaults) were not
started.

Revised (2026-09-25): comments & names use table.md's current vocabulary
(`<table-setting-termination>`, `<table-setting-terminator>`,
`<end-of-table-config>`, `TableConfigParsingError.invalidSetting`), and
`<sgr-parameters>` (not a `{text}` token) no longer accepts escape sequences.

## Step 2c: Remove Old-Draft `hidden` Named Format (2026-09-18 10:29 UTC)

The old built-in `hidden` named format (`::hidden`, `Format.isHidden`,
`ParsingError.hiddenFormatFollowedByContent`) is removed: hiding is now only
`<field-spec-hide>` (`_`) via `FieldSpec.isHidden`. `knownNamedFormatNameSet` is
empty, so every `<named-format-reference>` reports `unknownNamedFormat` until
persisted named formats exist, per fields-format.md.

## Step 3 (partial): Placeholder Letters (2026-09-18 10:31 UTC)

Placeholder letters now match fields-format.md: `%i` / `%I` (input; formerly
`%v` / `%V`), `%c` / `%C` (chronologic; formerly `%d` / `%D`), `%m` / `%M`
(match; formerly `%b` / `%B`) & `%b` / `%B` (boolean; formerly `%o` / `%O`). Not
yet done: `%k` / `%K` (name), `%v` / `%V` (version), `<abort-on-success>` /
`<abort-on-failure>` semantics (the existing `-` prefix still means the old
negation), `<lenient-coercion>` (`_`), type determinants, the
`<chronologic-transform>` argument syntax (`timeZone:…:`; the old `,` / `_`
date-format separators remain), sort options (`n` / `g` / `B` / `C` / `f` / `e`
/ `t` / `h` / `p` / `q`) & `template-text`'s whitespace treatment.

## Step 7 (partial): Stale Spec References (2026-09-18 10:36 UTC)

Rewrapped edited comment blocks to 80 columns.

Renamed stale nonterminal names in comments to the current specs' names:

- `<field-spec-edits-section>`
- `<block-terminator>`
- `<format-block>`
- `<format-template>`
- `<justify>`
- `<field-spec-insertion>`
- `<strict-coercion>`
- `<failure-block>`
- `<string-block>`
- `<number-block>`
- `<nullary-input>`

Old names are retained for code that hasn't yet been rewritten, e.g.:

- `<boundaries-option-set>`
- `<grouped-boundaries>`
- `<date>`
- `<input-date-format>`

## Step 3 (partial): Sort Localization (2026-09-18 10:37 UTC)

`<localization>` now parses per fields.md: `l` is `<system-locale>` & `L` starts
`<custom-locale>`, whose `<locale-identifier>` runs to a required
`<sort-option-terminator>` (`+`); an empty identifier is the system locale. The
other sort options (`<numbers-in-strings>`, `<boundaries>`,
`<nonconforming-location>`, `<trivia-order>`) still follow the old draft.

Revised (2026-09-25): a missing `<sort-option-terminator>` reports
`missingSortOptionTerminator` instead of `missingEndFence`.

## Step 3 (partial): Name Placeholder (2026-09-18 10:38 UTC)

`%k` / `%K` (`<nullary-name>` / `<non-nullary-name>`) are parsed, as
placeholders & as `<unconditional-branch>`es, reusing `Placeholder.label`'s
`negated: true` representation for the field name; `%l` / `%L` / `%k` / `%K` may
no longer be negated (the old `%-l` meant the field name).

## Step 3 (partial): `timeZone` Transform (2026-09-18 10:41 UTC)

The old `localTimeZone` chronologic transform is replaced by
`timeZone<time-zone-arguments>` (`.timeZone:Asia/Tokyo:`, `:UTC:`, `:-05\:30:`,
`:system:`), setting the output time zone (last wins) & reporting
`invalidTransformArguments` for an unknown code. IANA Time Zone Database
identifiers, Foundation time zone abbreviations & `system` match
case-insensitively. `<time-zone-arguments>` requires a `<time-zone-code>`, so
`.timeZone::` is an error.

## Step 3 (partial): Version Placeholders (2026-09-18 10:45 UTC)

`%v` / `%V` (`<nullary-version>` / `<non-nullary-version>`) match a string of
`.`-separated components each starting with an ASCII digit, as placeholders
(with success & failure blocks) & as branches; coercion is rejected. `Transform`
& its helpers moved from `Format.swift` to `Transform.swift` to stay under the
file-length limit. Found while testing: the old `parseDelimitedFormat` stops a
success / failure block at `%`, so a block cannot itself contain a placeholder
(e.g., `%.N%n (%i)++` from fields-format.md); noted in Temp/todo.md.

## Session 2 (2026-09-25)

Rebased my step commits onto the updated specs, fixing each in place:
`<original-input-order>` is rejected for table output; named references resolve
against immutable reference-config positions (a removed field spec stays a
`null`), and hiding such a field inserts a hidden copy of its base field spec;
table.md's renamed termination nonterminals & no escapes in `<sgr-parameters>`;
`missingSortOptionTerminator`; case-insensitive `<time-zone-code>`; ASCII digits
for versions. The gap-list & hide commits were accidentally merged into 1 commit
(`Add --fields / --table spec gap list.`); splitting them needs a branch reset,
which was not permitted, so it is left for review.

### Justify Names

`<justify>` names are now `startJustify` / `endJustify` (were `leftJustify` /
`rightJustify`), per fields-format.md.

### Transform Names

`Transform.capitalize` is now `initialTitlecase`, and `group`'s associated
values are `digitGroupSeparator` / `digitGroupSize`, matching fields-format.md's
`<initial-titlecase>`, `<digit-group-separator>` & `<digit-group-size>`.

### Format Rewrite

`Format.swift` (AST, evaluation, type determinants) & the new
`FormatParser.swift` implement fields-format.md: a `<format-block>` is a
`<pipeline>` (whose `<format-transform-pipeline>` becomes
`FieldSpec.justification`, retained iff transitively absent) or a
`<format-template>` (at least 1 placeholder); blocks are `+`-terminated with
kinds per matcher (string, boolean, number, chronologic, any, unconditional);
placeholders support `<abort-on-success>`, `<abort-on-failure>`, strict &
lenient coercion (trivia retained), block placeholders & match placeholders with
negated & unconditional branches; template-text whitespace follows the escaping
appendix; forbidden whitespace after `%`, modifiers, `.` & `:` is an error. An
uncoerced transform on an input not of its input type throws `FormattingError`
at render time (surfaced via `OutputError`). An absent `<format-block>` defaults
to the nullary placeholder for the working format's type determinant. This
resolves the `parseDelimitedFormat` item in Temp/todo.md (blocks may now contain
placeholders). Old-draft format tests were replaced by
`Tests/MASTests/Models/FieldsOption/MASTests+Format*.swift`.

### Sort Rewrite & mas Defaults

`SortSpec` is now a `<sort-priority>` & its `<sort-option-set>`s
(`SortOptionSet`: `<source>`, `<direction>`, `<case-sensitivity>`,
`<localization>` incl. `L…+`, `<numbers-in-strings>` `x` / `n` / `g`,
`<boundaries>` `b` / `B…+` / `C…+` with `<boundary-groups>` (default `:space:`),
`<nonconforming-location>` `f` / `e`, `<trivia-order>` `t` / `h` / `p` / `q`),
replacing the old draft's interpretations, grouping & whitespace placements. A
`<sort-modifier>` accepts succeeding `/`-prefixed `<sort-option-set>`s. Values
compare per the field's type determinant (chronologic, version, number with
trivia, boolean, string, any), each value belonging to the 1st
`<sort-option-set>` whose type it conforms to. mas.md's default sort options
(`Iailg`, `IailgB/_:space:+`, `Iascgb`, `IascgB/+`) are in
`defaultSortOptionSet(forFieldNamed:outputFormat:)`, and price / version fields'
default formats are typed (`%_N+%i+` / `%V+%i+`, via
`defaultFieldFormat(forFieldNamed:)`) so they compare per type.

### Built-In Fields Config Variants

`resolveBaseFieldsConfig` now validates config names per configs.md
(`^[-_0-9A-Za-z]+$` plus an optional output format suffix & an optional `@none`
reference suffix), reports a nonexistent name & selects variants per suffix or,
absent one, the output format: `@json` is machine-facing
(`machineFacingVariant()`: label = name, format `%i`), `@none` / `@table` /
`@key-value` user-facing & `standard@json` is `all`. Built-in `none` is `all`
with every field spec hidden, so overlays select fields (e.g.,
`@none.name,version`). `fetchFieldNames` now fully parses the value against the
static base (fetching every field for an `all`-derived base) instead of scanning
text, excluding hidden field specs that don't sort items; the old scanning
helpers are removed.

### Field Spec References & Whitespace

An `<index-prefix>` requires an `<index>` (`missingIndex`); a
`<field-spec-removal>`'s `<reference-field-name>` is terminated only by `@` &
`,`, per the escaping appendix; outer bare whitespace around field spec edits'
syntax tokens (modifier prefixes, separators, index prefixes) is ignored; &
trailing junk after a field spec reports `unexpectedCharacter`.

### Shell Completions

`mas.fish` completes `--fields` (requiring a value), `--key-value` & `--table`
alongside `--json`, each output format option excluding the others. Option
values aren't completed. `mas.bash` only completes commands, so it's unchanged.

### Per-Item Original Input Order

`<original-input-order>` now orders each item's fields independently by its own
key order (`FieldOrder.itemFieldSpecs(_:for:)`), for JSON & key-value output,
per fields.md.

### Compliance & Dead Code Pass

Full `Scripts/lint` (incl. SwiftLint Analyze) is clean. Removed the unthrown
`missingEndFence` error & the single-use `parseOptions` (inlined into
`<item-sort-section>` parsing, which now requires a non-empty
`<item-sort-option-set>`), used spec nonterminal names in the remaining comments
(`<*-transform-call>`, `<value-transform>`) & rewrapped an over-long comment.

### Standard As All With Hidden Field Specs

Per mas.md, built-in `none`, `all` & `standard` variants differ only in which
field specs are hidden: user-facing `standard` is now its own field specs
followed by `all`'s other field specs, hidden, so an overlay may unhide any
field (e.g., `.bundleID`). Pre-fetch, a reference to a field not yet discovered
fetches every field. A `// TODO:` in `resolveBaseFieldsConfig` describes the
context-stack lookup to implement once custom named configs are persisted.

### README

`README.md`'s Output Formats section links the specs & gives verified `--fields`
/ `--table` examples (Temp/todo.md "Documentation" item 1).

## Stopped (2026-09-18 10:45 UTC)

Stopped ahead of the 11:00 UTC deadline with a clean tree (`Scripts/format`,
`Scripts/lint -A`, `Scripts/build` & `Scripts/test` all pass; every step above
is committed). Remaining, in the original order:

- Step 2: ebnf.md outer bare whitespace treatment per production (only the
  existing trim of outer whitespace around text tokens exists); built-in `none`
  as `all` with every field spec hidden.
- Step 3:
  - `<abort-on-success>` / `<abort-on-failure>` (the `-` prefix still means the
    old negation).
  - `<lenient-coercion>` (`_`).
  - Type determinants & conformance.
  - `+` as the sole `<block-terminator>` (the old `:` / `::` pipeline terminator
    remains).
  - `template-text` whitespace.
  - Sort options:
    - `<numbers-in-strings>` (`x` / `n` / `g`, replacing `Interpretation` +
      `Grouping`).
    - `<boundaries>` (`b` / `B…+` / `C…+` with `<boundary-groups>`, replacing
      the old `b…` syntax).
    - `<nonconforming-location>`.
    - `<trivia-order>`.
    - Multiple `<sort-option-set>`s per `<sort-modifier>`.
    - Sorting by the field's type.
- Step 5: context stacks & persisted named configs (Temp/todo.md: massive
  effort).
- Step 6: re-derive `AppStoreFieldDefaults.swift` from mas.md's "Default Sort
  Options" once the sort option letters match fields.md.
- Step 7: rename the remaining old-draft nonterminal names in comments (sort
  boundaries, chronologic input / output formats) as that code is rewritten.

## Session 2 Status (2026-09-25)

The tree is clean: `Scripts/format`, `Scripts/lint` (full), `Scripts/build`
(debug & release) & `Scripts/test` pass, and every change above is committed.
Implemented since the 2026-09-18 stop: the format grammar rewrite (abort
modifiers, lenient coercion, type determinants, `+` block terminators,
template-text whitespace), the sort option rewrite (`x` / `n` / `g`, `b` / `B…+`
/ `C…+`, `f` / `e`, `t` / `h` / `p` / `q`, succeeding option sets, type-based
comparison), mas.md's default sort options & typed default formats, built-in
variants (`none` / `all` / `standard`, `@json` machine-facing) & per-item
`<original-input-order>`.

Remaining:

- Context stacks & persisted custom named configs / formats (Temp/todo.md "ASAP
  Version, But Massive Effort"; a `// TODO:` in `resolveBaseFieldsConfig`
  describes the lookup).
- The open questions appended to Temp/todo.md "Current Version".
- The gap-list & hide commits were merged into 1 commit during the rebase;
  splitting them needs a branch reset, which wasn't permitted.

### Nonexistent Fields

Per fields.md's "Nonexistent Fields", a display command whose fields are all
known up front (`config`, via `OutputConfig.fieldNameSet`) reports a reference
to any other field (an absolute field name, an insertion, or a hide of an
unmatched name) as `nonexistentField`; other commands' fields can't be known up
front, so aren't checked.

### Spec Compliance Audit (2026-09-25)

Probed every fields-format.md, fields.md & table.md grammar construct & prose
example (~300 cases, via a throwaway test) against the parser & renderer; the
only divergences, each fixed in its own commit:

- An uncoerced chronologic transform reported a type mismatch for a value `%c`
  matches (an ISO-8601 string or a Unix epoch number).
- UTC offsets rendered in ISO-8601's basic format (`+0900`) beside an extended
  date & time; now `+09:00`.
- Contiguous uncollapsed boundaries formed 1 segment & same-group boundaries
  compared by character; each boundary is now its own segment, compared by group
  precedence alone.
- A trailing `,` in a `<field-spec-edits-section>` was accepted.
- An explicit `s` with `b` / `u` still implied a table header row.

3 spec questions were appended to Temp/todo.md "Implementation Questions". Still
unimplemented: persisted custom named configs / named formats & context stack
lookup (Temp/todo.md "ASAP Version, But Massive Effort").
