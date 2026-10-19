# Table Output Option

`--table` is an optional option of every [display
command](configs.md#display-commands).

It selects table output, configuring its header row, separator line & column
spacing.

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

`--table`'s optional [value](configs.md#option-values), iff non-empty, is a
`<table-config>`.

A **table config** is a [named config](configs.md#named-configs) of the table
kind.

`--table` output sources from the context stack's
[`default`](configs.md#default-configs) table config; `<table-config>` is
overlaid on it for the current command line only, without persistently affecting
it. Each setting's default applies iff neither sets it.

The [built-in](configs.md#immutable-built-in-named-configs) `standard` table
config sets every `<table-setting>` to its default.

## Header

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-setting = <header-off> | <header-on> (* default: <header-off>; last wins *)

header-off = "h"
header-on  = "H" [ <style-specifier> ] <table-setting-termination>

style-specifier = {text: terminal-specific styling text with no bare ASCII letters}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `h`: no header row.
- `H`: a header row of field labels. `<style-specifier>`, if given, styles the
  entire header row, which is then preceded by
  [`<style-prefix>`](#style-prefix), `<style-specifier>` &
  [`<style-suffix>`](#style-suffix), and followed by
  [`<style-reset>`](#style-reset) (e.g., with their defaults, `1` for bold,
  `1;4` for bold & underlined, as ANSI SGR parameters); absent, the header row
  is unstyled. A bare ASCII letter in `<style-specifier>` is invalid, so that a
  mistyped setting is not silently consumed as `<style-specifier>` text (e.g.,
  `--table Hb`); escape it to include it (e.g., `--table H\b`).

## Header Styling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-styling-setting = <terminal-only-styling> | <always-styling> (* default: <terminal-only-styling>; last wins *)

terminal-only-styling = "t"
always-styling        = "a"
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
header-style-prefix-setting = <header-style-prefix-default> | <header-style-prefix-custom> (* default: <header-style-prefix-default>; last wins *)

header-style-prefix-default = "p" (* default style-prefix: {ESC [} *)
header-style-prefix-custom  = "P" [ <style-prefix> ] <table-setting-termination>

style-prefix = ^{text}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `p`: `ESC[` (the ANSI control sequence introducer, where `ESC` is U+001B)
  precedes `<style-specifier>`.
- `P`: a literal custom string precedes `<style-specifier>` (e.g., `P:` for
  none).

## Style Suffix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-suffix-setting = <header-style-suffix-default> | <header-style-suffix-custom> (* default: <header-style-suffix-default>; last wins *)

header-style-suffix-default = "x" (* default style-suffix: "m"; mnemonic: suffix *)
header-style-suffix-custom  = "X" [ <style-suffix> ] <table-setting-termination> (* mnemonic: suffix *)

style-suffix = ^{text}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `x`: `m` (the ANSI SGR final character) follows `<style-specifier>`.
- `X`: a literal custom string follows `<style-specifier>` (e.g., `X:` for
  none).

## Style Reset

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-style-reset-setting = <header-style-reset-default> | <header-style-reset-custom> (* default: <header-style-reset-default>; last wins *)

header-style-reset-default = "o" (* default style-reset: {ESC [0m}; mnemonic: off *)
header-style-reset-custom  = "O" [ <style-reset> ] <table-setting-termination> (* mnemonic: off *)

style-reset = ^{text}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `o`: `ESC[0m` (the ANSI SGR reset) follows the styled header row.
- `O`: a literal custom string follows the styled header row (e.g., `O:` for
  none).

## Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
separator-setting = <separator-off> | <separator-on> (* default: <separator-off>; last wins *)

separator-off = "s"
separator-on  = "S" [ <separator-pattern> ] <table-setting-termination>

separator-pattern = ^{text}^ (* default: "-" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no separator line.
- `S`: a line between the header row & the 1st data row. `<separator-pattern>`
  is repeated to fill the line's width, truncated before the 1st character that
  would exceed that width; spaces fill any remaining width (e.g., when that
  character is wide, such as `中`). A 0-width `<separator-pattern>` (e.g., a tab)
  is printed once, because no number of repetitions can fill any width. A
  `<separator-pattern>` that contains a line terminator (e.g., LF or CR) is
  invalid, because it would split the separator line.

## Broken

```ebnf
broken-setting = <broken> | <unbroken> (* default: <unbroken>; last wins *)

broken   = "b"
unbroken = "u"
```

- `b`: the [separator line](#separator) is broken into 1 independently-filled
  segment per column, joined by the same column spacing as every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  table width.

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-setting = <column-spacing-default> | <column-spacing-custom> (* default: <column-spacing-default>; last wins *)

column-spacing-default = "c" (* default column-spacing: "  " *)
column-spacing-custom  = "C" [ <column-spacing> ] <table-setting-termination>

column-spacing = ^{text}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: 2 spaces between adjacent columns.
- `C`: a literal custom spacing string between adjacent columns (e.g., `C:` for
  no spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a literal tab
  character, e.g., `$'C\t:'` in zsh). A `<column-spacing>` that contains a line
  terminator (e.g., LF or CR) is invalid, because it would split each row.

## Table Setting Termination

```ebnf
table-setting-termination = <table-setting-terminator> | <end-of-table-config>

table-setting-terminator = ":"
end-of-table-config      = end
```

E.g., in `--table Hb`, `b` is interpreted as invalid `<style-specifier>` text,
not as a separate `<broken-setting>`.

## Implied Settings

- `b` / `u` imply a separator line, if none is otherwise set: `S`.
- Any separator line (explicit or implied) implies a header row, if none is
  otherwise set: `H` (unstyled), because a separator line's sole purpose is to
  separate a header from the data.

A setting that explicitly sets an axis, even to "off" (`h` / `s`), always
overrides an axis's implied default, regardless of where in `--table`'s value it
appears.

A setting implied by `<table-config>` overrides inherited settings.

## Examples

- `--table H1:`: a bold header row (SGR `1`) iff standard output is a terminal,
  no separator.
- `--table H1:a`: a bold header row (SGR `1`) regardless of standard output, no
  separator.
- `--table $'H1:O\e[22m:'` (in zsh): a bold header row (SGR `1`) iff standard
  output is a terminal, reset to normal intensity (SGR `22`) instead of via a
  full reset, no separator.
- `--table S`: a header row (implied) & a dashed (`-`) separator line.
- `--table b`: a header row (implied) & a dashed (`-`), broken separator line.
- `--table S-+:b`: a header row (implied) & a `-+`-patterned, broken separator
  line.
- `--table C....`: no header, no separator, `....` between columns.

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
