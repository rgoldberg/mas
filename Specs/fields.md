# Field-Selection Option

`--fields` is an optional option of every [display
command](configs.md#display-commands).

It selects, orders, labels & formats the output fields.

It also sorts the items the command outputs.

Uses the [custom EBNF grammar](ebnf.md).

## Positions & Indices

List elements are located at 1-based integer **positions**.

Positions are referenced via integer **indices**.

Each index has an **effective index**:

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

### Visibility

Each field spec is either:

- **Visible**: Output.
- **Hidden**: Not output, but otherwise behaves as a visible one.

Regardless of a field spec's visibility:

- It has a position.
- It can be referenced by a `<field-spec-reference>`.
- Its `<sort>` sorts items iff [enabled](#sort-priority).

### Default Field Specs

A **default field spec** for a field is visible & has:

- Label: the field's name.
- Format: [`%i`](fields-format.md#unconditional-placeholders).
- Justification: [`<start-justify>`](fields-format.md#format-transforms).
- No `<sort>`, so it is not a sort key.

E.g., `--fields .+size`, when the base fields config has no field spec for
`size`, outputs `size` labeled `size`, formatted as `%i`, start-justified & not
sorting items.

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

Fields configs that share the same stem within the same context are
**variants**.

In a reference to a fields config (not in a name itself), `@unsuffixed` may
directly follow a stem in place of an output format suffix, which resolves to
the unsuffixed variant, regardless of the current output format (e.g.,
`x@unsuffixed`, but not `x@json@unsuffixed`, which is an error).

While a reference to a stem is [looked
up](configs.md#referencing-named-configs), a context matches it iff it contains
the stem's variant for the current output format or its unsuffixed variant,
preferring the former, so any variant in a more specific context overrides every
variant in a less specific one (e.g., for table output, `x` in `mas.list`
overrides `x@table` in `mas`).

A reference with an output format suffix or `@unsuffixed` matches a context iff
the context contains that variant (e.g., `x@json` skips a context that contains
only `x`).

A persisted fields config [extends a config of its own
name](configs.md#referencing-named-configs) iff its reference's stem is its own
stem, whatever either's suffix (e.g., for JSON output, a `default@json` in
`mas.list` that extends `default` extends `mas`'s `default` variant for JSON
output, instead of itself).

#### Immutable Built-In Named Fields Configs

For each [leaf context](configs.md#context-stacks):

- `none`: Every field spec is [hidden](#visibility) & its sort is
  [disabled](#sort-priority).
- `all`: Every field spec is visible. Absent a built-in field order: field specs
  are sorted by label (`<output>`), while other `<sort-option>`s are per the
  app's default sort options for labels for the current output format.
- [Built-in standard](configs.md#immutable-built-in-named-configs): Only a
  select list of field specs is visible.

A built-in fields config:

- May have built-in variants.
- Cannot have custom variants.

#### Default Fields Configs

In a context that contains no custom [`default`](configs.md#default-configs)
variant for the current output format (i.e., neither the suffixed nor the
unsuffixed one), `default` is that context's
[`standard`](configs.md#standard-configs) variant for it (e.g., for JSON output,
`standard@json`). A non-root context's `standard` variant for an output format
is its parent context's `default` variant for it.

So a custom unsuffixed `default` overrides every `standard` variant, while a
custom `default@json` overrides only `standard@json`. E.g., to customize table &
key-value output while JSON output retains `standard@json`, define
`default@table` & `default@key-value`, each extending 1 shared custom fields
config.

### Base Fields Config

The **base fields config** is a named fields config referenced in, or implicitly
selected by, a command line.

### Working Fields Config

The **working fields config** is a mutable copy of the base fields config, as
modified by the command line so far.

### Baseline Fields Config

The **baseline fields config** is an immutable snapshot of the working fields
config immediately before `<field-spec-edits-section>`.

### Resolved Fields Config

The **resolved fields config** is the working fields config after the command
line has been parsed; it is used to render output.

## Defaults for Absent Expressions

[Presence states](ebnf.md#presence-states) are as in the custom EBNF grammar,
except that an expression that contains no token, but that is neither an
alternative of a present choice nor an element of a present repetition, is:

- Directly absent iff it is in the [payload](#payloads) of a present modifier or
  option, even if the payload contains no token (e.g., `<label>` in `name=`, or
  `<locale-identifier>` in `N:`).
- Otherwise, transitively absent (e.g., `<sort-modifier>` in `name=x`).

The following is inserted before all other cases in the [absent variable
expression value algorithm](ebnf.md#defaults-for-absent-expressions):

- If transitively absent & it sets a property of the field spec that its
  `<field-modifiers>` modify (e.g., its label, format, justification, or a sort
  option): that property's value in the working fields config, if any.

An omitted modifier (e.g., `<sort-modifier>` from `name` or from `name=x`) or an
option omitted from a present payload without any mutually exclusive options
(e.g., `<direction>` from `name/1Ii`) thus retains the working fields config's
value, while an absent modifier payload or option payload (e.g., from `name=`,
`name:`, `name/`, `L:`, `B:`, `N:`) resets the value to its default for the
directly absent state.

## Nonexistent Fields

**Nonexistent fields** are guaranteed to not exist in any input, which is
determinable only for formats that specify all potential input fields up front,
e.g.: CSV, or JSON with a JSON schema.

Other formats cannot guarantee field nonexistence, e.g.: JSON without a JSON
schema, for which a field may exist for some JSON objects, but not exist for
others.

A reference to a nonexistent field is an error on the command line, but a
persisted fields config, which may apply to multiple commands, ignores each
`<absolute-field-spec>` & `<field-spec-edit>` that references one (e.g., a `mas`
context `default` of `@standard.name=App` ignores `name=App` for `mas config`,
whose item has no `name` field).

## Members

An item's field may have multiple **members** (e.g., the name / value pairs of a
JSON object that share a name), ordered by input order. A field spec formats
each member's value separately:

- **Table**: A cell is output for the field's last member.
- **Key-Value** & **JSON**: A key-value pair is output per member, in input
  order (except for [`<document-order>`](#field-order), which orders each member
  at its own position).
- **Sorting**: An item's value for a sort key is its field's last member's
  value.

A field spec formats an absent field's absent value once.

## Absent Values

A field spec's [formatted value](fields-format.md#value-types) is **absent** iff
formatting [aborts](fields-format.md#success--failure), or iff the field value
is absent & the format evaluates to it (e.g., via `%i`, `%u`, or `.round`,
because an absent value remains unchanged through every
[transform](fields-format.md#value-coercion)).

An absent value matches `u`, `U`, `e`, `E`, `w` & `W` as `null` does, and is
[coerced to a string](fields-format.md#value-coercion) as an empty string.

Output depends on the formatted value, not on the field value:

- **Table**: A cell is output for each visible field spec, regardless of whether
  its formatted value is absent, which is output as an empty string.
- **Key-Value**: A key-value pair is output for the field label & formatted
  value iff the formatted value is neither absent nor `null`.
- **JSON**: A key-value pair is output for the field label & formatted value iff
  the formatted value is not absent; e.g., for JSON input, `null`, `true`,
  `false`, `0`, `1`, `""` & `"null"` are all values.

E.g., for an absent field, `%N%n+none+` outputs `none` in every output format,
while `%i` & `%n` output an empty table cell, but no key-value pair in key-value
or JSON output.

## Fields Option

```ebnf
fields-config = ( <absolute-config> | <relative-config> )- (* default: "" *)
```

`--fields`'s [value](configs.md#option-values) is a `<fields-config>`. Giving
`--fields` more than once is an error.

`<absolute-config>` & `<relative-config>` are overlaid on top of the base fields
config for the current command line only; they do not persistently affect named
fields configs.

### Absolute Config

```ebnf
absolute-config = <absolute-field-spec> … <field-spec-separator>

absolute-field-spec = <absolute-field-name> <field-modifiers>
absolute-field-name = {text: field name with no bare "."}
```

An `<absolute-config>` is equivalent to a `<relative-config>` with base fields
config `none`, field order `<positional-order>` & a `<field-spec-insertion>` for
each of its field specs, e.g.:

- `version=Ver,size` ≡ `@none/P.+version=Ver,+size`
- `name,name` ≡ `@none/P.+name,+name`

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

base-fields-config-name = {text: fields config name} (* default: "default" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

#### Field Order

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-order-section        = <field-order-section-prefix> <field-order-option-set>
field-order-section-prefix = "/"

field-order-option-set        =
  <positional-order-option-set>
  | ( <document-order-option-set> | <sort-option-set> ) [ <field-order-tiebreaker> ]
  (* default source: <output> *)
field-order-tiebreaker        = <field-order-tiebreaker-prefix> <direction>
field-order-tiebreaker-prefix = "/"

positional-order-option-set = [ <order-option>+ ] <positional-order> [ <direction>+ ]
document-order-option-set   = [ <document-order-option>+ ] <document-order> [ <document-order-trailing-option>+ ] (* only for: JSON or key-value output *)

order-option                   = <order> | <direction>
document-order-option          = <order-option> | <absent-field-comparison> | <absent-field-placement>
document-order-trailing-option = <direction> | <absent-field-comparison> | <absent-field-placement>

order = <positional-order> | <document-order> (* last wins *)

positional-order = "P"
document-order   = "D"

absent-field-comparison = <absent-fields-least> | <absent-fields-greatest> (* default: <absent-fields-greatest>; last wins *)
absent-field-placement  = <relative-absent-fields> | <fixed-absent-fields> (* default: <relative-absent-fields>; last wins *)

absent-fields-least    = "a" (* mnemonic: 1st letter, so least *)
absent-fields-greatest = "z" (* mnemonic: last letter, so greatest *)
relative-absent-fields = "r"
fixed-absent-fields    = "f"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The working fields config's field specs are ordered per
`<field-order-option-set>`:

- `<document-order>`: ordered in document order, e.g., the order of keys in an
  input JSON object, each [member](#members) at its own position. A field spec
  whose field an item lacks (which outputs anything only per a format that
  renders an absent value, e.g., `%N%n+none+`) has no document position, so it
  compares as less (`a`) or greater (`z`) than every member. Per
  `<absent-field-placement>`, `<descending>` also reverses its location
  (`<relative-absent-fields>`, e.g., `D-` puts it 1st) or does not
  (`<fixed-absent-fields>`, e.g., `D-f` puts it last).
- `<positional-order>`: ordered by position.
- `<sort-option-set>`: if `<source>` is:
  - `<input>`: sorted by name.
  - `<output>`: sorted by label.

`<descending>` reverses `<order>`'s field order. For `<positional-order>`, it
does so by reversing the positions of the working fields config's field specs
before `<field-spec-edits-section>`, so its edits & each `<index>` (including a
`<baseline-sourced-field-spec-edit>`'s) apply to the reversed positions (e.g.,
in `@all/P-.+@1`, `@1` references `all`'s last field spec).

Field specs that the field order ties are ordered by position, reversed iff
`<field-order-tiebreaker>`'s `<direction>` is `<descending>`; no other
`<direction>` affects their order.

Unless the field order is `<positional-order>`, a field spec's position affects
only:

- Which field spec an `<index>` references.
- Tiebreaking the field order.

`<document-order-option-set>` is not supported for table output because items
may each have different fields, or the same fields in different orders, so a
table's rows share no document order; key-value & JSON output can order each
item's fields independently. An overridden `<document-order>` (e.g., in `/DP`)
is supported for every output format, because it orders nothing.

#### Item Sorting

```ebnf
item-sort-section        = <item-sort-section-prefix> <item-sort-option-set>
item-sort-section-prefix = "//"

item-sort-option-set = <item-sort-option>+
item-sort-option     = <disable-all-sorts> | <direction>

disable-all-sorts = "0" (* mnemonic: sort priority 0 *)
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
field-spec-reference = <named-field-spec-reference> | <indexed-field-spec-reference>

named-field-spec-reference   = <reference-field-name> [ <field-occurrence-index-prefix> <field-occurrence-index> ]
indexed-field-spec-reference = <field-spec-index-prefix> <field-spec-index>

reference-field-name = {text: field name with no bare "."}

field-occurrence-index-prefix = "@"
field-occurrence-index        = <index> (* transitive default: 1 *)

field-spec-index-prefix = "@"
field-spec-index        = <index>

index = {integer}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The **reference fields config** is a semi-mutable copy of the baseline fields
config, in which each removed field spec is replaced with `null`. The order of
field specs in the reference fields config is immutable (i.e., unaffected by any
inserts, moves, or removals performed in `<field-spec-edits-section>`).

Each index references a position in a list of the reference fields config's
field specs, in reference fields config order, filtered to include:

- For `<field-occurrence-index>`: only the field specs for field
  `<reference-field-name>`, or the `null`s that replaced them.
- For `<field-spec-index>`: all field specs.

E.g., in `x,a=aa,b,a=AA`:

- `a@2` references `a=AA`.
- `@2` references `a=aa`.

While a field spec's position in the reference fields config cannot be modified:

- Its `<field-modifiers>` may be modified.
- A `null` may replace it in its position, which does not modify any other field
  spec's position.

When accessing a field spec position via an index:

- If the position access reports an error, or if a `null` is present at the
  effective index in the list (unless `<field-spec-hide>` specifies otherwise),
  an error is reported.
- Otherwise, the field spec at the effective index in the list is the referenced
  field spec.

#### Relative Field Specs

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-spec-edits-section        = <field-spec-edits-section-prefix> [ <field-spec-edit> … <field-spec-separator> ]
field-spec-edits-section-prefix = "."

field-spec-edit = <baseline-sourced-field-spec-edit> | <reference-sourced-field-spec-edit>

baseline-sourced-field-spec-edit  = <field-spec-insertion>
reference-sourced-field-spec-edit = <field-spec-overlay> | <field-spec-move> | <field-spec-hide> | <field-spec-removal>

field-spec-insertion = <insert> <field-spec-reference> <field-modifiers>
field-spec-overlay   = <field-spec-reference> <field-modifiers>
field-spec-move      = <move> <field-spec-reference> <field-modifiers>
field-spec-hide      = <hide> <field-spec-reference> <field-modifiers>
field-spec-removal   = <remove> <field-spec-reference>

insert = "+"
move   = "%"
hide   = "_"
remove = "-"

field-spec-separator = ","
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

For a given `<reference-sourced-field-spec-edit>` `fs`, its `source` is the
field spec from the reference fields config referenced by `fs`. Thus, an
inserted field spec cannot be modified by another field spec edit.

For a given `<baseline-sourced-field-spec-edit>` `fs`, its `source` is the field
spec from the baseline fields config referenced by `fs`, resolved as in the
reference fields config, except that a `<named-field-spec-reference>` whose
`<reference-field-name>` names no field spec selects a [default field
spec](#default-field-specs) for field `<reference-field-name>` (whereas a
`<field-occurrence-index>` beyond its field's field specs is an error). Thus,
`<disable-all-sorts>` disables an inserted copy's sort (e.g., in
`@all//0.+name`).

$previous$ is the location in the working fields config where the direct results
of the immediately preceding `<field-spec-edit>` were effected: a field spec, or
the start of the working fields config. It is initially the start (i.e.,
immediately before the 1st field spec in the working fields config). It locates
a field spec, not an index, so moving another field spec does not change it
(e.g., for `a,b,c,d`, `.c,%a` moves `a` immediately after `c`, giving
`b,c,a,d`).

Field spec edits act as follows:

- `<field-spec-insertion>`:
  - Inserts a new visible field spec, a copy of `source`, immediately after
    $previous$, then overlays its `<field-modifiers>` onto the copy.
  - Sets $previous$ to the new field spec.
- `<field-spec-overlay>`:
  - Overlays its `<field-modifiers>` onto `source` & unhides it.
  - Sets $previous$ to `source`.
- `<field-spec-move>`:
  - Moves `source` to immediately after $previous$ (unless `source` is
    $previous$) & unhides it.
  - Sets $previous$ to `source`.
- `<field-spec-hide>`:
  - If its `<named-field-spec-reference>`'s `<reference-field-name>` names no
    field spec, or its `<field-spec-reference>` resolves to a `null`, inserts a
    new field spec (as `<field-spec-insertion>` would) as `source`.
  - Overlays its `<field-modifiers>` onto `source` & hides it, so a field can
    sort items without being output (e.g., `_size/1-`).
  - Sets $previous$ to `source`.
- `<field-spec-removal>`:
  - Sets $previous$ to the field spec immediately before `source` in the working
    fields config, or, if none precedes `source`, to its start.
  - Removes `source` from the working fields config.
  - Replaces `source` with `null` in the reference fields config.

### Field Modifiers

```ebnf
field-modifiers = [ <label-modifier> ] [ <format-modifier> ] [ <sort-modifier> ]
```

#### Payloads

A modifier's **payload** is the expression after its prefix (e.g., `<label>` in
`<label-modifier>`); an option's **payload** is the expression between its
letter & its `<sort-option-terminator>` (e.g., `<locale-identifier>` in
`<locale>`).

#### Labeling

```ebnf
label-modifier        = <label-modifier-prefix> [ <label> ]
label-modifier-prefix = "="

label = {text} (* direct default: {empty string} *)
```

- A field spec's `<label>` is its:
  - Header for table.
  - Key for key-value & JSON.

#### Formatting

[This section will be replaced by the content of
`fields-format.md`](fields-format.md).

#### Sorting

```ebnf
sort-modifier        = <sort-modifier-prefix> [ <sort> ]
sort-modifier-prefix = "/"

sort = <sort-priority> | [ <sort-priority> ] <sort-option-set>
```

- A **sort key** is a field spec with an enabled `<sort>`, which affects item
  sorting.
- Other field specs do not affect item sorting.

##### Sort Priority

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-priority = {non-negative integer} (* default: {<sort-priority> for the corresponding field spec in the working fields config} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A field spec with a `<sort>`:

- Requires a non-`null` `<sort-priority>`, otherwise an error is reported.
- Has its sort **disabled** by a `<sort-priority>` of `0`: its `<sort-option>`s
  are retained, but do not sort items until a positive `<sort-priority>` enables
  them, e.g., `_size/1` enables a hidden field spec's inherited `/0-`.
- Otherwise, takes sort precedence over field specs:
  - With a numerically higher `<sort-priority>` (i.e., lower numbers have higher
    priority).
  - Succeeding it with the same `<sort-priority>`.

##### Sort Options

```ebnf
sort-option-set = <sort-option>+
sort-option     =
  <source>
  | <direction>
  | <case-sensitivity>
  | <locale>
  | <number-segments>
  | <chronologic-segments>
  | <boundaries>
  | <nonconforming-comparison>
  | <nonconforming-placement>
  | <text-order>

sort-option-terminator = ":"
```

##### Sort Source

```ebnf
source = <input> | <output> (* default: <input>; last wins *)

input  = "I"
output = "O"
```

If a format modifies an input value, `<input>` sorts by the input, while
`<output>` sorts by the field spec's [formatted
value](fields-format.md#value-types), so it sorts identically for every output
format.

A value is compared as a string, a non-string being [coerced to a
string](fields-format.md#value-coercion), except that a number is a single
[segment](#sort-segments):

- A chronologic segment, iff `<chronologic-formats>` includes `<unix-time>` &
  the number is a [chronologic Unix
  time](fields-format.md#chronologic-formatting).
- Otherwise, a number segment, unless `<number-segments>` is `<lexicographic>`
  or `<versions>`, either of which compares the number as its text (so, with
  `<versions>`, its text's versions compare with other versions).

E.g., for an input Unix time being output as an ISO date (without time):

- `<input>` sorts by the input Unix time.
- `<output>` sorts by the output ISO date (without time), so rows on the same
  date tie & fall through to the next sort key.

##### Sort Segments

A value is split into **segments**, in descending precedence:

1. **Chronologic segments**, per `<chronologic-segments>`.
2. **Number segments**, per `<number-segments>`.
3. **Text segments**: each maximal sequence of the remaining
   [non-boundary](#sort-boundaries) characters.

A chronologic or number segment is a **typed segment**.

Typed segments are detected throughout the entire value, before boundaries: a
boundary within a typed segment is part of it (e.g., with the default
boundaries, `2020-03-18 17:39` is 1 datetime segment), while boundaries split
only the remaining text. The rules about a typed segment's adjacent characters
(e.g., digit adjacency, or a word-initial sign) apply to the value's characters,
boundaries included.

A **run of non-boundary text** is a maximal sequence of segments between
boundaries.

A value's **pieces** are, in order, its runs of non-boundary text & its
boundaries outside typed segments (with `<collapsed-boundaries>`, each run of
contiguous boundaries of the same boundary group being 1 piece). 2 values
compare their pieces as lists: a boundary piece precedes a run of non-boundary
text, and boundary pieces compare per their boundary groups' [sort
precedence](#sort-boundaries).

2 runs of non-boundary text compare their segments as 1 or 2 lists, per
`<text-order>`. Lists compare element by element: the 1st unequal pair of
elements decides, else a list that is a prefix of the other precedes it.

Segments of different kinds compare by kind, in ascending order: time-only
chronologic, other chronologic, number, then text. Segments of the same kind
compare:

- If time-only chronologic: by time of day, normalized to UTC per its UTC
  offset, or, if it has none, per the system time zone's UTC offset as if on the
  current date in the system time zone.
- If other chronologic: chronologically, a date-only at its start in the system
  time zone.
- If a version: as [specified](#version-comparison).
- If another number: numerically.
- If text: per `<case-sensitivity>` & `<locale>`.

###### Version Comparison

[Versions](fields-format.md#version-formatting) compare component by component:
numerically by each component's leading ASCII digits, then by its remaining
characters (a component with remaining characters precedes the same integer
without them; e.g., `1.0b` precedes `1.0`); a version with fewer components
precedes one that extends it.

Remaining characters compare as [lists](#sort-segments) of their maximal runs of
ASCII digits (each compared numerically) & of other characters (each compared
per `<case-sensitivity>` & `<locale>`), e.g., `2.0b9` precedes `2.0b10`.

##### Sort Direction

```ebnf
direction = <ascending> | <descending> (* default: <ascending>; last wins *)

ascending  = "+" (* mnemonic: increasing *)
descending = "-" (* mnemonic: decreasing *)
```

##### Sort Case Sensitivity

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
case-sensitivity = <sensitive> | <insensitive> (* default: <sensitive>; last wins *)

sensitive   = "s"
insensitive = "i"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<insensitive>` ignores case differences, as a collation's secondary strength
does (e.g., `a` equals `A`, but `é` does not equal `e`).

##### Sort Locale

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
locale = "L" [ <locale-identifier> ] <sort-option-terminator> (* transitive default locale-identifier: "canonical"; last wins *)

locale-identifier = {text: locale identifier, "canonical", or "system"} (* default: "system" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A `<locale-identifier>` of `canonical` identifies the canonical conventions; of
`system`, the system locale.

The canonical conventions compare text per the [CLDR root collation](
  https://www.unicode.org/reports/tr35/tr35-collation.html#Root_Collation
) (the Unicode Collation Algorithm with CLDR's root collation order & settings,
which is independent of every real-world locale), while a locale compares it per
its own collation. Each also supplies [`<grouped-numeric>`'s default number
conventions](#sort-number-segments).

Canonical number formatting uses a `.` decimal separator, a `,` digit group
separator, a digit group size of 3 & a secondary digit group size of 0.

##### Sort Number Segments

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
number-segments = <lexicographic> | <ungrouped-numeric> | <versions> | <grouped-numeric> (* default: <ungrouped-numeric>; last wins *)

lexicographic     = "x" (* mnemonic: 3rd letter of lexicographic *)
ungrouped-numeric = "u"
versions          = "v"
grouped-numeric   = "N" <grouped-numeric-arguments> <sort-option-terminator> (* default locale-identifier: {<locale>'s <locale-identifier>} *)

grouped-numeric-arguments = <number-format-arguments> <argument-separator>? [ <number-signs> ]

number-signs = <word-initial-signs> | <all-signs> | <no-signs> (* default: <word-initial-signs> *)

word-initial-signs = "word-initial"
all-signs          = "all"
no-signs           = "none"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The number segments are:

- `<lexicographic>`: none.
- `<ungrouped-numeric>`: each maximal run of ASCII digits, with a word-initial
  sign.
- `<versions>`: each [version](fields-format.md#version-formatting) (e.g., only
  `1.2` in `(1.2)` & in `1.2.beta`), without a sign.
- `<grouped-numeric>`: each **grouped number**, with a sign per
  `<number-signs>`.

Each number segment is the longest one that starts at the 1st position, after
the preceding typed segment, at which one starts (e.g., `<versions>` finds 1
version, `1.2.3`, rather than `1.2` & `3`, in `1.2.3`).

A grouped number is a run of ASCII digits split into [digit
groups](fields-format.md#numberformat) by a digit group separator, a decimal
separator followed by a fractional part, or both, in that order (e.g., `.5`
compares as `0.5`, as a [number coercion](fields-format.md#coercion) parses it),
then optionally an exponent indicator (`e` or `E`) & an optionally signed
integer exponent (e.g., `1.5e3` compares as `1500`), so it compares as a single
number (e.g., `1,234` as `1234`) rather than being broken into smaller ones by
the separator. Its group sizes & separators come from its [number format
arguments](fields-format.md#numberformat), each absent one defaulting to the
base conventions; a `<digit-group-size>` of `0` allows groups of any size.

A `-` or `+` immediately preceding a number segment is its sign:

- `<word-initial-signs>`: iff it starts the value or follows
  [whitespace](ebnf.md#whitespace) (e.g., in `-5` & `a -5`, but not in `a-5`).
- `<all-signs>`: always.
- `<no-signs>`: never.

##### Sort Chronologic Segments

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
chronologic-segments = "C" [ <chronologic-formats> ] <sort-option-terminator> (* transitive default chronologic-formats: "iso"; last wins *)

chronologic-formats = <chronologic-format> … <argument-separator>
chronologic-format  = <iso> | <iso-date> | <iso-datetime> | <iso-time> | <unix-time>

iso          = "iso"
iso-date     = "iso-date"
iso-datetime = "iso-datetime"
iso-time     = "iso-time"
unix-time    = "unix-time"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The chronologic segments are each longest text that a `<chronologic-format>`
matches, as [`%c` & `%.d` detect](fields-format.md#chronologic-formatting) it:

- `<iso-date>`: an ISO-8601 date-only.
- `<iso-datetime>`: an ISO-8601 datetime.
- `<iso-time>`: an ISO-8601 time-only.
- `<iso>`: an ISO-8601 date-only, datetime, or time-only.
- `<unix-time>`: a chronologic Unix time written as a decimal number.

Text that a `<chronologic-format>` matches is not a chronologic segment iff a
character immediately precedes or follows it that is:

- For `<iso>`, `<iso-date>`, `<iso-datetime>`, or `<iso-time>`: an ASCII digit,
  or, preceding an expanded year's sign, anything but whitespace (e.g.,
  `id-12345-06-07` has no chronologic segment).
- For `<unix-time>`: not whitespace (e.g., `at 1584553163 UTC` has a Unix time
  segment, but `v2`, `1.2.3`, `(1584553163)` & `1584553163,` have none).

Absent `<chronologic-formats>` (i.e., `C:`), there are no chronologic segments.

##### Sort Boundaries

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
boundaries = <uncollapsed-boundaries> | <collapsed-boundaries> (* default: "B+space+:"; last wins *)

uncollapsed-boundaries = "B" [ <boundary-groups> ] <sort-option-terminator>
collapsed-boundaries   = "M" [ <boundary-groups> ] <sort-option-terminator> (* mnemonic: merged *)

boundary-groups          = <boundary-group> … <boundary-group-separator>
boundary-group-separator = "_"

boundary-group      = ( <boundary-characters> | <multi-character-boundary> | <character-class> )+
boundary-characters = {text}

multi-character-boundary       = <multi-character-boundary-fence> <multi-character-boundary-text> <multi-character-boundary-fence>
multi-character-boundary-fence = "%"
multi-character-boundary-text  = {text}

character-class       = <character-class-fence> <character-class-name> <character-class-fence>
character-class-fence = "+"
character-class-name  =
  "alnum"
  | "alpha"
  | "ascii"
  | "blank"
  | "cntrl"
  | "digit"
  | "graph"
  | "lower"
  | "print"
  | "punct"
  | "space"
  | "upper"
  | "word"
  | "xdigit"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Input outside [typed segments](#sort-segments) is tokenized by **boundaries**
assigned to ordered sort precedence **boundary groups**, each defined by a
`<boundary-group>`; each group's members share the same sort precedence.

Each of the following is itself a boundary:

- Each character in a `<boundary-characters>`.
- Each `<multi-character-boundary-text>`.
- Each character belonging to the character class named
  `<character-class-name>`, per the POSIX Compatible definitions of [UTS #18
  Annex C](https://www.unicode.org/reports/tr18/#Compatibility_Properties)
  (e.g., `digit` is only `0` to `9`, and `punct` includes every symbol that is
  not alphabetic, such as `$`), with `ascii` being U+0000 to U+007F.

If multiple `<boundary-group>`s define the same boundary, it belongs to the last
group.

At each position, the longest boundary that matches there is consumed (e.g.,
with `B-%--%:`, `a--b` contains the boundary `--`, rather than 2 `-`s).

Boundaries take sort precedence over all boundaries in all groups succeeding
their group & over all non-boundary characters.

`<uncollapsed-boundaries>` retains contiguous boundaries in input as separate
characters; `<collapsed-boundaries>` collapses contiguous boundaries belonging
to the same boundary group into one. Absent `<boundary-groups>` (e.g., `B:`),
nothing is a boundary.

##### Sort Nonconforming Values

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nonconforming-comparison = <all-conforming> | <nonconforming-least> | <nonconforming-greatest> (* default: <all-conforming>; last wins *)

all-conforming         = "k" (* mnemonic: keep in place *)
nonconforming-least    = "a" (* mnemonic: 1st letter, so least *)
nonconforming-greatest = "z" (* mnemonic: last letter, so greatest *)

nonconforming-placement = <relative-nonconforming> | <fixed-nonconforming> (* default: <relative-nonconforming>; last wins *)

relative-nonconforming = "r"
fixed-nonconforming    = "f"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

With `<nonconforming-least>` or `<nonconforming-greatest>`, a value is
**nonconforming** iff it has no [typed segment](#sort-segments) (e.g., `Free`
for a price, or `null`). Nonconforming values compare among themselves as other
values do, but as less than (`a`) or greater than (`z`) every conforming value.
Per `<nonconforming-placement>`:

- `<relative-nonconforming>`: `<descending>` also reverses their location (e.g.,
  `a-` puts them last).
- `<fixed-nonconforming>`: they are 1st (`a`) or last (`z`) regardless of
  `<direction>` (e.g., `af-` puts them 1st), as SQL's `NULLS FIRST` &
  `NULLS LAST` put `NULL`s.

With `<all-conforming>`, no value is nonconforming.

##### Sort Text Order

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
text-order = <text-first> | <text-last> | <text-in-place> | <text-excluded> (* default: <text-in-place>; last wins *)

text-first    = "h" (* mnemonic: head *)
text-last     = "t" (* mnemonic: tail *)
text-in-place = "p"
text-excluded = "e"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Each run of non-boundary text compares its [segments](#sort-segments) as:

- `<text-first>`: a list of its text segments, then, iff those are equal, a list
  of its typed segments.
- `<text-last>`: a list of its typed segments, then, iff those are equal, a list
  of its text segments.
- `<text-in-place>`: a list of all its segments, in order.
- `<text-excluded>`: a list of its typed segments.

## Appendix: Escaping

[For a text token to consume text that would otherwise match a syntax literal, 1
or more of its characters must be escaped by prefixing it with a
`\`.](ebnf.md#tokens)

Throughout all text tokens, a literal `\` is written `\\`, because `\` always
escapes the next character.

[Outer bare whitespace is consumed or
ignored](ebnf.md#outer-bare-whitespace-treatment); whitespace must be escaped to
be consumed where bare whitespace is ignored.

In each row of the table below, the given characters must be escaped to be
consumed as either the 1st character of, or any character in, a text token
consumed by the given text terminal in the given syntactic context. Leading &
trailing outer bare whitespace is consumed or ignored, as given.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| `{text}`                                                             | 1st             | Any                     | Leading Whitespace | Trailing Whitespace     |
|:---------------------------------------------------------------------|:----------------|:------------------------|:-------------------|:------------------------|
| `<absolute-field-name>` of the 1st `<absolute-field-spec>`           | `@`             | `.` `=` `:` `/` `,`     | ignored            | ignored                 |
| `<absolute-field-name>` of a subsequent `<absolute-field-spec>`      |                 | `.` `=` `:` `/` `,`     | ignored            | ignored                 |
| `<base-fields-config-name>`                                          |                 | `/` `.`                 | ignored            | ignored                 |
| `<reference-field-name>` in `<field-spec-insertion>`                 |                 | `@` `.` `=` `:` `/` `,` | ignored            | ignored                 |
| `<reference-field-name>` in `<field-spec-overlay>`                   | `+` `%` `_` `-` | `@` `.` `=` `:` `/` `,` | ignored            | ignored                 |
| `<reference-field-name>` in `<field-spec-move>`                      |                 | `@` `.` `=` `:` `/` `,` | ignored            | ignored                 |
| `<reference-field-name>` in `<field-spec-hide>`                      |                 | `@` `.` `=` `:` `/` `,` | ignored            | ignored                 |
| `<reference-field-name>` in `<field-spec-removal>`                   |                 | `@` `.` `,`             | ignored            | ignored                 |
| `<label>`                                                            |                 | `:` `/` `,`             | ignored            | ignored                 |
| `<locale-identifier>` in `<locale>`                                  |                 | `:`                     | ignored            | ignored                 |
| `<boundary-characters>`                                              |                 | `%` `+` `_` `:`         | ignored            | ignored                 |
| `<multi-character-boundary-text>`                                    |                 | `%`                     | ignored            | ignored                 |
| `<format-name>` in a `<format-block>`                                |                 | `.` `/` `,`             | ignored            | ignored                 |
| `<template-text>` starting a `<format-block>`                        | `:` `.`         | `%` `/` `,`             | ignored            | consumed iff before `%` |
| `<template-text>` after a `<format-transform-pipeline>`              | `.`             | `%` `/` `,`             | ignored            | consumed iff before `%` |
| `<template-text>` immediately after a `<placeholder>`                |                 | `%` `/` `,`             | consumed           | consumed iff before `%` |
| `<format-name>` in a `<block>`                                       |                 | `.` `+`                 | ignored            | ignored                 |
| `<template-text>` starting a `<block>`                               | `:` `.`         | `%` `+`                 | ignored            | consumed iff before `%` |
| `<template-text>` immediately after a `<placeholder>` in a `<block>` |                 | `%` `+`                 | consumed           | consumed iff before `%` |
| `<decimal-separator>` in `<number-format>`                           |                 | `:`                     | ignored            | ignored                 |
| `<time-zone-code>` in `<date-time-zone-arguments>`                   |                 | `:`                     | ignored            | ignored                 |
| `<reference-date>`                                                   |                 | `:`                     | ignored            | ignored                 |
| `<trivia-suffix-regex>`                                              |                 | `:`                     | ignored            | ignored                 |
| Any other text argument                                              |                 | `,` `:`                 | ignored            | ignored                 |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A bare `.` in a field name is invalid, reserving it for future syntax; an
escaped `.` is consumed (e.g., `a\.b` names the field `a.b`).
