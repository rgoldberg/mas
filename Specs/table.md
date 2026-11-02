# Table Output Options

`--table` & `--table-config` are optional options of every [display
command](configs.md#display-commands).

Each selects table output; `--table-config` also configures its header row,
separator line & column spacing.

Uses the [custom EBNF grammar](ebnf.md).

## Table Config

```ebnf
table-config  = <table-setting>+
table-setting =
  <header-setting>
  | <header-styling-setting>
  | <header-style-prefix-setting>
  | <header-style-suffix-setting>
  | <header-style-reset-setting>
  | <separator-setting>
  | <broken-setting>
  | <column-spacing-setting>
```

`<table-config>` is the table config kind's [output config
syntax](configs.md#output-configs), and `--table-config` is table output's
[output config option](configs.md#output-configs).

A **table config** is a [named config](configs.md#named-configs) of the table
kind.

Each [line terminator](configs.md#line-terminators) in a header or data cell is
rendered as `⏎`, so each row is 1 line (e.g., `a` & `b` separated by an LF
render as `a⏎b`). Each other C0 control character (U+0000 to U+001F) & each DEL
(U+007F) in a header or data cell is rendered as its [Control
Pictures](https://www.unicode.org/charts/PDF/U2400.pdf) symbol (e.g., a tab as
`␉` & an ESC as `␛`), and each other C1 control character (U+0080 to U+009F) as
its ECMA-48 7-bit equivalent (an ESC followed by the character 64 code points
below it), with that ESC rendered as `␛` (e.g., U+009B, an 8-bit CSI, as `␛[`),
because each would otherwise misalign its column (e.g., a tab, whose
[width](configs.md#width) is 0, but which a terminal renders up to its next tab
stop) or modify the terminal's state (e.g., an ESC, which starts an escape
sequence).

A table without any item or any column renders nothing, not even a header row or
a separator line.

A column's **column width** is the [width](configs.md#width) of its widest cell,
including its header cell iff the header row is rendered. Each header & data
cell is aligned within its column width per its column's
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
header-on  = "H" [ <style-specifier> ] <table-setting-termination>

style-specifier = {string: terminal-specific styling text with no bare ASCII letters & no line terminators}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `h`: no header row, so no [separator line](#separator).
- `H`: a header row of field labels, each aligned as its column is (per its
  field spec's [alignment](fields.md#alignment)). `<style-specifier>`, if given,
  styles the entire header row: [`<style-prefix>`](#style-prefix),
  `<style-specifier>` & [`<style-suffix>`](#style-suffix) precede it, and
  [`<style-reset>`](#style-reset) follows it (e.g., with their defaults, `1` for
  bold, `1;4` for bold & underlined, as ANSI SGR parameters); absent, the header
  row is unstyled. A bare ASCII letter in `<style-specifier>` is invalid, so
  that a mistyped setting is not silently consumed as `<style-specifier>` text
  (e.g., `--table-config Hb`); escape it to include it (e.g.,
  `--table-config 'H\b'`). A `<style-specifier>` that contains a [line
  terminator](configs.md#line-terminators) is invalid, because it would split
  each row that it styles.

## Header Styling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-styling-setting = <header-terminal-only-styling> | <header-always-styling> (* default: <header-terminal-only-styling>; last wins; inherited *)

header-terminal-only-styling = "t"
header-always-styling        = "a"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `t`: the header row is styled iff standard output is a terminal.
- `a`: the header row is always styled, even if standard output is not a
  terminal, e.g., when piped to `less -R`.

## Style Prefix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-prefix-setting = <header-style-prefix-default> | <header-style-prefix-custom> (* default: <header-style-prefix-default>; last wins; inherited *)

header-style-prefix-default = "p" (* default style-prefix: {ESC [} *)
header-style-prefix-custom  = "P" [ <style-prefix> ] <table-setting-termination>

style-prefix = ^{string: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `p`: `ESC[` (the ANSI control sequence introducer, where `ESC` is U+001B)
  precedes `<style-specifier>`.
- `P`: a custom string precedes `<style-specifier>` (e.g., `P:` for none). A
  `<style-prefix>` that contains a line terminator is invalid, because it would
  split each row that it styles.

## Style Suffix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-suffix-setting = <header-style-suffix-default> | <header-style-suffix-custom> (* default: <header-style-suffix-default>; last wins; inherited *)

header-style-suffix-default = "x" (* default style-suffix: "m"; mnemonic: last letter of suffix *)
header-style-suffix-custom  = "X" [ <style-suffix> ] <table-setting-termination> (* mnemonic: last letter of suffix *)

style-suffix = ^{string: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `x`: `m` (the ANSI SGR control sequence's final byte) follows
  `<style-specifier>`.
- `X`: a custom string follows `<style-specifier>` (e.g., `X:` for none). A
  `<style-suffix>` that contains a line terminator is invalid, because it would
  split each row that it styles.

## Style Reset

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-reset-setting = <header-style-reset-default> | <header-style-reset-custom> (* default: <header-style-reset-default>; last wins; inherited *)

header-style-reset-default = "o" (* default style-reset: {ESC [0m}; mnemonic: off *)
header-style-reset-custom  = "O" [ <style-reset> ] <table-setting-termination> (* mnemonic: off *)

style-reset = ^{string: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `o`: `ESC[0m` (the ANSI SGR reset) follows the styled header row.
- `O`: a custom string follows the styled header row (e.g., `O:` for none). A
  `<style-reset>` that contains a line terminator is invalid, because it would
  split each row that it styles.

## Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
separator-setting = <separator-off> | <separator-on> (* default: <separator-off>; last wins; inherited *)

separator-off = "s"
separator-on  = "S" [ <separator-pattern> ] <table-setting-termination>

separator-pattern = ^{string: no line terminators}^ (* default: "-" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no separator line.
- `S`: a line after the header row, before the 1st data row, rendered iff the
  header row is, because a separator line's sole purpose is to separate a header
  from the data; absent a header row, `S` is retained, but unrendered (e.g.,
  `S:h` renders neither, while, for a persistent `default` table config of
  `S=:h`, `--table-config H` renders a header row & a `=`-patterned separator
  line). `<separator-pattern>` is repeated to fill the line's
  [width](configs.md#width), truncated before the 1st character that would
  exceed that width; spaces fill any remaining width (e.g., when that character
  is wide, such as `中`). A 0-width `<separator-pattern>` (e.g., a tab) is
  printed once, with no space-fill, because no number of repetitions can fill
  any width. A `<separator-pattern>` that contains a [line
  terminator](configs.md#line-terminators) is invalid, because it would split
  the separator line.

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
  segment per column, joined by the same column spacing as every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  table width, except that it retains each tab of each column spacing in place,
  filling each run between tabs independently, because a tab's rendered width
  depends on the terminal's tab stops, which an app cannot determine (e.g., with
  `$'C\t:S'`, the separator line of 2 3-wide columns is `---`, a tab & `---`).

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-setting = <column-spacing-default> | <column-spacing-custom> (* default: <column-spacing-default>; last wins; inherited *)

column-spacing-default = "c" (* default column-spacing: "  " *)
column-spacing-custom  = "C" [ <column-spacing> ] <table-setting-termination>

column-spacing = ^{string: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: 2 spaces between adjacent columns.
- `C`: a custom spacing string between adjacent columns (e.g., `C:` for no
  spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a tab character, e.g.,
  `$'C\t:'` in zsh). A `<column-spacing>` that contains a line terminator is
  invalid, because it would split each row.

## Table Setting Termination

```ebnf
table-setting-termination = <table-setting-terminator> | <end-of-table-config>

table-setting-terminator = ":"
end-of-table-config      = end
```

E.g., in `--table-config Hb`, `b` is an error (because `<style-specifier>`
cannot consume it), not a separate `<broken-setting>`.

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

- `--table`: no header, no separator, 2 spaces between columns.
- `--table-config H1:`: a header row, bold (SGR `1`) iff standard output is a
  terminal, no separator.
- `--table-config H1:a`: a header row, bold (SGR `1`) regardless of standard
  output, no separator.
- `--table-config $'H1:O\e[22m:'` (in zsh): a header row, bold (SGR `1`) iff
  standard output is a terminal, reset to normal intensity (SGR `22`) instead of
  via a full reset, no separator.
- `--table-config S`: a header row (implied) & a dashed (`-`) separator line.
- `--table-config b`: a header row (implied) & a dashed (`-`), broken separator
  line.
- `--table-config S-+:b`: a header row (implied) & a `-+`-patterned, broken
  separator line.
- `--table-config C....`: no header, no separator, `....` between columns.

## Appendix: Escaping

[For a variable token to consume text that would otherwise match a literal, 1 or
more of its characters must be escaped by prefixing it with a
`\`.](ebnf.md#tokens)

Throughout all variable tokens, a `\` is written `\\`, because `\` always
escapes the next character.

In each row of the table below, the given characters must be escaped to be
consumed as any character in a variable token consumed by the given typed
terminal. Leading & trailing outer bare whitespace is ignored by
`<style-specifier>` & consumed by every other typed terminal.

| Nonterminal           | Any                 |
|:----------------------|:--------------------|
| `<style-specifier>`   | `:` & ASCII letters |
| `<style-prefix>`      | `:`                 |
| `<style-suffix>`      | `:`                 |
| `<style-reset>`       | `:`                 |
| `<separator-pattern>` | `:`                 |
| `<column-spacing>`    | `:`                 |
