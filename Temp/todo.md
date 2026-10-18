# To-Do

## Current Version

### Documentation

1. Update `README.md`
2. Getting Started / Overview
3. Manual accompanying specs
4. Examples

## ASAP Version, But Massive Effort

### Persisted Custom Named Formats & Configs

1. Custom named formats: every reference to one reports `unknownNamedFormat`.
2. [Custom named configs](../Specs/configs.md#custom-named-configs) of every
   kind:
   1. Looking a name up through the [context
      stack](../Specs/configs.md#referencing-named-configs). Lookup order is
      undefined: whether [suffix substitution](
        ../Specs/fields.md#output-format-specific-named-fields-configs
      ), the context-stack search, or [`default` →
      `standard`](../Specs/configs.md#default-configs) applies 1st.
      1. `x@table` in `mas` & `x` in `mas.list`: which one
         `mas list --fields @x` uses.
   2. Resolving a config that extends its same-named ancestor.
   3. Reporting reference cycles.
   4. A custom `default` (currently always `standard`).
   5. Custom [variants](../Specs/fields.md#named-fields-configs).
3. Inherited `--table` / `--key-value` / `--json` settings: they currently apply
   only on top of `standard`, so implied
   [table](../Specs/table.md#implied-settings) &
   [key-value](../Specs/key-value.md#implied-settings) settings' precedence over
   inherited ones has no effect yet.
4. Per-context custom default formats.

#### Custom Names Removal

If an initial version is released before persistence is supported, then remove
persistence-based functionality from specs & code:

1. Possibly vestigial after `1226-fields-no-custom-names` removes named formats
   & custom configs; decide whether to remove each in
   `1226-fields-no-custom-names`:
   1. [`<string-pipeline>` &
      `<unconditional-pipeline>`](../Specs/fields-format.md#pipelines): each is
      only an alias of a single `<*-transform-pipeline>`.
   2. The [`default` fields config](../Specs/fields.md#default-fields-configs):
      always `standard`; removing it also requires editing the [default
      configs](../Specs/configs.md#default-configs).
   3. [`mas`'s context stacks](../Specs/mas.md#context-stacks): used only by
      custom config lookup, but the [context stacks
      definition](../Specs/configs.md#context-stacks) links to it as its
      example.
   4. "Immutable" in ["Immutable Built-In Named Fields
      Configs"](../Specs/fields.md#immutable-built-in-named-fields-configs) &
      possibly in ["Immutable Built-In Named
      Configs"](../Specs/configs.md#immutable-built-in-named-configs).

## Later Versions

### `numberFormat` Number Templates

Number templates for `numberFormat` (e.g., [UTS #35 number
patterns](https://www.unicode.org/reports/tr35/tr35-numbers.html)).

1. They would cover group sizes, fraction digits & scientific notation, as an
   alternative argument form, distinguished from `<number-format-arguments>`
   (which would remain valid) by a leading character that no locale identifier
   can contain.
2. They overlap `round` & `scale`'s fraction digits, and are base 10 only.
3. They would also select an output notation (positional, `e`, or `E`), which is
   not supported: every number transform retains its input's notation, except
   `scale`, which always renders positional notation.

### Radix `%n` Modifier

E.g., `%16n`.

### Meaningful Number Units

E.g., SI prefixes.

Cross-unit conversion.

### Chronologic Coercion & Output Formats

Mirror number coercion: chronologic coercion takes fenced arguments giving the
input format (e.g., `%.:yyyy-MM-dd:c`, `..:yyyy-MM-dd:timeZone:UTC:`), with
[UTS #35 date format patterns](
  https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
) as the pattern syntax. It would also cover the ISO-8601 representations that
auto-detection omits (e.g., week dates).

A named or literal output format (e.g., a chronologic-to-string transform
mirroring `numberFormat`) needs the same pattern syntax & persisted named
formats.

[`<chronologic-formats>`](../Specs/fields.md#sort-chronologic-segments) can then
take custom formats (e.g., `yyyy-MM-dd`).

### Boolean Coercion Options

Coercion arguments for boolean coercion, e.g.:

- Case: uppercase, lowercase, consistent case, or case-insensitive.
- `0` & non-`0` numbers.

### Heterogeneous Pipeline Types & Coercion Anywhere

Let a pipeline mix value types, requiring only that each transform's input type
accept its predecessor's output type (e.g., a transform that takes any input &
outputs a number may precede one whose input type is number or any). Allow
`<coercion>` before any transform call. Each makes only currently invalid
formats valid.

### Structured Value Operations

1. Nested field references via the `.` [reserved in field
   names](../Specs/fields.md#appendix-escaping) (e.g., `a.b` for member `b` of
   field `a`'s object, `a.0` for element `0` of field `a`'s array).
2. Array & object type predicates.
3. Array & object transforms.

### Configurable Absent Value Handling

Configurable behavior per output format:

- `error`: Report an error for absent values.
- `omit`: Omit output for absent values.
- `emit`: Output a configurable default value for absent values.

### Configurable Unix Time Segment Neighbors

Let a [`<unix-time>`](../Specs/fields.md#sort-chronologic-segments) sort segment
be adjacent to configurable characters other than whitespace (e.g., brackets:
Unicode `Ps` & `Pe`), separately from sort boundaries.

### Configurable Boundary Collapsing

- Same boundary
- Same group
- All

### `<document-order>` for `@table`

Let `<document-order>` order a table's columns by the 1st item's document order
(e.g., the key order of the 1st input JSON object), since rows otherwise share
no document order; every later item's fields would follow the 1st item's order,
with fields that the 1st item lacks after the others, in position order.

### Base Output Config Names

Let `--table`'s, `--key-value`'s & `--json`'s values each select a named config
of its kind other than the context stack's `default` (e.g., via a
`<base-table-config-name>`), which a persisted config of that kind would then
[extend](../Specs/configs.md#referencing-named-configs).
