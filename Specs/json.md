# JSON Output

A JSON config configures JSON output's pretty-printing, top-level structure &
non-ASCII character rendering.

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

`<json-config>` is the JSON config kind's [output config
syntax](configs.md#output-configs).

A **JSON config** is a [named config](configs.md#named-configs) of the JSON
kind.

A key-value pair is output even if its key repeats another's (e.g.,
`name=x,version=x` outputs 2 `x` keys, as does a field with 2
[members](fields.md#members)), because JSON does not forbid repeated keys,
though some consumers retain only 1 of them.

In each key & each string value, each `"` & `\` is rendered as `\"` & `\\`, each
backspace, tab, LF, form feed & CR as `\b`, `\t`, `\n`, `\f` & `\r`, and each
other C0 control character (U+0000 to U+001F), each DEL (U+007F), each C1
control character (U+0080 to U+009F), each U+2028 & each U+2029 as a `\uXXXX`
escape sequence with lowercase hex digits (e.g., `\u001b` for an ESC & `\u009b`
for U+009B), because JSON requires each C0 control character to be escaped,
while a raw DEL would be invisible, a raw C1 control character would modify the
output device's state (e.g., U+009B, an 8-bit CSI, which starts an escape
sequence) & a raw U+2028 or U+2029 would be a [line
terminator](configs.md#line-terminators), so [`p`](#pretty-printing) would not
render a value on 1 line. Each other character, including `/`, is rendered
verbatim, except as [`e`](#non-ascii) escapes it.

Each number's text is rendered as JSON number syntax, modified only as that
syntax requires: without a leading `+`, without a `0` before another digit of
its integer part & with at least 1 digit before its `.`, but retaining its
trailing `0`s (e.g., `+01.50` as `1.50` & `.5` as `0.5`).

## Pretty-Printing

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
pretty-printing-setting = <compact> | <pretty-printed> (* default: <compact>; last wins; inherited *)

compact        = "p" (* mnemonic: lowercase of P, as off *)
pretty-printed = "P" [ <indentation> ] <setting-termination>

indentation = ^{string: only spaces, tabs, LFs & CRs}^ (* default: "  " *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `p`: each top-level JSON value is rendered on 1 line, with no whitespace
  outside strings.
- `P`: each top-level JSON value is rendered with each object member & each
  array element on its own line, indented by 1 `<indentation>` per nesting level
  (e.g., `P:` for 2 spaces, `P<TAB>:` for a tab); each `:` between a key & its
  value is followed by 1 space; each empty object or array, which has no member
  or element to put on its own line, is rendered as `{}` or `[]`, respectively
  (e.g., an item without any key-value pair).

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
- `a`: a single top-level JSON array holds every item as an element (0 items
  render `[]`), followed by a newline.

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

- `v`: each non-ASCII character other than a C1 control character, U+2028, or
  U+2029 is rendered verbatim, encoded as UTF-8.
- `e`: each non-ASCII character is rendered as a JSON `\uXXXX` escape sequence
  with lowercase hex digits (e.g., `\u00e9` for `é`), or, for a character
  outside the Basic Multilingual Plane, as an escape sequence for each of its
  UTF-16 surrogates (e.g., `\ud83d\ude00` for `😀`), so the output contains only
  ASCII characters.

## Examples

- An empty JSON config: 1 compact JSON object per item, 1 per line.
- `P`: 1 pretty-printed JSON object per item, indented by 2 spaces.
- `a`: a single compact JSON array of every item, on 1 line.
- `aP`: a single pretty-printed JSON array of every item, indented by 2 spaces.
- `P<TAB>:a`: a single pretty-printed JSON array of every item, indented by
  tabs.
- `e`: 1 compact, ASCII-only JSON object per item, 1 per line.
