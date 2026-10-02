# Key-Value Output Option

`--key-value` is an optional option of every [display
command](configs.md#display-commands).

It selects key-value output, configuring its key styling, leader, key-value
spacing & item separator line.

Uses the [custom EBNF grammar](ebnf.md).

## Key-Value Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-value-option = "--key-value" [ &<key-value-config> ]

key-value-config  = [ <key-value-setting>+ ] (* last wins; default: "" *)
key-value-setting = <key-setting> | <key-styling-setting> | <leader-setting> | <key-value-spacing-setting> | <item-separator-setting>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **key-value config** is a [named config](configs.md#named-configs) of the
key-value kind.

`--key-value` output sources from the context stack's
[`default`](configs.md#default-configs) key-value config; `<key-value-config>`
is overlaid on it for the current command line only, without persistently
affecting it. Each setting's default applies iff neither sets it.

The [built-in](configs.md#immutable-built-in-named-configs) `standard` key-value
config sets every `<key-value-setting>` to its default.

Each row of an item is its key, its leader, then its value, with
`<key-value-spacing>` on each side of the leader (or once between the key & the
value, iff there is no leader).

## Key

```ebnf
key-setting = <unstyled-key> | <styled-key> (* default: <unstyled-key> *)

unstyled-key = "k"
styled-key   = "K" <sgr-parameters> <key-value-setting-termination>
```

- `k`: unstyled keys.
- `K`: keys styled by `<sgr-parameters>`, as [defined for table
  output](table.md#header) (e.g., `1` for bold, `1;4` for bold & underlined),
  applied to each key, but not to its leader, its key-value spacing, or its
  value.

## Key Styling

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-styling-setting = <terminal-only-styling> | <always-styling> (* default: <terminal-only-styling> *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<terminal-only-styling>` & `<always-styling>` are as [defined for table
output](table.md#header-styling):

- `t`: `<sgr-parameters>` are applied iff standard output is a terminal.
- `a`: `<sgr-parameters>` are always applied, even if standard output is not a
  terminal, e.g., when piped to `less -R`.

## Leader

```ebnf
leader-setting = <leader-off> | <leader-on> (* default: <leader-on> *)

leader-off = "l"
leader-on  = "L" [ <leader-pattern> ] <key-value-setting-termination>

leader-pattern = ^{text}^ (* default: "▁" *)
```

- `l`: no leader; each value immediately follows its key's key-value spacing, so
  an item's values are not aligned.
- `L`: a leader between each key & its value, aligning all of an item's values.
  `<leader-pattern>` is repeated to fill the leader's width, truncated at that
  width iff it does not evenly divide the width. A leader's width is the width
  of its item's widest key, less the width of its own key, plus the width of
  `<leader-pattern>`, so the widest key's leader is a single `<leader-pattern>`.
  A 0-width `<leader-pattern>` (e.g., a tab) is printed once, since no number of
  repetitions can fill any width.

## Key-Value Spacing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-value-spacing-setting = <key-value-spacing-default> | <key-value-spacing-custom> (* default: <key-value-spacing-default> *)

key-value-spacing-default = "c"
key-value-spacing-custom  = "C" [ <key-value-spacing> ] <key-value-setting-termination>

key-value-spacing = ^{text}^ (* direct default: ""; transitive default: " " *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `c`: resets key-value spacing to `<key-value-spacing>`'s transitive default.
- `C`: a literal custom spacing string on each side of the leader (e.g., `C:`
  for no spacing at all, `C<TAB>:` for a tab, where `<TAB>` is a literal tab
  character, e.g., `$'C\t:'` in zsh).

## Item Separator

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
item-separator-setting = <item-separator-off> | <item-separator-on> (* default: <item-separator-on> *)

item-separator-off = "s"
item-separator-on  = "S" [ <item-separator-pattern> ] <key-value-setting-termination>

item-separator-pattern = ^{text}^ (* default: "" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: no item separator line; each item's 1st row immediately follows the
  previous item's last row.
- `S`: a line between each pair of adjacent items. `<item-separator-pattern>` is
  repeated to fill the width of the widest row of any item, truncated at that
  width iff it does not evenly divide the width. A 0-width
  `<item-separator-pattern>` (e.g., a tab) is printed once, since no number of
  repetitions can fill any width, so an empty `<item-separator-pattern>` renders
  a blank line.

## Key-Value Setting Termination

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
key-value-setting-termination = <key-value-setting-terminator> | <end-of-key-value-config>

key-value-setting-terminator = ":"
end-of-key-value-config      = {end of <key-value-config>}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

E.g., in `--key-value Ls`, `s` is interpreted as `<leader-pattern>` text, not as
a separate `<item-separator-setting>`.

## Examples

- `--key-value K1:`: bold keys (SGR `1`) iff standard output is a terminal.
- `--key-value K1:a`: bold keys (SGR `1`) regardless of standard output.
- `--key-value L.:`: values aligned by a dotted (`.`) leader.
- `--key-value 'L :C:'`: values aligned by spaces, with 1 space after each
  item's widest key.
- `--key-value lC=`: `key=value` rows, with a blank line between items.
- `--key-value S=`: a `=`-patterned line between items.
- `--key-value s`: no line between items.

## Appendix: Escaping

[For a text token to consume text that would otherwise match a syntax literal, 1
or more of its characters must be escaped by prefixing it with a
`\`.](ebnf.md#tokens)

Throughout all text tokens, a literal `\` is written `\\`, because `\` always
escapes the next character.

In each row of the table below, the given characters must be escaped to be
consumed as any character in a text token consumed by the given text terminal.
Leading & trailing outer bare whitespace is consumed.

| `{text}`                   | Any |
|:---------------------------|:----|
| `<leader-pattern>`         | `:` |
| `<key-value-spacing>`      | `:` |
| `<item-separator-pattern>` | `:` |
