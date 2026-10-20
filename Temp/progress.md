# Progress

## Status (2026-10-19)

`Specs/*.md` are implemented (audited 2026-10-19, then implemented with each
later spec change), except persisted named formats & custom named configs,
including context stack lookup, as described by [their open
issues](todo.md#persisted-custom-named-formats--configs) & by `// TODO:`s in
`Format.swift`, `FieldSpec.swift` & `FormatParser.swift`: every
`<named-format-reference>` reports `unknownNamedFormat`.

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

### Hide, Unhide & Baseline-Sourced Insertion (2026-09-18, revised 2026-10-19)

`FieldSpec.isHidden` models hiding. `<field-spec-hide>` (`_`) overlays its
`<field-modifiers>` onto its source & hides it, inserting a new hidden field
spec iff its `<named-field-spec-reference>`'s `<reference-field-name>` names no
field spec (e.g., `_size/1-`); `<field-spec-overlay>` & `<field-spec-move>`
unhide their source. `<field-spec-insertion>` takes a full
`<field-spec-reference>` (`+name`, `+name@i`, `+@i`) resolved against the
immutable baseline fields config (`FieldSpecsBuilder.baselineFieldSpecs`), so
`<disable-all-sorts>` & `/P-`'s reversal apply to it, selecting the default
field spec iff a named reference's name names no field spec. Named references
resolve against the reference fields config's immutable positions
(`referencePositions(forName:)`), so a field spec removed earlier in the section
retains its position as `null` (referencing it is an error), and a
`<field-spec-hide>` of such a field inserts a hidden copy of its baseline field
spec. Output omits hidden field specs.

### Table Config (2026-09-18, revised 2026-09-25)

`parseTableConfig` supports `<header-styling-setting>` (`t` / `a`, stored as
`TableConfig.headerStyling`; the header row is styled iff `a` or standard output
is a terminal), defaults an absent `<separator-pattern>` to `-`, reports an
error for a `<separator-pattern>` / `<column-spacing>` that contains a line
terminator & handles escaping (`\:`, `\\`, dangling `\` is an error) in
`<separator-pattern>` / `<column-spacing>` text via `parseTableSettingText`;
`<style-specifier>` is parsed via `parseStyleSpecifier`. Comments & names use
the [table spec's](../Specs/table.md) vocabulary (`<table-setting-termination>`,
`<table-setting-terminator>`, `<end-of-table-config>`,
`TableConfigParsingError.invalidSetting`).

### Key-Value Config (2026-10-02)

`parseKeyValueConfig` parses [`--key-value`'s
value](../Specs/key-value.md#key-value-config) into `KeyValueConfig`, sharing
`parseOutputConfigSettingPayload`, `parseStyleSpecifier` & `styled`
(`OutputConfigSetting.swift`) with `parseTableConfig`; `K` requires a non-empty
`<style-specifier>`. `repeatedPattern` also fills leaders & item separator
lines, printing a 0-width pattern (e.g., a tab) once; it truncates each pattern
before the 1st character that would exceed its width, then fills any remaining
width (e.g., after a truncated `中`) with spaces. `<leader-setting>` is `f` /
`F`; `<leading-spacing-setting>` (`l` / `L`) & `<trailing-spacing-setting>` (`r`
/ `R`) set `KeyValueConfig.leadingSpacing` & `.trailingSpacing`; `f` implies a
leading spacing of `:`, if none is otherwise set.

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
`FieldSpec.justification`, inherited iff absent) or a `<format-template>` (at
least 1 placeholder); blocks are `+`-terminated (`<block-terminator>`) with
kinds per matcher (string, boolean, number, chronologic, any, unconditional) &
may contain placeholders; placeholders support `<abort-on-success>`,
`<abort-on-failure>`, `<coercion>` / `<number-coercion>` (with trivia), block
placeholders & match placeholders with `<branch-negation>` & unconditional
branches; template-text whitespace follows the [escaping
appendix](../Specs/fields.md#appendix-escaping); forbidden whitespace after `%`,
modifiers, `.` & `:` is an error. An uncoerced transform on an input not of its
input type throws `FormattingError` at render time (surfaced via `OutputError`).
An absent block or `<format-block>` defaults to an empty string; the pipeline of
a non-nullary unconditional placeholder or block placeholder is mandatory.
Hiding is only `<field-spec-hide>`. Tests are in
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
chronologic, number, text), then per kind. Formats do not type fields (a
machine-facing variant's format is `%i`). Each uncollapsed boundary is its own
piece, compared by group precedence alone.

### Time-Only Chronologic Values (2026-10-15)

Chronologic auto-detection also detects an ISO-8601 time-only
(`Chronologic.time`), which is rendered in a time zone as if on `timeZone`'s
`<reference-date>` (its 2nd argument), else on the current date in the system
time zone (`Environment.now`); `dateOnly` on it is a value coercion failure.

### Unix Time (2026-10-18)

`chronologic(from:isCoerced:)` interprets a number as a Unix time; it interprets
a string whose entire content is a decimal number as one only with `<coercion>`,
which `%d` & `%D` accept (e.g., `%.D` matches `"0"`). `<unix-time>` in
`<chronologic-formats>` (`SortOptionSet.hasUnixTimeSegments`) makes a number
value a single chronologic segment (`numberValueSegment(of:)`) & a decimal
number that is a whole whitespace-delimited word in a string a chronologic
segment (`unixTimeSegment(at:in:value:)`).

### Built-In Fields Config Variants (2026-09-25)

`resolveBaseFieldsConfig` validates config names [per
spec](../Specs/configs.md#named-configs) (`^[-_0-9A-Za-z]+$` plus an optional
output format suffix & an optional `@unsuffixed` reference suffix), reports a
nonexistent name & selects variants per suffix or, absent one, the output
format: `@json` is machine-facing (`machineFacingVariant()`: label = name,
format = `%i`), `@unsuffixed` / `@table` / `@key-value` user-facing &
`standard@json` is `all@json`. [Per
spec](../Specs/mas.md#built-in-named-fields-configs), every field is in each of
built-in `none`, `all` & `standard`: `none` is `all` with every field spec
hidden & its sort disabled; user-facing `standard` is its own field specs
followed by `all`'s other field specs, hidden, so an overlay may select any
field (e.g., `@none.name,version`, `.bundleID`). `fetchFieldNames` fully parses
the value against the static base (fetching every field for a reference to a
field not yet discovered), excluding hidden field specs that do not sort items.

### mas Defaults (2026-09-25)

[mas's default sort options](../Specs/mas.md#default-sort-options) are in
`defaultSortOptionSet(forFieldNamed:outputFormat:)`: `v` for version fields; `a`
& [grouped numbers](../Specs/mas.md#price-sorting) per the App Store locale
guessed from the macOS region for `formattedPrice`. Every field's machine-facing
default format is `%i`.

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
(`FieldOrder.itemFieldSpecs(_:for:)`) for JSON & key-value output, and is an
error for table output.

### Nonexistent Fields (2026-09-25)

[Per spec](../Specs/fields.md#nonexistent-fields), a display command whose
fields are all known up front (`config`, via `OutputConfig.fieldNameSet`)
reports a reference to any other field (an absolute field name, an insertion, or
a hide of an unmatched name) as `nonexistentField`; other commands' fields
cannot be known up front, so are not checked.

### Spec Compliance Audit (2026-09-25)

Probed every [formatting](../Specs/fields-format.md),
[fields](../Specs/fields.md) & [table](../Specs/table.md) grammar expression &
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
`none`'s 1st field spec for its field (or of its default field spec), so it
inherits mas's labels, formats, disabled sorts & justification (machine-facing
for JSON), overlaid with its `<field-modifiers>`. Numbers are processed exactly,
of unlimited precision & magnitude, via `DecimalNumber` & `BigInt`: comparisons
(number & version segments), coercion (a coerced number's canonical form retains
its notation, e.g., `1e3`) & `scale`; `<grouped-numeric>` compares each grouped
number, fractional part & exponent included, as 1 number. Chronologic instants
are exact milliseconds (`Int`), not `Date`'s `Double`.

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
`<descending>` reverses the working & reference field specs' positions before
`<field-spec-edits-section>`, so edits & each `<index>` apply to the reversed
positions. An `<absolute-config>` is equivalent to `@none/P` followed by a
`<field-spec-insertion>` per field spec, so its fields config's field order is
`.positional`; `none`'s field specs' sorts are disabled, so its leftover hidden
field specs never affect output.

### Spec Compliance Audit (2026-10-09)

Re-audited every spec against the code, fixing each divergence: chronologic
auto-detection requires a string's entire content to be an ISO-8601
extended-format datetime or date-only, whose every field is in range, instead of
Foundation's lenient parsing, which accepted trailing text, unpadded fields &
out-of-range fields (e.g., `2020-02-30`), and interpreted the local datetime
`2020-03-18T17:39:23` as date-only; a datetime may have a `,` decimal sign &
omit its UTC offset (for the system time zone); fractional seconds are truncated
to whole milliseconds exactly (e.g., `.3` no longer renders as `.299`); & each
sort key's `<output>` values use its own field spec's format & label, even if
another field spec has the same field name.

### Style Settings (2026-10-10)

`H` / `K` take a `<style-specifier>`, a [constrained text
terminal](../Specs/ebnf.md#constrained-text-terminals) parsed by
`parseStyleSpecifier`, which ignores its outer bare whitespace & reports an
error for a bare ASCII letter. `styled` wraps a styled string in
`StyleSequences` (`TableConfig.headerStyleSequences` /
`KeyValueConfig.keyStyleSequences`): `<style-prefix>` (`p` / `P`, default
`ESC[`), `<style-specifier>` & `<style-suffix>` (`x` / `X`, default `m`) precede
it; `<style-reset>` (`o` / `O`, default `ESC[0m`) follows it. Every output
config setting payload is a `{text}` token.

### Integer Scalar Descriptions (2026-10-10)

`scale` constrains `<significant-digits>` from 1 to 100 & `<fractional-digits>`
from 0 to 100, bounding its calculation & output length.

Integer descriptions' scalar tokens are consumed via maximal munch by
`parseIntegerText`: ASCII digits, after an optional sign only for `<index>`.
Their magnitudes are unconstrained: an `<index>` beyond `Int`'s range reports
`invalidPosition`, `<sort-priority>` is a `BigUInt` & `nonNegativeInteger`
saturates at `Int.max`. `scale` renders `0` without calculating `<radix>` to the
power of `<exponent>` for a huge `<exponent>`.

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
give strings. Table & key-value output render it coerced to a string, while
`<output>` sorts by it for every output format. Type comments are `type:`,
`input type:` & `output type:`; every predicate's is an `output type:`.

### Structured Values (2026-10-18)

A [structured value](../Specs/fields-format.md#value-types) (an array or an
object) is rendered at its type by JSON output & coerced to its compact JSON
text (non-ASCII characters verbatim) everywhere else, including table &
key-value output & sorting; no predicate whose output type is not any matches
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
instead of `""` (e.g., `%w` inserts a whitespace-only string as is, and JSON
output renders a solely-`%u` format's value as `null`).

A `<leader-pattern>` or `<item-separator-pattern>` that contains a line
terminator reports `invalidLeaderPattern` / `invalidItemSeparatorPattern`, as a
table's `<separator-pattern>` & `<column-spacing>` do.

A `<trivia-suffix-regex>` is the last argument of `<number-coercion-arguments>`,
so a bare `,` in it is part of it instead of an error (e.g., `%.:,,,,,,,.*:n`
matches `"5,x"`).

`timeZone`'s `<time-zone-arguments>` are optional, as `numberFormat`'s are,
because every argument has a default (e.g., `.timeZone` ≡ `.timeZone::`).

[Chronologic rendering](../Specs/fields-format.md#chronologic-formatting) is
specified, as already implemented: seconds always render & a UTC offset renders
as `Z` iff it is 0, else as `±hh:mm`.

`numberFormat` retaining scientific notation is specified, as already
implemented (e.g., `.numberFormat:de:` renders `12345.6E3` as `12.345,6E3`).

A formatted value is [absent](../Specs/fields.md#absent-values) iff formatting
aborts, or iff the field value is absent & the format evaluates to it unchanged
(`Format.rendered(value:label:name:)` returns `nil`); key-value & JSON output
decide whether to output a field from its formatted value instead of from its
field value, so a fallback (e.g., `%N%n+none+`) outputs for an absent field,
while an aborted format outputs nothing (instead of an empty string).

A `null` or absent value remains unchanged through every transform, with or
without `<coercion>` (`FormatValue.applying(_:)`), so a transform on a `null` or
absent field (e.g., `.round`) never reports `transformInputTypeMismatch`, and
`..uppercase` evaluates to `null` for `null` instead of to `""`.

### 2nd Spec Review Fixes (2026-10-18)

[Presence states](../Specs/fields.md#defaults-for-absent-expressions) are
decided by payload, as already implemented: a modifier omitted from present
`<field-modifiers>` (e.g., `<sort-modifier>` in `name=x`) retains the working
fields config's value, while an expression in a present payload that contains no
token (e.g., `N:`'s arguments) resets to its default; only a field spec's
properties are retained from the working fields config.

`<unconditional-pipeline>`'s named alternative is followed only by an
`<unconditional-transform-pipeline>`, as `<number-pipeline>`'s &
`<chronologic-pipeline>`'s are, so a named unconditional format satisfies every
`<named-format-reference>`; a block's `<transform-pipeline>` applies to the
enclosing matcher's value, as already implemented.

An absent value matching `u`, `e` & `w` as `null` does & coercing to an empty
string is specified, as already implemented.

A `<field-spec-hide>` of a field spec removed earlier in the section inserting a
hidden copy of its baseline field spec, instead of reporting an error, is
specified, as already implemented.

How a value's pieces (`SortOptionSet.pieces(of:)`) compare as a list & that
`<text-first>` / `<text-last>` compare 2 lists are specified, as already
implemented.

Equal digit group & decimal separators being an error is specified once, for
every user of number format arguments, including number coercion, as already
implemented.

Number-to-string transforms retaining trivia is specified, as already
implemented; `<match-placeholder>`'s predicates have `output type:` comments;
`<coercible-modifiers>` & `<number-modifiers>` are inlined.

The unused implicit scalar & implicit repetition kinds & optionality states are
removed from the custom EBNF grammar.

Configs specify that only a persisted fields config extends another (via its
`<base-fields-config-section>`); fields.md no longer refers to a "current
section", because a `<relative-config>` has at most 1
`<field-spec-edits-section>`.

`Temp/` no longer names removed identifiers or features, and uses [standard
terminology](terms.md).

The canonical conventions compare text per the CLDR root collation
(`compareLexically` uses the `root` locale), instead of Foundation's
non-localized order, so, e.g., `é` precedes `f` & JSON output's keys sort
`appleTVScreenshotURLs` before `appStorePageURL`; `<insensitive>` ignores only
case differences.

`<character-class-name>`s follow UTS #18 Annex C's POSIX Compatible definitions
(`CharacterClass.contains(_:)`, per a character's 1st Unicode scalar), instead
of ASCII-only `cntrl`, `graph` & `print` & approximations of the others, so,
e.g., `alpha` includes `Ⅻ`, `blank` includes U+3000 & `xdigit` excludes `Ａ`.

`scale` retains a leading `+` (`radixScaled`'s `isPlusSigned`), as `round` does.

With `<versions>`, a number value compares as its text, so its versions compare
with a string's versions (e.g., `2` follows `"1.5"`), instead of tying with
every version segment.

The reference suffix that selects a fields config's unsuffixed variant is
`@unsuffixed` (`unsuffixedVariantReferenceSuffix`), instead of `@none`, which
clashed with the built-in `none`.

`%v` & `%V` have output type string & a `<string-block>`, so a string transform
applies to a matched version without `<coercion>` (e.g., `%V.uppercase+-+`);
`<any-block-placeholder>` covers only `<nullary-blank-predicate>`s & their
non-nullary forms, so `<nullary-scalar-conditional-predicate>` &
`<nullary-standard-predicate>` (& their non-nullary forms) are removed.

`%d` & `%D` (`Predicate.date`) match a chronologic value with a date & accept
`<coercion>`; `%c` & `%C` (`Predicate.timeOnly`) match only a time-only value
without `<coercion>`, and their block is a `<time-only-block>`, whose pipeline
(`BlockKind.timeOnly`) cannot contain `dateOnly`, so no predicate depends on its
block's contents (`Format.appliesDateOnly` is removed); mas's `Released` field
uses `%D.dateOnly++`.

Chronologic values render in ISO-8601 extended format (`ChronologicStyle`'s own
formatting, instead of `Date.ISO8601FormatStyle`), a year outside 0000 to 9999
as ISO-8601's expanded representation (a sign & at least 5 digits), which
auto-detection also accepts; dates are in the proleptic Gregorian calendar
(`CivilDate`), instead of Foundation's Julian calendar before 1582-10-15; &
instants are exact milliseconds, so every Unix time in range renders exactly.

`%m` & `%M` are `<unary-match>` & `<binary-match>` (`unaryMatch`), with their
`<unary-match-placeholder>` & `<binary-match-placeholder>` alternatives of
`<conditional-placeholder>`, instead of nullary & non-nullary predicates,
because `%m`'s `<branches>` make it not nullary.

### 3rd Spec Review Fixes (2026-10-19)

A placeholder's outcomes cover `%m` & `%M` (whose value is the matched branch's
value), and specs clarify boolean blocks' coercion, number-to-string transforms'
`<number-coercion-arguments>`, a named format followed by a coerced transform
call, the reference fields config's `null`s & a number's sort text, as already
implemented.

Number coercion selects the shortest trivia prefix for which the rest of the
string after the longest number matches `<trivia-suffix-regex>`
(`Coercion.coercedNumber(in:)`), instead of failing when the shortest prefix
followed by a number leaves a nonmatching suffix (e.g., `%.:,,,,,.*:n` now
matches `"a1b2"`).

An expanded year's sign starts a chronologic sort segment only when word-initial
(`chronologicSegment(at:in:)`), so a hyphenated ID (e.g., `id-12345-06-07`) is
not a date.

A unary form's block is either a `<success-block>` or a `<success-pipeline>`
(non-structural), e.g., `%I…+`'s `<unconditional-pipeline>`.

### Spec Compliance Audit (2026-10-19)

Re-audited every spec against the code, fixing each divergence below.

A `<character-class-name>` ignores its outer bare whitespace inside its
`<character-class-fence>`s (e.g., `B+ space +:`), instead of reporting
`invalidCharacterClass`.

`<number-signs>` & each `<chronologic-format>` are syntax tokens, so an escaped
one (e.g., `N,,,,,\all:` or `C\iso:`) is an error, instead of text that matches
it. `parseArguments` leaves an `<argument-separator>` after a
separator-terminated last argument unconsumed, so `<grouped-numeric-arguments>`
parses its `<number-signs>` after its `<number-format-arguments>`.

A number or number-to-string transform's `<number-coercion>` does not coerce a
structured value, so formatting aborts (e.g., `..:,,,,,\\[,\\]:round` for
`[1]`), as no number coercion matcher matches one, instead of coercing its
compact JSON text.

Key-value output outputs no line for an item without rows (e.g., whose every
formatted value is absent or `null`), instead of an empty line, so its adjacent
item separator lines (iff any) are adjacent, and, without any, the next item's
1st row immediately follows the previous item's last row.

A `<field-occurrence-index>` beyond its field's field specs is an error
(`invalidPosition`) for a `<field-spec-insertion>` & a `<field-spec-hide>`
(e.g., `+adamID@3`), as already implemented: only a `<reference-field-name>`
that names no field spec selects a default field spec or inserts one.

A coerced number's canonical form has no leading `0`s in its exponent & no `-`
sign on a 0 exponent (e.g., `%.n` coerces `"1e-03"` to `1e-3` & `"1e-00"` to
`1e0`), as in its significand.

ISO-8601 detection's field ranges are specified, as already implemented: an hour
from `00` to `23` (no `24:00:00`), a minute & a second from `00` to `59` (no
leap second) & a UTC offset at most 18 hours from UTC.

Table & key-value output print nothing (instead of an empty line) iff there is
nothing to output: a table without any visible field spec, or key-value output
in which no item has a row (`[JSON.Object].table(fieldSpecs:tableConfig:)` &
`.keyValue(fieldSpecs:fieldOrder:keyValueConfig:)` return `nil`).

`initialTitlecase` titlecasing a cased number or symbol at which it stops (e.g.,
`ⓐbc` becomes `Ⓐbc` & `ⅰx` becomes `Ⅰx`), per Unicode's titlecase mappings &
ICU, is specified, as already implemented.

A field may have multiple [members](../Specs/fields.md#members) (e.g., a JSON
object's duplicate keys): a table cell & a sort key use the last one
(`JSON.Object[lastNodeKey:]`), while key-value & JSON output each one, in input
order, formatted separately (`FieldOrder.itemMembers(_:for:)`, which, for
`<document-order>`, orders each member at its own position), instead of every
output format & sorting using the 1st one.

JSON output outputting a key-value pair for each field spec's member, even if
its key repeats another's (e.g., `--fields name=x,version=x`), is specified, as
already implemented.

`<nonconforming-placement>` (`SortOptionSet.nonconformingPlacement`) sets
whether nonconforming values' location depends on `<direction>`:
`<relative-nonconforming>` (`r`, the default) lets `<descending>` reverse it, as
before, while `<fixed-nonconforming>` (`f`) puts them 1st (`a`) or last (`z`)
regardless of `<direction>` (e.g., `af-`), as SQL's `NULLS FIRST` & `NULLS LAST`
do.

A `<document-order-option-set>` also takes `<absent-field-comparison>` (`a` /
`z`, default `z`) & `<absent-field-placement>` (`r` / `f`, default `r`)
(`DocumentOrderOptionSet`): a field spec whose field an item lacks compares as
less or greater than every member, and `<descending>` reverses its location iff
`<relative-absent-fields>` (e.g., `D-` puts it 1st, but `D-f` last), as before
by default; a `<positional-order-option-set>` reports either as
`unsupportedAbsentFieldOption`.

### 2nd Spec Compliance Audit (2026-10-19)

Whitespace between a `<field-spec-edit>`'s `<insert>`, `<move>`, `<hide>`, or
`<remove>` & its `<field-spec-index-prefix>` is ignored (e.g., `+ @1`), instead
of reporting `missingFieldName`.

Whitespace after `<number-coercion-arguments>`' closing `<argument-fence>` is
ignored (e.g., `%.:de: n`, `..:de: round`), instead of reporting `invalidLetter`
or `unknownTransform`; within `<number-coercion>`, only `<coercion>`'s `.`
forbids succeeding whitespace.

Each output option's syntax is defined over its [option
value](../Specs/configs.md#option-values) alone, which Swift Argument Parser
takes from the rest of the option's command-line argument after an option value
separator (e.g., `--fields=name`, `--table=`), or else from the next
command-line argument; a test confirms that both forms are equivalent.

### 4th Spec Review Fixes (2026-10-20)

A version component's remaining characters compare as lists of their maximal
runs of ASCII digits (each compared numerically) & of other characters (each
compared lexically) (`SortOptionSet.compareVersionSuffixes`), instead of as
text, so, e.g., `2.0b9` precedes `2.0b10`.

A `<field-spec-hide>` whose `<indexed-field-spec-reference>` resolves to a
`null` inserts a hidden copy of its baseline field spec (e.g., `-@1,_@1`), as a
`<named-field-spec-reference>` already did (`hideSource(for:)`), instead of
reporting an error.

Each block's template (e.g., `<string-template>`) is structured as
`<format-template>` is, but also allows text alone, so no 2 `<template-text>`s
are adjacent, as already implemented.

`k` has no default `<style-specifier>`, which `K` could not take, so its keys
are simply unstyled, as already implemented.

`<key-styling-setting>` has its own letters' nonterminals
(`<key-terminal-only-styling>` & `<key-always-styling>`), as each other setting
already did, instead of sharing `<header-styling-setting>`'s
(`<header-terminal-only-styling>` & `<header-always-styling>`).
