# To-Do

## Current Version

### Documentation

1. Update `README.md`
2. Getting Started / Overview
3. Manual accompanying specs
4. Examples

### Repeated Options

Every mas flag & option other than an output format flag / option & `--fields`
may be repeated without an error (e.g., `--bundle --bundle`); decide whether
giving any of them more than once is an error, as it is for output format flags
/ options & `--fields`.

### Release Process

1. At the next release, update the homebrew-core `mas` formula's Swift & Xcode
   dependencies to the [minimum versions](../CLAUDE.md#minimum-versions).
2. Update the release process & `mas-cli/homebrew-tap` to not use the `pr-pull`
   label:
   1. Remove the `pr-pull` [release
      rule](../.claude/rules/scripting.md#releases).

### Swift Argument Parser Empty Values

Awaiting an upstream release (not actionable until then): mas cannot be released
until a Swift Argument Parser release includes
[apple/swift-argument-parser#961](
  https://github.com/apple/swift-argument-parser/pull/961
), which makes an empty value after `=` (e.g., `--fields=`) an empty value
instead of no value, and `Package.swift` depends on that release (via `from:`)
instead of on #961's merge commit in Swift Argument Parser's main branch.

### Swift Argument Parser Attached-Only Values

Awaiting an upstream release (not actionable until then): once a Swift Argument
Parser release resolves [apple/swift-argument-parser#992](
  https://github.com/apple/swift-argument-parser/issues/992
) with a `defaultAsFlag` parsing strategy that accepts a value only after `=`,
replace each output format's flag & option (e.g., `--json` &
`--json-config <json-config>`) with 1 option whose optional value is accepted
only after `=` (e.g., `--json[=<json-config>]`).

## ASAP Version, But Massive Effort

### Persisted Custom Named Formats & Configs

1. Custom named formats: every reference to one reports `unknownNamedFormat` (or
   `invalidFormatName` for an invalid format name).
2. [Custom named configs](../Specs/configs.md#custom-named-configs) of every
   kind:
   1. Looking a name up through the [context
      stack](../Specs/configs.md#referencing-named-configs) from its starting
      context.
   2. Resolving a config that extends its same-named ancestor, including a root
      context `default` that extends `default`.
   3. A persisted table, key-value, or JSON config
      [extending](../Specs/configs.md#referencing-named-configs) `default`.
   4. Reporting reference cycles & a custom config named `standard` or any
      built-in config's name.
   5. A custom `default` (currently always `standard`) & each context's
      [`standard`](../Specs/configs.md#standard-configs) layering custom
      `default`s over the built-in standard.
   6. Custom [variants](../Specs/fields.md#named-fields-configs), including
      matching a stem or a suffixed reference per context, `default` variants &
      a variant extending its own stem.
   7. A persisted fields config [ignoring its references to nonexistent
      fields](../Specs/fields.md#nonexistent-fields).
3. Inherited `--table-config` / `--key-value-config` / `--json-config` settings:
   they currently apply only on top of `standard`, so implied
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
input format (e.g., `%.:yyyy-MM-dd:d`, `..:yyyy-MM-dd:timeZone:UTC:`), with
[UTS #35 date format patterns](
  https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
) as the pattern syntax. It would also cover the ISO-8601 representations that
auto-detection omits (e.g., week dates) & let `%c` & `%C` take a coercion (e.g.,
`%.:HH\:mm:c`), which they currently lack, because only a time-only value
matches them.

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

### Member Indices

Let a field spec select [members](../Specs/fields.md#members) of its field via a
**member index**, per [positions &
indices](../Specs/fields.md#positions--indices) (e.g., `name@@2` for the 2nd
member, `name@@-1` for the last), which needs:

1. A prefix reserved in field names, as `.` is, of only [shell-safe
   punctuation](../.claude/rules/specs.md) (e.g., `@@`, doubling `@` as `//`
   doubles `/`), never `#`, which zsh's `EXTENDED_GLOB` interprets.
2. Syntax for all members, or an absent member index meaning the default (each
   member for key-value & JSON output, the last for a table cell & a sort key).
3. Which member a sort key uses if multiple are selected, and whether selecting
   multiple is an error for table output.
4. How `<document-order>` orders selected members.

### Configurable Absent Value Handling

Configurable behavior per output format:

- `error`: Report an error for absent values.
- `omit`: Omit output for absent values.
- `emit`: Output a configurable default value for absent values.

### Configurable Unix Time Segment Adjacent Characters

Let a [`<unix-time>`](../Specs/fields.md#sort-chronologic-segments) sort segment
be adjacent to configurable characters other than whitespace (e.g., brackets:
Unicode `Ps` & `Pe`), separately from sort boundaries.

### Configurable Boundary Collapsing

- Same boundary
- Same group
- All

### `<document-order>` for Table Output

Let `<document-order>` order a table's columns by the 1st item's document order
(e.g., the key order of the 1st input JSON object), because rows otherwise share
no document order; every later item's fields would follow the 1st item's order,
with fields that the 1st item lacks after the others, in position order.

### Base Output Config Names

Let `--table-config`'s, `--key-value-config`'s & `--json-config`'s values &
persisted configs of their kinds each select a named config of its kind to
[extend](../Specs/configs.md#referencing-named-configs) other than `default`
(e.g., via a `<base-table-config-name>`).

### Multi-Line Rows

Let a line terminator in a table header or data cell, or in a key-value key,
continue its row on a new line, instead of rendering as `⏎`: each line
terminator terminates the current line of its cell or key, the row's other cells
continue to the row's end, then the row's next line holds each cell's or key's
next line, so a row is as many lines as its most-lined cell or key. This needs:

1. Whether multi-line rows replace `⏎` or are a setting (e.g., for line-oriented
   consumers, such as `cut`, which need 1 line per row).
2. Whether a continuation line is marked (e.g., as `psql` marks one with `+`),
   because it can otherwise be mistaken for the next row.
3. How each line is justified, styled (e.g., a style reset per header line) &
   measured (e.g., column widths & separator lines per widest line).
4. Whether a line terminator in a style, pattern, or spacing remains invalid.
