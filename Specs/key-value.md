# Key-Value Output

A key-value config configures key-value output's key styling, leader, leading
spacing, trailing spacing & item separator line.

Uses the [custom EBNF grammar](ebnf.md).

## Key-Value Config

```ebnf
key-value-config  = <key-value-setting>+
key-value-setting =
  <key-setting>
  | <styling-setting>
  | <style-prefix-setting>
  | <style-suffix-setting>
  | <style-reset-setting>
  | <leader-setting>
  | <leading-spacing-setting>
  | <trailing-spacing-setting>
  | <item-separator-setting>
```

`<key-value-config>` is the key-value config kind's [output config
syntax](configs.md#output-configs).

A **key-value config** is a [named config](configs.md#named-configs) of the
key-value kind.

Each row of an item is its key, its leading spacing, its leader, its trailing
spacing, then its value.

Each [line terminator](configs.md#line-terminators) & each other control
character in a key is rendered as it is in a [table cell](table.md#table-config)
(e.g., a tab as `␉`), so each key is 1 line & aligns its leader.

Each line terminator in a value is rendered as a newline (e.g., a CRLF as 1 LF),
so the value continues on a new line. Each such non-empty line is indented to
the value's start by its row's unstyled text before the value, after that text's
last line terminator, if any, with each tab retained & each other character
replaced by as many spaces as its [width](configs.md#width), so each tab reaches
the same tab stop as in the row, because a tab's rendered width depends on the
output device's tab stops, which an app cannot determine. E.g., the key `Notes`
& a value of `a` & `b` separated by an LF render, with:

- `fL=:R:`, as `Notes=a`, then 6 spaces & `b` on the next line.
- `fL<TAB>:R:`, as `Notes`, a tab & `a`, then 5 spaces, a tab & `b` on the next
  line.
- `fL<LF>:R  :`, as `Notes`, then 2 spaces & `a` on the next line, then 2 spaces
  & `b` on the line after.

Each other control character in a value, except a tab, is rendered as it is in a
key (e.g., an ESC as `␛`), because each would otherwise modify the output
device's state (e.g., an ESC, which starts an escape sequence) or move the
cursor back over the row (e.g., a backspace), while a tab, which only advances
the cursor to its next tab stop, follows everything that a value's line must
align with, so it misaligns nothing.

## Key

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-setting = <unstyled-key> | <styled-key> (* default: <unstyled-key>; last wins; inherited *)

unstyled-key = "k"
styled-key   = "K" <style-specifier> <setting-termination>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `k`: unstyled keys.
- `K`: keys styled by `<style-specifier>`, as [defined for table
  output](table.md#header) (e.g., with the default [style
  prefix](table.md#style-prefix), [style suffix](table.md#style-suffix) & [style
  reset](table.md#style-reset), `1` for bold, `1;4` for bold & underlined),
  applied to each key, but not to its spacing, its leader, or its value.

## Key Styling

`<styling-setting>`, `<style-prefix-setting>`, `<style-suffix-setting>` &
`<style-reset-setting>` are [defined for table output](table.md#styling).

## Leader

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
leader-setting = <leader-off> | <leader-on> (* default: <leader-on>; last wins; inherited *)

leader-off = "f" (* default leader-pattern: {empty string}; mnemonic: fill *)
leader-on  = "F" [ <leader-pattern> ] <setting-termination> (* mnemonic: fill *)

leader-pattern = ^{string}^ (* default: "▁" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `f`: an empty leader, so an item's values are not aligned; an effective `f`
  [implies a leading spacing](#implied-alternatives).
- `F`: a leader between each key & its value, aligning all of an item's values.
  `<leader-pattern>` is repeated to fill the leader's [width](configs.md#width),
  truncated before the 1st character that would exceed that width; spaces fill
  any remaining width (e.g., when that character is wide, such as `中`). A
  leader's width is the width of its item's widest rendered key, less the width
  of its own rendered key, plus the width of `<leader-pattern>`, so the widest
  key's leader is 1 `<leader-pattern>`. A 0-width `<leader-pattern>` (e.g., a
  tab) is rendered once, with no space-fill, because no number of repetitions
  can fill any width.

## Leading Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
leading-spacing-setting = <leading-spacing-default> | <leading-spacing-custom> (* default: <leading-spacing-default>; last wins; inherited *)

leading-spacing-default = "l" (* default leading-spacing: " " *)
leading-spacing-custom  = "L" [ <leading-spacing> ] <setting-termination>

leading-spacing = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `l`: 1 space after each key.
- `L`: a custom spacing string after each key (e.g., `L:` for no leading
  spacing, `fL<TAB>:` for a tab without a leader).

## Trailing Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
trailing-spacing-setting = <trailing-spacing-default> | <trailing-spacing-custom> (* default: <trailing-spacing-default>; last wins; inherited *)

trailing-spacing-default = "r" (* default trailing-spacing: " "; mnemonic: right *)
trailing-spacing-custom  = "R" [ <trailing-spacing> ] <setting-termination> (* mnemonic: right *)

trailing-spacing = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `r`: 1 space before each value.
- `R`: a custom spacing string before each value (e.g., `R:` for no trailing
  spacing).

## Item Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
item-separator-setting = <item-separator-off> | <item-separator-on> (* default: <item-separator-on>; last wins; inherited *)

item-separator-off = "s"
item-separator-on  = "S" [ <item-separator-line> ] <setting-termination>

item-separator-line = ^{string}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no item separator line; each item's 1st row immediately follows the
  previous item's last row.
- `S`: `<item-separator-line>`, output as is, between each pair of adjacent
  items (e.g., `S---:` outputs `---`), so its width depends on no item, and an
  empty `<item-separator-line>` renders a blank line.

An item without any key-value pair has no rows, but is still an item, so the
item separator lines on each side of it remain (e.g., with `S---:`, such an item
between 2 others leaves 2 adjacent `---` lines), unless no item has a key-value
pair, in which case nothing is rendered.

## Implied Alternatives

- An effective `f` implies a leading spacing of `:` (i.e., `L\::`), so each row
  is `key: value` (e.g., `fF:` implies none, so its leading spacing is `l`'s 1
  space).

An implied alternative yields to an explicit alternative of its setting &
retains an inherited [payload](configs.md#output-configs), as [output configs
specify](configs.md#implied-alternatives) (e.g., `fl` has `l`'s leading spacing;
with an inherited `l`, `f` implies `key: value` rows, while with an inherited
`L=:`, `f` retains `key= value` rows).

## Examples

- An empty key-value config: unstyled keys, values aligned by a `▁`-patterned
  leader (with 1 space on each side) & a blank line between items.
- `K1:`: bold keys (SGR `1`) iff normal output supports styling.
- `K1:a`: bold keys (SGR `1`) whether or not normal output supports styling.
- `K\b:P<:X>:O</b>:a`: keys wrapped in `<b>` & `</b>` tags whether or not normal
  output supports styling.
- `F.:`: values aligned by a dotted (`.`) leader.
- `F :L:R:`: values aligned by spaces, with 1 space after each item's widest
  key.
- `L\::F :R:`: `key:` rows with values aligned by spaces, with 1 space after
  each item's widest `key:`.
- `f`: `key: value` rows (implied leading spacing).
- `fL=:R:`: `key=value` rows, with a blank line between items.
- `S===`: a `===` line between items.
- `s`: no line between items.

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

| Nonterminal             | Any                 |
|:------------------------|:--------------------|
| `<style-specifier>`     | `:` & ASCII letters |
| `<style-prefix>`        | `:`                 |
| `<style-suffix>`        | `:`                 |
| `<style-reset>`         | `:`                 |
| `<leader-pattern>`      | `:`                 |
| `<leading-spacing>`     | `:`                 |
| `<trailing-spacing>`    | `:`                 |
| `<item-separator-line>` | `:`                 |
