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

`--table-config` is table output's [output config
option](configs.md#output-configs), whose syntax is `<table-config>`.

A **table config** is a [named config](configs.md#named-configs) of the table
kind.

Each [line terminator](configs.md#line-terminators) in a header or data cell is
rendered as `⏎`, so each row is 1 line (e.g., `a` & `b` separated by an LF
render as `a⏎b`).

A table without any item or any column renders nothing, not even a header row or
a separator line.

## Header

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-setting = <header-off> | <header-on> (* default: <header-off>; last wins; inherited *)

header-off = "h"
header-on  = "H" [ <style-specifier> ] <table-setting-termination>

style-specifier = {text: terminal-specific styling text with no bare ASCII letters & no line terminators}
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

style-prefix = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `p`: `ESC[` (the ANSI control sequence introducer, where `ESC` is U+001B)
  precedes `<style-specifier>`.
- `P`: a literal custom string precedes `<style-specifier>` (e.g., `P:` for
  none). A `<style-prefix>` that contains a line terminator is invalid, because
  it would split each row that it styles.

## Style Suffix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-suffix-setting = <header-style-suffix-default> | <header-style-suffix-custom> (* default: <header-style-suffix-default>; last wins; inherited *)

header-style-suffix-default = "x" (* default style-suffix: "m"; mnemonic: suffix *)
header-style-suffix-custom  = "X" [ <style-suffix> ] <table-setting-termination> (* mnemonic: suffix *)

style-suffix = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `x`: `m` (the ANSI SGR control sequence's final byte) follows
  `<style-specifier>`.
- `X`: a literal custom string follows `<style-specifier>` (e.g., `X:` for
  none). A `<style-suffix>` that contains a line terminator is invalid, because
  it would split each row that it styles.

## Style Reset

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-reset-setting = <header-style-reset-default> | <header-style-reset-custom> (* default: <header-style-reset-default>; last wins; inherited *)

header-style-reset-default = "o" (* default style-reset: {ESC [0m}; mnemonic: off *)
header-style-reset-custom  = "O" [ <style-reset> ] <table-setting-termination> (* mnemonic: off *)

style-reset = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `o`: `ESC[0m` (the ANSI SGR reset) follows the styled header row.
- `O`: a literal custom string follows the styled header row (e.g., `O:` for
  none). A `<style-reset>` that contains a line terminator is invalid, because
  it would split each row that it styles.

## Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
separator-setting = <separator-off> | <separator-on> (* default: <separator-off>; last wins; inherited *)

separator-off = "s"
separator-on  = "S" [ <separator-pattern> ] <table-setting-termination>

separator-pattern = ^{text: no line terminators}^ (* default: "-" *)
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
  table width.

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-setting = <column-spacing-default> | <column-spacing-custom> (* default: <column-spacing-default>; last wins; inherited *)

column-spacing-default = "c" (* default column-spacing: "  " *)
column-spacing-custom  = "C" [ <column-spacing> ] <table-setting-termination>

column-spacing = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: 2 spaces between adjacent columns.
- `C`: a literal custom spacing string between adjacent columns (e.g., `C:` for
  no spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a literal tab
  character, e.g., `$'C\t:'` in zsh). A `<column-spacing>` that contains a line
  terminator is invalid, because it would split each row.

## Table Setting Termination

```ebnf
table-setting-termination = <table-setting-terminator> | <end-of-table-config>

table-setting-terminator = ":"
end-of-table-config      = end
```

E.g., in `--table-config Hb`, `b` is interpreted as invalid `<style-specifier>`
text, not as a separate `<broken-setting>`.

## Implied Alternatives

- `b` / `u` imply a separator line: `S`.
- An effective `S` implies a header row: `H` (unstyled), because a separator
  line is rendered only with a header row (e.g., `S` & `b` imply `H`, while
  `S:s` & `bs` imply none).

An implied alternative yields to an explicit alternative of its setting & to an
inherited [payload](configs.md#output-configs), as [output configs
specify](configs.md#implied-alternatives) (e.g., `S:h` implies no header row;
with an inherited `H1:`, `S` retains the bold header row, while with an
inherited `h`, `S` implies an unstyled one; with an inherited `S=:h`, `b` breaks
the `=`-patterned separator line, below an implied, unstyled header row).

## Examples

- `--table`: no header, no separator, 2 spaces between columns.
- `--table-config H1:`: a bold header row (SGR `1`) iff standard output is a
  terminal, no separator.
- `--table-config H1:a`: a bold header row (SGR `1`) regardless of standard
  output, no separator.
- `--table-config $'H1:O\e[22m:'` (in zsh): a bold header row (SGR `1`) iff
  standard output is a terminal, reset to normal intensity (SGR `22`) instead of
  via a full reset, no separator.
- `--table-config S`: a header row (implied) & a dashed (`-`) separator line.
- `--table-config b`: a header row (implied) & a dashed (`-`), broken separator
  line.
- `--table-config S-+:b`: a header row (implied) & a `-+`-patterned, broken
  separator line.
- `--table-config C....`: no header, no separator, `....` between columns.

## Appendix: Escaping

[For a text token to consume text that would otherwise match a syntax literal, 1
or more of its characters must be escaped by prefixing it with a
`\`.](ebnf.md#tokens)

Throughout all text tokens, a literal `\` is written `\\`, because `\` always
escapes the next character.

In each row of the table below, the given characters must be escaped to be
consumed as any character in a text token consumed by the given text terminal.
Leading & trailing outer bare whitespace is ignored by `<style-specifier>` &
consumed by every other text terminal.

| `{text}`              | Any                 |
|:----------------------|:--------------------|
| `<style-specifier>`   | `:` & ASCII letters |
| `<style-prefix>`      | `:`                 |
| `<style-suffix>`      | `:`                 |
| `<style-reset>`       | `:`                 |
| `<separator-pattern>` | `:`                 |
| `<column-spacing>`    | `:`                 |
