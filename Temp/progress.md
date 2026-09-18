# Progress

## Step 1: Gap List (2026-09-18 10:18 UTC)

Spec production → existing code → keep / change / missing. Existing code was
written against older drafts; nonterminal names in comments are stale
throughout (e.g., `<field-specs-section>` → `<field-spec-edits-section>`,
`<original-order-option-set>` → `<order-option-set>`, `<pipeline-terminator>`
→ `<block-terminator>`, `<format>` → `<format-block>`).

### ebnf.md

| Production / rule                    | Existing code                                                  | Verdict |
|:-------------------------------------|:---------------------------------------------------------------|:--------|
| Escaping (`\` + any character)       | `parseEscapedText` in `FieldSpec.swift`                        | keep    |
| Dangling escape prefix is an error   | `ParsingError.danglingEscape`                                  | keep    |
| Outer bare whitespace treatment      | Only leading whitespace of the entire value is dropped         | change  |
| Longest syntax literal wins          | Ad hoc per section (`//` vs `/` checked by `hasPrefix`)        | keep    |
| Transitive default = working value   | `existing` / `defaults:` parameters                            | keep    |
| Direct default resets                | `name=` / `name:` / `name/` reset via empty-payload checks     | keep    |
| `(* last wins *)`                    | Per-axis last-wins in `parseOptions`                           | keep    |

### fields.md

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
| Bare `/` (`.workingOrder`)                | Present; spec has no such state (default source `<output>`) | change |
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

### fields-format.md

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
| `<abort-on-success>` `-` / `<abort-on-failure>` `+` | `placeholderNegation` only                      | change  |
| `<lenient-coercion>` `_`                     | none                                                   | missing |
| Standard predicates `u e w b t f s`          | `StandardKind` uses `o` for boolean; spec uses `b`     | change  |
| Nullary / non-nullary (case) forms           | present                                                | keep    |
| `<block-terminator>` `+`                     | `formatDelimiter`                                      | keep    |
| Number / version / chronologic `n v c`       | `Placeholder` cases                                    | keep    |
| Match placeholders `m` / `M` + branches      | `Branches`, `Branch`                                   | keep    |
| Type determinant / conformance               | none                                                   | missing |
| Abort semantics (empty output)               | `renderedParts` returns `nil`                          | keep    |

### table.md

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

### configs.md & mas.md

| Rule                                      | Existing code                                  | Verdict |
|:------------------------------------------|:-----------------------------------------------|:--------|
| Context stack lookup                      | none (only built-ins per command)              | missing |
| Custom named configs                      | none (Temp/todo.md: massive effort)            | missing |
| `standard@json` → `all`                   | `appliesJSONSubstitution`                      | keep    |
| Built-in `none` / `all` / `standard`      | `resolveBaseFieldsConfig`                      | keep    |
| Machine-facing `@json` label = name, `%i` | `defaultedForJSON`                             | keep    |
| Default sort options table                | `AppStoreFieldDefaults.swift` (old letters)    | change  |
| Per-command default output format         | `OutputConfig.defaultFormat`                   | keep    |

## Stopped (2026-09-18 10:18 UTC)

Only step 1 was completed before the 11:00 UTC deadline; no code was changed.
Step 2 should begin with `<field-order-section>` (`w`, drop `.workingOrder`),
`<item-sort-section>` (`r` → priority `0`), & `<field-spec-hide>` (`_`).
