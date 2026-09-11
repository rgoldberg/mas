# Field-Selection Option

Uses the custom EBNF grammar defined in [ebnf.md](ebnf.md).

## Commands

A **command** corresponds to a Swift Argument Parser `ParseableCommand`.

## Display Commands

A **display command** is a command whose primary function is to display data.

`mas` display commands are:

- `config`
- `list`
- `lookup`
- `outdated`
- `search`

## Output Formats

Display commands support multiple **output format**s:

- **Table**: Row per item (normally an app), column per field.
- **Key-Value**: Key-value pair on its own row per field, blank line between
  items.
- **JSON**: JSON object per item, key-value pair per field.

Output configuration is universal across output formats unless otherwise
specified.

The default output format of each display command is:

| Command    | Format    |
|:-----------|:----------|
| `config`   | key-value |
| `list`     | table     |
| `lookup`   | key-value |
| `outdated` | table     |
| `search`   | table     |

## Command Lists

A **command list** is the list of commands in the command line from root to
leaf; the leaf is the command that actually runs.

## Contexts

A **context** can contain named configurations.

A context exists for each command in a command list.

The name of each context is a `.`-delimited concatenation of all the commands
from the root through the current command.

## Context Stacks

A **context stack** is the contexts for the commands of a command list in
reverse order, i.e., ordered from the most specific (leaf) to the least specific
(root) context:

| Command List   | Most Specific Context | Least Specific Context |
|:---------------|:----------------------|:-----------------------|
| `mas config`   | `mas.config`          | `mas`                  |
| `mas list`     | `mas.list`            | `mas`                  |
| `mas lookup`   | `mas.lookup`          | `mas`                  |
| `mas outdated` | `mas.outdated`        | `mas`                  |
| `mas search`   | `mas.search`          | `mas`                  |

## Positions & Indices

List elements are located at 1-based integer positions.

Positions are referenced via integer indices. Each index has an effective index,
computed as follows:

- If non-negative $index$: $index$.
- If negative $index$: $length + 1 + index$ (where $length$ is the list's
  length).

Index `0` represents a pseudo-position that precedes all list elements.

Accessing an invalid position causes an error to be reported. Invalid positions
are:

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

## Fields Configs

A **fields config** specifies which fields are included in the output, along
with other output configuration.

A fields config may include:

- Rules that apply to all fields
- Field-specific field specs

### Named Fields Configs

A **named fields config** has been persisted with a case-sensitive name that is
unique for a context.

Fields config names must not contain characters that do not match the regex
`[-_0-9A-Za-z]`.

#### Output-Format-Specific Named Fields Configs

A fields config's name may include an optional output format suffix matching the
regex `@(json|key-value|table)$`; if the current output format matches the
suffix, the fields config with the suffixed name is substituted for any
unsuffixed reference to the unsuffixed name.

An additional suffix matching the regex `@none$` may be appended to a reference
to a fields config name (not to a name itself), which resolves to the fields
config with the unsuffixed name, regardless of the current output format.

Fields configs that share the same unsuffixed name within the same context, but
that have different suffixes, are known as output format variants.

#### Referencing Named Fields Configs

A named fields config may be referenced:

- On the command line
- By other persisted fields configs

A named fields config is found by returning the first fields config found with a
given name while iterating through the context stack from most to least specific
context; if no match is found, an error is reported.

#### Immutable Built-In Named Fields Configs

Global:

- `none`: Includes no fields; uses the global defaults for all rules; has no
  output format variants.

