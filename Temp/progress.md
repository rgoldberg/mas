# Progress

## Step 1: Gap List (2026-09-18 10:18 UTC)

Spec production → existing code → keep / change / missing. Existing code was
written against older drafts; nonterminal names in comments are stale
throughout (e.g., `<field-specs-section>` → `<field-spec-edits-section>`,
`<original-order-option-set>` → `<order-option-set>`, `<pipeline-terminator>`
→ `<block-terminator>`, `<format>` → `<format-block>`).

### ebnf.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production / rule                    | Existing code                                                  | Verdict |
|:-------------------------------------|:---------------------------------------------------------------|:--------|
| Escaping (`\` + any character)       | `parseEscapedText` in `FieldSpec.swift`                        | keep    |
| Dangling escape prefix is an error   | `ParsingError.danglingEscape`                                  | keep    |
| Outer bare whitespace treatment      | Only leading whitespace of the entire value is dropped         | change  |
| Longest syntax literal wins          | Ad hoc per section (`//` vs `/` checked by `hasPrefix`)        | keep    |
| Transitive default = working value   | `existing` / `defaults:` parameters                            | keep    |
| Direct default resets                | `name=` / `name:` / `name/` reset via empty-payload checks     | keep    |
| `(* last wins *)`                    | Per-axis last-wins in `parseOptions`                           | keep    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### fields.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production                                | Existing code                                             | Verdict |
|:------------------------------------------|:----------------------------------------------------------|:--------|
| Positions & indices                       | `effectivePosition(forIndex:length:)`                     | keep    |
| Hidden field specs                        | `Format.isHidden` (a format flag, not a field spec flag)  | change  |
| `<fields-config>` absolute vs relative    | `resolvedFieldsConfig` switch on 1st character            | keep    |
| `<absolute-config>`                       | `parseAbsoluteConfig`                                     | keep    |
| `<base-fields-config-section>` (`@name`)  | `resolveBaseFieldsConfig`                                 | keep    |
| Output format suffix `@json` etc.         | `outputFormatSuffixSet`                                   | keep    |
| `@none` reference suffix                  | handled in `resolveBaseFieldsConfig`                      | keep    |
| `default` → `standard` (+ suffix)         | handled                                                   | keep    |
| `<field-order-section>` `/`               | `parseFieldOrderSection`                                  | change  |
| `<order-option-set>`: `w` / `o` + dirs    | Only `o` (`isOriginalOrderOptionSet`); `w` missing        | change  |
| `<sort-option-set>` field order           | `.byName` / `.byLabel`                                    | keep    |
| Bare `/` (`.workingOrder`)                | Present; spec has no such state (`/` alone is an error)   | change  |
| `<item-sort-section>` `//`                | `parseItemSortSection`                                    | change  |
| `<disable-all-sorts>` `r`                 | `r` / `R` reset options to contextual defaults            | change  |
| Item sort `<direction>` tiebreak          | `ItemSort.tiebreakDirection`                              | keep    |
| `<field-spec-reference>` (`name@i`, `@i`) | `parseFieldSpecReference`                                 | keep    |
| Reference config `null` on removal        | `referenceFieldSpecs[...] = nil`                          | keep    |
| `<field-spec-edits-section>` `.`          | `parseFieldSpecsSection`                                  | change  |
| `<field-spec-insertion>` `+`              | `.insert` (by name only; `+@i` / `+name@i` missing)       | change  |
| `<field-spec-overlay>`                    | `.overlay` (does not unhide)                              | change  |
| `<field-spec-move>` `%`                   | `.move` (does not unhide)                                 | change  |
| `<field-spec-hide>` `_`                   | none (`_` currently a format flag)                        | missing |
| `<field-spec-removal>` `-`                | `.remove`                                                 | keep    |
| `<field-modifiers>` order `= : /`         | `parseLabel`, `parseFormat`, `parseSortSpecModifier`      | keep    |
| `<label-modifier>` `=` default `""`       | `parseLabel` (`name=` → `""`)                             | keep    |
| `<sort-modifier>` `/` + `<sort>`          | `SortSpec.init(from:...)`                                 | change  |
| Multiple `<sort-option-set>`s (`/1I/O`)   | none                                                      | missing |
| `<sort-priority>` `0` disables            | priority stored; `0` semantics unclear                    | change  |
| `<source>` `I` / `O`                      | `SortSpec.Source`                                         | keep    |
| `<direction>` `a` / `d`                   | `SortSpec.Direction`                                      | keep    |
| `<case-sensitivity>` `s` / `i`            | `SortSpec.CaseSensitivity`                                | keep    |
| `<localization>` `c` / `l` / `L…+`        | `Localization`; `L` fence via `localeNameFence`           | keep    |
| `<numbers-in-strings>` `x` / `n` / `g`    | `Interpretation` (`x n p v`) + `Grouping` (`u g`)         | change  |
| `<boundaries>` `b` / `B…+` / `C…+`        | `b` prefix + `%` collapse + `_`/`+` fences (old draft)    | change  |
| `<boundary-groups>` default `:space:`     | `WhitespacePlacement` (old draft)                         | change  |
| `<character-class>` `:name:`              | `CharacterClass`                                          | keep    |
| `<multi-character-boundary>` `%…%`        | `Boundary.characters`                                     | keep    |
| `<nonconforming-location>` `f` / `e`      | none                                                      | missing |
| `<trivia-order>` `t` / `h` / `p` / `q`    | none                                                      | missing |
| Version comparison                        | `Interpretation.version`                                  | change  |
| Sort by type (chronologic / number / …)   | Sort by `Interpretation`, not by format type              | change  |
| Appendix: Escaping table                  | Terminator sets roughly match; whitespace rows do not     | change  |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### fields-format.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production                                   | Existing code                                          | Verdict |
|:---------------------------------------------|:-------------------------------------------------------|:--------|
| `<format-modifier>` `:` + `<format-block>`   | `parseFormat`                                          | keep    |
| `<pipeline>` (named / format / value)        | `parseFormat` 4 branches                               | keep    |
| `<format-template>` / `<template-text>`      | `parseTemplate`, `FormatPart.text`                     | keep    |
| `template-text = ~^{text}^~` whitespace      | not implemented                                        | change  |
| `<named-format>` `:name`                     | `FormatReference`; no persisted formats                | keep    |
| `<string-transform>` names                   | `Transform` (check `initialUppercase`, `sentenceCase`) | change  |
| `<number-transform>` `absoluteValue` etc.    | `Transform`                                            | keep    |
| `group` / `scale` arguments `:…:`            | `groupTransform`, `scaleTransform`                     | keep    |
| `<chronologic-transform>` `iso` etc.         | `DateSpec` (old draft with `,` / `_` separators)       | change  |
| `<strict-coercion>` `.` on transforms        | `placeholderCoercion`                                  | keep    |
| `<format-transform>` justify names           | `Justification`                                        | keep    |
| `<placeholder>` prefix `%`                   | `PlaceholderParser`                                    | keep    |
| `<abort-on-success>` `-` / `-failure>` `+`   | `placeholderNegation` only                             | change  |
| `<lenient-coercion>` `_`                     | none                                                   | missing |
| Standard predicates `u e w b t f s`          | `StandardKind` uses `o` for boolean; spec uses `b`     | change  |
| Nullary / non-nullary (case) forms           | present                                                | keep    |
| `<block-terminator>` `+`                     | `formatDelimiter`                                      | keep    |
| Number / version / chronologic `n v c`       | `Placeholder` cases                                    | keep    |
| Match placeholders `m` / `M` + branches      | `Branches`, `Branch`                                   | keep    |
| Type determinant / conformance               | none                                                   | missing |
| Abort semantics (empty output)               | `renderedParts` returns `nil`                          | keep    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### table.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Production                               | Existing code                                 | Verdict |
|:-----------------------------------------|:----------------------------------------------|:--------|
| `<table-config>` (last wins per axis)    | `parseTableConfig`                            | keep    |
| `h` / `H[sgr](:\|end)`                   | handled                                       | keep    |
| `<header-styling-setting>` `t` / `a`     | none                                          | missing |
| `s` / `S[pattern](:\|end)`               | handled                                       | keep    |
| `b` / `u`                                | handled                                       | keep    |
| `c` / `C[spacing](:\|end)`               | handled                                       | keep    |
| Implied settings                         | `TableConfigAxis`                             | keep    |
| Whitespace significant in `S` / `C` text | handled (no trimming)                         | keep    |
| Escaping `:` in text                     | check `parseTableOptionValue`                 | change  |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

### configs.md & mas.md

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Rule                                      | Existing code                                  | Verdict |
|:------------------------------------------|:-----------------------------------------------|:--------|
| Context stack lookup                      | none (only built-ins per command)              | missing |
| Custom named configs                      | none (Temp/todo.md: massive effort)            | missing |
| `standard@json` → `all`                   | `appliesJSONSubstitution`                      | keep    |
| Built-in `none` / `all` / `standard`      | `resolveBaseFieldsConfig`                      | keep    |
| Machine-facing `@json` label = name, `%i` | `defaultedForJSON`                             | keep    |
| Default sort options table                | `AppStoreFieldDefaults.swift` (old letters)    | change  |
| Per-command default output format         | `OutputConfig.defaultFormat`                   | keep    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Step 2a: Field Order & Item Sort Sections (2026-09-18 10:22 UTC)

`<field-order-section>` now follows fields.md: `<field-order-option-set>` is
required after `/` (a bare `/` reports `missingFieldOrderOptionSet`);
`<order-option-set>` supports `<base-fields-config-order>` (`w`, new
`FieldOrder.base`) & `<original-input-order>` (`o`), with `<direction>` last
wins; a `<sort-option-set>` defaults its `<source>` to `<output>` (sort by
label). `<item-sort-section>`'s `<disable-all-sorts>` (`r`) now sets each
field spec's `<sort-priority>` to `0` (retaining its `<sort-option-set>`)
instead of resetting options to contextual defaults, & `R` is gone; sort keys
with priority `0` are excluded from `ItemSort.keys`
(`[FieldSpec].enabledSortKeys`), so a later `<field-spec-edit>` such as
`.adamID/1` re-enables a sort. Remaining for step 2: `<field-spec-hide>` (`_`),
unhiding on overlay / move, `+@i` / `+name@i` insertion references, & outer
bare whitespace treatment per ebnf.md.

## Step 2b: Hide, Unhide & Base-Sourced Insertion (2026-09-18 10:25 UTC)

`FieldSpec` gains a stored `isHidden`; `<field-spec-hide>` (`_`) overlays its
`<field-modifiers>` onto `source` & hides it, inserting a new hidden field spec
iff its `<named-field-spec-reference>` resolves to no field spec (e.g.,
`_size/1d`); `<field-spec-overlay>` & `<field-spec-move>` unhide `source`.
`<field-spec-insertion>` now takes a full `<field-spec-reference>` (`+name`,
`+name@i`, `+@i`) resolved against the immutable base fields config
(`FieldSpecsBuilder.baseFieldSpecs`), selecting default settings iff a named
reference matches nothing. Output filters hidden field specs. The old-draft
`:hidden` named format still exists alongside (see Temp/todo.md); `none` is
still an empty fields config rather than `all` with every field spec hidden.

## Step 4 (partial): Table Config (2026-09-18 10:27 UTC)

`parseTableConfig` now supports `<header-styling-setting>` (`t` terminal-only
/ `a` always, stored as `TableConfig.headerStyling`; table rendering applies
`<sgr-parameters>` iff `a` or standard output is a terminal), defaults an
absent `<separator-pattern>` to `-` (a `{text}` token is never empty, so `S` /
`S:` are dashed), & handles escaping (`\:`, `\\`, dangling `\` is an error) in
`<sgr-parameters>` / `<separator-pattern>` / `<column-spacing>` text via
`parseTableSettingText`. Comments now use table.md's vocabulary (setting,
`<table-config-terminator>`, `<end-of-shell-word>`). Steps 3 (sort options,
format modifiers) & 5 / 6 (named config contexts, mas defaults) were not
started.

## Step 2c: Remove Old-Draft `hidden` Named Format (2026-09-18 10:29 UTC)

The old-draft built-in `hidden` named format (`::hidden`, `Format.isHidden`,
`ParsingError.hiddenFormatFollowedByContent`) is removed: hiding is now only
`<field-spec-hide>` (`_`) via `FieldSpec.isHidden`. `knownNamedFormatNameSet`
is empty, so every `<named-format-reference>` reports `unknownNamedFormat`
until persisted named formats exist, per fields-format.md.

## Step 3 (partial): Placeholder Letters (2026-09-18 10:31 UTC)

Placeholder letters now match fields-format.md: `%i` / `%I` (input; formerly
`%v` / `%V`), `%c` / `%C` (chronologic; formerly `%d` / `%D`), `%m` / `%M`
(match; formerly `%b` / `%B`), & `%b` / `%B` (boolean; formerly `%o` / `%O`).
Not yet done: `%k` / `%K` (name), `%v` / `%V` (version), `<abort-on-success>`
/ `<abort-on-failure>` semantics (the existing `-` prefix still means the old
draft's negation), `<lenient-coercion>` (`_`), type determinants, the
`<chronologic-transform>` argument syntax (`timeZone:…:`; the old `,` / `_`
date-format separators remain), sort options (`n` / `g` / `B` / `C` / `f` / `e`
/ `t` / `h` / `p` / `q`), & `template-text`'s whitespace treatment.

## Step 7 (partial): Stale Spec References (2026-09-18 10:36 UTC)

Renamed stale nonterminal names in comments to the current specs' names:
`<field-spec-edits-section>`, `<block-terminator>`, `<format-block>`,
`<format-template>`, `<justify>`, `<field-spec-insertion>`,
`<strict-coercion>`, `<failure-block>`, `<string-block>`, `<number-block>`,
`<nullary-input>`; rewrapped the touched comment blocks to 80 columns. Names
for still-old-draft syntax (sort boundaries: `<boundaries-option-set>`,
`<grouped-boundaries>`, etc.; chronologic: `<date>`, `<input-date-format>`,
etc.) were left until that code is rewritten.

## Step 3 (partial): Sort Localization (2026-09-18 10:37 UTC)

`<localization>` now parses per fields.md: `l` is `<system-locale>` & `L`
begins `<custom-locale>`, whose `<locale-identifier>` runs to a required
`<sort-option-terminator>` (`+`); an empty identifier is the system default
locale. The other sort options (`<numbers-in-strings>`, `<boundaries>`,
`<nonconforming-location>`, `<trivia-order>`) still follow the old draft.

## Step 3 (partial): Name Placeholder (2026-09-18 10:38 UTC)

`%k` / `%K` (`<nullary-name>` / `<non-nullary-name>`) are parsed, as
placeholders & as `<unconditional-branch>`es, reusing `Placeholder.label`'s
`negated: true` representation for the field name; `%l` / `%L` / `%k` / `%K`
may no longer be negated (the old draft's `%-l` meant the field name).

## Step 3 (partial): `timeZone` Transform (2026-09-18 10:41 UTC)

The old-draft `localTimeZone` chronologic transform is replaced by
`timeZone<time-zone-arguments>` (`.timeZone:Asia/Tokyo:`, `:UTC:`, `:-05\:30:`,
`:system:`), setting the output time zone (last wins) & reporting
`invalidTransformArguments` for an unknown code. `.timeZone::` (an absent
`<time-zone-code>`, defaulting to `system`) is not yet accepted because the
old-draft parser still treats `::` as a pipeline terminator; rewriting
`<block-terminator>` handling to `+` alone will fix that.

## Stopped (2026-09-18 10:42 UTC)

Stopped ahead of the 11:00 UTC deadline with a clean tree (`Scripts/format`,
`Scripts/lint -AP`, `Scripts/build` & `Scripts/test` all pass; every step
above is committed). Remaining, in the original order:

- Step 2: ebnf.md outer bare whitespace treatment per production (only the
  existing trim of outer whitespace around text tokens exists); built-in
  `none` as `all` with every field spec hidden.
- Step 3: `%v` / `%V` version placeholders; `<abort-on-success>` /
  `<abort-on-failure>` (the `-` prefix still means the old draft's negation);
  `<lenient-coercion>` (`_`); type determinants & conformance; `+` as the sole
  `<block-terminator>` (the old `:` / `::` pipeline terminator remains);
  `template-text` whitespace; sort options `<numbers-in-strings>` (`x` / `n` /
  `g`, replacing `Interpretation` + `Grouping`), `<boundaries>` (`b` / `B…+` /
  `C…+` with `<boundary-groups>`, replacing the old `b…` syntax),
  `<nonconforming-location>`, `<trivia-order>`, multiple `<sort-option-set>`s
  per `<sort-modifier>`, & sorting by the field's type.
- Step 5: context stacks & persisted named configs (Temp/todo.md: massive
  effort).
- Step 6: re-derive `AppStoreFieldDefaults.swift` from mas.md's "Default Sort
  Options" once the sort option letters match fields.md.
- Step 7: rename the remaining old-draft nonterminal names in comments (sort
  boundaries, chronologic input / output formats) as that code is rewritten.
