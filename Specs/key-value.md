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

`--key-value-config`'s [value](configs.md#option-values), iff non-empty, is a
`<key-value-config>`.

A **key-value config** is a [named config](configs.md#named-configs) of the
key-value kind.

Key-value output sources from the context stack's
[`default`](configs.md#default-configs) key-value config; `<key-value-config>`
is overlaid on it for the current command line only, without persistently
affecting it. Each setting's default applies iff neither sets it.

The [built-in standard](configs.md#immutable-built-in-named-configs) key-value
config sets every `<key-value-setting>` to its default.

Each row of an item is its key, its leading spacing, its leader, its trailing
spacing, then its value.

## Key

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-setting = <unstyled-key> | <styled-key> (* default: <unstyled-key>; last wins *)

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
key-styling-setting = <key-terminal-only-styling> | <key-always-styling> (* default: <key-terminal-only-styling>; last wins *)

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
key-style-prefix-setting = <key-style-prefix-default> | <key-style-prefix-custom> (* default: <key-style-prefix-default>; last wins *)

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
key-style-suffix-setting = <key-style-suffix-default> | <key-style-suffix-custom> (* default: <key-style-suffix-default>; last wins *)

key-style-suffix-default = "x" (* default style-suffix: "m"; mnemonic: suffix *)
key-style-suffix-custom  = "X" [ <style-suffix> ] <key-value-setting-termination> (* mnemonic: suffix *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<style-suffix>` is as [defined for table output](table.md#style-suffix):

- `x`: `m` (the ANSI SGR final character) follows `<style-specifier>`.
- `X`: a literal custom string follows `<style-specifier>` (e.g., `X:` for
  none).

## Key Style Reset

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-style-reset-setting = <key-style-reset-default> | <key-style-reset-custom> (* default: <key-style-reset-default>; last wins *)

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
leader-setting = <leader-off> | <leader-on> (* default: <leader-on>; last wins *)

leader-off = "f" (* default leader-pattern: {empty string}; mnemonic: fill *)
leader-on  = "F" [ <leader-pattern> ] <key-value-setting-termination> (* mnemonic: fill *)

leader-pattern = ^{text}^ (* default: "▁" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `f`: an empty leader, so an item's values are not aligned; it [implies a
  leading spacing](#implied-settings).
- `F`: a leader between each key & its value, aligning all of an item's values.
  `<leader-pattern>` is repeated to fill the leader's width, truncated before
  the 1st character that would exceed that width; spaces fill any remaining
  width (e.g., when that character is wide, such as `中`). A leader's width is
  the width of its item's widest key, less the width of its own key, plus the
  width of `<leader-pattern>`, so the widest key's leader is a single
  `<leader-pattern>`. A 0-width `<leader-pattern>` (e.g., a tab) is printed
  once, because no number of repetitions can fill any width. A
  `<leader-pattern>` that contains a [line
  terminator](configs.md#line-terminators) is invalid, because it would split
  each row.

## Leading Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
leading-spacing-setting = <leading-spacing-default> | <leading-spacing-custom> (* default: <leading-spacing-default>; last wins *)

leading-spacing-default = "l" (* default leading-spacing: " " *)
leading-spacing-custom  = "L" [ <leading-spacing> ] <key-value-setting-termination>

leading-spacing = ^{text}^ (* default: {empty string} *)
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
trailing-spacing-setting = <trailing-spacing-default> | <trailing-spacing-custom> (* default: <trailing-spacing-default>; last wins *)

trailing-spacing-default = "r" (* default trailing-spacing: " "; mnemonic: right *)
trailing-spacing-custom  = "R" [ <trailing-spacing> ] <key-value-setting-termination> (* mnemonic: right *)

trailing-spacing = ^{text}^ (* default: {empty string} *)
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
item-separator-setting = <item-separator-off> | <item-separator-on> (* default: <item-separator-on>; last wins *)

item-separator-off = "s"
item-separator-on  = "S" [ <item-separator-pattern> ] <key-value-setting-termination>

item-separator-pattern = ^{text}^ (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no item separator line; each item's 1st row immediately follows the
  previous item's last row.
- `S`: a line between each pair of adjacent items. `<item-separator-pattern>` is
  repeated to fill the width of the widest row of any item, truncated before the
  1st character that would exceed that width; spaces fill any remaining width
  (e.g., when that character is wide, such as `中`). A 0-width
  `<item-separator-pattern>` (e.g., a tab) is printed once, because no number of
  repetitions can fill any width, so an empty `<item-separator-pattern>` renders
  a blank line. An `<item-separator-pattern>` that contains a line terminator is
  invalid, because it would split the item separator line.

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

## Implied Settings

- `f` implies a leading spacing of `:` (i.e., `L\::`), if none is otherwise set,
  so each row is `key: value`.

A setting that explicitly sets an axis (e.g., `l`) always overrides that axis's
implied setting, regardless of where in `<key-value-config>` it appears.

A setting implied by `<key-value-config>` overrides inherited settings.

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
- `--key-value-config S=`: a `=`-patterned line between items.
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

| `{text}`                   | Any                 |
|:---------------------------|:--------------------|
| `<style-specifier>`        | `:` & ASCII letters |
| `<style-prefix>`           | `:`                 |
| `<style-suffix>`           | `:`                 |
| `<style-reset>`            | `:`                 |
| `<leader-pattern>`         | `:`                 |
| `<leading-spacing>`        | `:`                 |
| `<trailing-spacing>`       | `:`                 |
| `<item-separator-pattern>` | `:`                 |
