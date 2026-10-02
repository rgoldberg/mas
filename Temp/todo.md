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
order no-op (functionally an overlay); that either needs stating or restricting.

Under `o` or a sort, `<field-spec-edits-section>` still decides which specs
exist & their modifiers; the output order is calculated for all of them
uniformly at output time (from input key order, or by sorting names / labels),
so positions are moot & a move degenerates to an overlay. Only under `w` do
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
choices or restore the per-alternative formulation. Non-choice instances:
`table-config = [ <table-setting>+ ]` ([`table.md`](../Specs/table.md); the
literal reading makes `hS` a header on, contradicting Implied Settings),
`key-value-config = <key-value-setting>+`
([`key-value.md`](../Specs/key-value.md)), `json-config = <json-setting>+`
([`json.md`](../Specs/json.md)) & `format-transform-pipeline = ( … )+`
([`fields-format.md`](../Specs/fields-format.md)).

### Bad Letters

- `r`: `<disable-all-sorts>`
- `w`: `<base-fields-config-order>`

### Documentation

1. Update `README.md`
2. Getting Started / Overview
3. Manual accompanying specs
4. Examples

### Implementation Questions (2026-09-18)

- Todo comments:
  - New: `TODO:` per CLAUDE.md with `// swiftlint:disable:next todo`.
- `<output>` sort source compares values by "the rendered value type": is that
  the type of the rendered JSON node (only `%i` passthrough retains a non-string
  type), or the output type of the format's final pipeline / placeholder (e.g.,
  chronologic for `%C.dateOnly++`)?

- Values that conform to no `<sort-option-set>` "retain their input order":
  implemented as comparing equal for that sort key, so a lower-priority sort key
  may still order them; should they instead be ordered by input order
  immediately?
- mas.md says version fields' default formats use `%v`: implemented as `%V+%i+`,
  so a nonconforming value still renders as is instead of aborting to an empty
  string. Is that intended?

- `<nullary-chronologic>`'s value is an "ISO date / datetime / time, per input",
  but "Chronologic Formatting"'s auto-detection tries only ISO-8601 datetime,
  ISO-8601 date-only & Unix epoch, so time-only input (e.g., `12:30:00`) isn't
  chronologic (implemented as such). Should time-only input be detected, or
  should "/ time" be removed?
- Chronologic auto-detection accepts a string of a decimal number (e.g., `"0"`)
  as a Unix epoch timestamp, unlike `%n`, which requires a JSON number absent
  `<coercion>`. Should only a JSON number be a "numeric timestamp"?

### Spec Review Session Open Issues (2026-09-27)

1. Extra sort option sets have no type ([fields.md](../Specs/fields.md),
   Sorting): each later set sorts values that conform to none of the preceding
   sets' types, but a set has no type of its own.
   1. `price:%.n/1n/Ii`: which values the 2nd set sorts, and as which type.
2. Starting values for a new field spec are undefined
   ([fields.md](../Specs/fields.md), Relative Field Specs): "a field spec with
   default settings" is never defined.
   1. `--fields .+size` when `size` isn't in the base fields config: its label,
      format & sort.
3. How far `{integer}` extends ([ebnf.md](../Specs/ebnf.md), Consuming Tokens):
   only text & syntax tokens are defined, not scalar descriptions.
   1. `--table H1a:`
   2. `@+1`
4. Sequences have no section ([ebnf.md](../Specs/ebnf.md)): they appear only in
   Precedence, so a sequence's value is undefined.
   1. The value of `sort = [ <sort-priority> ] <sort-option-set>`.
5. JSON output types are undefined: the type-preserving passthrough for `%i` is
   mentioned but not defined, and it conflicts with `"" if null`.
   1. Whether `%i` on `null` outputs `null` or `""`.
6. No comparison is defined for fields typed "any"
   ([fields.md](../Specs/fields.md), Sort Source).
   1. `name:%i/1`
7. Lookup order is undefined ([configs.md](../Specs/configs.md) &
   [fields.md](../Specs/fields.md)): whether suffix substitution, the
   context-stack search, or `default` → `standard` applies 1st.
   1. `x@table` in `mas` & `x` in `mas.list`: which one `mas list --fields @x`
      uses.
8. Deferred: whether to remove `{text: field name}` &
   `{text: fields config name}` ([fields.md](../Specs/fields.md)).
9. Deferred: number templates for `numberFormat` (e.g., [UTS #35 number
   patterns](https://www.unicode.org/reports/tr35/tr35-numbers.html)).
   1. They would cover group sizes, fraction digits & scientific notation,
      leaving only the locale & symbol overrides as arguments.
   2. They overlap `round` & `scale`'s fraction digits, and are base 10 only.
10. Selecting an output notation (positional, `e`, or `E`) isn't supported:
    every number transform retains its input's notation, except `scale`, which
    always renders positional notation.

### Custom Names Removal Session Open Issues (2026-10-01)

1. Possibly vestigial after `1226-fields-no-custom-names` removes named formats
   & custom configs; decide whether to remove each in
   `1226-fields-no-custom-names`:
   1. `<string-pipeline>` & `<unconditional-pipeline>`
      ([fields-format.md](../Specs/fields-format.md), Pipelines): each is only
      an alias of a single `<*-transform-pipeline>`.
   2. The `default` fields config ([fields.md](../Specs/fields.md), Default
      Fields Configs): always `standard`; removing it also requires editing
      [configs.md](../Specs/configs.md)'s Default Configs.
   3. [mas.md](../Specs/mas.md)'s Context Stacks: used only by custom config
      lookup, but [configs.md](../Specs/configs.md)'s Context Stacks links to it
      as its example.
   4. "Immutable" in [fields.md](../Specs/fields.md)'s "Immutable Built-In Named
      Fields Configs" heading: it only contrasts with custom configs, but
      [configs.md](../Specs/configs.md) links to the heading's anchor.

### Bug Fix Session Open Issues (2026-10-02)

1. A `<separator-pattern>` ([table.md](../Specs/table.md), Separator),
   `<leader-pattern>`, or `<item-separator-pattern>`
   ([key-value.md](../Specs/key-value.md), Leader & Item Separator) whose last
   repeated character is wide (e.g., `中`) can overshoot its width, since a
   character can't be split & both specs forbid padding instead.

## ASAP Version, But Massive Effort

### Persisted Named Formats & Custom Named Configs

## Later Versions

### Radix `%n` modifier

e.g., `%16n`.

### Meaningful Number Units

e.g., SI prefixes

Cross-unit conversion.

### Chronologic Coercion & Output Formats

Mirror number coercion: chronologic coercion takes fenced arguments giving the
input format (e.g., `%.:yyyy-MM-dd:c`, `..:yyyy-MM-dd:timeZone:UTC:`), with
[UTS #35 date format patterns](
  https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
) as the pattern syntax.

A named or literal output format (e.g., a chronologic-to-string transform
mirroring `numberFormat`) needs the same pattern syntax & persisted named
formats.

### Boolean Coercion Options

Coercion arguments for boolean coercion, e.g.:

- Case: uppercase, lowercase, consistent case, or case-insensitive.
- `0` & non-`0` numbers.

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

Let `--table`'s value select a named table config other than the context stack's
`default`.
