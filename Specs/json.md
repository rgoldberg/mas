# JSON Output Options

`--json` & `--json-config` are optional options of every [display
command](configs.md#display-commands).

Each selects JSON output; `--json-config` also configures its pretty-printing,
top-level structure & non-ASCII character rendering.

Uses the [custom EBNF grammar](ebnf.md).

## JSON Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
json-config  = <json-setting>+
json-setting = <pretty-printing-setting> | <top-level-structure-setting> | <non-ascii-setting>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`--json-config` is JSON output's [output config
option](configs.md#output-configs), whose syntax is `<json-config>`.

A **JSON config** is a [named config](configs.md#named-configs) of the JSON
kind.

A key-value pair is output even if its key repeats another's (e.g.,
`--fields name=x,version=x` outputs 2 `x` keys, as does a field with 2
[members](fields.md#members)), because JSON does not forbid repeated keys,
though some consumers retain only 1 of them.

## Pretty-Printing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
pretty-printing-setting = <compact> | <pretty-printed> (* default: <compact>; last wins; inherited *)

compact        = "p" (* mnemonic: lowercase of P, as off *)
pretty-printed = "P" [ <indentation> ] <json-setting-termination>

indentation = ^{string: only spaces & tabs}^ (* default: "  " *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `p`: each top-level JSON value is rendered on 1 line, with no whitespace
  outside strings.
- `P`: each top-level JSON value is rendered with each object member & each
  array element on its own line, indented by 1 `<indentation>` per nesting level
  (e.g., `P:` for 2 spaces, `P<TAB>:` for a tab, where `<TAB>` is a tab
  character, e.g., `$'P\t:'` in zsh); each `:` between a key & its value is
  followed by 1 space.

## Top-Level Structure

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
top-level-structure-setting = <item-stream> | <item-array> (* default: <item-stream>; last wins; inherited *)

item-stream = "s"
item-array  = "a"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `s`: each item is a top-level JSON object, followed by a newline (with `p`,
  this is [JSON Lines](https://jsonlines.org)); 0 items render nothing.
- `a`: every item is an element of a single top-level JSON array, followed by a
  newline; 0 items render `[]`.

## Non-ASCII

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
non-ascii-setting = <non-ascii-verbatim> | <non-ascii-escaped> (* default: <non-ascii-verbatim>; last wins; inherited *)

non-ascii-verbatim = "v"
non-ascii-escaped  = "e"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Applies to every key & every string value.

- `v`: each non-ASCII character is rendered verbatim, encoded as UTF-8.
- `e`: each non-ASCII character is rendered as a JSON `\uXXXX` escape sequence
  with lowercase hex digits (e.g., `\u00e9` for `é`), or, for a character
  outside the Basic Multilingual Plane, as an escape sequence for each of its
  UTF-16 surrogates (e.g., `\ud83d\ude00` for `😀`), so the output contains only
  ASCII characters.

## JSON Setting Termination

```ebnf
json-setting-termination = <json-setting-terminator> | <end-of-json-config>

json-setting-terminator = ":"
end-of-json-config      = end
```

E.g., in `--json-config Pa`, `a` is an error (because `<indentation>` cannot
consume it), not a separate `<top-level-structure-setting>`.

## Examples

- `--json`: 1 compact JSON object per item, 1 per line.
- `--json-config P`: 1 pretty-printed JSON object per item, indented by 2
  spaces.
- `--json-config a`: a single compact JSON array of every item, on 1 line.
- `--json-config aP`: a single pretty-printed JSON array of every item, indented
  by 2 spaces.
- `--json-config $'P\t:a'`: a single pretty-printed JSON array of every item,
  indented by tabs.
- `--json-config e`: 1 compact, ASCII-only JSON object per item, 1 per line.
