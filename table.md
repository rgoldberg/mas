# Table Output Option

Uses the custom EBNF grammar defined in [ebnf.md](ebnf.md).

`--table` selects table output for a display command (see
[fields.md](fields.md) for `--fields`, which drives field selection,
labeling, formatting, & sorting independent of the output format).
`--table`'s own, optional value configures the table's header row,
separator line, & column spacing.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
table-value  = { <table-option> } (* ad hoc order; last 1 per axis wins *)
table-option = <header-option> | <separator-option> | <broken-option> | <column-spacing-option>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Header

```ebnf
header-option = <header-off> | <header-on>
header-off    = "h"
header-on     = "H" [ <sgr-parameters> ] [ <table-value-terminator> ]

sgr-parameters = {positive integer} ( ";" {positive integer} )*
```

- `h`: no header row. The default, absent `--table` entirely, or absent any
  header / separator option in `--table`'s value.
- `H`: a header row of field labels. `<sgr-parameters>`, if given, are raw
  ANSI SGR parameters (e.g., `1` for bold, `1;4` for bold & underlined)
  applied to the whole header row; absent, the header row is unstyled.

## Separator

```ebnf
separator-option = <separator-off> | <separator-on>
separator-off     = "s"
separator-on      = "S" [ {text} ] [ <table-value-terminator> ]
```

- `s`: no separator line. The default.
- `S`: a line between the header row & the 1st data row. Its pattern (the
  text between `S` & `<table-value-terminator>`) is repeated to fill the
  line, cutting off immediately (never padding) if it doesn't evenly divide
  the line's width. Absent, the pattern is empty (a blank line).

## Broken

```ebnf
broken-option = "b" | "u"
```

Meaningless without a separator line (see "Implied Options" below for what
happens when 1 isn't otherwise present).

- `b`: the separator line is broken into 1 independently-filled segment per
  column, joined by the same column spacing as every other row.
- `u`: the separator line is 1 continuous, column-unaware line spanning the
  whole table's width. The default, when a separator line exists.

## Column Spacing

```ebnf
column-spacing-option  = <column-spacing-default> | <column-spacing-custom>
column-spacing-default = "c"
column-spacing-custom  = "C" {text} <table-value-terminator>
```

- `c`: resets column spacing to the built-in default (currently 2 spaces) —
  tracks the default's own current value, rather than fixing today's value
  literally.
- `C`: a literal custom spacing string between adjacent columns (e.g., `C:`
  for no spacing at all, `C\t:` for a tab). Absent both `c` & `C`, the
  built-in default applies.

## Terminator

```ebnf
table-value-terminator = ":"
```

Closes an `H` / `S` / `C` option's value. Needed only when what follows
wouldn't otherwise unambiguously end it (i.e., isn't itself the end of
`--table`'s whole value, or another option letter that couldn't be mistaken
for more of the same value) — otherwise, whatever follows is read as (part
of) an attempted, likely invalid, value.

## Implied Options

- `b` / `u` imply a separator line, if none is otherwise set: `S-` (a dashed
  line), not a blank 1, since a blank line would defeat the point of
  distinguishing broken from unbroken.
- Any separator line (explicit or implied) implies a header row, if none is
  otherwise set: `H` (unstyled) — a separator line's whole point is to
  separate a header from the data.

An option that explicitly sets an axis — even to "off" (`h` / `s`) — always
wins over an axis's implied default, regardless of where in `--table`'s
value it appears.

## Examples

- `--table`: no header, no separator, 2-space columns (identical to `mas`'s
  historical, pre-`--table`-configuration output).
- `--table H`: a plain header row, no separator.
- `--table H1:`: a bold header row (SGR `1`), no separator.
- `--table S`: a header row (implied) & a blank separator line.
- `--table b`: a header row (implied) & a dashed (`-`), broken separator
  line.
- `--table S-+:b`: a header row (implied) & a `-+`-patterned, broken
  separator line.
- `--table C....:`: no header, no separator, `....` between columns.
