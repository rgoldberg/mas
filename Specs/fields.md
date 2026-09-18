# Field-Selection Option

`--fields` is an optional option of every [display
command](configs.md#display-commands).

It selects, orders, labels & formats the output fields.

It also sorts the items the command outputs.

Uses the [custom EBNF grammar](ebnf.md).

## Positions & Indices

List elements are located at 1-based integer positions.

Positions are referenced via integer indices. Each index has an effective index,
evaluated as follows:

- If non-negative $index$: $index$.
- If negative $index$: $length + 1 + index$ (where $length$ is the list's
  length).

Index `0` represents a pseudo-position that precedes all list elements.

Accessing an invalid position is an error. Invalid positions are:

- Non-positive positions (despite non-positive indices being valid).
- Positions that are greater than a list's length.

A negative index may be used to _reference_ an element, but the index _of_ an
element is always positive.

## Field Specs

A **field spec** & its position define the configuration for an output field:

- Inclusion
- Order
- Label (table header; key-value / JSON key)
- Value format
- Item sorting

Each field spec is either **visible** or **hidden**. A hidden field spec is not
output, but otherwise behaves as a visible one: it has a position, may be
referenced by a `<field-spec-reference>`, & its `<sort>` sorts items iff
[enabled](#sort-priority).

## Fields Configs

A **fields config** specifies which fields are included in the output, along
with other output configuration.

A fields config may include:

- Rules that apply to all fields
- Field-specific field specs

### Named Fields Configs

A **named fields config** is a [named config](configs.md#named-configs) of the
fields kind, whose name may be immediately followed by an [output format
suffix](#output-format-specific-named-fields-configs).

#### Output-Format-Specific Named Fields Configs

A fields config's name may include an optional output format suffix matching the
regex `@(json|key-value|table)$`; if the current output format matches the
suffix, the fields config with the suffixed name is substituted for any
reference to the stem alone.

An additional suffix matching the regex `@none$` may be appended to a reference
to a fields config name (not to a name itself), which resolves to the fields
config named by the stem alone, regardless of the current output format.

Fields configs that share the same stem within the same context, but that have
different suffixes, are **output format variants**.

#### Immutable Built-In Named Fields Configs

For each [leaf context](configs.md#context-stacks):

- `none`: Every field spec is hidden.
- `all`: Every field spec is visible. Absent a built-in field order: field specs
  are sorted by label (`<output>`), while other `<sort-option>`s are as per the
  defaults for string fields for the current output format.
- `standard`: Only a select list of field specs is visible.

Output format variants may exist for any built-in fields config. If an output
format variant does not exist for any built-in field config, it must not be
defined by a user.

#### Default Fields Configs

If a nonexistent [`default`](configs.md#default-configs) was referenced with an
output format suffix, that suffix is appended to `standard`.

### Base Fields Config

The resolved fields config is sourced from a **base fields config**: a named
fields config referenced in, or implicitly selected by, a command line.

### Baseline Fields Config

The **baseline fields config** is an immutable snapshot of the working fields
config immediately before the current section.

### Working Fields Config

The **working fields config** is the fields config's current state as it is
being modified.

### Resolved Fields Config

The **resolved fields config** is used to render output.

## Defaults for Absent Expressions

The following is inserted before all other cases in the [absent expression value
algorithm](ebnf.md#defaults-for-absent-expressions):

- The value for the given expression `EXPRESSION` in the working fields config.

## Nonexistent Fields

**Nonexistent fields** are guaranteed to not exist in any input, which is
determinable only for formats that specify all potential input fields up front,
e.g.: CSV, or JSON with a JSON schema.

Other formats cannot guarantee field nonexistence, e.g.: JSON without a JSON
schema, for which a field may exist for some JSON objects, but not exist for
others.

A reference to a nonexistent field is an error.

## Absent Values

- **Table**: A column is output for each field spec regardless of whether a
  value exists for a given item (absent values are output as empty strings).
- **Key-Value**: A key-value pair is output for the field label & value iff a
  non-`null` value exists.
- **JSON**: A key-value pair is output for the field label & value iff a value
  exists (which may be any value; e.g., for JSON input, `null`, `true`, `false`,
  `0`, `1`, `""`, `"null"`, etc. are all values).

## Fields Option

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
fields-option = "--fields" &<fields-config>
fields-config = ( <absolute-config> | <relative-config> )- (* default: <relative-config> *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<absolute-config>` & `<relative-config>` are overlaid on top of the base fields
config for the current command line only; they do not persistently affect named
fields configs.

### Absolute Config

```ebnf
absolute-config = <absolute-field-spec> … <field-spec-separator>

absolute-field-spec = <absolute-field-name> <field-modifiers>
absolute-field-name = {text}
```

The resolved fields config is sourced solely from `<absolute-config>`; this is
the equivalent of the base fields config being `none`.

Each field spec in an `<absolute-config>` appends a new output for its field.

### Relative Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
relative-config = [ <base-fields-config-section> ] [ <field-order-section> ] [ <item-sort-section> ] [ <field-spec-edits-section> ]
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The resolved fields config is sourced from the base fields config as modified by
`<relative-config>`.

#### Base Fields Config Selection

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
base-fields-config-section        = <base-fields-config-section-prefix> <base-fields-config-name>
base-fields-config-section-prefix = "@"

base-fields-config-name = {text} (* default: "default" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- If no fields config named `<base-fields-config-name>` exists in any context in
  the context stack, an error is reported.

#### Field Order

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-order-section        = <field-order-section-prefix> <field-order-option-set>
field-order-section-prefix = "/"

field-order-option-set = <order-option-set> | <sort-option-set> (* default source: <output> *)

order-option-set = [ <direction>+ ] <order> [ <order-option>+ ] (* last wins *)

order-option = <order> | <direction>
order        = <base-fields-config-order> | <original-input-order>

base-fields-config-order = "w"
original-input-order     = "o" (* only for: @json or @key-value context variants *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The working fields config's field specs are ordered per
`<field-order-option-set>`:

- `<original-input-order>`: ordered in original input order, e.g., the order of
  keys in an input JSON object.
- `<base-fields-config-order>`: ordered as in the base fields config.
- `<sort-option-set>`: if `<source>` is:
  - `<input>`: sorted by name.
  - `<output>`: sorted by label.

`<descending>` reverses `<order>`'s field order.

If the field order is not `<base-fields-config-order>`, a field spec's position
does not affect output order; it only affects which field spec is referenced by
an `<index>`.

`<original-input-order>` is not supported for table output because items are
processed in a streaming manner & may each have different fields, or the same
fields in different orders, so no original input order exists for all of a
table's rows; key-value & JSON output may order each item's fields
independently.

#### Item Sorting

```ebnf
item-sort-section        = <item-sort-section-prefix> <item-sort-option-set>
item-sort-section-prefix = "//"

item-sort-option-set = <item-sort-option>+ (* last wins *)
item-sort-option     = <disable-all-sorts> | <direction>

disable-all-sorts = "r"
```

`<disable-all-sorts>` sets each field spec's `<sort-priority>` to `0`, disabling
all sorting without affecting any `<sort-option-set>`; a subsequent
`<field-spec-edit>` may re-enable a field spec's sort.

`<ascending>` tiebreaks item sorting by input order, `<descending>` by reverse
input order; absent any field spec with an enabled `<sort>`, items are ordered
solely by this tiebreak.

#### Field Spec References

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-spec-reference         = <named-field-spec-reference> | <indexed-field-spec-reference>
named-field-spec-reference   = <reference-field-name> [ <index-prefix> <index> ] (* default index: "1" *)
indexed-field-spec-reference = <index-prefix> <index>

reference-field-name = {text}

index-prefix = "@"
index        = {integer}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The **reference fields config** is a potentially partial, semi-mutable copy of
the baseline fields config. The order of field specs in the reference fields
config is immutable (i.e., unaffected by any inserts, moves, or removals
performed in the current section), with:

- `<named-field-spec-reference>` including only field specs for field
  `<reference-field-name>`.
- `<indexed-field-spec-reference>` including all field specs.

While a field spec's position in the reference fields config cannot be modified:

- Its `<field-modifiers>` may be modified.
- A `null` may replace it in its position, which does not modify any other field
  spec's position.

When accessing a field spec position via an index:

- If the position access reports an error, or if a `null` is present at the
  effective index in the reference fields config, an error is reported.
- Otherwise, the field spec at the effective index in the reference fields
  config is the referenced field spec.

#### Relative Field Specs

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-spec-edits-section        = <field-spec-edits-section-prefix> [ <field-spec-edit> … <field-spec-separator> ]
field-spec-edits-section-prefix = "."

field-spec-edit = <base-sourced-field-spec-edit> | <reference-sourced-field-spec-edit>

base-sourced-field-spec-edit = <field-spec-insertion>

field-spec-insertion = <insert> <field-spec-reference> <field-modifiers>

reference-sourced-field-spec-edit = <field-spec-overlay> | <field-spec-move> | <field-spec-hide> | <field-spec-removal>

field-spec-overlay = <field-spec-reference> <field-modifiers>
field-spec-move    = <move> <field-spec-reference> <field-modifiers>
field-spec-hide    = <hide> <field-spec-reference> <field-modifiers>
field-spec-removal = <remove> <field-spec-reference>

insert = "+"
move   = "%"
hide   = "_"
remove = "-"

field-spec-separator = -","
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

For a given `<reference-sourced-field-spec-edit>` `fs`, its `source` is the
field spec from the reference fields config referenced by `fs`. Thus, field
specs inserted in a section cannot be modified by other field spec edits in the
same section).

For a given `<base-sourced-field-spec-edit>` `fs`, its `source` is the field
spec from the base fields config referenced by `fs`, resolved as in the
reference fields config, except that a `<named-field-spec-reference>` that
references no field spec selects a field spec with default settings for field
`<reference-field-name>`.

The $previous$ index is the index in the working fields config where the direct
results of the immediately preceding `<field-spec-edit>` were effected. It is
initially set to `0` (i.e., immediately before the 1st field spec in the working
fields config).

Field spec edits act as follows:

- `<field-spec-insertion>`:
  - Inserts a new visible field spec, a copy of `source`, immediately after
    $previous$, then overlays its `<field-modifiers>` onto the copy.
  - Sets $previous$ to the new field spec's index in the working fields config.
- `<field-spec-overlay>`:
  - Overlays its `<field-modifiers>` onto `source` & unhides it.
  - Sets $previous$ to `source`'s index in the working fields config.
- `<field-spec-move>`:
  - Moves `source` to immediately after $previous$ & unhides it.
  - Sets $previous$ to `source`'s new index in the working fields config.
- `<field-spec-hide>`:
  - If its `<named-field-spec-reference>` resolves to no field spec, inserts a
    new field spec (as `<field-spec-insertion>` would) as `source`.
  - Overlays its `<field-modifiers>` onto `source` & hides it, so a field may
    sort items without being output (e.g., `_size/1d`).
  - Sets $previous$ to `source`'s index in the working fields config.
- `<field-spec-removal>`:
  - Sets $previous$ to the index immediately before `source`'s index in the
    working fields config.
  - Removes `source` from the working fields config.
  - Replaces `source` with `null` in the reference fields config.

### Field Modifiers

```ebnf
field-modifiers = [ <label-modifier> ] [ <format-modifier> ] [ <sort-modifier> ]
```

#### Labeling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
label-modifier        = <label-modifier-prefix> [ <label> ] (* transitive default label: {field name from the enclosing field-spec} *)
label-modifier-prefix = "="
label                 = {text} (* default: "" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A field spec's `<label>` is its:
  - Header for table.
  - Key for key-value & JSON.

#### Formatting

[This section will be replaced by the contents of
`fields-format.md`](fields-format.md).

#### Sorting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-modifier        = <sort-modifier-prefix> [ <sort> [ ( <sort-modifier-prefix> <sort-option-set> )+ ] ]
sort-modifier-prefix = -"/"
sort                 = <sort-priority> | [ <sort-priority> ] <sort-option-set> (* direct default: null *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A **sort key** is a field spec with an enabled `<sort>`, which affects item
  sorting.
- Other field specs do not affect item sorting.

Each `<sort-option-set>` after `<sort>` sorts, among themselves, the [values
that conform to none of the preceding `<sort-option-set>`s'
types](#sort-nonconforming-values); the field remains 1 sort key, at `<sort>`'s
priority.

##### Sort Priority

```ebnf
sort-priority = {non-negative integer}
```

A field spec with a `<sort>`:

- Requires a non-`null` `<sort-priority>`, otherwise an error is reported.
- Has its sort **disabled** by a `<sort-priority>` of `0`: its `<sort-option>`s
  are retained, but do not sort items until a positive `<sort-priority>` enables
  them, e.g., `_size/1` enables a hidden field spec's inherited `/0d`.
- Otherwise, takes sort precedence over fields:
  - With a numerically higher `<sort-priority>` (i.e., lower numbers have higher
    priority).
  - Succeeding it with the same `<sort-priority>`.

##### Sort Options

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-option-set = <sort-option>+ (* last wins *)
sort-option     = <source> | <direction> | <case-sensitivity> | <localization> | <numbers-in-strings> | <boundaries> | <nonconforming-location> | <trivia-order>

sort-option-terminator = "+"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Sort Source

```ebnf
source = <input> | <output> (* default: <input> *)
input  = "I"
output = "O"
```

If an input value is modified by a format for output, `<input>` sorts based on
the input, not the output. `<output>` is the opposite.

Values are compared not as characters, but as:

- If `<input>`: the field's [type](fields-format.md#types).
- Otherwise (i.e., `<output>`): the rendered value type.

Values of a type are compared:

- If chronologic: chronologically.
- If number: numerically.
- If version: as [specified](#version-comparison).
- If boolean: sorting `false` before `true`.
- If string: as per `<case-sensitivity>`, `<localization>`,
  `<numbers-in-strings>` & `<boundaries>`.

e.g., for an input timestamp being output as an ISO date (without time):

- `<input>` sorts by the input timestamp.
- `<output>` sorts by the output ISO date (without time), so rows on the same
  date tie & fall through to the next sort key.

###### Version Comparison

[Versions](fields-format.md#version-formatting) compare component by component:
numerically, then by the non-`.` characters (a component with non-`.` characters
precedes the same integer without them; e.g., `1.0b` precedes `1.0`); a version
with fewer components precedes one that extends it.

##### Sort Direction

```ebnf
direction  = <ascending> | <descending> (* default: <ascending> *)

ascending  = "a"
descending = "d"
```

##### Sort Case Sensitivity

```ebnf
case-sensitivity = <sensitive> | <insensitive> (* default: <sensitive> *)

sensitive   = "s"
insensitive = "i"
```

##### Sort Localization

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
localization = <canonical> | <localized> (* default: <canonical> *)

canonical = "c"
localized = <system-locale> | <custom-locale>

system-locale = "l"
custom-locale = "L" [ <locale-name> ] <sort-option-terminator>

locale-name = {text} (* default: {system default locale name} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<canonical>` uses a locale-independent comparison, while `<localized>` uses a
locale-dependent comparison. This also affects numeric fractional part & integer
grouping separators.

##### Sort Numbers in Strings

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
numbers-in-strings = <lexical> | <numeric> | <grouped-numeric> (* default: <lexical> *)

lexical         = "x"
numeric         = "n"
grouped-numeric = "g"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<lexical>` compares digits as characters. `<numeric>` compares each run of
digits as a number. `<grouped-numeric>` does the same after removing the
[canonical or localized](#sort-localization) numeric grouping separator (e.g.,
`,` in `1,234`), so a grouped number compares as 1 number (e.g., `1,234` as
`1234`) rather than being broken into smaller ones by the separator.

##### Sort Boundaries

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
boundaries = <no-boundaries> | <uncollapsed-boundaries> | <collapsed-boundaries> (* default: <uncollapsed-boundaries> *)

no-boundaries          = "b"
uncollapsed-boundaries = "B" [ <boundary-groups> ] <sort-option-terminator>
collapsed-boundaries   = "C" [ <boundary-groups> ] <sort-option-terminator>

boundary-groups = <boundary-group> … <group-separator> (* default: ":space:" *)
group-separator = "_"

boundary-group      = ( <boundary-characters> | <multi-character-boundary> | <character-class> )+
boundary-characters = {text}

multi-character-boundary       = <multi-character-boundary-fence> <multi-character-boundary-text> <multi-character-boundary-fence>
multi-character-boundary-fence = "%"
multi-character-boundary-text  = {text}

character-class       = <character-class-fence> <character-class-name> <character-class-fence>
character-class-fence = ":"
character-class-name  = "alnum" | "alpha" | "ascii" | "blank" | "cntrl" | "digit" | "graph" | "lower" | "print" | "punct" | "space" | "upper" | "word" | "xdigit"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Input is tokenized by **boundaries** assigned to ordered sort precedence
**boundary groups**, each defined by a `<boundary-group>`; each group's members
share the same sort precedence.

Each of the following is itself a boundary:

- Each character in a `<boundary-characters>`.
- Each `<multi-character-boundary-text>`.
- Each character belonging to a GNU Extended POSIX character class named
  `<character-class-name>`.

The last occurrence of a boundary for a value throughout all `<boundary-group>`s
overrides all other boundaries for the same value.

Boundaries take sort precedence over all boundaries in all groups succeeding
their group & over all non-boundary characters.

`<uncollapsed-boundaries>` retains contiguous boundaries in input as separate
characters; `<collapsed-boundaries>` collapses contiguous boundaries belonging
to the same boundary group into one. `<no-boundaries>` tokenizes nothing.

##### Sort Nonconforming Values

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nonconforming-location = <before-conforming> | <after-conforming> (* default: <after-conforming> *)

before-conforming = "f"
after-conforming  = "e"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A value is **nonconforming** to a `<sort-option-set>` iff it does not conform to
the field's [type](fields-format.md#types), e.g., `"XYZ"` for a chronologic
field, or `null` for a string field. [Nonconforming values are ordered among
themselves by the `<sort-modifier>`'s next `<sort-option-set>`, if
any](#sorting); those conforming to no `<sort-option-set>` retain their input
order. `<nonconforming-location>` orders each `<sort-option-set>`'s
nonconforming values before or after its conforming ones.

##### Sort Trivia Order

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
trivia-order = <trivia-first> | <trivia-last> | <trivia-split> | <trivia-ignored> (* default: <trivia-first> *)

trivia-first   = "t"
trivia-last    = "h"
trivia-split   = "p"
trivia-ignored = "q"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A number field with [`<lenient-coercion>`](fields-format.md#trivia) sorts by:
  - `<trivia-first>`: trivia prefix, then trivia suffix, then number.
  - `<trivia-last>`: number, then trivia prefix, then trivia suffix.
  - `<trivia-split>`: trivia prefix, then number, then trivia suffix.
  - `<trivia-ignored>`: number.
- Otherwise: `<trivia-order>` does not affect sorting.

## Appendix: Escaping

As per [tokens](ebnf.md#tokens), for a text token to consume text that would
otherwise match a syntax literal, 1 or more of its characters must be escaped by
prefixing it with a `\`.

Throughout all text tokens, a literal `\` is written `\\`, because `\` always
escapes the next character.

Outer bare whitespace is significant (consumed) or insignificant (not consumed)
as per [character significance](ebnf.md#character-significance); whitespace must
be escaped instead of bare to be consumed where bare whitespace is
insignificant.

In each row of the table below, the given characters must be escaped to be
consumed as either the 1st character of, or any character in, a text token
consumed by the given text terminal in the given syntactic context. Leading &
trailing outer bare whitespace is significant or insignificant, as given.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| `{text}`                                                             | 1st             | Any                 | Leading Whitespace | Trailing Whitespace        |
|:---------------------------------------------------------------------|:----------------|:--------------------|:-------------------|:---------------------------|
| `<absolute-field-name>` of the 1st `<absolute-field-spec>`           | `@` `.`         | `=` `:` `/` `,`     | insignificant      | insignificant              |
| `<absolute-field-name>` of a subsequent `<absolute-field-spec>`      |                 | `=` `:` `/` `,`     | insignificant      | insignificant              |
| `<base-fields-config-name>`                                          |                 | `/` `.`             | insignificant      | insignificant              |
| `<reference-field-name>` in `<field-spec-overlay>`                   | `+` `%` `_` `-` | `@` `=` `:` `/` `,` | insignificant      | insignificant              |
| `<reference-field-name>` in `<field-spec-move>`                      |                 | `@` `=` `:` `/` `,` | insignificant      | insignificant              |
| `<reference-field-name>` in `<field-spec-hide>`                      |                 | `@` `=` `:` `/` `,` | insignificant      | insignificant              |
| `<reference-field-name>` in `<field-spec-removal>`                   |                 | `@` `,`             | insignificant      | insignificant              |
| `<label>`                                                            |                 | `:` `/` `,`         | insignificant      | insignificant              |
| `<locale-name>` in `<custom-locale>`                                 |                 | `+`                 | insignificant      | insignificant              |
| `<boundary-characters>`                                              |                 | `%` `:` `_` `+`     | insignificant      | insignificant              |
| `<multi-character-boundary-text>`                                    |                 | `%`                 | insignificant      | insignificant              |
| `<format-name>` in a `<format-block>`                                |                 | `.` `/` `,`         | insignificant      | insignificant              |
| `<template-text>` beginning a `<format-block>`                       | `:` `.`         | `%` `/` `,`         | insignificant      | significant iff before `%` |
| `<template-text>` immediately after a `<placeholder>`                |                 | `%` `/` `,`         | significant        | significant iff before `%` |
| `<format-name>` in a `<block>`                                       |                 | `.` `+`             | insignificant      | insignificant              |
| `<template-text>` beginning a `<block>`                              | `:` `.`         | `%` `+`             | insignificant      | significant iff before `%` |
| `<template-text>` immediately after a `<placeholder>` in a `<block>` |                 | `%` `+`             | significant        | significant iff before `%` |
| `<locale-name>` in `<group-arguments>` / `<group-separator>`         |                 | `,` `:`             | significant        | significant                |
| `<time-zone-code>`                                                   |                 | `:`                 | insignificant      | insignificant              |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->
