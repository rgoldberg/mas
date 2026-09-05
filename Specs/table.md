# Table Output Option

`--table` is an optional option of every [display
command](configs.md#display-commands).

It selects table output, configuring its header row, separator line & column
spacing.

Uses the [custom EBNF grammar](ebnf.md).

## Table Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
table-option  = "--table" [ &<table-config> ]
table-config  = <table-setting>+ (* last wins *)
table-setting = <header-setting> | <header-styling-setting> | <separator-setting> | <broken-setting> | <column-spacing-setting>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **table config** is a [named config](configs.md#named-configs) of the table
kind.

`--table` output sources from the context stack's
[`default`](configs.md#default-configs) table config; `<table-config>` is
overlaid on it for the current command line only, without persistently affecting
it. Each setting's default applies iff neither sets it.

The [built-in](configs.md#immutable-built-in-named-configs) `standard` table
config sets every `<table-setting>` to its default.

## Header

```ebnf
header-setting = <header-off> | <header-on> (* default: <header-off> *)

header-off = "h"
header-on  = "H" [ <sgr-parameters> ] <table-setting-termination>

sgr-parameters          = <sgr-parameter> … <sgr-parameter-separator>
sgr-parameter           = {non-negative integer}
sgr-parameter-separator = ";"
```

- `h`: no header row.
- `H`: a header row of field labels. `<sgr-parameters>`, if given, are raw ANSI
  SGR parameters (e.g., `1` for bold, `1;4` for bold & underlined) applied to
  the entire header row; absent, the header row is unstyled.

## Header Styling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-styling-setting = <terminal-only-styling> | <always-styling> (* default: <terminal-only-styling> *)

terminal-only-styling = "t"
always-styling        = "a"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `t`: `<sgr-parameters>` are applied iff standard output is a terminal.
- `a`: `<sgr-parameters>` are always applied, even if standard output is not a
  terminal, e.g., when piped to `less -R`.

## Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
separator-setting = <separator-off> | <separator-on> (* default: <separator-off> *)

separator-off = "s"
separator-on  = "S" [ <separator-pattern> ] <table-setting-termination>

separator-pattern = ^{text}^ (* default: "-" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no separator line.
- `S`: a line between the header row & the 1st data row. `<separator-pattern>`
  is repeated to fill the line, truncated at the line's width iff it does not
  evenly divide the width.

## Broken

```ebnf
broken-setting = <broken> | <unbroken> (* default: <unbroken> *)

broken   = "b"
unbroken = "u"
```

- `b`: the [separator line](#implied-settings) is broken into 1
  independently-filled segment per column, joined by the same column spacing as
  every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  table width.

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-setting = <column-spacing-default> | <column-spacing-custom> (* default: <column-spacing-default> *)

column-spacing-default = "c"
column-spacing-custom  = "C" [ <column-spacing> ] <table-setting-termination>

column-spacing = ^{text}^ (* direct default: ""; transitive default: "  " *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: resets column spacing to `<column-spacing>`'s transitive default.
- `C`: a literal custom spacing string between adjacent columns (e.g., `C:` for
  no spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a literal tab
  character, e.g., `$'C\t:'` in zsh).

## Table Setting Termination

```ebnf
table-setting-termination = <table-setting-terminator> | <end-of-table-config>
table-setting-terminator  = ":"
end-of-table-config       = {end of <table-config>}
```

E.g., in `--table Hb`, `b` is interpreted as invalid `<sgr-parameters>` text,
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
Leading & trailing outer bare whitespace is consumed.

| `{text}`              | Any |
|:----------------------|:----|
| `<separator-pattern>` | `:` |
| `<column-spacing>`    | `:` |
