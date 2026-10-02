# JSON Output Option

`--json` is an optional option of every [display
command](configs.md#display-commands).

It selects JSON output, configuring its pretty-printing, top-level structure &
non-ASCII character rendering.

Uses the [custom EBNF grammar](ebnf.md).

## JSON Config

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
json-option = "--json" [ &<json-config> ]

json-config  = [ <json-setting>+ ] (* last wins; default: "" *)
json-setting = <pretty-printing-setting> | <top-level-structure-setting> | <non-ascii-setting>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **JSON config** is a [named config](configs.md#named-configs) of the JSON
kind.

`--json` output sources from the context stack's
[`default`](configs.md#default-configs) JSON config; `<json-config>` is overlaid
on it for the current command line only, without persistently affecting it. Each
setting's default applies iff neither sets it.

The [built-in](configs.md#immutable-built-in-named-configs) `standard` JSON
config sets every `<json-setting>` to its default.

## Pretty-Printing

```ebnf
pretty-printing-setting = <compact> | <pretty-printed> (* default: <compact> *)

compact        = "p"
pretty-printed = "P" [ <indentation> ] <json-setting-termination>

indentation = ^{text: only spaces & tabs}^ (* default: "  " *)
```

- `p`: each top-level JSON value is rendered on 1 line, with no whitespace
  outside strings.
- `P`: each top-level JSON value is rendered with each object member & each
  array element on its own line, indented by 1 `<indentation>` per nesting
  level, and with 1 space after each `:` between a key & its value (e.g., `P:`
  for 2 spaces, `P<TAB>:` for a tab, where `<TAB>` is a literal tab character,
  e.g., `$'P\t:'` in zsh).

## Top-Level Structure

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
top-level-structure-setting = <item-stream> | <item-array> (* default: <item-stream> *)

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
non-ascii-setting = <non-ascii-verbatim> | <non-ascii-escaped> (* default: <non-ascii-verbatim> *)

non-ascii-verbatim = "v"
non-ascii-escaped  = "e"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Applies to every key & every string value.

- `v`: each non-ASCII character is rendered verbatim, encoded as UTF-8.
- `e`: each non-ASCII character is rendered as a JSON `\uXXXX` escape sequence
  (a UTF-16 surrogate pair of them for a character outside the Basic
  Multilingual Plane), so the output contains only ASCII characters.

## JSON Setting Termination

```ebnf
json-setting-termination = <json-setting-terminator> | <end-of-json-config>

json-setting-terminator = ":"
end-of-json-config      = {end of <json-config>}
```

E.g., in `--json Pa`, `a` is interpreted as invalid `<indentation>` text, not as
a separate `<top-level-structure-setting>`.

## Examples

- `--json`: 1 compact JSON object per item, 1 per line.
- `--json P`: 1 pretty-printed JSON object per item, indented by 2 spaces.
- `--json a`: a single compact JSON array of every item, on 1 line.
- `--json aP`: a single pretty-printed JSON array of every item, indented by 2
  spaces.
- `--json $'P\t:a'`: a single pretty-printed JSON array of every item, indented
  by tabs.
- `--json e`: 1 compact, ASCII-only JSON object per item, 1 per line.
