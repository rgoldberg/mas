# To-Do

## Current Version

### Custom Names Removal

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

### EBNF

1. [`(* last wins *)`](../Specs/ebnf.md#last-wins-comments) is defined on a
   choice as "the last occurrence of any of the choice's alternatives overrides
   all preceding occurrences of any of the choice's alternatives", which
   describes a comment attached to an innermost choice (e.g., `<direction>`),
   but the comments sit on the option _sets_
   ([`<sort-option-set>`](../Specs/fields.md#sort-options), etc.), which would
   make `I+-` collapse to `-`. Either move the comments to the innermost choices
   or restore the per-alternative formulation. Non-choice instances:
   1. [`table-config = [ <table-setting>+ ]`](../Specs/table.md#table-config):
      the literal reading makes `hS` a header on, contradicting the [implied
      settings](../Specs/table.md#implied-settings).
   2. [`key-value-config = [ <key-value-setting>+ ]`](
        ../Specs/key-value.md#key-value-config
      ).
   3. [`json-config = [ <json-setting>+ ]`](../Specs/json.md#json-config).
   4. [`format-transform-pipeline = ( … )+`](
        ../Specs/fields-format.md#format-transforms
      ).
2. How far `{integer}` extends: [only text & syntax token consumption is
   defined](../Specs/ebnf.md#consuming-tokens); [scalar description consumption
   is not](../Specs/ebnf.md#scalar-descriptions).
   1. `@+1`
3. Sequences have no section: they appear only in
   [precedence](../Specs/ebnf.md#precedence), so a sequence's value is
   undefined.
   1. The value of `sort = [ <sort-priority> ] <sort-option-set>`.

### Fields

1. Should [`<field-modifiers>`s](../Specs/fields.md#field-modifiers) be
   unordered?
2. ["a field spec with default settings" is never
   defined](../Specs/fields.md#relative-field-specs).
   1. `--fields .+size` when `size` is not in the base fields config: its label,
      format & sort.
3. Deferred: whether to remove
   [`{text: field name}`](../Specs/fields.md#absolute-config) &
   [`{text: fields config name}`](
     ../Specs/fields.md#base-fields-config-selection
   ).

### Formatting

1. [Version fields' default formats use
   `%v`](../Specs/mas.md#default-sort-options): implemented as `%V+%i+`, so a
   nonconforming value still renders as is instead of aborting to an empty
   string. Is that intended?
2. [Chronologic
   auto-detection](../Specs/fields-format.md#chronologic-formatting):
   1. `<nullary-chronologic>`'s value is an "ISO date / datetime / time, per
      input", but auto-detection tries only ISO-8601 datetime, ISO-8601
      date-only & Unix epoch, so time-only input (e.g., `12:30:00`) is not
      chronologic (implemented as such). Should time-only input be detected, or
      should "/ time" be removed?
   2. It accepts a string of a decimal number (e.g., `"0"`) as a Unix epoch
      timestamp, unlike `%n`, which requires a JSON number absent `<coercion>`.
      Should only a JSON number be a "numeric timestamp"?
   3. Which ISO-8601 representations should be detected?
      1. Implemented:
         1. Extended-format date.
         2. Extended-format date & complete time, with optional fractional
            seconds (after `.` or `,`) & an optional UTC offset (`Z`, `±hh`,
            `±hhmm`, or `±hh:mm`).
      2. Undetected:
         1. Basic format (e.g., `20200318`, currently read as a Unix epoch).
         2. Reduced precision (e.g., `2020-03-18T17:39`).
         3. Ordinal dates.
         4. Week dates.
         5. RFC 3339 variants:
            1. Space separator.
            2. Lowercase `t` or `z`.

### Sorting

1. [`<output>` sort source](../Specs/fields.md#sort-source) compares values by
   "the rendered value type": is that the type of the rendered JSON node (only
   `%i` passthrough retains a non-string type), or the output type of the
   format's final pipeline / placeholder (e.g., chronologic for
   `%C.dateOnly++`)?
   1. JSON output types are undefined: the [type-preserving passthrough for
      `%i`](../Specs/fields-format.md#format-transforms) is mentioned but not
      defined, and it conflicts with
      [`"" if null`](../Specs/fields-format.md#unconditional-placeholders)
      (e.g., whether `%i` on `null` outputs `null` or `""`).
   2. [No comparison is defined for fields typed
      "any"](../Specs/fields.md#sort-source), e.g., `name:%i/1`.
2. [Extra sort option sets have no type](../Specs/fields.md#sorting): each later
   set sorts values that conform to none of the preceding sets' types, but a set
   has no type of its own (e.g., for `price:%.n/1n/Ii`, which values the 2nd set
   sorts, and as which type?).
   1. [Values that conform to no `<sort-option-set>` "retain their input
      order"](../Specs/fields.md#sort-nonconforming-values): implemented as
      comparing equal for that sort key, so a lower-priority sort key may still
      order them; should they instead be ordered by input order immediately?
3. A [`<sort-priority>`](../Specs/fields.md#sort-priority) directly absent from
   a `<sort>` (e.g., `name/I`) is `null`, which is an error, so
   `[ <sort-priority> ]` can never be absent: implemented as the working fields
   config's `<sort-priority>` (an error iff the field spec has no `<sort>`).
   Which is intended?

### Output Configs

1. A [`<separator-pattern>`](../Specs/table.md#separator),
   [`<leader-pattern>`](../Specs/key-value.md#leader), or
   [`<item-separator-pattern>`](../Specs/key-value.md#item-separator) whose last
   repeated character is wide (e.g., `中`) can overshoot its width, since a
   character cannot be split & both specs forbid padding instead.

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
4. Per-context user-configured default formats.

## Later Versions

### `numberFormat` Number Templates

Number templates for `numberFormat` (e.g., [UTS #35 number
patterns](https://www.unicode.org/reports/tr35/tr35-numbers.html)).

1. They would cover group sizes, fraction digits & scientific notation, leaving
   only the locale & symbol overrides as arguments.
2. They overlap `round` & `scale`'s fraction digits, and are base 10 only.
3. They would also select an output notation (positional, `e`, or `E`), which is
   not supported: every number transform retains its input's notation, except
   `scale`, which always renders positional notation.

### Radix `%n` Modifier

e.g., `%16n`.

### Meaningful Number Units

e.g., SI prefixes.

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

### Heterogeneous Pipeline Types & Coercion Anywhere

### Nested Objects & Arrays

### Configurable Absent Value Handling

Configurable behavior per output format:

- `error`: Report an error for absent values.
- `omit`: Omit output for absent values.
- `emit`: Output a configurable default value for absent values.

### Configurable Boundary Collapsing

- Same boundary
- Same group
- All

### `<document-order>` for `@table`

### `<base-table-config-name>`

Let `--table`'s value select a named table config other than the context stack's
`default`.
