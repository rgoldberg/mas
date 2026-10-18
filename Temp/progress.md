# Progress

## Status (2026-10-09)

All `--fields` / `--table` work is in 1 commit (`` TODO: `FieldsSpec`. ``).
`Specs/*.md` are implemented (audited 2026-10-09), except:

- Persisted named formats & custom named configs, including context stack
  lookup, as described by [its open
  issues](todo.md#persisted-named-formats--custom-named-configs) & by
  `// TODO:`s in `FieldSpec.swift` & `FormatParser.swift`: every
  `<named-format-reference>` reports `unknownNamedFormat`.
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
(`FieldSpecsBuilder.baseFieldSpecs`), selecting the default field spec iff a
named reference matches nothing. Named references resolve against the reference
fields config's immutable positions (`referencePositions(forName:)`), so a field
spec removed earlier in the section keeps its position as `null` (referencing it
is an error), and a `<field-spec-hide>` of such a field inserts a hidden copy of
its base field spec. Output omits hidden field specs.

### Table Config (2026-09-18, revised 2026-09-25)

`parseTableConfig` supports `<header-styling-setting>` (`t` / `a`, stored as
`TableConfig.headerStyling`; the header row is styled iff `a` or standard output
is a terminal), defaults an absent `<separator-pattern>` to `-`, rejects a
`<separator-pattern>` / `<column-spacing>` that contains a line terminator &
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
once; it truncates each pattern before the 1st character that would exceed its
width, then fills any remaining width (e.g., after a truncated `中`) with spaces.
`<leader-setting>` is `f` / `F`; `<leading-spacing-setting>` (`l` / `L`) &
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

### Sort Locale (2026-09-18, revised 2026-10-15)

`<locale>` (`L`) has a `<locale-identifier>` that runs to a required
`<sort-option-terminator>` (`:`; `missingSortOptionTerminator` if absent): an
empty identifier is the system locale, and `canonical` (the default) identifies
the canonical conventions (`SortOptionSet.locale` is `nil`).
`<number-format-arguments>` also accept `canonical`.

### Format Rewrite (2026-09-25)

`Format.swift` (AST, evaluation, chronologic parsing) & `FormatParser.swift`
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
(surfaced via `OutputError`). An absent block or `<format-block>` defaults to an
empty string; the pipeline of a non-nullary unconditional placeholder or block
placeholder is mandatory. The built-in `hidden` named format is gone (hiding is
only `<field-spec-hide>`). Tests are in
`Tests/MASTests/Models/FieldsOption/MASTests+Format*.swift`.

### Sort Rewrite (2026-09-25, revised 2026-10-15)

`SortSpec` is a `<sort-priority>` & its `<sort-option-set>` (`SortOptionSet`:
`<source>`, `<direction>`, `<case-sensitivity>`, `<locale>`, `<number-segments>`
(`x`, `u`, `v`, or `N` with `<grouped-numeric-arguments>`, including
`<number-signs>`), `<chronologic-segments>` (`C` with `<chronologic-formats>`,
default `iso`), `<boundaries>` (`B` / `M`, an empty `<boundary-groups>` meaning
none; default `+space+`), `<nonconforming-comparison>` (`k`, `a`, or `z`) &
`<text-order>` (`h`, `t`, `p`, or `e`)); a `/` after it reports
`invalidSortOption`. A value compares as a string (`null` as `""`), except that
a number is a single number segment unless `<lexicographic>`: each run of
non-boundary text splits into chronologic, number & text segments, compared per
`<text-order>` element by element, by kind (time-only chronologic, other
chronologic, number, text), then per kind. Formats no longer type fields, so the
type determinant & `FieldSpec.outputsInput` are gone (a machine-facing variant's
format is `%i`). Each uncollapsed boundary is its own piece, compared by group
precedence alone.

### Time-Only Chronologic Values (2026-10-15)

`%c` also detects an ISO-8601 time-only (`Chronologic.time`), which is rendered
in a time zone as if on `timeZone`'s `<reference-date>` (its 2nd argument), else
on the current date in the system time zone (`Environment.now`). A time-only
value fails a chronologic predicate whose block applies `dateOnly` to it;
elsewhere, `dateOnly` on it is a value coercion failure.

### Unix Time (2026-10-18)

`chronologic(from:isCoerced:)` reads a number as a Unix time; it reads a string
whose entire content is a decimal number as one only with `<coercion>`, which
`%c` & `%C` now accept (e.g., `%.C` matches `"0"`). `<unix-time>` in
`<chronologic-formats>` (`SortOptionSet.hasUnixTimeSegments`) makes a number
value a single chronologic segment (`numberValueSegment(of:)`) & a decimal
number that is a whole whitespace-delimited word in a string a chronologic
segment (`unixTimeSegment(at:in:value:)`).

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
`defaultSortOptionSet(forFieldNamed:outputFormat:)`: `v` for version fields; `a`
& [grouped numbers](../Specs/mas.md#price-sorting) per the App Store locale
guessed from the macOS region for `formattedPrice`. Every field's default format
is `%i`.

### Field Spec References & Whitespace (2026-09-25)

A `<field-occurrence-index-prefix>` requires a `<field-occurrence-index>`
(`missingFieldOccurrenceIndex`) (whose default of `1` is only transitive) & a
`<field-spec-index-prefix>` requires a `<field-spec-index>`
(`missingFieldSpecIndex`); a `<field-spec-removal>`'s `<reference-field-name>`
is terminated only by `@` & `,`, per the [escaping
appendix](../Specs/fields.md#appendix-escaping); outer bare whitespace around
field spec edits' syntax tokens (modifier prefixes, separators, index prefixes)
is ignored; trailing junk after a field spec reports `unexpectedCharacter`; & a
trailing `,` in a `<field-spec-edits-section>` is an error.

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
Unix time numbers, extended ISO-8601 UTC offsets like `+09:00`, an explicit `s`
with `b` / `u` no longer implying a table header row).

### Spec Revision Updates (after 2026-09-27)

Implemented the 2026-09-27 spec revisions: `<number-coercion-arguments>` (base
conventions, `<trivia-prefix-regex>` & `<trivia-suffix-regex>`), `numberFormat`
(`NumberConventions.swift`), `scale`'s `<radix>`, `<exponent>`,
`<significant-digits>` & `<fractional-digits>`, `<grouped-numeric>` (`N…:`) &
`<nonconforming-comparison>` (`a` / `z`).

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
aborts the entire format, instead of falling back to the matcher's value, `""`,
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
settings), so it inherits mas's labels, formats, disabled sorts & justification
(machine-facing for JSON), overlaid with its `<field-modifiers>`. Numbers are
processed exactly, of unlimited precision & magnitude, via `DecimalNumber` &
`BigInt`: comparisons (number & version segments), coercion (a coerced number's
canonical form retains its notation, e.g., `1e3`) & `scale`; `<grouped-numeric>`
compares each grouped number, fractional part & exponent included, as 1 number.
Chronologic Unix times still go through `Date`'s `Double`.

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

`H` / `K` take a `<style-specifier>`, a [constrained text
terminal](../Specs/ebnf.md#constrained-text-terminals) parsed by
`parseStyleSpecifier`, which ignores its outer bare whitespace & rejects a bare
ASCII letter. `styled` wraps a styled string in `StyleSequences`
(`TableConfig.headerStyleSequences` / `KeyValueConfig.keyStyleSequences`):
`<style-prefix>` (`p` / `P`, default `ESC[`), `<style-specifier>` &
`<style-suffix>` (`x` / `X`, default `m`) precede it; `<style-reset>` (`o` /
`O`, default `ESC[0m`) follows it. Every output config setting payload is a
`{text}` token.

### Integer Scalar Descriptions (2026-10-10)

`scale` constrains `<significant-digits>` from 1 to 100 & `<fractional-digits>`
from 0 to 100, bounding its calculation & output length.

Integer descriptions' scalar tokens are consumed via maximal munch by
`parseIntegerText`: ASCII digits, after an optional sign only for `<index>`.
Their magnitudes are unconstrained: an `<index>` beyond `Int`'s range reports
`invalidPosition`, `<sort-priority>` is a `BigUInt` & `nonNegativeInteger`
saturates at `Int.max`. `scale` renders `0` without calculating `radix^exponent`
for a huge `<exponent>`.

A Unix time is chronologic iff its whole milliseconds, rounded down, fit in a
signed 64-bit integer, as `unixTimeDate` already implemented.

A value that `scale` would render with more than 100 digits before the radix
point does not conform to its input type, so `Transform.applied(to:)` returns
`nil` for it: an uncoerced `scale` reports `transformInputTypeMismatch`, while a
coerced one aborts. `radixScaled` estimates the result's radix magnitude from
the value's exponent, to skip calculating a result that is too large or that
renders as `0`.

`round` calculates no power of 10 larger than its value's significand: an
integer value is its own result & a value less than `0.1` rounds to `0`, so a
huge exponent no longer hangs it.

`ScaledMagnitude` rounds `scale`'s magnitude without calculating powers of 10 or
of `<radix>` larger than its result needs, so a huge field value & a huge
`<exponent>` that nearly cancel no longer hang `scale`: it approximates with
doubling precision until the approximation decides each rounding, deciding a
value exactly at a rounding boundary via its prime factorization.

### Value Types (2026-10-18)

Formats evaluate to [typed values](../Specs/fields-format.md#value-types):
`Format.evaluated(in:)` returns a `FormatValue` (a template that is solely 1
placeholder has that placeholder's value; any other template concatenates its
elements' values, each coerced to a string), which `FormatValue.node` gives as a
field spec's formatted value: e.g., `%N%n+%i+` gives `null` for `null`, `.round`
gives a number, while `numberFormat`, a chronologic value & a number whose text
(trivia included) is not JSON number syntax (e.g., `.scale:16,0,,0:`'s `ff`)
give strings. `table` & `key-value` output render it coerced to a string, while
`<output>` sorts by it for every output format. Type comments are `type:`,
`input type:` & `output type:`; every predicate's is an `output type:`.

### Structured Values (2026-10-18)

A [structured value](../Specs/fields-format.md#value-types) (an array or an
object) is rendered at its type by `json` output & coerced to its compact JSON
text (non-ASCII characters verbatim) everywhere else, including `table` &
`key-value` output & sorting; no predicate whose output type is not any matches
one. A bare `.` in a field name reports `reservedFieldNameCharacter`, reserving
it for nested field references; `\.` names a field that contains `.`.

### ISO-8601 Detection Variants (2026-10-18)

Chronologic auto-detection also accepts RFC 3339's `t` or space separator & `z`
UTC offset, and a datetime without seconds (e.g., `2020-03-18 17:39`); basic
format, ordinal dates, week dates & other reduced precision remain undetected,
because most collide with numbers, ratios, ranges, or IDs.

### Typed Segments Before Boundaries (2026-10-18)

Sorting detects [typed segments](../Specs/fields.md#sort-segments) throughout
the entire value before boundaries (`SortOptionSet.pieces(of:)`), so a boundary
within a typed segment is part of it (e.g., `2020-03-18 17:39` is 1 datetime
segment & `1 000` is 1 grouped number when space is its digit group separator);
boundaries split only the remaining text.

### Spec Review Fixes (2026-10-18)

`%v` & `%V` match a string whose entire content is a `<versions>` sort segment's
version (`versionRegex`), so they no longer match a component with characters
other than Unicode general category `L` or `N` characters, `+`s & `-`s (e.g.,
`1.0 beta`).

A `<time-zone-code>` UTC offset may also be a 2-digit hour & a 2-digit minute
without a `:` (e.g., `+0530`), as an ISO-8601 UTC offset may.

`%u`, `%e` & `%w` (& their non-nullary forms) evaluate to the field value
instead of `""` (e.g., `%w` inserts a whitespace-only string as is, and `json`
output renders a solely-`%u` format's value as `null`).

A `<leader-pattern>` or `<item-separator-pattern>` that contains a line
terminator reports `invalidLeaderPattern` / `invalidItemSeparatorPattern`, as a
table's `<separator-pattern>` & `<column-spacing>` do.

A `<trivia-suffix-regex>` is the last argument of `<number-coercion-arguments>`,
so a bare `,` in it is part of it instead of an error (e.g., `%.:,,,,,,,.*:n`
matches `"5,x"`).
