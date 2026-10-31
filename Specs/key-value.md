# Key-Value Output Options

`--key-value` & `--key-value-config` are optional options of every [display
command](configs.md#display-commands).

Each selects key-value output; `--key-value-config` also configures its key
styling, leader, leading spacing, trailing spacing & item separator line.

Uses the [custom EBNF grammar](ebnf.md).

## Key-Value Config

```ebnf
key-value-config  = <key-value-setting>+
key-value-setting =
  <key-setting>
  | <key-styling-setting>
  | <key-style-prefix-setting>
  | <key-style-suffix-setting>
  | <key-style-reset-setting>
  | <leader-setting>
  | <leading-spacing-setting>
  | <trailing-spacing-setting>
  | <item-separator-setting>
```

`--key-value-config` is key-value output's [output config
option](configs.md#output-configs), whose syntax is `<key-value-config>`.

A **key-value config** is a [named config](configs.md#named-configs) of the
key-value kind.

Each row of an item is its key, its leading spacing, its leader, its trailing
spacing, then its value.

Each [line terminator](configs.md#line-terminators) in a key is rendered as `⏎`,
so each key is 1 line. Each line terminator in a value is rendered as a newline
(e.g., a CRLF as 1 LF), so the value continues on a new line, each such
non-empty line indented by spaces to the value's start (e.g., with `fL=:R:`, the
key `Notes` & a value of `a` & `b` separated by an LF render as `Notes=a`, then
6 spaces & `b` on the next line).

## Key

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-setting = <unstyled-key> | <styled-key> (* default: <unstyled-key>; last wins; inherited *)

unstyled-key = "k"
styled-key   = "K" <style-specifier> <key-value-setting-termination>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `k`: unstyled keys.
- `K`: keys styled by `<style-specifier>`, as [defined for table
  output](table.md#header) (e.g., with the default [style
  prefix](#key-style-prefix), [style suffix](#key-style-suffix) & [style
  reset](#key-style-reset), `1` for bold, `1;4` for bold & underlined), applied
  to each key, but not to its spacing, its leader, or its value.

## Key Styling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-styling-setting = <key-terminal-only-styling> | <key-always-styling> (* default: <key-terminal-only-styling>; last wins; inherited *)

key-terminal-only-styling = "t"
key-always-styling        = "a"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<key-styling-setting>` is as [`<header-styling-setting>` is defined for table
output](table.md#header-styling):

- `t`: keys are styled iff standard output is a terminal.
- `a`: keys are always styled, even if standard output is not a terminal, e.g.,
  when piped to `less -R`.

## Key Style Prefix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-style-prefix-setting = <key-style-prefix-default> | <key-style-prefix-custom> (* default: <key-style-prefix-default>; last wins; inherited *)

key-style-prefix-default = "p" (* default style-prefix: {ESC [} *)
key-style-prefix-custom  = "P" [ <style-prefix> ] <key-value-setting-termination>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<style-prefix>` is as [defined for table output](table.md#style-prefix):

- `p`: `ESC[` (the ANSI control sequence introducer, where `ESC` is U+001B)
  precedes `<style-specifier>`.
- `P`: a literal custom string precedes `<style-specifier>` (e.g., `P:` for
  none).

## Key Style Suffix

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-style-suffix-setting = <key-style-suffix-default> | <key-style-suffix-custom> (* default: <key-style-suffix-default>; last wins; inherited *)

key-style-suffix-default = "x" (* default style-suffix: "m"; mnemonic: suffix *)
key-style-suffix-custom  = "X" [ <style-suffix> ] <key-value-setting-termination> (* mnemonic: suffix *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<style-suffix>` is as [defined for table output](table.md#style-suffix):

- `x`: `m` (the ANSI SGR control sequence's final byte) follows
  `<style-specifier>`.
- `X`: a literal custom string follows `<style-specifier>` (e.g., `X:` for
  none).

## Key Style Reset

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-style-reset-setting = <key-style-reset-default> | <key-style-reset-custom> (* default: <key-style-reset-default>; last wins; inherited *)

key-style-reset-default = "o" (* default style-reset: {ESC [0m}; mnemonic: off *)
key-style-reset-custom  = "O" [ <style-reset> ] <key-value-setting-termination> (* mnemonic: off *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<style-reset>` is as [defined for table output](table.md#style-reset):

- `o`: `ESC[0m` (the ANSI SGR reset) follows each styled key.
- `O`: a literal custom string follows each styled key (e.g., `O:` for none).

## Leader

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
leader-setting = <leader-off> | <leader-on> (* default: <leader-on>; last wins; inherited *)

leader-off = "f" (* default leader-pattern: {empty string}; mnemonic: fill *)
leader-on  = "F" [ <leader-pattern> ] <key-value-setting-termination> (* mnemonic: fill *)

leader-pattern = ^{text: no line terminators}^ (* default: "▁" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `f`: an empty leader, so an item's values are not aligned; an effective `f`
  [implies a leading spacing](#implied-alternatives).
- `F`: a leader between each key & its value, aligning all of an item's values.
  `<leader-pattern>` is repeated to fill the leader's [width](configs.md#width),
  truncated before the 1st character that would exceed that width; spaces fill
  any remaining width (e.g., when that character is wide, such as `中`). A
  leader's width is the width of its item's widest key, less the width of its
  own key, plus the width of `<leader-pattern>`, so the widest key's leader is 1
  `<leader-pattern>`. A 0-width `<leader-pattern>` (e.g., a tab) is printed
  once, with no space-fill, because no number of repetitions can fill any width.
  A `<leader-pattern>` that contains a [line
  terminator](configs.md#line-terminators) is invalid, because it would split
  each row.

## Leading Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
leading-spacing-setting = <leading-spacing-default> | <leading-spacing-custom> (* default: <leading-spacing-default>; last wins; inherited *)

leading-spacing-default = "l" (* default leading-spacing: " " *)
leading-spacing-custom  = "L" [ <leading-spacing> ] <key-value-setting-termination>

leading-spacing = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `l`: 1 space after each key.
- `L`: a literal custom spacing string after each key (e.g., `L:` for no leading
  spacing, `L<TAB>:` for a tab, where `<TAB>` is a literal tab character, e.g.,
  `$'L\t:'` in zsh). A `<leading-spacing>` that contains a [line
  terminator](configs.md#line-terminators) is invalid, because it would split
  each row.

## Trailing Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
trailing-spacing-setting = <trailing-spacing-default> | <trailing-spacing-custom> (* default: <trailing-spacing-default>; last wins; inherited *)

trailing-spacing-default = "r" (* default trailing-spacing: " "; mnemonic: right *)
trailing-spacing-custom  = "R" [ <trailing-spacing> ] <key-value-setting-termination> (* mnemonic: right *)

trailing-spacing = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `r`: 1 space before each value.
- `R`: a literal custom spacing string before each value (e.g., `R:` for no
  trailing spacing). A `<trailing-spacing>` that contains a line terminator is
  invalid, because it would split each row.

## Item Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
item-separator-setting = <item-separator-off> | <item-separator-on> (* default: <item-separator-on>; last wins; inherited *)

item-separator-off = "s"
item-separator-on  = "S" [ <item-separator-line> ] <key-value-setting-termination>

item-separator-line = ^{text: no line terminators}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no item separator line; each item's 1st row immediately follows the
  previous item's last row.
- `S`: `<item-separator-line>`, output as is, between each pair of adjacent
  items (e.g., `S---:` outputs `---`), so its width depends on no item, and an
  empty `<item-separator-line>` renders a blank line. An `<item-separator-line>`
  that contains a line terminator is invalid, because it would split the item
  separator line.

An item without any key-value pair has no rows, but is still an item, so the
item separator lines on each side of it remain (e.g., with `S---:`, such an item
between 2 others leaves 2 adjacent `---` lines), unless no item has a key-value
pair, in which case nothing is rendered.

## Key-Value Setting Termination

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-value-setting-termination = <key-value-setting-terminator> | <end-of-key-value-config>

key-value-setting-terminator = ":"
end-of-key-value-config      = end
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

E.g., in `--key-value-config Fs`, `s` is interpreted as `<leader-pattern>` text,
not as a separate `<item-separator-setting>`.

## Implied Alternatives

- An effective `f` implies a leading spacing of `:` (i.e., `L\::`), so each row
  is `key: value` (e.g., `fF:` implies none, so its leading spacing is `l`'s 1
  space).

An implied alternative yields to an explicit alternative of its setting & to an
inherited [payload](configs.md#output-configs), as [output configs
specify](configs.md#implied-alternatives) (e.g., `fl` has `l`'s leading spacing;
with an inherited `l`, `f` implies `key: value` rows, while with an inherited
`L=:`, `f` retains `key= value` rows).

## Examples

- `--key-value`: unstyled keys, values aligned by a `▁`-patterned leader (with 1
  space on each side) & a blank line between items.
- `--key-value-config K1:`: bold keys (SGR `1`) iff standard output is a
  terminal.
- `--key-value-config K1:a`: bold keys (SGR `1`) regardless of standard output.
- `--key-value-config 'K\b:P<:X>:O</b>:a'`: keys wrapped in `<b>` & `</b>` tags
  regardless of standard output.
- `--key-value-config F.:`: values aligned by a dotted (`.`) leader.
- `--key-value-config 'F :L:R:'`: values aligned by spaces, with 1 space after
  each item's widest key.
- `--key-value-config 'L\::F :R:'`: `key:` rows with values aligned by spaces,
  with 1 space after each item's widest `key:`.
- `--key-value-config f`: `key: value` rows (implied leading spacing).
- `--key-value-config fL=:R:`: `key=value` rows, with a blank line between
  items.
- `--key-value-config S===`: a `===` line between items.
- `--key-value-config s`: no line between items.

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

| `{text}`                | Any                 |
|:------------------------|:--------------------|
| `<style-specifier>`     | `:` & ASCII letters |
| `<style-prefix>`        | `:`                 |
| `<style-suffix>`        | `:`                 |
| `<style-reset>`         | `:`                 |
| `<leader-pattern>`      | `:`                 |
| `<leading-spacing>`     | `:`                 |
| `<trailing-spacing>`    | `:`                 |
| `<item-separator-line>` | `:`                 |
