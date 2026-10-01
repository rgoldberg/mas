# Progress

## Status (2026-10-09)

All `--fields` / `--table` work is in 1 commit (`` TODO: `FieldsSpec`. ``).
`Specs/*.md` are implemented (audited 2026-10-09), except:

- Persisted named formats & custom named configs, including context stack
  lookup, as described by [its open
  issues](todo.md#persisted-named-formats--custom-named-configs) & by
  `// TODO:`s in `FieldSpec.swift` & `FormatParser.swift`: every
  `<named-format-reference>` reports `unknownNamedFormat`.
- Version fields' default format is `%V+%i+`, not the
  [specified](../Specs/mas.md#default-sort-options) `%v` ([open
  question](todo.md#formatting)).
- Behaviors pending the [open questions for the current
  version](todo.md#current-version), each marked by a `// TODO:` where
  implemented provisionally (e.g., the `<output>` sort source's type).

## History

### Field Order & Item Sort Sections (2026-09-18)

`<field-order-section>` requires a `<field-order-option-set>` after `/` (a bare
`/` reports `missingFieldOrderOptionSet`); it supports
`<positional-order-option-set>` (`P`, `FieldOrder.positional`) &
`<document-order-option-set>` (`D`); a `<sort-option-set>` there defaults its
`<source>` to `<output>` (sort by label). `<disable-all-sorts>` (`0`) sets each
field spec's `<sort-priority>` to `0`, retaining its `<sort-option-set>`s;
priority-`0` sort keys are excluded from `ItemSort.keys`
(`[FieldSpec].enabledSortKeys`), so a later `<field-spec-edit>` such as
`.adamID/1` re-enables a sort.

### Hide, Unhide & Base-Sourced Insertion (2026-09-18, revised 2026-09-25)

`FieldSpec.isHidden` models hiding. `<field-spec-hide>` (`_`) overlays its
`<field-modifiers>` onto its source & hides it, inserting a new hidden field
spec iff its `<named-field-spec-reference>` resolves to no field spec (e.g.,
`_size/1-`); `<field-spec-overlay>` & `<field-spec-move>` unhide their source.
`<field-spec-insertion>` takes a full `<field-spec-reference>` (`+name`,
`+name@i`, `+@i`) resolved against the immutable base fields config
(`FieldSpecsBuilder.baseFieldSpecs`), selecting default settings iff a named
reference matches nothing. Named references resolve against the reference fields
config's immutable positions (`referencePositions(forName:)`), so a field spec
removed earlier in the section keeps its position as `null` (referencing it is
an error), and a `<field-spec-hide>` of such a field inserts a hidden copy of
its base field spec. Output omits hidden field specs.

### Table Config (2026-09-18, revised 2026-09-25)

`parseTableConfig` supports `<header-styling-setting>` (`t` / `a`, stored as
`TableConfig.headerStyling`; the header row is styled iff `a` or standard output
is a terminal), defaults an absent `<separator-pattern>` to `-`, rejects a
`<separator-pattern>` / `<column-spacing>` containing a line terminator &
handles escaping (`\:`, `\\`, dangling `\` is an error) in `<separator-pattern>`
/ `<column-spacing>` text via `parseTableSettingText`; `<style-specifier>` is
parsed via `parseStyleSpecifier`. Comments & names use the [table
spec's](../Specs/table.md) vocabulary (`<table-setting-termination>`,
`<table-setting-terminator>`, `<end-of-table-config>`,
`TableConfigParsingError.invalidSetting`).

### Key-Value Config (2026-10-02)

`parseKeyValueConfig` parses [`--key-value`'s
value](../Specs/key-value.md#key-value-config) into `KeyValueConfig`, sharing
`parseOutputConfigSettingPayload`, `parseStyleSpecifier` & `styled`
(`OutputConfigSetting.swift`) with `parseTableConfig`; `K` requires a non-empty
`<style-specifier>`. `repeatedPattern` (formerly `repeatedTablePattern`) also
fills leaders & item separator lines, printing a 0-width pattern (e.g., a tab)
once. `<leader-setting>` is `f` / `F`; `<leading-spacing-setting>` (`l` / `L`) &
`<trailing-spacing-setting>` (`r` / `R`) set `KeyValueConfig.leadingSpacing` &
`.trailingSpacing`; `f` implies a leading spacing of `:`, if none is otherwise
set.

### JSON Config (2026-10-02)

`parseJSONConfig` parses [`--json`'s value](../Specs/json.md#json-config) into
`JSONConfig`; `JSON.Node.rendered(jsonConfig:)` pretty-prints & escapes
non-ASCII characters (lowercase hex `\uXXXX`). For 0 items, `a` renders `[]`:
`list` now outputs after its "Failed to find any installed apps" warning, while
`search` still reports `noCatalogAppsFound`. Like `--table`, `--key-value` &
`--json` consume the next argument as their value, so a positional argument must
not immediately follow them (e.g., `mas lookup 497799835 --json`, not
`mas lookup --json 497799835`).

### Placeholders & Transforms (2026-09-18, revised 2026-09-25)

Placeholder letters match the [placeholders
spec](../Specs/fields-format.md#placeholders) (`%i`, `%l`, `%k`, `%c`, `%m`,
`%b`, `%v`, etc.). `timeZone<time-zone-arguments>` (e.g.,
`.timeZone:Asia/Tokyo:`, `:UTC:`, `:-05\:30:`, `:system:`) sets the output time
zone (last wins); it matches IANA Time Zone Database identifiers, Foundation
time zone abbreviations & `system` case-insensitively, reports
`invalidTransformArguments` for an unknown `<time-zone-code>` & defaults an
absent one to `system`. Versions are `.`-separated components each starting with
an ASCII digit. `<justify>` names are `startJustify`, `endJustify`,
`centerStartJustify` & `centerEndJustify`; `Transform.initialTitlecase` matches
`<initial-titlecase>`.

### Sort Localization (2026-09-18, revised 2026-09-25)

`<localization>`: `l` is `<system-locale>` & `L` starts `<custom-locale>`, whose
`<locale-identifier>` runs to a required `<sort-option-terminator>` (`:`;
`missingSortOptionTerminator` if absent); an empty identifier is the system
locale.

### Format Rewrite (2026-09-25)

`Format.swift` (AST, evaluation, type determinants) & `FormatParser.swift`
implement [formatting](../Specs/fields-format.md#formatting): a `<format-block>`
is a `<pipeline>` (whose `<format-transform-pipeline>` becomes
`FieldSpec.justification`, retained iff transitively absent) or a
`<format-template>` (at least 1 placeholder); blocks are `+`-terminated
(`<block-terminator>`) with kinds per matcher (string, boolean, number,
chronologic, any, unconditional) & may contain placeholders; placeholders
support `<abort-on-success>`, `<abort-on-failure>`, `<coercion>` /
`<number-coercion>` (with trivia), block placeholders & match placeholders with
`<branch-negation>` & unconditional branches; template-text whitespace follows
the [escaping appendix](../Specs/fields.md#appendix-escaping); forbidden
whitespace after `%`, modifiers, `.` & `:` is an error. An uncoerced transform
on an input not of its input type throws `FormattingError` at render time
(surfaced via `OutputError`). An absent `<format-block>` defaults to the nullary
placeholder for the working format's type determinant. The built-in `hidden`
named format is gone (hiding is only `<field-spec-hide>`). Tests are in
`Tests/MASTests/Models/FieldsOption/MASTests+Format*.swift`.

### Sort Rewrite (2026-09-25)

`SortSpec` is a `<sort-priority>` & its `<sort-option-set>`s (`SortOptionSet`:
`<source>`, `<direction>`, `<case-sensitivity>`, `<localization>`,
`<numbers-in-strings>`, `<boundaries>` with `<boundary-groups>` (default
`+space+`), `<nonconforming-comparison>` & `<trivia-order>`). A
`<sort-modifier>` accepts succeeding `/`-prefixed `<sort-option-set>`s. Values
compare per the field's type determinant (chronologic, version, number with
trivia, boolean, string, any), each value belonging to the 1st
`<sort-option-set>` whose type it conforms to. Each uncollapsed boundary is its
own segment, compared by group precedence alone.

### Built-In Fields Config Variants (2026-09-25)

`resolveBaseFieldsConfig` validates config names [per
spec](../Specs/configs.md#named-configs) (`^[-_0-9A-Za-z]+$` plus an optional
output format suffix & an optional `@none` reference suffix), reports a
nonexistent name & selects variants per suffix or, absent one, the output
format: `@json` is machine-facing (`machineFacingVariant()`: label = name,
output formatted as `%i`, format retained to type the field), `@none` / `@table`
/ `@key-value` user-facing & `standard@json` is `all`. [Per
spec](../Specs/mas.md#built-in-named-fields-configs), built-in `none`, `all` &
`standard` differ only in which field specs are hidden: `none` is `all` with
every field spec hidden & its sort disabled; user-facing `standard` is its own
field specs followed by `all`'s other field specs, hidden, so an overlay may
select any field (e.g., `@none.name,version`, `.bundleID`). `fetchFieldNames`
fully parses the value against the static base (fetching every field for a
reference to a field not yet discovered), excluding hidden field specs that do
not sort items.

### mas Defaults (2026-09-25)

[mas's default sort options](../Specs/mas.md#default-sort-options) are in
`defaultSortOptionSet(forFieldNamed:outputFormat:)` (including `a` for
`formattedPrice`); price & version fields' default formats are typed (via
`defaultFieldFormat(forFieldNamed:)`), price fields' using [price
coercion](../Specs/mas.md#price-coercion) with the App Store locale guessed from
the macOS region.

### Field Spec References & Whitespace (2026-09-25)

An `<index-prefix>` requires an `<index>` (`missingIndex`); a
`<field-spec-removal>`'s `<reference-field-name>` is terminated only by `@` &
`,`, per the [escaping appendix](../Specs/fields.md#appendix-escaping); outer
bare whitespace around field spec edits' syntax tokens (modifier prefixes,
separators, index prefixes) is ignored; trailing junk after a field spec reports
`unexpectedCharacter`; & a trailing `,` in a `<field-spec-edits-section>` is an
error.

### Per-Item Document Order (2026-09-25)

`<document-order>` orders each item's fields independently by its own key order
(`FieldOrder.itemFieldSpecs(_:for:)`) for JSON & key-value output, and is
rejected for table output.

### Nonexistent Fields (2026-09-25)

[Per spec](../Specs/fields.md#nonexistent-fields), a display command whose
fields are all known up front (`config`, via `OutputConfig.fieldNameSet`)
reports a reference to any other field (an absolute field name, an insertion, or
a hide of an unmatched name) as `nonexistentField`; other commands' fields
cannot be known up front, so are not checked.

### Spec Compliance Audit (2026-09-25)

Probed every [formatting](../Specs/fields-format.md),
[fields](../Specs/fields.md) & [table](../Specs/table.md) grammar construct &
prose example (~300 cases, via a throwaway test) against the parser & renderer,
and fixed every divergence (e.g., chronologic coercion of ISO-8601 strings &
Unix epoch numbers, extended ISO-8601 UTC offsets like `+09:00`, an explicit `s`
with `b` / `u` no longer implying a table header row).

### Spec Revision Updates (after 2026-09-27)

Implemented the 2026-09-27 spec revisions: `<number-coercion-arguments>` (base
conventions, `<trivia-prefix-regex>` & `<trivia-suffix-regex>`), `numberFormat`
(`NumberConventions.swift`), `scale`'s `<radix>`, `<exponent>`,
`<significant-digits>` & `<fractional-digits>`, `<custom-grouped-numeric>`
(`G…:`) & `<nonconforming-comparison>` (`a` / `z`).

### Shell Completions & README (2026-09-25)

`mas.fish` completes `--fields` (requiring a value), `--key-value` & `--table`
alongside `--json`, each output format option excluding the others; option
values are not completed. `mas.bash` only completes commands, so it is
unchanged. The [output formats documentation](../README.md#output-formats) links
the specs & gives verified `--fields` / `--table` examples.

### Spec Compliance Audit (2026-10-01)

Re-audited every spec against the code, fixing each divergence: input left over
after a `<field-order-section>` (e.g., `/P,x`, `/Ia/dx`) reports
`unexpectedCharacter`; a whitespace-only `<field-order-option-set>` reports
`missingFieldOrderOptionSet`; `--table` ignores outer bare whitespace between
settings & around a `<style-specifier>` (e.g., `h s`, `H 1;4 :`); &
`<locale-identifier>` accepts BCP 47 identifiers (e.g., `en-US`), as well as ICU
ones.

### Aborting Blocks, Justify Inheritance & Absent Values (2026-10-01)

A block that aborts (a success block, a failure block, or a branch's block) now
aborts the whole format, instead of falling back to the matcher's value, `""`,
or the next branch. An absent `<justify>` is inherited from the working fields
config (`<start-justify>` absent any to inherit, e.g., in a built-in config),
including in a `<pipeline>` whose `<format-transform-pipeline>` is directly
absent. The [absent values spec](../Specs/fields.md#absent-values) now states
once that an absent value is output as an empty string unless its format renders
it otherwise (e.g., via a `<failure-block>`). Each change of this & the previous
audit has tests.

### Absolute Configs & Exact Numbers (2026-10-01)

Each `<absolute-field-spec>` is a visible copy of the base fields config
`none`'s 1st field spec for its field (or of a field spec with default
settings), so it inherits mas's labels, typed formats, disabled sorts &
justification (machine-facing for JSON), overlaid with its `<field-modifiers>`.
Numbers are processed exactly, of unlimited precision & magnitude, via
`DecimalNumber` & `BigInt`: comparisons (number, version & `<numeric>` /
`<grouped-numeric>` string sorting), coercion (a coerced number's canonical form
retains its notation, e.g., `1e3`) & `scale`; `<grouped-numeric>` compares each
grouped number, fractional part & exponent included, as 1 number. Chronologic
Unix epoch timestamps still go through `Date`'s `Double`.

### Field Order Tiebreaker (2026-10-06)

`<field-order-tiebreaker>` (e.g., `/I+/-`, `/D/-`) orders field specs that the
field order ties by position, or by reverse position iff its `<direction>` is
`<descending>` (`FieldOrder.byName` / `.byLabel` / `.document`'s
`tiebreakDirection`); no other `<direction>` affects their order, so `/D-` no
longer reverses ties. A `/` lacking a `<direction>` reports
`missingFieldOrderTiebreakerDirection`; a tiebreaker under `<positional-order>`
reports `tiebreakerUnsupportedForPositionalOrder`.

### Positional Order & Absolute Config Equivalence (2026-10-08)

`<positional-order>` (`P`, `FieldOrder.positional`) orders field specs by
position in the working fields config, after `<field-spec-edits-section>`; its
`<descending>` reverses the working, reference & base field specs' positions
before `<field-spec-edits-section>`, so edits & each `<index>` apply to the
reversed positions. An `<absolute-config>` is equivalent to `@none/P` followed
by a `<field-spec-insertion>` per field spec, so its fields config's field order
is `.positional`; `none`'s field specs' sorts are disabled, so its leftover
hidden field specs never affect output.

### Spec Compliance Audit (2026-10-09)

Re-audited every spec against the code, fixing each divergence: chronologic
auto-detection requires a string's entire content to be an ISO-8601
extended-format datetime or date-only, whose every field is in range, instead of
Foundation's lenient parsing, which accepted trailing text, unpadded fields &
out-of-range fields (e.g., `2020-02-30`), and read the local datetime
`2020-03-18T17:39:23` as date-only; a datetime may have a `,` decimal sign &
omit its UTC offset (for the system time zone); fractional seconds are truncated
to whole milliseconds exactly (e.g., `.3` no longer renders as `.299`); each
sort key's `<output>` values use its own field spec's format & label, even if
another field spec has the same field name; & a machine-facing variant formats
only its output as `%i`, retaining each field spec's format to type its field
(e.g., so `@json` sorts prices as numbers & versions as versions).

### Style Settings (2026-10-10)

`H` / `K` take a `<style-specifier>`, a [described constrained text
terminal](../Specs/ebnf.md#described-constrained-text-terminals) parsed by
`parseStyleSpecifier`, which ignores its outer bare whitespace & rejects a bare
ASCII letter. `styled` wraps a styled string in `StyleSequences`
(`TableConfig.headerStyleSequences` / `KeyValueConfig.keyStyleSequences`):
`<style-prefix>` (`p` / `P`, default `ESC[`), `<style-specifier>` &
`<style-suffix>` (`x` / `X`, default `m`) precede it; `<style-reset>` (`o` /
`O`, default `ESC[0m`) follows it. Every output config setting payload is a
`{text}` token.