For each [leaf context](#context-stacks):

- `all`: Includes all fields. Absent a user-requested field order, fields are
  sorted by label, per the [Default Sort Options](#default-sort-options)
  table's `Text` row for the current output format.
- `standard`: Includes a select list of fields.

Output format variants may exist for `all` and/or `standard`. If an output
format variant does not exist for any built-in field config, it may not be
defined by a user.

`standard@json` is always a reference to `all`.

#### Custom Named Fields Configs

Users may define & persist named fields configs.

All fields configs are ultimately derived transitively from `none` or a
contextual `all`.

#### Default Fields Configs

If no custom fields config is named `default` in a leaf context, `standard` is
substituted.

If a nonexistent `default` was referenced with an output format suffix, that
suffix is appended to `standard`.

### Base Fields Config

The resolved fields config is computed from a **base fields config**: a named
fields config referenced in, or implicitly selected by, a command line.

### Baseline Fields Config

The **baseline fields config** is an immutable snapshot of the working fields
config immediately before the current section.

### Working Fields Config

The **working fields config** is the current state of the fields config as it is
being modified.

### Resolved Fields Config

The **resolved fields config** is used to generate output.

## Semantically Significant Characters

**Semantically significant character**s are:

- Non-whitespace
- Escaped whitespace
- Bare whitespace between the first significant character & the last significant
  character in a token

## Semantically Insignificant Characters

**Semantically insignificant character**s are:

- Bare whitespace before the first significant character in a token
- Bare whitespace after the last significant character in a token

## Defaults for Absent Tokens

The following is inserted before all other cases in the
[absent token value algorithm](ebnf.md#defaults-for-absent-tokens):

- The value for the given `TOKEN` token in the working fields config.

## Nonexistent Fields

**Nonexistent fields** are guaranteed to not exist in any input, which is
determinable only for formats that specify all potential input fields up front,
e.g.: CSV, or JSON with a JSON schema.

Other formats cannot guarantee field nonexistence, e.g.: JSON without a JSON
schema, for which a field may exist for some JSON objects, but not exist for
others.

A reference to a nonexistent field is an error.

## Absent Values

### Initial Version

- **Table**: A column is output for each field spec regardless of whether a
  value exists for a given item (absent values are output as empty strings).
- **Key-Value**: A key-value pair is output for the field label & value iff a
  non-null value exists.
- **JSON**: A key-value pair is output for the field label & value iff a value
  exists (which could be any value; e.g., for JSON input, `null`, `true`,
  `false`, `0`, `1`, `""`, `"null"`, etc. are all values).

### Future Versions

Configurable behavior per output format:

- `error`: Report an error for absent values.
- `omit`: Omit output for absent values.
- `emit`: Output a configurable default value for absent values.

## Fields Option

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
fields-option = "--fields" {whitespace} <fields-config>
fields-config = <absolute-config> | <relative-config> (* default: <relative-config> *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The resolved fields config is:

- If `<fields-option>` is absent: `default` for the current context.
- If `<absolute-config>` is present: sourced solely from `<absolute-config>`;
  this is the equivalent of the baseline fields config being `none`.
- If `<relative-config>` is present: sourced from the base fields config as
  modified by `<relative-config>`.

`<absolute-config>` & `<relative-config>` are overlaid on top of the base fields
config for the current command line only; they do not persistently affect named
fields configs.

### Absolute Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
absolute-config = <first-absolute-field-spec> [ ( <field-spec-separator> <subsequent-absolute-field-spec> )+ ]

first-absolute-field-spec = <first-absolute-field-name> <field-modifiers>
first-absolute-field-name = <subsequent-absolute-field-name\[:<base-fields-config-section-prefix>:][:<field-order-section-prefix>:][:<item-sort-section-prefix>:][:<field-specs-section-prefix>:]>

subsequent-absolute-field-spec = <subsequent-absolute-field-name> <field-modifiers>
subsequent-absolute-field-name = {text\\[:<label-modifier-prefix>:][:<format-modifier-prefix>:][:<sort-modifier-prefix>:][:<field-spec-separator>:]}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Each field spec in an `<absolute-config>` appends a new output for its field.

### Relative Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
relative-config = [ <base-fields-config-section> ] [ <field-order-section> ] [ <item-sort-section> ] [ <field-specs-section> ]
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- Computes the resolved fields config from the base fields config as adjusted by
  the command line.

#### Base Fields Config Selection

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
base-fields-config-section        = <base-fields-config-section-prefix> <base-fields-config-name>
base-fields-config-section-prefix = "@"

base-fields-config-name = {text\\[:<field-order-section-prefix>:][:<item-sort-section-prefix>:][:<field-specs-section-prefix>:]} (* default: "default" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- If no fields config named `<base-fields-config-name>` exists in any context in
  the context stack, an error is reported.

#### Field Ordering

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-order-section        = <field-order-section-prefix> [ <field-order-option-set> ] (* default: inherited field order *)
field-order-section-prefix = "/"

field-order-option-set = <original-order-option-set> | <sort-option-set>

original-order-option-set = [ <original-order-option>+ ] <original-order> [ <original-order-option>+ ]
original-order-option     = <original-order> | <direction>

original-order = "o" (* supported only for key-value & JSON, not for table *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Fields are ordered:

- If `<field-order-section>` is:
  - **Absent**: per inherited field order.
  - **Present**: if `<field-order-option-set>` is:
    - **Absent**: per order in working fields config; i.e., field order from the
      base fields config as modified by `<field-specs-section>`.
    - **Present**, if `<original-order-option-set>` is:
      - **Absent**, `<sort-option-set>` is guaranteed present; if `<source>` is:
        - `<input>`, by sorting by name.
        - `<output>`, by sorting by label.
      - **Present**, per original order, e.g., the ordering of keys in a JSON
        object.

#### Item Sorting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
item-sort-section        = <item-sort-section-prefix> [ <item-sort-option-set> ] (* default: inherited item sorting *)
item-sort-section-prefix = "//"

item-sort-option-set = <item-sort-option>+
item-sort-option     = <reset> | <direction>

reset = <reset-to-contextual> | <reset-to-global>

reset-to-contextual = "r"
reset-to-global     = "R"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<reset-to-contextual>` resets all inherited sort options to the contextual
defaults for the active output format from
[Default Sort Options](#default-sort-options) (not to the defaults from the base
fields config or global defaults).

`<reset-to-global>` resets all inherited sort options to the global defaults
(not to the defaults from the base fields config or
[Default Sort Options](#default-sort-options)).

`<ascending>` tiebreaks item sorting by input order, `<descending>` by reverse
input order.

#### Field Spec References

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
field-spec-reference         = <named-field-spec-reference> | <indexed-field-spec-reference>
named-field-spec-reference   = <reference-field-name> [ <index-prefix> <index> ] (* default index: "1" *)
indexed-field-spec-reference = <index-prefix> <index>

reference-field-name = {text\\[:<index-prefix>:][:<label-modifier-prefix>:][:<format-modifier-prefix>:][:<sort-modifier-prefix>:][:<field-spec-separator>:]}

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

While the position of a field spec in the reference fields config cannot be
modified:

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
field-specs-section        = <field-specs-section-prefix> [ <field-spec> … <field-spec-separator> ]
field-specs-section-prefix = "."

field-spec = <insert-field-spec> | <sourced-field-spec>

insert-field-spec = <insert> <insert-field-name> <field-modifiers>

sourced-field-spec = <overlay-field-spec> | <move-field-spec> | <remove-field-spec>

overlay-field-spec = <field-spec-reference\[:<insert>:][:<move>:][:<remove>:]> <field-modifiers>
move-field-spec    = <move> <field-spec-reference> <field-modifiers>
remove-field-spec  = <remove> <field-spec-reference>

insert = "+"
move   = "%"
remove = "-"

insert-field-name = {text\\[:<label-modifier-prefix>:][:<format-modifier-prefix>:][:<sort-modifier-prefix>:][:<field-spec-separator>:]}

field-spec-separator = ","
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

For a given `<sourced-field-spec>` `fs`, its `source` is the field spec from the
reference fields config referenced by `fs` (this prevents field specs that were
inserted in a section from being modified by other field specs in the same
section).

The $previous$ index is the index in the working fields config where the direct
results of the immediately preceding field spec were effected. It is initially
set to `0` (i.e., before the first field spec in the working fields config).

Field specs perform actions as follows:

- `<insert-field-spec>`:
  - Inserts a new field spec immediately after $previous$.
  - Sets $previous$ to the new field spec's index in the working fields config.
- `<overlay-field-spec>`:
  - Overlays its field modifiers onto `source`.
  - Sets $previous$ to `source`'s index in the working fields config.
- `<move-field-spec>`:
  - Moves `source` to immediately after $previous$.
  - Sets $previous$ to `source`'s new index in the working fields config.
- `<remove-field-spec>`:
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
label-modifier        = <label-modifier-prefix> [ <label> ] (* transitive default label: {field name from the containing field-spec} *)
label-modifier-prefix = "="
label                 = {text\\[:<format-modifier-prefix>:][:<sort-modifier-prefix>:][:<field-spec-separator>:]} (* default: "" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A field spec's `<label>` is its:
  - Header for table.
  - Key for key-value & JSON.

#### Formatting

[This section will be replaced by the contents of
`fields-formatting.md`](fields-formatting.md).

#### Sorting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-modifier        = <sort-modifier-prefix> [ <sort> ] (* default: clears inherited field sorting *)
sort-modifier-prefix = "/"
sort                 = <sort-priority> [ <sort-option-set> ] | <sort-option-set>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A `<sort-modifier>` without a `<sort>` (`/`) clears inherited sorting for the
  field.
- A field without an effective `<sort>` does not affect row sorting.

##### Sort Priority

```ebnf
sort-priority = {non-negative 64-bit integer}
```

A field with an effective `<sort>`:

- Requires a non-`null` effective `<sort-priority>`, otherwise an error is
  reported.
- Takes sort precedence over fields:
  - With a numerically higher `<sort-priority>` (i.e., lower numbers have higher
    priority).
  - Succeeding it with the same `<sort-priority>`.

##### Sort Options

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
sort-option-set = <sort-option>+
sort-option     = <source> | <direction> | <case-sensitivity> | <localization> | <grouping> | <interpretation> | <boundaries>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- Each sort option of the same type (e.g., each `<source>` value) is
  functionally mutually exclusive with all other values of the same type.
- If multiple sort options of the same type are present (e.g., `<ascending>` &
  `<descending>`), the last overrides the preceding.

##### Sort Source

```ebnf
source = <input> | <output> (* default: <input> *)
input  = "I"
output = "O"
```

If an input value is modified by a format for output, `<input>` sorts based on
the input, not the output. `<output>` is the opposite.

e.g., for an input timestamp being output as an ISO date (without time):

- `<input>` sorts by the input timestamp.
- `<output>` sorts by the output ISO date (without time).

##### Sort Direction

```ebnf
direction  = <ascending> | <descending> (* default: <ascending> *)
ascending  = "a"
descending = "d"
```

##### Sort Case Sensitivity

```ebnf
case-sensitivity = <sensitive> | <insensitive> (* default: <sensitive> *)
sensitive        = "s"
insensitive      = "i"
```

##### Sort Localization

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
localization = <canonical> | <localized> (* default: <canonical> *)
canonical    = "c"
localized    = <localized-prefix> [ <locale-name-fence> [ <locale-name> ] <locale-name-fence> ]

localized-prefix = "l"

locale-name-fence = "+"
locale-name       = {text\\[:<locale-name-fence>:]} (* default: {system default locale name} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<canonical>` uses a locale-independent comparison, while `<localized>` uses a
locale-dependent comparison. This also affects numeric fractional part & integer
grouping separators.

##### Sort Grouping

```ebnf
grouping  = <ungrouped> | <grouped> (* default: <ungrouped> *)
ungrouped = "u"
grouped   = "g"
```

##### Sort Interpretation

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
interpretation = <lexical> | <numeric> | <price> | <version> (* default: <lexical> *)
lexical        = "x"
numeric        = "n"
price          = "p"
version        = "v"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Sort Boundaries

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
boundaries        = <boundaries-prefix> [ <boundaries-option-set> ] ( <grouped-boundaries> | <ungrouped-boundaries> ) (* default: "b+_+" *)
boundaries-prefix = "b"

boundaries-option-set = <boundaries-option>+
boundaries-option     = <collapse-contiguous>

collapse-contiguous = "%"

whitespace-boundary-modifier = <grouped-whitespace-boundary-modifier> | <ungrouped-whitespace-boundary-modifier>

grouped-boundaries                     = "+" ( ( <grouped-whitespace-boundary-suppressor> | <grouped-whitespace-boundary-modifier> ) [ <grouped-boundaries-list> ] | [ <grouped-whitespace-boundary-modifier> ] <grouped-boundaries-list> [ <grouped-whitespace-boundary-modifier> ] ) "+"
grouped-whitespace-boundary-suppressor = "+"
grouped-whitespace-boundary-modifier   = "_"
grouped-boundaries-list                = <boundary-list> … <group-separator>
group-separator                        = "_"

ungrouped-boundaries                     = "_" ( ( <ungrouped-whitespace-boundary-suppressor> | <ungrouped-whitespace-boundary-modifier> ) [ <ungrouped-boundaries-list> ] | [ <ungrouped-whitespace-boundary-modifier> ] <ungrouped-boundaries-list> [ <ungrouped-whitespace-boundary-modifier> ] ) "_"
ungrouped-whitespace-boundary-suppressor = "_"
ungrouped-whitespace-boundary-modifier   = "+"
ungrouped-boundaries-list                = <boundary-list> … <group-joiner>
group-joiner                             = "+"

boundary-list       = <boundary-characters> | <multi-character-boundary> | <character-class>
boundary-characters = {text\\[:<character-class-fence>:][:<multi-character-boundary-fence>:]+_}

multi-character-boundary       = <multi-character-boundary-fence> <multi-character-boundary-text> <multi-character-boundary-fence>
multi-character-boundary-fence = "%"
multi-character-boundary-text  = {text\\[:<multi-character-boundary-fence>:]}

character-class       = <character-class-fence> <character-class-name> <character-class-fence>
character-class-fence = ":"
character-class-name  = "alnum" | "alpha" | "ascii" | "blank" | "cntrl" | "digit" | "graph" | "lower" | "print" | "punct" | "space" | "upper" | "word" | "xdigit"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Input is tokenized by **boundaries** assigned to ordered sort precedence
**boundary groups**; each group's members share the same sort precedence.

Boundaries & boundary groups are either **explicit** or **implicit**.

Explicit boundaries are defined in `<boundary-list>`s:

- Each character in a `<boundary-characters>` is itself an explicit boundary.
- Each `<multi-character-boundary-text>` is itself an explicit boundary.
- Each character belonging to a GNU Extended POSIX character class named
  `<character-class-name>` is itself an explicit boundary.

The last occurrence of an explicit boundary for a value across all
`<boundary-list>`s overrides all other boundaries (explicit or implicit) for the
same value.

Boundaries take sort precedence over all boundaries in all groups succeeding
their group & over all non-boundary characters.

Explicit groups are specified in `<boundaries>`:

- In `<grouped-boundaries>`, all boundaries within a `<boundary-list>` belong to
  a single group.
- In `<ungrouped-boundaries>`:
  - By default:
    - All boundaries from a single `<character-class>` belong to a single group.
    - Each other boundary belongs to its own group.
  - A `<group-joiner>` merges the immediately succeeding group into the
    immediately preceding group.

By default, all whitespace characters are assigned to an implicit endmost group;
`<grouped-whitespace-boundary-suppressor>` &
`<ungrouped-whitespace-boundary-suppressor>` suppress it.

- A **trailing** `<whitespace-boundary-modifier>` (without a leading one)
  includes in the **last** explicit group all whitespace characters for which no
  explicit boundaries are present.
- A **solitary** or a **leading** `<whitespace-boundary-modifier>` (without a
  trailing one) positions the whitespace implicit group **before** all explicit
  groups.
- Both a **leading & trailing** `<whitespace-boundary-modifier>` include in the
  **first** explicit group all whitespace characters for which no explicit
  boundaries are present.

By default, contiguous boundaries in input are preserved as separate characters.
`<collapse-contiguous>` collapses contiguous boundaries belonging to the same
boundary group into one.

##### Default Sort Options

| Format    | Type    | Default       |
|:----------|:--------|:--------------|
| Table     | Text    | `Iailgnb+_+`  |
| Table     | Price   | `Iailgpb+_+`  |
| Table     | Version | `Iailuvb+_+`  |
| Table     | Path    | `Iailgnb+/+`  |
| Key-Value | Text    | `Iailgnb+_+`  |
| Key-Value | Price   | `Iailgpb+_+`  |
| Key-Value | Version | `Iailuvb+_+`  |
| Key-Value | Path    | `Iailgnb+/+`  |
| JSON      | Text    | `Iascgnb+++`  |
| JSON      | Price   | `Iascgpb+++`  |
| JSON      | Version | `Iascuvb+++`  |
| JSON      | Path    | `Iascgnb++/+` |

JSON suppresses the implicit whitespace boundary entirely (`+++` /
`++/+`'s leading `+` after the fence) rather than defaulting it (`+_+` /
`+/+`), matching its already-more-literal case-sensitive / canonical
choices on the other axes: Table / Key-Value are read by people, so
whitespace sorting like a low-precedence separator is the friendlier
default; JSON is read by programs, so nothing gets special-cased. Path
keeps its `/` boundary either way — the suppression only concerns
whitespace.
