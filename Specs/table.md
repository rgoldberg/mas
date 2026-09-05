# Table Output Option

Uses the [custom EBNF grammar](ebnf.md).

`--table` selects table output for a
[display command](configs.md#display-commands).

## Table Config

A **table config** is a [named config](configs.md#named-configs) of the table
kind: a `<table-value>` configuring the table's header row, separator line &
column spacing.

`--table` output sources from the context stack's
[`default`](configs.md#default-configs) table config; `--table`'s optional value
is a `<table-value>` overlaid on it for the current command line only, without
persistently affecting it. Each option's default applies iff neither sets it.

The [built-in](configs.md#immutable-built-in-named-configs) `standard` table
config has every `<table-option>` at its default (i.e., no header, no
separator).

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
table-value  = [ <table-option>+ ] (* last wins *)
table-option = <header-option> | <header-styling-option> | <separator-option> | <broken-option> | <column-spacing-option>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Header

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-option = <header-off> | <header-on> (* default: <header-off> *)
header-off    = "h"
header-on     = "H" [ <sgr-parameters> ] ( <table-value-terminator> | <end-of-shell-word> )

sgr-parameters          = <sgr-parameter> … <sgr-parameter-separator>
sgr-parameter           = {non-negative integer}
sgr-parameter-separator = ";"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `h`: no header row.
- `H`: a header row of field labels. `<sgr-parameters>`, if given, are raw ANSI
  SGR parameters (e.g., `1` for bold, `1;4` for bold & underlined) applied to
  the whole header row; absent, the header row is unstyled.

## Header Styling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-styling-option = <terminal-only-styling> | <always-styling> (* default: <terminal-only-styling> *)
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
separator-option  = <separator-off> | <separator-on> (* default: <separator-off> *)
separator-off     = "s"
separator-on      = "S" [ <separator-pattern> ] ( <table-value-terminator> | <end-of-shell-word> )
separator-pattern = ^{text}^ (* default: "-" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no separator line.
- `S`: a line between the header row & the 1st data row. `<separator-pattern>`
  is repeated to fill the line, cutting off immediately if it does not evenly
  divide the line's width.

## Broken

```ebnf
broken-option = <broken> | <unbroken> (* default: <unbroken> *)
broken        = "b"
unbroken      = "u"
```

- `b`: the [separator line](#implied-options) is broken into 1
  independently-filled segment per column, joined by the same column spacing as
  every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  whole table's width.

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-option  = <column-spacing-default> | <column-spacing-custom> (* default: <column-spacing-default> *)
column-spacing-default = "c"
column-spacing-custom  = "C" [ <column-spacing> ] ( <table-value-terminator> | <end-of-shell-word> )
column-spacing         = ^{text}^ (* direct default: ""; transitive default: "  " *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: resets column spacing to `<column-spacing>`'s transitive default.
- `C`: a literal custom spacing string between adjacent columns (e.g., `C:` for
  no spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a literal tab
  character, e.g., `$'C\t:'` in zsh).

## Terminator

```ebnf
table-value-terminator = ":"
end-of-shell-word      = {the end of --table's whole value}
```

E.g., in `--table Hb`, `b` is interpreted as invalid `<sgr-parameters>` text,
not as a separate `<broken-option>`.

## Implied Options

- `b` / `u` imply a separator line, if none is otherwise set: `S`.
- Any separator line (explicit or implied) implies a header row, if none is
  otherwise set: `H` (unstyled), because a separator line's sole purpose is to
  separate a header from the data.

An option that explicitly sets an axis, even to "off" (`h` / `s`), always
overrides an axis's implied default, regardless of where in `--table`'s value it
appears.

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
