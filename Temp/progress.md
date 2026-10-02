# Progress

## Status (2026-10-01)

All `--fields` / `--table` work is in 1 commit (`` TODO: `FieldsSpec`. ``).
`Specs/*.md` are implemented (audited 2026-10-01), except:

- Persisted named formats & custom named configs, including context stack
  lookup, as described by Temp/todo.md "Persisted Named Formats & Custom Named
  Configs" & by `// TODO:`s in `FieldSpec.swift` & `FormatParser.swift`: every
  `<named-format-reference>` reports `unknownNamedFormat`.
- Version fields' default format is `%V+%i+`, not mas.md's `%v` (Temp/todo.md
  "Implementation Questions").
- Behaviors pending the open questions in Temp/todo.md "Current Version", each
  marked by a `// TODO:` where implemented provisionally (e.g., `w`'s order, the
  `<output>` sort source's type).

## History

### Field Order & Item Sort Sections (2026-09-18)

`<field-order-section>` requires a `<field-order-option-set>` after `/` (a bare
`/` reports `missingFieldOrderOptionSet`); `<order-option-set>` supports
`<base-fields-config-order>` (`w`, `FieldOrder.base`) & `<original-input-order>`
(`o`); a `<sort-option-set>` there defaults its `<source>` to `<output>` (sort
by label). `<disable-all-sorts>` (`r`) sets each field spec's `<sort-priority>`
to `0`, retaining its `<sort-option-set>`s; priority-`0` sort keys are excluded
from `ItemSort.keys` (`[FieldSpec].enabledSortKeys`), so a later
`<field-spec-edit>` such as `.adamID/1` re-enables a sort.

### Hide, Unhide & Base-Sourced Insertion (2026-09-18, revised 2026-09-25)

`FieldSpec.isHidden` models hiding. `<field-spec-hide>` (`_`) overlays its
`<field-modifiers>` onto its source & hides it, inserting a new hidden field
spec iff its `<named-field-spec-reference>` resolves to no field spec (e.g.,
`_size/1d`); `<field-spec-overlay>` & `<field-spec-move>` unhide their source.
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
`TableConfig.headerStyling`; `<sgr-parameters>` apply iff `a` or standard output
is a terminal), defaults an absent `<separator-pattern>` to `-`, rejects a
`<separator-pattern>` / `<column-spacing>` containing a line terminator &
handles escaping (`\:`, `\\`, dangling `\` is an error) in `<separator-pattern>`
/ `<column-spacing>` text via `parseTableSettingText`; `<sgr-parameters>`
accepts no escape sequences. Comments & names use table.md's vocabulary
(`<table-setting-termination>`, `<table-setting-terminator>`,
`<end-of-table-config>`, `TableConfigParsingError.invalidSetting`).

### Placeholders & Transforms (2026-09-18, revised 2026-09-25)

Placeholder letters match fields-format.md (`%i`, `%l`, `%k`, `%c`, `%m`, `%b`,
`%v`, etc.). `timeZone<time-zone-arguments>` (e.g., `.timeZone:Asia/Tokyo:`,
`:UTC:`, `:-05\:30:`, `:system:`) sets the output time zone (last wins); it
matches IANA Time Zone Database identifiers, Foundation time zone abbreviations
& `system` case-insensitively, reports `invalidTransformArguments` for an
unknown `<time-zone-code>` & defaults an absent one to `system`. Versions are
`.`-separated components each starting with an ASCII digit. `<justify>` names
are `startJustify`, `endJustify`, `centerStartJustify` & `centerEndJustify`;
`Transform.initialTitlecase` matches `<initial-titlecase>`.

### Sort Localization (2026-09-18, revised 2026-09-25)

`<localization>`: `l` is `<system-locale>` & `L` starts `<custom-locale>`, whose
`<locale-identifier>` runs to a required `<sort-option-terminator>` (`+`;
`missingSortOptionTerminator` if absent); an empty identifier is the system
locale.

### Format Rewrite (2026-09-25)

`Format.swift` (AST, evaluation, type determinants) & `FormatParser.swift`
implement fields-format.md: a `<format-block>` is a `<pipeline>` (whose
`<format-transform-pipeline>` becomes `FieldSpec.justification`, retained iff
transitively absent) or a `<format-template>` (at least 1 placeholder); blocks
are `+`-terminated (`<block-terminator>`) with kinds per matcher (string,
boolean, number, chronologic, any, unconditional) & may contain placeholders;
placeholders support `<abort-on-success>`, `<abort-on-failure>`, `<coercion>` /
`<number-coercion>` (with trivia), block placeholders & match placeholders with
`<branch-negation>` & unconditional branches; template-text whitespace follows
the escaping appendix; forbidden whitespace after `%`, modifiers, `.` & `:` is
an error. An uncoerced transform on an input not of its input type throws
`FormattingError` at render time (surfaced via `OutputError`). An absent
`<format-block>` defaults to the nullary placeholder for the working format's
type determinant. The built-in `hidden` named format is gone (hiding is only
`<field-spec-hide>`). Tests are in
`Tests/MASTests/Models/FieldsOption/MASTests+Format*.swift`.

### Sort Rewrite (2026-09-25)

`SortSpec` is a `<sort-priority>` & its `<sort-option-set>`s (`SortOptionSet`:
`<source>`, `<direction>`, `<case-sensitivity>`, `<localization>`,
`<numbers-in-strings>`, `<boundaries>` with `<boundary-groups>` (default
`:space:`), `<nonconforming-comparison>` & `<trivia-order>`). A
`<sort-modifier>` accepts succeeding `/`-prefixed `<sort-option-set>`s. Values
compare per the field's type determinant (chronologic, version, number with
trivia, boolean, string, any), each value belonging to the 1st
`<sort-option-set>` whose type it conforms to. Each uncollapsed boundary is its
own segment, compared by group precedence alone.

### Built-In Fields Config Variants (2026-09-25)

`resolveBaseFieldsConfig` validates config names per configs.md
(`^[-_0-9A-Za-z]+$` plus an optional output format suffix & an optional `@none`
reference suffix), reports a nonexistent name & selects variants per suffix or,
absent one, the output format: `@json` is machine-facing
(`machineFacingVariant()`: label = name, format `%i`), `@none` / `@table` /
`@key-value` user-facing & `standard@json` is `all`. Per mas.md, built-in
`none`, `all` & `standard` differ only in which field specs are hidden: `none`
is `all` with every field spec hidden & user-facing `standard` is its own field
specs followed by `all`'s other field specs, hidden, so an overlay may select
any field (e.g., `@none.name,version`, `.bundleID`). `fetchFieldNames` fully
parses the value against the static base (fetching every field for a reference
to a field not yet discovered), excluding hidden field specs that don't sort
items.

### mas Defaults (2026-09-25)

mas.md's default sort options are in
`defaultSortOptionSet(forFieldNamed:outputFormat:)` (including `y` for
`formattedPrice`); price & version fields' default formats are typed (via
`defaultFieldFormat(forFieldNamed:)`), price fields' using mas.md's "Price
Coercion" with the App Store locale guessed from the macOS region.

### Field Spec References & Whitespace (2026-09-25)

An `<index-prefix>` requires an `<index>` (`missingIndex`); a
`<field-spec-removal>`'s `<reference-field-name>` is terminated only by `@` &
`,`, per the escaping appendix; outer bare whitespace around field spec edits'
syntax tokens (modifier prefixes, separators, index prefixes) is ignored;
trailing junk after a field spec reports `unexpectedCharacter`; & a trailing `,`
in a `<field-spec-edits-section>` is an error.

### Per-Item Original Input Order (2026-09-25)

`<original-input-order>` orders each item's fields independently by its own key
order (`FieldOrder.itemFieldSpecs(_:for:)`) for JSON & key-value output, and is
rejected for table output.

### Nonexistent Fields (2026-09-25)

Per fields.md's "Nonexistent Fields", a display command whose fields are all
known up front (`config`, via `OutputConfig.fieldNameSet`) reports a reference
to any other field (an absolute field name, an insertion, or a hide of an
unmatched name) as `nonexistentField`; other commands' fields can't be known up
front, so aren't checked.

### Spec Compliance Audit (2026-09-25)

Probed every fields-format.md, fields.md & table.md grammar construct & prose
example (~300 cases, via a throwaway test) against the parser & renderer, and
fixed every divergence (e.g., chronologic coercion of ISO-8601 strings & Unix
epoch numbers, extended ISO-8601 UTC offsets like `+09:00`, an explicit `s` with
`b` / `u` no longer implying a table header row).

### Spec Revision Updates (after 2026-09-27)

Implemented the 2026-09-27 spec revisions: `<number-coercion-arguments>` (base
conventions, `<trivia-prefix-regex>` & `<trivia-suffix-regex>`), `numberFormat`
(`NumberConventions.swift`), `scale`'s `<radix>`, `<exponent>`,
`<significant-digits>` & `<fractional-digits>`, `<custom-grouped-numeric>`
(`G…+`) & `<nonconforming-comparison>` (`y` / `z`).

### Shell Completions & README (2026-09-25)

`mas.fish` completes `--fields` (requiring a value), `--key-value` & `--table`
alongside `--json`, each output format option excluding the others; option
values aren't completed. `mas.bash` only completes commands, so it's unchanged.
`README.md`'s Output Formats section links the specs & gives verified `--fields`
/ `--table` examples.

### Spec Compliance Audit (2026-10-01)

Re-audited every spec against the code, fixing each divergence: input left over
after a `<field-order-section>` (e.g., `/w,x`, `/Ia/x`) reports
`unexpectedCharacter`; a whitespace-only `<field-order-option-set>` reports
`missingFieldOrderOptionSet`; `--table` ignores outer bare whitespace between
settings & around each `<sgr-parameter>` (e.g., `h s`, `H 1 ; 4 :`); &
`<locale-identifier>` accepts BCP 47 identifiers (e.g., `en-US`), as well as ICU
ones.

### Aborting Blocks, Justify Inheritance & Absent Values (2026-10-01)

A block that aborts (a success block, a failure block, or a branch's block) now
aborts the whole format, instead of falling back to the matcher's value, `""`,
or the next branch. An absent `<justify>` is inherited from the working fields
config (`<start-justify>` absent any to inherit, e.g., in a built-in config),
including in a `<pipeline>` whose `<format-transform-pipeline>` is directly
absent. fields.md's "Absent Values" now states once that an absent value is
output as an empty string unless its format renders it otherwise (e.g., via a
`<failure-block>`). Each change of this & the previous audit has tests.

### Absolute Configs & Exact Numbers (2026-10-01)

Each `<absolute-field-spec>` is a visible copy of the base fields config
`none`'s 1st field spec for its field (or of a field spec with default
settings), so it inherits mas's labels, typed formats, sorts & justification
(machine-facing for JSON), overlaid with its `<field-modifiers>`. Numbers are
processed exactly, of unlimited precision & magnitude, via `DecimalNumber` &
`BigInt`: comparisons (number, version & `<numeric>` / `<grouped-numeric>`
string sorting), coercion (a coerced number's canonical form retains its
notation, e.g., `1e3`) & `scale`; `<grouped-numeric>` compares each grouped
number, fractional part & exponent included, as 1 number. Chronologic Unix epoch
timestamps still go through `Date`'s `Double`.
