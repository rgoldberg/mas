# Table Output

A table config configures table output's header row, header styling, separator
line & column spacing.

Uses the [custom EBNF grammar](ebnf.md).

## Table Config

```ebnf
table-config  = <table-setting>+
table-setting =
  <header-setting>
  | <styling-setting>
  | <styling-prefix-setting>
  | <styling-suffix-setting>
  | <styling-reset-setting>
  | <separator-setting>
  | <broken-setting>
  | <column-spacing-setting>
```

`<table-config>` is the table config kind's [output config
syntax](configs.md#output-configs).

A **table config** is a [named config](configs.md#named-configs) of the table
kind.

Each [line terminator](configs.md#line-terminators) in a header or data cell is
rendered as `⏎`, so each cell is 1 line (e.g., `a` & `b` separated by an LF
render as `a⏎b`). Each other C0 control character (U+0000 to U+001F) & each DEL
(U+007F) in a header or data cell is rendered as its [Control
Pictures](https://www.unicode.org/charts/PDF/U2400.pdf) symbol (e.g., a tab as
`␉` & an ESC as `␛`), and each other C1 control character (U+0080 to U+009F) as
its ECMA-48 7-bit equivalent (an ESC followed by the character 64 code points
below it), with that ESC rendered as `␛` (e.g., U+009B, an 8-bit CSI, as `␛[`),
because each would otherwise misalign its column (e.g., a tab, whose
[width](configs.md#width) is 0, but which an output device renders up to its
next tab stop) or modify the output device's state (e.g., an ESC, which starts
an escape sequence).

A table without any item or any column renders nothing, not even a header row or
a separator line.

A column's **column width** is the [width](configs.md#width) of its widest
rendered cell, including its header cell iff the header row is rendered. Each
header & data cell is aligned within its column width per its column's
[alignment](fields.md#alignment), with spaces filling the rest of that width,
except that no cell of the last column has trailing spaces (e.g., a
center-aligned last column's cells have only leading spaces). Each pair of
adjacent columns is joined by the column spacing, so the **table width** is the
sum of the column widths, plus the column spacing's width once per pair of
adjacent columns (e.g., 2 per pair for the default 2-space column spacing).

## Header

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-setting = <header-off> | <header-on> (* default: <header-off>; last wins; inherited *)

header-off = "h"
header-on  = "H" [ <styling-specifier> ] <setting-termination>

styling-specifier = {string: output-device-specific styling text with no bare ASCII letters}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `h`: no header row, so no [separator line](#separator).
- `H`: a header row of field labels, each aligned as its column is (per its
  field spec's [alignment](fields.md#alignment)). `<styling-specifier>`, if
  given, styles the entire header row: [`<styling-prefix>`](#styling-prefix),
  `<styling-specifier>` & [`<styling-suffix>`](#styling-suffix) precede it, and
  [`<styling-reset>`](#styling-reset) follows it (e.g., with the [ANSI SGR
  styling defaults](command-line.md#styling-defaults), `1` for bold, `1;4` for
  bold & underlined); absent, the header row is unstyled. A bare ASCII letter in
  `<styling-specifier>` is invalid, so that a mistyped setting is not silently
  consumed as `<styling-specifier>` text (e.g., `Hb`); escape it to include it
  (e.g., `H\b`).

## Styling

`<styling-setting>`, `<styling-prefix-setting>`, `<styling-suffix-setting>` &
`<styling-reset-setting>` style each **stylable string**: the header row or, in
[key-value output](key-value.md#key), each key.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
styling-setting = <supported-only-styling> | <always-styling> (* default: <supported-only-styling>; last wins; inherited *)

supported-only-styling = "t" (* mnemonic: 2nd letter of styling *)
always-styling         = "a"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `t`: each stylable string is styled iff normal output [supports
  styling](configs.md#normal--error-output).
- `a`: each stylable string is always styled, even if normal output does not
  support styling (e.g., if an app cannot determine that its output device, such
  as a pager, can render styled text).

Styling text depends on the output device, so no default of `p`, `x`, or `o`
styles anything: an app should override each as appropriate for its output
devices (e.g., with the [ANSI SGR styling
defaults](command-line.md#styling-defaults)). Otherwise, `<styling-specifier>`
is output as is (e.g., `H1:a` outputs `1` before a header row).

## Styling Prefix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
styling-prefix-setting = <styling-prefix-default> | <styling-prefix-custom> (* default: <styling-prefix-default>; last wins; inherited *)

styling-prefix-default = "p" (* default styling-prefix: {empty string} *)
styling-prefix-custom  = "P" [ <styling-prefix> ] <setting-termination>

styling-prefix = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `p`: no string precedes `<styling-specifier>`, unless an app [overrides this
  default](#styling).
- `P`: a custom string precedes `<styling-specifier>` (e.g., `P:` for none).

## Styling Suffix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
styling-suffix-setting = <styling-suffix-default> | <styling-suffix-custom> (* default: <styling-suffix-default>; last wins; inherited *)

styling-suffix-default = "x" (* default styling-suffix: {empty string}; mnemonic: last letter of suffix *)
styling-suffix-custom  = "X" [ <styling-suffix> ] <setting-termination> (* mnemonic: last letter of suffix *)

styling-suffix = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `x`: no string follows `<styling-specifier>`, unless an app [overrides this
  default](#styling).
- `X`: a custom string follows `<styling-specifier>` (e.g., `X:` for none).

## Styling Reset

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
styling-reset-setting = <styling-reset-default> | <styling-reset-custom> (* default: <styling-reset-default>; last wins; inherited *)

styling-reset-default = "o" (* default styling-reset: {empty string}; mnemonic: off *)
styling-reset-custom  = "O" [ <styling-reset> ] <setting-termination> (* mnemonic: off *)

styling-reset = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `o`: no string follows each styled string, unless an app [overrides this
  default](#styling).
- `O`: a custom string follows each styled string (e.g., `O:` for none).

## Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
separator-setting = <separator-off> | <separator-on> (* default: <separator-off>; last wins; inherited *)

separator-off = "s"
separator-on  = "S" [ <separator-pattern> ] <setting-termination>

separator-pattern = ^{string}^ (* default: "-" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no separator line.
- `S`: a line after the header row, before the 1st data row, rendered iff the
  header row is, because a separator line's sole purpose is to separate a header
  from the data; absent a header row, `S` is retained, but unrendered (e.g.,
  `S:h` renders neither, while, for a persistent `default` table config of
  `S=:h`, a transient `H` renders a header row & a `=`-patterned separator
  line). `<separator-pattern>` is repeated to fill the line's
  [width](configs.md#width), truncated before the 1st character that would
  exceed that width; spaces fill any remaining width (e.g., when that character
  is wide, such as `中`), except at the line's end, as no cell of the last column
  has trailing spaces (e.g., for a table width of 5, `S中:` renders `中中`, and a
  `b` line's last segment is aligned as such a cell is). A 0-width
  `<separator-pattern>` (e.g., a tab) is rendered once, because no number of
  repetitions can fill any width: per run between tabs of a `u` line, with no
  space-fill, or per segment of a [`b`](#broken) line, which aligns each
  segment.

## Broken

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
broken-setting = <broken> | <unbroken> (* default: <unbroken>; last wins; inherited *)

broken   = "b"
unbroken = "u"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `b`: the [separator line](#separator) is broken into 1 independently filled
  segment per column, each aligned within its column width as a cell is (e.g., a
  0-width segment is space-filled per its column's alignment), joined by the
  same column spacing as every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  table width, except that it retains each tab of each column spacing in place,
  filling each run between tabs independently, because a tab's rendered width
  depends on the output device's tab stops, which an app cannot determine (e.g.,
  with `C<TAB>:S`, the separator line of 2 3-wide columns is `---`, a tab &
  `---`).

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-setting = <column-spacing-default> | <column-spacing-custom> (* default: <column-spacing-default>; last wins; inherited *)

column-spacing-default = "c" (* default column-spacing: "  " *)
column-spacing-custom  = "C" [ <column-spacing> ] <setting-termination>

column-spacing = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: 2 spaces between adjacent columns.
- `C`: a custom spacing string between adjacent columns (e.g., `C:` for no
  spacing at all, `C<TAB>:` for a tab).

## Implied Alternatives

- `b` / `u` imply a separator line: `S`.
- An effective `S` implies a header row: `H` (unstyled), because a separator
  line is rendered only with a header row (e.g., `S` & `b` imply `H`, while
  `S:s` & `bs` imply none).

An implied alternative yields to an explicit alternative of its setting &
retains an inherited [payload](configs.md#output-configs), as [output configs
specify](configs.md#implied-alternatives) (e.g., `S:h` implies no header row;
with an inherited `H1:`, `S` retains the bold header row, while with an
inherited `h`, `S` implies an unstyled one; with an inherited `S=:h`, `b` breaks
the `=`-patterned separator line, below an implied, unstyled header row).

## Examples

These examples use the [ANSI SGR styling
defaults](command-line.md#styling-defaults).

- An empty table config: no header, no separator, 2 spaces between columns.
- `H1:`: a header row, bold (SGR `1`) iff normal output supports styling, no
  separator.
- `H1:a`: a header row, bold (SGR `1`) whether or not normal output supports
  styling, no separator.
- `H1:O<ESC>[22m:`: a header row, bold (SGR `1`) iff normal output supports
  styling, reset to normal intensity (SGR `22`) instead of via a full reset, no
  separator.
- `S`: a header row (implied) & a dashed (`-`) separator line.
- `b`: a header row (implied) & a dashed (`-`), broken separator line.
- `S-+:b`: a header row (implied) & a `-+`-patterned, broken separator line.
- `C....`: no header, no separator, `....` between columns.

## Appendix: Escaping

[For a variable token to consume text that would otherwise match a literal, 1 or
more of its characters must be escaped by prefixing each with a
`\`.](ebnf.md#tokens)

Throughout all variable tokens, a `\` is written `\\`, because `\` always
escapes the next character.

In each row of the table below, the given characters must be escaped to be
consumed as any character in a variable token consumed by the given typed
terminal. Leading & trailing outer bare whitespace is ignored by
`<styling-specifier>` & consumed by every other typed terminal.

| Nonterminal           | Any                 |
|:----------------------|:--------------------|
| `<styling-specifier>` | `:` & ASCII letters |
| `<styling-prefix>`    | `:`                 |
| `<styling-suffix>`    | `:`                 |
| `<styling-reset>`     | `:`                 |
| `<separator-pattern>` | `:`                 |
| `<column-spacing>`    | `:`                 |
