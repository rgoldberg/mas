# To-Do

## Current Version

### Unordered `<*-modifiers>`?

### `<base-fields-config-order>`

Does `<base-fields-config-order>`:

1. Order as the base fields config would render them?
   1. Apply inherited `<original-input-order>`?
   2. Apply inherited `<sort-option-set>`?
2. Or use the inherited field specs' listed order?
   1. "ordered as in the base fields config." →
      1. "ordered as the base fields config lists its field specs."
      2. "ordered as the base fields config's field specs listed order."
      3. "ordered as the base fields config's field specs are listed."
   2. Ignores inherited `<original-input-order>`.
   3. Ignores inherited `<sort-option-set>`.

Reversed iff `<descending>`.

Then modified by `<field-spec-edits-section>`.

#### Move, Insert, Remove Sorted Field Specs

`<field-spec-edits-section>`:

1. Should `<field-spec-overlay>` be the only supported field spec action?
2. Should `<field-spec-removal>` also be supported?
3. What about `<field-spec-insertion>` & `<field-spec-move>`
   1. Insert:
      1. Forbid?
      2. Where?
      3. Always prepend?
      4. Always append?
      5. Optionally prepend or append?
   2. Move: any purpose?
      1. Forbid?

Rewrite field spec indices to reference positions based on field spec listed
order? Or, better, specify that sorting fields of the same value retains their
existing relative order. What if sorted by label instead of name, so their
relative order changes because of different labels?

Under any field order other than `<base-fields-config-order>`, a move is an
order no-op (functionally an overlay); that either requires stating or
restricting.

Under `o` or a sort, `<field-spec-edits-section>` still decides which specs
exist & their modifiers; the output order is evaluated for all of them uniformly
at output time (from input key order, or by sorting names / labels), so
positions are moot & a move degenerates to an overlay. Only under `w` do
positions render; `w` is the base's listed order, known before any input is
read, so an insert "after X" is always placeable. No forbidding needed.

#### `<direction>`

Should `<base-fields-config-order>` allow `<direction>`?

If so, should it reverse only the order from the base fields config, not
subsequent edits from `<field-spec-edits-section>`?

### `(* last wins *)`

[`ebnf.md`](../Specs/ebnf.md) defines `(* last wins *)` as "the last occurrence
of any alternative overrides all preceding occurrences of any alternative",
which describes a comment attached to an innermost choice (e.g., `<direction>`),
but the comments sit on the option _sets_ (`<sort-option-set>` etc.), which
would make `Iad` collapse to `d`. Either move the comments to the innermost
choices or restore the per-alternative formulation.

### Bad Letters

- `r`: `<disable-all-sorts>`
- `w`: `<base-fields-config-order>`

### Update Shell Completions

Probably only complete the options themselves; option value completion not
available, but ensure that completions know if option values are required or
optional.

### Documentation

1. Link to specs
2. Getting Started / Overview
3. Manual accompanying specs
4. Examples

## ASAP Version, But Massive Effort

### Persisted Named Formats & Custom Named Configs

## Later Versions

### Radix `%n` modifier

e.g., `%16n`.

### Meaningful Number Units

e.g., SI prefixes

Cross-unit conversion.

### `<input-chronologic-format>` & `<output-chronologic-format>`

`<input-chronologic-format>` & named or literal `<output-chronologic-format>`
(requires a pattern syntax & persisted named formats). Removed partial spec:

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
chronologic-success-block =
  <input-chronologic-format> … <chronologic-input-format-separator> <chronologic-input-output-separator> [ <output-chronologic-format> ]
  | <output-chronologic-format>
input-chronologic-format  = <chronologic-format>
output-chronologic-format = <chronologic-format> (* default: ISO-8601 datetime in local time zone *)

chronologic-format        = <chronologic-pipeline> | <inline-chronologic-format>
inline-chronologic-format = {text}

chronologic-input-format-separator = ","
chronologic-input-output-separator = "_"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A custom `<input-chronologic-format>` & an `<output-chronologic-format>` that is
not a bare `<chronologic-transform-pipeline>` (i.e., a named-format reference,
or literal pattern text) are not implemented yet; using either is a parse error,
rather than silently falling back to the defaults:

- `<input-chronologic-format>` requires a defined pattern syntax for
  `<inline-chronologic-format>`, which does not exist yet.
- A named `<output-chronologic-format>` requires persisted named formats; a
  literal one requires the same pattern syntax `<input-chronologic-format>`
  does.

Escaping appendix rows: `<format-name>` in a `<block>` also ended by `,` & `_`;
`<inline-chronologic-format>`: 1st `:` `.`, any `+` `,` `_`, whitespace
insignificant.

### Configurable Boundary Collapsing

- Same boundary
- Same group
- All

### Configurable Absent Value Handling

Configurable behavior per output format:

- `error`: Report an error for absent values.
- `omit`: Omit output for absent values.
- `emit`: Output a configurable default value for absent values.

### Heterogeneous Pipeline Types & Coercion Anywhere

### `<original-input-order>` for `@table`

### Nested Objects & Arrays

### `<base-table-config-name>`

Allow `--table`'s value to select a named table config other than the context
stack's `default`.
