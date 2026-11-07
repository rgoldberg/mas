# Field Selection

A fields config selects, orders, labels & formats a [display
command](configs.md#display-commands)'s output fields.

It also sorts the items the command outputs.

Uses the [custom EBNF grammar](ebnf.md).

## Positions & Indices

List elements are located at 1-based integer **positions**.

Positions are referenced via integer **indices**.

Each index is normalized once into its **normalized index**, the position that
it references:

- If non-negative $index$: $index$.
- If negative $index$: $length + 1 + index$ (where $length$ is the list's
  length).

Accessing an invalid position is an error. Invalid positions are:

- Non-positive positions.
- Positions that are greater than a list's length.

A normalized index is never normalized again, nor reduced modulo $length$, so an
index whose normalized index is invalid is an error (e.g., for a 3-element list,
`-1` references position 3, while `0`, `4`, `-4` & `-5` are errors, `-5`'s
normalized index being `-1`).

A negative index may be used to _reference_ an element, but the index _of_ an
element is always positive.

## Field Specs

A **field spec** & its position define the configuration for an output field:

- Inclusion
- Order
- Label (table header; key-value / JSON key)
- Value format
- Alignment (table column)
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

A **default field spec** for a field has the [`default` preset](#presets)
attached, is visible unless it is for a hidden unlisted field & otherwise has
the following:

- Label: the field's name.
- Format: `%i`.
- Alignment: [`start`](#alignment).
- No `<sort>`, so it is not a sort key.

E.g., `.+size`, when the base fields config has no field spec for `size`,
outputs `size` labeled `size`, formatted as `%i`, start-aligned & not sorting
items, absent a custom `default` preset (e.g., one of `%end` would end-align
it).

### Unlisted Fields

A fields config **lists** a field iff the app lists it, or a `<field-name>`
names it in the fields config's `<fields-config>` or in that of any fields
config that it [extends](configs.md#referencing-named-configs) (the resolved
fields config extends its base fields config), e.g., `foo` in `@all.-foo`. An
app lists each field that it knows before reading any input (e.g., each field of
an input format that specifies all potential input fields up front, per
[nonexistent fields](#nonexistent-fields)).

An item's field is **unlisted** iff the fields config does not list it. A
[built-in fields config](#immutable-built-in-named-fields-configs)'s unlisted
fields are visible or hidden as it specifies; any other fields config's are
visible iff those of the fields config that it extends are (e.g., visible for
`@all.-foo`, but hidden for an `<absolute-config>`, which extends `none`).

Each unlisted field has a [default field spec](#default-field-specs) that has no
position, so no index references it. Its `<sort>`, if any, is
[disabled](#sort-priority) after its `default` preset is attached, as by
`<disable-all-sorts>`, so an unlisted field never sorts items (e.g., if the
`default` preset sets an enabled sort, `@all` sorts items only by its listed
fields).

Each visible unlisted field is output per its default field spec;
`<positional-order>` orders it as an [unpositioned field](#field-order), while
`<document-order>` orders it at its own document position. A field order that
ties it with a field spec or with another unlisted field orders it as if it were
a field spec positioned after every field spec, among unlisted fields in order
of their 1st occurrence in the input. For table output, each visible unlisted
field of any item has a column; for key-value & JSON output, each item outputs
only its own unlisted fields.

Because unlisted fields have no positions, neither a fields config nor its
positions depend on the input, so key-value & JSON output can output each item
as soon as it is read, unless item sorting reorders items.

## Fields Configs

A **fields config** specifies which fields are included in the output, along
with other output configuration.

A fields config may include:

- Settings that apply to all fields (e.g., its field order)
- Field-specific field specs

### Named Fields Configs

A **named fields config** is a [named config](configs.md#named-configs) of the
fields kind, whose name may be immediately followed by an [output format
suffix](#output-format-specific-named-fields-configs).

#### Output-Format-Specific Named Fields Configs

A fields config's name may include an optional output format suffix matching the
regex `@(json|key-value|table)$`.

Fields configs that share the same stem within the same context are
**variants**.

In a reference to a fields config (not in a name itself), `@unsuffixed` may
directly follow a stem instead of an output format suffix, which resolves to the
unsuffixed variant, regardless of the current output format (e.g.,
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

A persistent fields config [extends a config of its own
name](configs.md#referencing-named-configs) iff its reference's stem is its own
stem, whatever either's suffix (e.g., for JSON output, a `default@json` in
`mas.list` that extends `default` extends `mas`'s `default` variant for JSON
output, instead of itself).

#### Immutable Built-In Named Fields Configs

For each [leaf context](configs.md#context-stacks):

- `none`: Hidden [unlisted fields](#unlisted-fields) & a [hidden](#visibility)
  field spec for each field that the app lists, as if `<disable-all-sorts>` were
  `none`'s last item-sort option, so `none` [disables](#sort-priority) every
  field's sort, listed or not (e.g., if the `default` preset sets an enabled
  sort, `@none.b/I` sorts items by `b`, while neither `@none.b/0I` nor
  `name,foo` sorts items, even if the app does not list `foo`). Absent a
  built-in field order: field specs are ordered by `<positional-order>`, so a
  fields config that extends it outputs its inserted field specs in insertion
  order (e.g., `@none.+b,+a` outputs `b`, then `a`).
- `all`: Visible unlisted fields & a visible field spec for each field that the
  app lists. Absent a built-in field order: its field order is its [saved field
  order](#field-order) of kind `O`, so field specs are sorted by label.
- [Built-in standard](configs.md#immutable-built-in-named-configs): Only a
  select list of field specs is visible, and unlisted fields are hidden. Absent
  a built-in field order: field specs are ordered by `<positional-order>`.

A built-in fields config:

- Has the [`default` preset](#presets) attached to each of its field specs.
- Saves, as its saved field order of each `<primary-field-order-kind>`, the
  app's **default field order** of that kind for the current output format,
  which the app gives as field order syntax (e.g.,
  [mas's](mas.md#default-field-orders)), or, absent one, that kind's
  `<primary-field-order-kind>` alone (e.g., `/P`).
- May have built-in variants.
- Cannot have custom variants.

#### Default Fields Configs

A reference to [`default`](configs.md#default-configs) matches a context's
custom `default` variants as any reference matches a stem's variants (e.g., for
JSON output, `default` matches `default@json`, then `default`). Iff it matches
none, [`standard`](configs.md#standard-configs) is substituted for `default`,
retaining any suffix (e.g., for JSON output, `default` becomes `standard`, which
resolves to `standard@json`, while `default@table` becomes `standard@table`). A
non-root context's `standard`, with any suffix, is its parent context's
`default` with that suffix.

So a custom unsuffixed `default` overrides every `standard` variant, while a
custom `default@json` overrides only `standard@json`. E.g., to customize table &
key-value output while JSON output retains `standard@json`, define
`default@table` & `default@key-value`, each extending 1 shared custom fields
config.

### Base Fields Config

The **base fields config** is a named fields config referenced in a
[transient](configs.md#transient-configs) fields config, or implicitly selected
for a run.

### Working Fields Config

The **working fields config** is a mutable copy of the fields config that a
`<fields-config>` extends (for a transient fields config, the base fields
config), as modified by that `<fields-config>` so far.

### Baseline Fields Config

The **baseline fields config** is an immutable snapshot of the working fields
config immediately before `<field-spec-edits-section>`.

### Resolved Fields Config

The **resolved fields config** is the working fields config after any transient
fields config has been parsed; it is used to render output.

## Inherited Values

A fields config's **settings** are each field spec's
[settings](#field-modifiers), plus, per [saved field order](#field-order), a
separate setting per `(* inherited *)` nonterminal in
`<primary-field-order-option-set>`, plus `<field-order-tiebreaker>`, plus a
separate setting per `(* inherited *)` nonterminal in `<item-sort-section>`.

An [inherited](ebnf.md#inherited-comments) nonterminal's inherited value is the
working fields config's value for the same setting, if any:

- In `<field-modifiers>`: that of the field spec that they modify.
- In `<item-sort-option>`: that of item sorting.
- `<field-order-sections>` itself: the field order, each saved field order &
  `<field-order-tiebreaker>`.
- `<field-order-tiebreaker>` itself: the working fields config's, whatever the
  field order's kind (e.g., if `x` has `/T-/P`, `@x/I` tiebreaks descending).
- In `<field-order-adjustment-set>`: that of the field order.
- `<field-order-sort-option-set>`'s `<source>`: that of the field order, iff the
  field order's kind is `<input>` or `<output>`, so a
  `<field-order-sort-option-set>`'s kind never depends on the saved field order
  that it inherits from.
- In `<positional-order-option-set>`, `<document-order-option-set>` &
  `<field-order-sort-option-set>`, except that `<source>`: that of its kind's
  saved field order.

So an omitted modifier (e.g., `<preset-modifier>` or `<sort-modifier>` in
`.name=x`) or option (e.g., `<direction>` in `.name/1`, in `.name/1Ii`, or in
`//0`) retains the working fields config's value, while an empty
[payload](#payloads) (e.g., in `.name=`, `.name/`, `L:`, or `B:`) is directly
absent, so it resets the payload's value to the payload's own default, rather
than to its option's (e.g., `B:` sets no boundaries, rather than `B+space+:`'s,
and `L:` selects the system locale, rather than the canonical conventions), as
it does each value within it (e.g., `.name/` removes the field spec's `<sort>`,
resetting its `<sort-priority>` & each of its `<sort-option>`s, while `.name:`
empties its format, but retains its alignment).

## Nonexistent Fields

**Nonexistent fields** are guaranteed to not exist in any input, which is
determinable only for input formats that specify all potential input fields up
front, e.g.: CSV, or JSON with a JSON schema.

Other input formats cannot guarantee field nonexistence, e.g.: JSON without a
JSON schema, for which a field may exist for some JSON objects, but not exist
for others.

A reference to a nonexistent field is an error in a transient fields config, but
a persistent fields config, which may apply to multiple commands, ignores each
`<absolute-field-spec>` & `<field-spec-edit>` that references one (e.g., a `mas`
context `default` of `@standard.name=App` ignores `.name=App` for `mas config`,
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
because an absent value remains unmodified through every
[transform](fields-format.md#value-coercion)).

An absent value matches `u`, `U`, `e`, `E`, `w` & `W` as `null` does; it is
[coerced to a string](fields-format.md#value-coercion) as an empty string.

Output depends on the formatted value, not on the field value, except that
key-value & JSON output omit each [unlisted field](#unlisted-fields) that an
item lacks:

- **Table**: A cell is output for each column (each visible field spec & each
  visible unlisted field of any item), regardless of whether its formatted value
  is absent, which is output as an empty string.
- **Key-Value**: A key-value pair is output for the field label & formatted
  value iff the formatted value is neither absent nor `null`.
- **JSON**: A key-value pair is output for the field label & formatted value iff
  the formatted value is not absent; e.g., for JSON input, `null`, `true`,
  `false`, `0`, `1`, `""` & `"null"` are all values.

E.g., for an absent field, `%N%n+none+` outputs `none` in every output format,
while `%i` & `%n` output an empty table cell, but no key-value pair in key-value
or JSON output.

## Fields Config Syntax

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
fields-config = <absolute-config> | <relative-config> (* default: <relative-config> *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Giving more than 1 transient fields config for a run is an error.

In a transient fields config, `<absolute-config>` & `<relative-config>` are
overlaid on top of the base fields config for its run only; they do not
persistently affect named fields configs.

### Absolute Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
absolute-config = <absolute-field-spec> … <field-spec-separator>

absolute-field-spec = <field-name> <field-modifiers>

field-name = {string: field name with no bare "."} (* error: in a transient fields config, it names a nonexistent field *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

An `<absolute-config>` is equivalent to a `<relative-config>` with base fields
config `none` & a `<field-spec-insertion>` for each of its field specs, e.g.:

- `version=Ver,size` ≡ `@none.+version=Ver,+size`
- `name,name` ≡ `@none.+name,+name`

Because `none`'s sorts are [disabled](#immutable-built-in-named-fields-configs),
an `<absolute-field-spec>` sorts items only if its `<field-modifiers>` enable
its sort (e.g., if the `default` preset is `/I`, `name,version` does not sort
items, while `name/1,version` sorts them by `name`'s input).

### Relative Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
relative-config = [ <base-fields-config-section> ] [ <field-order-sections> ] [ <item-sort-section> ] [ <field-spec-edits-section> ]
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The resolved fields config is sourced from the base fields config as modified by
`<relative-config>`'s present sections, so, e.g., `@x.name` retains `x`'s field
order & item-sort `<direction>`.

#### Base Fields Config Selection

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
base-fields-config-section        = <base-fields-config-section-prefix> <base-fields-config-name>
base-fields-config-section-prefix = "@"

base-fields-config-name =
  {string: fields config name, or a stem followed by '@unsuffixed'}
  (* default: 'default'; error: no fields config of its name is found, or it is in a reference cycle *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

#### Field Order

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-order-sections       = <field-order-section>+ (* inherited *)
field-order-section        = <field-order-section-prefix> <field-order-option-set>
field-order-section-prefix = "/"

field-order-option-set         = <primary-field-order-option-set> | <field-order-tiebreaker>
primary-field-order-option-set =
  <positional-order-option-set> | <document-order-option-set> | <field-order-sort-option-set> | <field-order-adjustment-set>
field-order-kind               = <primary-field-order-kind> | <field-order-tiebreaker-prefix> (* non-structural *)
primary-field-order-kind       = <positional-order> | <document-order> | <input> | <output> (* non-structural *)
field-order-tiebreaker         = <field-order-tiebreaker-prefix> <direction> (* last wins; inherited *)
field-order-tiebreaker-prefix  = "T"

field-order-adjustment-set  =
  <adjustment-sort-option>+
  (* error: it has an effective <all-conforming> & is per <positional-order-option-set> or <document-order-option-set> *)
field-order-sort-option-set =
  [ <adjustment-sort-option>+ ] <non-adjustment-sort-option> [ <sort-option>+ ]
  (* default source: <output> *)

positional-order-option-set = [ <order-option>+ ] <positional-order> [ <order-trailing-option>+ ]
document-order-option-set   =
  [ <order-option>+ ] <document-order> [ <order-trailing-option>+ ]
  (* error: for table output, it sets the resolved fields config's field order *)

order-option          = <order> | <order-trailing-option>
order-trailing-option = <direction> | <unpositioned-field-comparison> | <unpositioned-field-placement>

order = <positional-order> | <document-order> (* last wins *)

positional-order = "P"
document-order   = "D"

unpositioned-field-comparison = <unpositioned-fields-least> | <unpositioned-fields-greatest> (* default: <unpositioned-fields-greatest>; last wins; inherited *)
unpositioned-field-placement  = <relative-unpositioned-fields> | <fixed-unpositioned-fields> (* default: <relative-unpositioned-fields>; last wins; inherited *)

unpositioned-fields-least    = "a" (* mnemonic: 1st letter, so least *)
unpositioned-fields-greatest = "z" (* mnemonic: last letter, so greatest *)
relative-unpositioned-fields = "r"
fixed-unpositioned-fields    = "f"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The **field order**, in which each item's fields are output, is per the last
`<primary-field-order-option-set>` in `<field-order-sections>`:

- `<document-order>`: ordered in document order, e.g., the order of keys in an
  input JSON object, each [member](#members) at its own position. A field spec
  whose field an item lacks (which outputs anything only per a format whose
  formatted value for an absent field is not [absent](#absent-values), e.g.,
  `%N%n+none+`) has no document position, so its field is **unpositioned**.
- `<positional-order>`: ordered by position. Each visible [unlisted
  field](#unlisted-fields) has no position, so it is **unpositioned**;
  unpositioned fields are ordered among themselves by their 1st occurrence in
  the input, reversed iff `<descending>`.
- `<field-order-sort-option-set>`: if `<source>` is:
  - `<input>`: sorted by name.
  - `<output>`: sorted by label.
- `<field-order-adjustment-set>`: per the same one of
  `<positional-order-option-set>`, `<document-order-option-set>` &
  `<field-order-sort-option-set>` as the working fields config's field order,
  setting only its `<direction>` & its comparison & placement of the fields or
  values that it cannot order (unpositioned fields or nonconforming values),
  because an adjustment alone is meant to adjust the working field order, not to
  replace it. Per `<positional-order-option-set>` or
  `<document-order-option-set>`, each `<nonconforming-comparison>` &
  `<nonconforming-placement>` sets `<unpositioned-field-comparison>` &
  `<unpositioned-field-placement>`, respectively, to the alternative of its
  letter, which `<all-conforming>` lacks, because no field order can order an
  unpositioned field as a positioned one. E.g., if `x` has `/aP`, `@x/-` ≡
  `@x/aP-` & `@x/f` ≡ `@x/aPf`; if `x` has `/D`, `@x/-` ≡ `@x/D-`; if `x` has
  `/I`, `@x/-` ≡ `@x/I-` & `@x/a` ≡ `@x/Ia`; if `x` has `/P`, `@x/ka` ≡ `@x/aP`,
  while `@x/k` & `@x/ak` are errors.

A field order's **kind** is its effective `<order>` or `<source>`'s
`<primary-field-order-kind>`, or, for a `<field-order-adjustment-set>`, that of
the field order that it adjusts (e.g., `P` for `/DP`, or `O` for `/i` while the
field order is `/P`). A `<field-order-section>`'s kind is its field order's, or,
for a `<field-order-tiebreaker>`, `T`.

A fields config **saves** the field order of each `<field-order-section>` whose
kind is a `<primary-field-order-kind>` as its **saved field order** of that
kind, so it has 1 per `<primary-field-order-kind>`, the field order's included;
each [inherits](#inherited-values) from its own kind's saved field order, never
from one of another kind, because each kind's options mean something else for
another kind (e.g., if `x` is `@none/O-/P`, `@x/O` sorts by label, descending,
while `@x/I` sorts by name, ascending, per `none`'s saved field order of kind
`I`). Thus, a section that a later one overrides still sets its kind's options
for a later section of that kind, in its own fields config or in one that
extends it (e.g., `/iO/P` orders by position, while a fields config that extends
it & has `/O` sorts by label, case-insensitively), and a later section of the
same kind inherits from an earlier one, so splitting sections between a fields
config & one that it extends does not change what they mean (e.g., `/iO/-O` ≡
`/iO-`).

Because a `<field-order-tiebreaker>` has a `<field-order-kind>` of its own, it &
a `<primary-field-order-option-set>` never override each other (e.g., `/T-/I` ≡
`/I/T-`), so it cannot be mistaken for a `<field-order-adjustment-set>` (e.g.,
`/O/T-` sorts by label, tiebreaking descending, while `/O/-` ≡ `/O-` sorts by
label, descending). It has no effect while the field order is positional, which
ties no field specs, but it still tiebreaks a later section of another kind
(e.g., if `x` is `@none/T-`, `@x/I` tiebreaks descending).

An unpositioned field compares as less (`a`) or greater (`z`) than every
positioned one. Per `<unpositioned-field-placement>`, `<descending>` also
reverses its location (`<relative-unpositioned-fields>`, e.g., `D-` or `P-` puts
it 1st) or does not (`<fixed-unpositioned-fields>`, e.g., `D-f` or `P-f` puts it
last).

`<descending>` reverses a positional order or a document order. For
`<positional-order>`, it does so by reversing the positions of the working
fields config's field specs before `<field-spec-edits-section>`, so its edits &
each `<index>` (including a `<baseline-sourced-field-spec-edit>`'s) apply to the
reversed positions (e.g., in `@all/P-.+@1`, `@1` references `all`'s last field
spec). A `<direction>` of a field order per `<positional-order-option-set>`
reverses those positions iff it differs from the working fields config's saved
positional field order's `<direction>`, which already reversed them iff
`<descending>` (e.g., if `x` has `/P-`, each of `@x/P-`, `@x/P` & `@x/-` outputs
`x`'s field order, while each of `@x/P+` & `@x/+` reverses it; if `y` is `@x/O`,
`@y/P-` outputs `x`'s field order, while `@y/P+` reverses it). So a positional
order that a later section overrides still reverses positions (e.g., `/P-/I`
sorts by name, tiebreaking as `/I/T-` does, while each `<index>` references the
reversed positions).

Field specs that the field order ties are ordered by position, reversed iff the
effective `<field-order-tiebreaker>`'s `<direction>` is `<descending>`; no other
`<direction>` affects their order.

An option omitted from a present field order section may retain the working
fields config's value, [as specified](#inherited-values) (e.g., if `x` has
`/I-`, `@x/i` sorts by name, descending, while `@x/D` & `@x/P` are ascending; if
`x` has `/D-`, `@x/PD`, being a `<document-order-option-set>`, is descending; if
`x` has `/aP-`, `@x/P` retains `a` & `<descending>`).

Unless the field order is `<positional-order>`, a field spec's position affects
only:

- Which field spec an `<index>` references.
- Tiebreaking the field order.
- Sort precedence among sort keys with the same
  [`<sort-priority>`](#sort-priority).

`<document-order-option-set>` is unsupported for table output because items may
each have different fields, or the same fields in different orders, so a table's
rows share no document order; key-value & JSON output can order each item's
fields independently. E.g., for table output, if `x` is `@all/D`, `@x/P` is
supported, while `@x` is an error. Because `<order>` is last wins, `/DP` is a
`<positional-order-option-set>`, so it is supported, while `/PD` is a
`<document-order-option-set>`, so it is an error for table output.

#### Item Sorting

```ebnf
item-sort-section        = <item-sort-section-prefix> [ <item-sort-option-set> ]
item-sort-section-prefix = "//"

item-sort-option-set = <item-sort-option>+
item-sort-option     = <disable-all-sorts> | <direction>

disable-all-sorts = "0" (* mnemonic: as <disabled-sort-prefix> *)
```

`<disable-all-sorts>` disables each field spec's `<sort>`, as
`<disabled-sort-prefix>` does, retaining its `<sort-priority>` &
`<sort-option>`s; a subsequent `<field-spec-edit>` may re-enable a field spec's
sort (e.g., if `x` has `name/5I`, `@x//0.name/I` re-enables it with a
`<sort-priority>` of `5`). It disables a sort that an attached preset set, as it
does an explicit one, while a preset that a subsequent `<preset-modifier>`
attaches sets its own sort (e.g., if preset `p` sets an enabled sort,
`@x//0.name%+p` sorts by it). Each [default field spec](#default-field-specs)
that a subsequent `<field-spec-edit>`, in its own fields config or in one that
extends it, selects likewise has its `<sort>`, if any, disabled after its
`default` preset is attached (e.g., if the `default` preset sets an enabled sort
& neither `x` nor `y` has a field spec for `foo`, neither `@x//0.+foo` nor, for
a `y` of `@x//0`, `@y.+foo` sorts items by `foo`).

`<ascending>` tiebreaks item sorting by input order, `<descending>` by reverse
input order; absent any field spec with an enabled `<sort>`, items are ordered
solely by this tiebreak. E.g., per [inherited values](#inherited-values), if `x`
has `//-`, then `@x//0` & `@x//` tiebreak by reverse input order.

#### Field Spec References

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-spec-reference = <named-field-spec-reference> | <indexed-field-spec-reference>

named-field-spec-reference   = <field-name> [ <field-occurrence-index-prefix> <field-occurrence-index> ]
indexed-field-spec-reference = <field-spec-index-prefix> <field-spec-index>

field-occurrence-index-prefix = "@"
field-occurrence-index        = <index> (* transitive default: {1 iff <field-name> names a field spec or a null, else no index} *)

field-spec-index-prefix = "@"
field-spec-index        = <index>

index = {integer} (* error: its normalized index is invalid *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The **reference fields config** is a semi-mutable copy of the baseline fields
config, in which each removed field spec is replaced with `null`. The order of
field specs in the reference fields config is immutable (i.e., unaffected by any
insertions, moves, or removals performed in `<field-spec-edits-section>`).

Each index references a position in a list of the reference fields config's
field specs, in reference fields config order, filtered to include:

- For `<field-occurrence-index>`: only the field specs for field `<field-name>`,
  or the `null`s that replaced them.
- For `<field-spec-index>`: all field specs.

E.g., if the baseline fields config's field specs are `x,a=aa,b,a=AA`:

- `a@2` in `.a@2` references `a=AA`.
- `@2` in `.@2` references `a=aa`.

While a field spec's position in the reference fields config cannot be modified:

- Its `<field-modifiers>` may be modified.
- A `null` may replace it in its position, which does not modify any other field
  spec's position, and a field spec may replace that `null` in turn.

An index's `<field-spec-reference>` references the field spec or `null` at its
normalized index in the list; a `<field-spec-edit>` applies to a `null` as
[specified](#relative-field-specs).

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
inserted field spec cannot be modified by another field spec edit, unless a
`<reference-sourced-field-spec-edit>` inserted it as its `source`.

A `<reference-sourced-field-spec-edit>` whose `<named-field-spec-reference>` has
no `<field-occurrence-index>` & whose `<field-name>` names neither a field spec
nor a `null` in the reference fields config (e.g., one for an [unlisted
field](#unlisted-fields)) has no such `source`: a `<field-spec-removal>` then
does nothing (leaving $previous$ unmodified), though it lists its field, while
any other one 1st inserts a new field spec (as `<field-spec-insertion>` would)
as its `source` (e.g., for an unlisted `foo`, `@all.foo=Foo` inserts a visible
field spec & `@all._foo` a hidden one, while `@all.-foo` lists `foo`, so `all`
does not output it). Until a `<field-spec-removal>` removes that inserted field
spec, each later such `<named-field-spec-reference>` for its field references
it, though no index does (e.g., `@all.foo=X,foo=Y` outputs 1 `foo`, labeled
`Y`).

A `<reference-sourced-field-spec-edit>` other than a `<field-spec-removal>`
whose `<field-spec-reference>` resolves to a `null` likewise 1st inserts a new
field spec (as `<field-spec-insertion>` would, copying the baseline fields
config's field spec) as its `source`, which replaces the `null` in the reference
fields config, so that a later field spec edit modifies it (e.g., `.-a,a=X`
restores `a`, labeled `X`, while `.-a,a=X,a=Y` outputs 1 `a`, labeled `Y`).

A `<field-spec-removal>` whose `<field-spec-reference>` resolves to a `null`
does nothing, leaving $previous$ unmodified (e.g., `.-a,-a` means what `.-a`
means).

For a given `<baseline-sourced-field-spec-edit>` `fs`, its `source` is the field
spec from the baseline fields config referenced by `fs`, so
`<disable-all-sorts>` disables an inserted copy's sort (e.g., if `x` has
`name/I`, `@x//0.+name` inserts a copy of `name` whose sort is disabled).
`source` is resolved as in the reference fields config, except that a
`<named-field-spec-reference>` without a `<field-occurrence-index>` whose
`<field-name>` names no field spec selects a [default field
spec](#default-field-specs) for field `<field-name>` (whereas a present
`<field-occurrence-index>` beyond its field's field specs is an error, e.g.,
`.+x@1` when `x` has no field spec).

$previous$ is the location in the working fields config where the direct results
of the immediately preceding `<field-spec-edit>` were effected: a field spec, or
the start of the working fields config. Before the 1st `<field-spec-edit>`, it
is the start (i.e., immediately before the 1st field spec in the working fields
config). It locates a field spec, not an index, so moving another field spec
does not affect it (e.g., for `a,b,c,d`, `.c,%a` moves `a` immediately after
`c`, giving `b,c,a,d`).

Field spec edits act as follows:

- `<field-spec-insertion>`:
  - Inserts a new visible field spec, a copy of `source`, immediately after
    $previous$, then overlays its `<field-modifiers>` onto the copy.
  - Sets $previous$ to the new field spec.
- `<field-spec-overlay>`:
  - Overlays its `<field-modifiers>` onto `source` & unhides it.
  - Sets $previous$ to `source`.
- `<field-spec-move>`:
  - Overlays its `<field-modifiers>` onto `source`, moves it to immediately
    after $previous$ (unless `source` is $previous$) & unhides it.
  - Sets $previous$ to `source`.
- `<field-spec-hide>`:
  - Overlays its `<field-modifiers>` onto `source` & hides it, so a field can
    sort items without being output (e.g., `._size/1-`).
  - Sets $previous$ to `source`.
- `<field-spec-removal>`:
  - Sets $previous$ to the field spec immediately before `source` in the working
    fields config, or, if none precedes `source`, to its start.
  - Removes `source` from the working fields config.
  - Replaces `source` with `null` in the reference fields config, if it is
    there.

### Field Modifiers

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-modifiers = [ <preset-modifier> ] [ <label-modifier> ] [ <format-modifier> ] [ <sort-modifier> ]
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A field spec has a separate **setting** per `(* inherited *)` nonterminal in
`<field-modifiers>` (e.g., `<label>` or `<direction>`), plus its
[alignment](#alignment). A `<field-modifiers>` **sets** each setting whose
nonterminal does not retain its [inherited value](#inherited-values) in it
(e.g., `/-` enables `<sort>` & sets `<direction>`, but no other sort option,
while `/` removes `<sort>` & resets every setting within it).

`<preset-modifier>`, then `<label-modifier>`, `<format-modifier>` &
`<sort-modifier>` overlay their settings onto the field spec, so a later one
overrides an earlier one's setting.

#### Payloads

A modifier's **payload** is the expression after its prefix (e.g., `<label>` in
`<label-modifier>`); an option's **payload** is the expression between its
letter & its `<sort-option-terminator>` (e.g., `<locale-identifier>` in
`<locale>`).

#### Presets

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
preset-modifier = <preset-list>
preset-list     = <absolute-presets> | <relative-presets> (* inherited *)

absolute-presets = <preset-clearing> | <absolute-preset>+
preset-clearing  = "%"
absolute-preset  = <preset-prefix> <preset-name>
preset-prefix    = "%"

relative-presets = <preset-delta>+
preset-delta     = <preset-prefix> ( <preset-addition> | <preset-removal> ) <preset-name>
preset-addition  = "+"
preset-removal   = "-"

preset-name = {string: preset name} (* error: no preset of its name is found, or it is in a reference cycle *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **preset** is a [named config](configs.md#named-configs) of the preset [config
kind](configs.md#config-kinds), whose syntax is `<field-modifiers>`, which a
`<preset-name>` references (e.g., `%x` references preset `x`). Each field spec
has a list of **attached** presets, which its `<preset-list>` sets:

- `<absolute-presets>`: replaces the list with the presets of its
  `<absolute-preset>`s, in order (e.g., `name%p%q`), or, for
  `<preset-clearing>`, with none (e.g., `name%`).
- `<relative-presets>`: applies each `<preset-delta>` to the list, left to
  right: `<preset-addition>` attaches its preset at the end of the list,
  replacing any attached preset of its name, while `<preset-removal>`
  **detaches** the attached preset of its name, if any (e.g.,
  `.name%-default%+end` detaches `default` from `name`, then attaches `end`,
  while `.name%-end` modifies nothing if `end` is not attached).

Attached presets are identified by name, whichever context each was looked up
from, so at most 1 preset of each name is attached: an `<absolute-presets>` that
names a preset more than once attaches it only at its last occurrence (e.g.,
`%p%q%p` ≡ `%q%p`), and a `<preset-delta>` matches an attached preset of its
name, even one looked up from another context (e.g., for a fields config `x` of
`@all.name%-default` in context `mas`, `mas list --fields @x` detaches from
`name` the `default` preset that `all` attached from `mas.list`).
`<preset-name>`'s error comment applies even to a `<preset-removal>` that
detaches nothing (e.g., `%-bytess`, a typo of `bytes`, is an error absent a
preset `bytess`).

Attaching a preset (including moving it to the end of the list) sets, at that
point & in order, each [setting](#field-modifiers) that attaching each preset
attached within it sets, then each one other than `<preset-list>` that its own
`<field-modifiers>` sets, retaining every other one (e.g., if preset `p` is
`/-`, `@all.name/O,name%+p` sorts items by `name`'s formatted value,
descending). Each setting of a field spec is thus the last value set, in order,
by an explicit modifier or by an attached preset, else the value that the field
spec otherwise has (e.g., a [default field spec](#default-field-specs)'s label
is its field's name). Detaching a preset re-exposes the value that it overrode
for each setting that it sets (e.g., if preset `p` sets label `P`,
`@all.name=N,name%+p` labels `name` `P`, while `@all.name=N,name%+p,name%-p`
labels it `N`). A copy of a field spec (e.g., by a `<field-spec-insertion>`)
retains its attached presets & when each of its settings was set.

E.g., if preset `bytes` is `%end:%+.N.scale:6,,0:+ MB`, `size%bytes%start=Size`
outputs `size` labeled `Size`, formatted per `bytes` & start-aligned, while
`.+size%+bytes` inserts a copy of `size` that also has its `default` preset
attached.

A preset's own `<preset-list>` sets the list of presets attached within it,
which starts empty, not the list of any field spec to which it is attached,
though attaching it sets what they set (e.g., if preset `mb` is `%bytes=Size`,
`.size%mb` attaches only `mb` to `size`, yet end-aligns it & labels it `Size`).

A `<preset-name>` is looked up from the starting context of its reference, as
[specified for every config kind](configs.md#referencing-named-configs); the
`default` preset that a default field spec or a built-in fields config's field
spec has attached is looked up from the starting context of the reference that
selects the base fields config (e.g., `mas.list`'s `default` preset for
`mas list --fields @all`).

The preset kind's [built-in
standard](configs.md#immutable-built-in-named-configs) sets nothing, so, absent
any custom one, the [`default`](configs.md#default-configs) preset sets nothing.
The preset kind's other built-in presets each set only an
[alignment](#alignment): `start`, `centerStart`, `centerEnd`, or `end`.

##### Alignment

A field spec's **alignment** aligns its label & its values in its table output
column; key-value & JSON output, which have no columns, ignore it. No modifier
other than a `<preset-modifier>` sets a field spec's alignment; each built-in
alignment preset sets it:

- `start`: at the column's start.
- `centerStart`: centered, with any odd remaining column width's extra space
  after the value (leaving it nearer the column's start).
- `centerEnd`: centered, with any odd remaining column width's extra space
  before the value (leaving it nearer the column's end).
- `end`: at the column's end.

#### Labeling

```ebnf
label-modifier        = <label-modifier-prefix> [ <label> ]
label-modifier-prefix = "="

label = {string} (* direct default: {empty string}; inherited *)
```

- A field spec's `<label>` is its:
  - Header for table.
  - Key for key-value & JSON.

#### Formatting

[`<format-modifier>` is specified separately](fields-format.md).

#### Sorting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-modifier        = <sort-modifier-prefix> [ <sort> ]
sort-modifier-prefix = "/"

sort =
  <disabled-sort-prefix>+ [ <sort-option-set> ]
  | [ <disabled-sort-prefix>+ ] <sort-priority> [ <sort-option-set> ]
  | <sort-option-set>
  (* value: {disabled iff it starts with <disabled-sort-prefix>, else enabled}; inherited *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **sort key** is a field spec with an enabled `<sort>`, which affects item
sorting.

##### Sort Priority

```ebnf
disabled-sort-prefix = "0" (* mnemonic: 0, as off *)

sort-priority = {integer: positive, no leading 0s} (* default: 100; inherited *)
```

A `<sort>` that starts with `<disabled-sort-prefix>` **disables** its field
spec's sort (e.g., `05` disables a sort whose `<sort-priority>` is `5`, as does
`005`): its `<sort-priority>` & `<sort-option>`s are retained, but do not sort
items until a `<sort>` without `<disabled-sort-prefix>` enables them, e.g.,
`._size/1` or `._size/I` enables a hidden field spec's inherited `/0-`, while
`._size/0I` modifies its `<sort-option>`s, but its sort remains disabled.

A field spec with an enabled `<sort>` takes sort precedence over field specs:

- With a numerically higher `<sort-priority>` (i.e., lower numbers have higher
  priority).
- With the same `<sort-priority>` that succeed it in the order of the field
  specs in the resolved fields config, regardless of the field order, though
  `<positional-order>`'s `<descending>` reverses that order by reversing
  positions (e.g., if `x` has `name/I,version/I`, `@x` sorts items by `name`,
  then by `version`, while `@x/P-` sorts them by `version`, then by `name`).

Thus, a `<sort-priority>` below `100` takes sort precedence over every sort that
omits its `<sort-priority>` & inherits none, while one above `100` cedes it
(e.g., `name/I,version/1I` sorts items by `version`, then by `name`, while
`name/I,version/101I` sorts them by `name`, then by `version`).

##### Sort Options

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-option-set            = <sort-option>+
sort-option                = <adjustment-sort-option> | <non-adjustment-sort-option>
adjustment-sort-option     = <direction> | <nonconforming-comparison> | <nonconforming-placement>
non-adjustment-sort-option = <source> | <case-sensitivity> | <locale> | <number-segments> | <chronologic-segments> | <boundaries> | <text-order>

sort-option-terminator = ":"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The app may set, per output format, **default sort options** for each field's
content, each of which replaces the default of its `<sort-option>` in a field
spec's `<sort>` (e.g., [mas's](mas.md#default-sort-options) make `<insensitive>`
the default `<case-sensitivity>` for table output, so `name/I` sorts items by
`name` case-insensitively), while a `<field-order-sort-option-set>` inherits its
options from a [saved field order](#field-order), which a built-in fields config
sets per the app's default field orders.

##### Sort Source

```ebnf
source = <input> | <output> (* default: <input>; last wins; inherited *)

input  = "I"
output = "O"
```

If a format modifies an input value, `<input>` sorts by the input, while
`<output>` sorts by the field spec's [formatted
value](fields-format.md#value-types), so the value that it sorts by is the same
for every output format.

A value is compared as a string, a non-string being [coerced to a
string](fields-format.md#value-coercion), except that a number is a single
[segment](#sort-segments), between its [trivia](fields-format.md#coercion)
prefix & suffix, each compared as a string (e.g., the trivia prefix `$` in
`$10`):

- A chronologic segment, iff `<chronologic-formats>` includes `<unix-time>` &
  the number is a [representable Unix
  time](fields-format.md#chronologic-formatting).
- Otherwise, a number segment, unless `<number-segments>` is `<lexicographic>`
  or `<versions>`, either of which compares the number as a string, its trivia
  included (so, with `<versions>`, its text's versions compare with other
  versions).

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

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
direction = <ascending> | <descending> (* default: <ascending>; last wins; inherited *)

ascending  = "+"
descending = "-"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Sort Case Sensitivity

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
case-sensitivity = <sensitive> | <insensitive> (* default: <sensitive>; last wins; inherited *)

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
locale = "L" [ <locale-identifier> ] <sort-option-terminator> (* transitive default locale-identifier: <canonical-locale>; last wins; inherited *)

locale-identifier =
  <canonical-locale>
  | <system-locale>
  | {string: ICU or BCP 47 identifier of a locale that Foundation makes available}
  (* default: <system-locale> *)

canonical-locale = 'canonical'
system-locale    = 'system'
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A `<locale-identifier>` of:

- `<canonical-locale>` identifies the canonical conventions.
- `<system-locale>` identifies the system locale.

The canonical conventions compare text per the [CLDR root collation](
  https://www.unicode.org/reports/tr35/tr35-collation.html#Root_Collation
) (the Unicode Collation Algorithm with CLDR's root collation order & settings,
which is independent of every real-world locale), while a locale compares it per
its own collation. Each also sets [`<grouped-numeric>`'s base
conventions](#sort-number-segments).

The canonical conventions' number formatting uses a `.` decimal separator, a `,`
digit group separator, a digit group size of 3 & a secondary digit group size
of 0.

##### Sort Number Segments

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
number-segments = <lexicographic> | <ungrouped-numeric> | <versions> | <grouped-numeric> (* default: <ungrouped-numeric>; last wins; inherited *)

lexicographic     = "x" (* mnemonic: 3rd letter of lexicographic *)
ungrouped-numeric = "u"
versions          = "v"
grouped-numeric   = "N" <grouped-numeric-arguments> <sort-option-terminator> (* default locale-identifier: {<locale>'s <locale-identifier>} *)

grouped-numeric-arguments = <number-format-arguments> <argument-separator>? [ <number-signs> ]

number-signs = <word-initial-signs> | <all-signs> | <no-signs> (* default: <word-initial-signs> *)

word-initial-signs = 'word-initial'
all-signs          = 'all'
no-signs           = 'none'
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

A grouped number is an integer part (a run of ASCII digits, optionally split
into [digit groups](fields-format.md#numberformat) by digit group separators)
and/or a decimal separator preceding a fractional part (a run of ASCII digits),
in that order (e.g., `.5` compares as `0.5`, as a [number
coercion](fields-format.md#coercion) parses it), then optionally an exponent
indicator (`e` or `E`) & an optionally signed integer exponent (e.g., `1.5e3`
compares as `1500`), so it compares as a single number (e.g., `1,234` as `1234`)
rather than being broken into smaller ones by the separator. Its integer part
may have leading `0`s & its fractional part trailing `0`s (e.g., `007.50`
compares as `7.5`). Its group sizes & separators come from its [number format
arguments](fields-format.md#numberformat); a `<digit-group-size>` of `0` allows
groups of any size.

A `<grouped-numeric>` without a `<locale-identifier>` takes the base conventions
of its option set's effective `<locale>`, even if it is inherited (e.g., if `x`
has `name/IN:`, `@x.name/Lde_DE:` compares `1.234` as `1234`).

A `-` or `+` immediately preceding a number segment is its sign:

- `<word-initial-signs>`: iff it starts the value or follows
  [whitespace](ebnf.md#whitespace) (e.g., in `-5` & `a -5`, but not in `a-5`).
- `<all-signs>`: always.
- `<no-signs>`: never.

##### Sort Chronologic Segments

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
chronologic-segments = "C" [ <chronologic-formats> ] <sort-option-terminator> (* transitive default chronologic-formats: 'iso'; last wins; inherited *)

chronologic-formats = <chronologic-format> … <argument-separator>
chronologic-format  = <date-format> | <iso-time>

iso          = 'iso'
iso-date     = 'iso-date'
iso-datetime = 'iso-datetime'
iso-time     = 'iso-time'
unix-time    = 'unix-time'
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The chronologic segments are each longest text that a `<chronologic-format>`
matches, as [`%.c`, `%.d` & `%.:unix-time:d`
detect](fields-format.md#chronologic-formatting) it:

- `<iso-date>`: a representable ISO-8601 date-only.
- `<iso-datetime>`: a representable ISO-8601 datetime.
- `<iso-time>`: an ISO-8601 time-only.
- `<iso>`: a representable ISO-8601 date-only or datetime, or an ISO-8601
  time-only.
- `<unix-time>`: a representable Unix time written as a decimal number.

Text that a `<chronologic-format>` matches is not a chronologic segment iff a
character immediately precedes or follows it that is:

- For `<iso>`, `<iso-date>`, `<iso-datetime>`, or `<iso-time>`: an ASCII digit,
  or, preceding an expanded year's sign, anything but whitespace (e.g.,
  `id-12345-06-07` has no chronologic segment).
- For `<unix-time>`: not whitespace (e.g., `at 1584553163 UTC` has a Unix time
  segment, but `v2`, `1.2.3`, `(1584553163)` & `1584553163,` have none).

Directly absent `<chronologic-formats>` (i.e., `C:`), there are no chronologic
segments.

##### Sort Boundaries

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
boundaries = <uncollapsed-boundaries> | <collapsed-boundaries> (* default: "B+space+:"; last wins; inherited *)

uncollapsed-boundaries = "B" [ <boundary-groups> ] <sort-option-terminator>
collapsed-boundaries   = "M" [ <boundary-groups> ] <sort-option-terminator> (* mnemonic: merged *)

boundary-groups          = <boundary-group> | [ <boundary-group> ] ( <boundary-group-separator> [ <boundary-group> ] )+
boundary-group-separator = "_"

boundary-group      = ( <boundary-characters> | <multi-character-boundary> | <character-class> )+
boundary-characters = {string}

multi-character-boundary       = <multi-character-boundary-fence> <multi-character-boundary-text> <multi-character-boundary-fence>
multi-character-boundary-fence = "%"
multi-character-boundary-text  = {string}

character-class       = <character-class-fence> <character-class-name> <character-class-fence>
character-class-fence = "+"
character-class-name  =
  'alnum'
  | 'alpha'
  | 'ascii'
  | 'blank'
  | 'cntrl'
  | 'digit'
  | 'graph'
  | 'lower'
  | 'print'
  | 'punct'
  | 'space'
  | 'upper'
  | 'word'
  | 'xdigit'
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A value's text outside [typed segments](#sort-segments) is split by
**boundaries** assigned to ordered sort precedence **boundary groups**, each
defined by a `<boundary-group>`; each group's members share the same sort
precedence.

Each of the following is itself a boundary:

- Each character in a `<boundary-characters>`.
- Each `<multi-character-boundary-text>`.
- Each character belonging to the character class named
  `<character-class-name>`, per the POSIX Compatible definitions of [UTS #18
  Annex C](https://www.unicode.org/reports/tr18/#Compatibility_Properties)
  (e.g., `digit` is only `0` to `9`, and `punct` includes every symbol that is
  not alphabetic, such as `$`), with `ascii` being U+0000 to U+007F.

If multiple `<boundary-group>`s define the same boundary, it belongs to the last
group. An empty group defines no boundary, so it affects no other group's sort
precedence (e.g., `B/_:` means what `B/:` means, and `B_:` what `B:` means).

At each position, the longest boundary that matches there is consumed (e.g.,
with `B-%--%:`, `a--b` contains the boundary `--`, rather than 2 `-`s).

Boundaries take sort precedence over all boundaries in all groups succeeding
their group & over all non-boundary characters.

`<uncollapsed-boundaries>` retains a value's contiguous boundaries as separate
boundaries; `<collapsed-boundaries>` collapses contiguous boundaries belonging
to the same boundary group into one. Directly absent `<boundary-groups>` (e.g.,
`B:`), nothing is a boundary.

##### Sort Nonconforming Values

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nonconforming-comparison = <all-conforming> | <nonconforming-least> | <nonconforming-greatest> (* default: <all-conforming>; last wins; inherited *)

all-conforming         = "k" (* mnemonic: keep in place *)
nonconforming-least    = "a" (* mnemonic: 1st letter, so least *)
nonconforming-greatest = "z" (* mnemonic: last letter, so greatest *)

nonconforming-placement = <relative-nonconforming> | <fixed-nonconforming> (* default: <relative-nonconforming>; last wins; inherited *)

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
text-order = <text-first> | <text-last> | <text-in-place> | <text-excluded> (* default: <text-in-place>; last wins; inherited *)

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

[For a variable token to consume text that would otherwise match a literal, 1 or
more of its characters must be escaped by prefixing it with a
`\`.](ebnf.md#tokens)

Throughout all variable tokens, a `\` is written `\\`, because `\` always
escapes the next character.

[Outer bare whitespace is consumed, ignored, or
forbidden](ebnf.md#outer-bare-whitespace-treatment); whitespace must be escaped
to be consumed where bare whitespace is ignored or forbidden.

In each row of the table below, the given characters must be escaped to be
consumed as either the 1st character of, or any character in, a variable token
consumed by the given typed terminal in the given syntactic context. Leading &
trailing outer bare whitespace is consumed, ignored, or forbidden, as given.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Nonterminal                                                                                     | 1st         | Any                         | Leading Whitespace | Trailing Whitespace     |
|:------------------------------------------------------------------------------------------------|:------------|:----------------------------|:-------------------|:------------------------|
| `<field-name>` of the 1st `<absolute-field-spec>`                                               | `@`         | `.` `%` `=` `:` `/` `,`     | ignored            | ignored                 |
| `<field-name>` of a subsequent `<absolute-field-spec>`                                          |             | `.` `%` `=` `:` `/` `,`     | ignored            | ignored                 |
| `<base-fields-config-name>`                                                                     |             |                             | ignored            | ignored                 |
| `<field-name>` in `<field-spec-insertion>`                                                      |             | `@` `.` `%` `=` `:` `/` `,` | ignored            | ignored                 |
| `<field-name>` in `<field-spec-overlay>`                                                        | `+` `_` `-` | `@` `.` `%` `=` `:` `/` `,` | ignored            | ignored                 |
| `<field-name>` in `<field-spec-move>`                                                           |             | `@` `.` `%` `=` `:` `/` `,` | ignored            | ignored                 |
| `<field-name>` in `<field-spec-hide>`                                                           |             | `@` `.` `%` `=` `:` `/` `,` | ignored            | ignored                 |
| `<field-name>` in `<field-spec-removal>`                                                        |             | `@` `.` `,`                 | ignored            | ignored                 |
| `<preset-name>` in a `<preset-modifier>`                                                        |             |                             | ignored            | ignored                 |
| `<label>`                                                                                       |             | `:` `/` `,`                 | ignored            | ignored                 |
| `<locale-identifier>` in `<locale>`                                                             |             | `:`                         | ignored            | ignored                 |
| `<boundary-characters>`                                                                         |             | `%` `+` `_` `:`             | ignored            | ignored                 |
| `<multi-character-boundary-text>`                                                               |             | `%`                         | ignored            | ignored                 |
| `<preset-name>` in a `<format-block>`                                                           |             |                             | forbidden          | ignored                 |
| `<template-text>` starting a `<format-block>`                                                   | `:` `.`     | `%` `/` `,`                 | ignored            | consumed iff before `%` |
| `<template-text>` immediately after a placeholder in a `<format-block>`                         |             | `%` `/` `,`                 | consumed           | consumed iff before `%` |
| `<preset-name>` in a `<success-block>` or a `<failure-block>`                                   |             |                             | forbidden          | ignored                 |
| `<template-text>` starting a `<success-block>` or a `<failure-block>`                           | `:` `.`     | `%` `+`                     | ignored            | consumed iff before `%` |
| `<template-text>` immediately after a placeholder in a `<success-block>` or a `<failure-block>` |             | `%` `+`                     | consumed           | consumed iff before `%` |
| `<decimal-separator>` in `<number-format>`                                                      |             | `:`                         | ignored            | ignored                 |
| `<time-zone-code>` in `<date-time-zone-arguments>`                                              |             | `:`                         | ignored            | ignored                 |
| `<reference-date>`                                                                              |             |                             | ignored            | ignored                 |
| `<trivia-suffix-regex>`                                                                         |             | `:`                         | ignored            | ignored                 |
| Any other argument                                                                              |             | `,` `:`                     | ignored            | ignored                 |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Whitespace-only `<template-text>` immediately after a placeholder is consumed
iff before `%` (e.g., `%i %l` retains its space).

A bare `.` in a field name is invalid, reserving it for future syntax; an
escaped `.` is consumed (e.g., `a\.b` names the field `a.b`).

A preset's `<label>` & `<template-text>` need not escape `,`, because a preset's
syntax has no `<field-spec-separator>` (e.g., a preset of `=a,b` sets the label
`a,b`).

No [config name](configs.md#named-configs) or `<reference-date>` can contain a
character that must be escaped to be consumed, so their rows list none (e.g.,
`@x\.y` is an error, because no config can be named `x.y`).
