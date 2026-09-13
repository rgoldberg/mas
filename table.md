# Table Output Option

Uses the custom EBNF grammar defined in [ebnf.md](ebnf.md).

`--table` selects table output for a display command (see
[fields.md](fields.md) for `--fields`, which drives field selection,
labeling, formatting & sorting independent of the output format).
`--table`'s own, optional value configures the table's header row,
separator line & column spacing.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
table-value  = [ <table-option>+ ] (* ad hoc order; last 1 per axis wins *)
table-option = <header-option> | <separator-option> | <broken-option> | <column-spacing-option>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Header

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
header-option = <header-off> | <header-on>
header-off    = "h"
header-on     = "H" [ <sgr-parameters> ] ( <table-value-terminator> | <end-of-shell-word> )

sgr-parameters          = <sgr-parameter> … <sgr-parameter-separator>
sgr-parameter           = {non-negative integer}
sgr-parameter-separator = ";"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `h`: no header row. The default, absent `--table` entirely, or absent any
  header / separator option in `--table`'s value.
- `H`: a header row of field labels. `<sgr-parameters>`, if given, are raw
  ANSI SGR parameters (e.g., `1` for bold, `1;4` for bold & underlined)
  applied to the whole header row; absent, the header row is unstyled.

## Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
separator-option  = <separator-off> | <separator-on>
separator-off     = "s"
separator-on      = "S" [ <separator-pattern> ] ( <table-value-terminator> | <end-of-shell-word> )
separator-pattern = {text}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no separator line. The default.
- `S`: a line between the header row & the 1st data row. Its pattern (the
  text between `S` & `<table-value-terminator>`) is repeated to fill the
  line, cutting off immediately (never padding) if it doesn't evenly divide
  the line's width. Absent, the pattern is empty (a blank line).

## Broken

```ebnf
broken-option = <broken> | <unbroken>
broken        = "b"
unbroken      = "u"
```

Meaningless without a separator line (see "Implied Options" below for what
happens when 1 isn't otherwise present).

- `b`: the separator line is broken into 1 independently-filled segment per
  column, joined by the same column spacing as every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  whole table's width. The default, when a separator line exists.

## Column Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
column-spacing-option  = <column-spacing-default> | <column-spacing-custom>
column-spacing-default = "c"
column-spacing-custom  = "C" [ <column-spacing> ] ( <table-value-terminator> | <end-of-shell-word> )
column-spacing         = {text}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: resets column spacing to the built-in default (currently 2 spaces);
  tracks the default's own current value, rather than fixing today's value
  literally.
- `C`: a literal custom spacing string between adjacent columns (e.g., `C:`
  for no spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a literal tab
  character, e.g., `$'C\t:'` in zsh). Absent both `c` & `C`, the built-in
  default applies.

## Terminator

```ebnf
table-value-terminator = ":"
end-of-shell-word      = {the end of --table's whole value}
```

Closes an `H` / `S` / `C` option's value: each of those options' value
otherwise runs through the rest of `--table`'s whole value (i.e., the whole
shell word), with no other way to end early. `<table-value-terminator>` is
therefore omittable only at `<end-of-shell-word>`; anywhere else, whatever
follows is read as (part of) that option's value, e.g., in `--table Hb`, `b`
is read as (invalid) `<sgr-parameters>` text, not as a separate
`<broken-option>`.

## Implied Options

- `b` / `u` imply a separator line, if none is otherwise set: `S-` (a dashed
  line), not a blank 1, since a blank line would defeat the point of
  distinguishing broken from unbroken.
- Any separator line (explicit or implied) implies a header row, if none is
  otherwise set: `H` (unstyled), since a separator line's whole point is to
  separate a header from the data.

An option that explicitly sets an axis, even to "off" (`h` / `s`), always
wins over an axis's implied default, regardless of where in `--table`'s
value it appears.

## Examples

- `--table`: no header, no separator, 2-space columns.
- `--table H`: a plain header row, no separator.
- `--table H1:`: a bold header row (SGR `1`), no separator.
- `--table S`: a header row (implied) & a blank separator line.
- `--table b`: a header row (implied) & a dashed (`-`), broken separator
  line.
- `--table S-+:b`: a header row (implied) & a `-+`-patterned, broken
  separator line.
- `--table C....`: no header, no separator, `....` between columns.

## Escaping

Per [ebnf.md's token rules](ebnf.md#tokens), a bare `<table-value-terminator>`
(`:`) ends a `<separator-pattern>` or `<column-spacing>`; escape it (`\:`) to
include it, & write a literal `\` as `\\`.
