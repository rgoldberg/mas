# mas Configuration

`mas`-specific configuration of the generic [configs](configs.md) & [`--fields`
option](fields.md).

## Display Commands

`mas` display commands, with their default output formats, are:

| Command    | Format    |
|:-----------|:----------|
| `config`   | key-value |
| `list`     | table     |
| `lookup`   | key-value |
| `outdated` | table     |
| `search`   | table     |

## Items

Items are apps, except for `config`, whose sole item is the running `mas`
process.

## Context Stacks

| Command List   | Most Specific Context | Least Specific Context |
|:---------------|:----------------------|:-----------------------|
| `mas config`   | `mas.config`          | `mas`                  |
| `mas list`     | `mas.list`            | `mas`                  |
| `mas lookup`   | `mas.lookup`          | `mas`                  |
| `mas outdated` | `mas.outdated`        | `mas`                  |
| `mas search`   | `mas.search`          | `mas`                  |

## Built-In Named Fields Configs

For the same `mas` leaf context & output format suffix, every field is in each
of `all`, `none` & the [built-in
standard](configs.md#immutable-built-in-named-configs):

- `all`: Every field spec is visible.
- `none`: `all`, with every field spec hidden & its sort disabled.
- Built-in standard: Its own visible field specs, followed by hidden copies of
  `all`'s field specs for every other field.

A `mas` built-in fields config has:

- A user-facing unsuffixed variant.
- A user-facing `@table` variant.
- A user-facing `@key-value` variant.
- A machine-facing `@json` variant.

For the same output format, its unsuffixed, `@table` & `@key-value` variants are
identical.

The built-in standard's `@json` variant is a reference to `all@json`.

Default labels & formats favor:

- If user-facing: readability.
- If machine-facing: precision & parsability:
  - Label is the field name.
  - Output is formatted as `%i`.

Field specs for `adamID` & `fileSizeBytes` are
[end-justified](fields-format.md#format-transforms); all others are
start-justified.

## Price Sorting

`formattedPrice`'s default sort options compare [grouped
numbers](fields.md#sort-number-segments) with the **App Store locale**'s
conventions as their [base conventions](fields-format.md#numberformat) & include
`a`, because its nonconforming values are almost always `Free` or a translation
of it, which equals 0.

The App Store's locale cannot be determined programmatically, so the App Store
locale is the locale of the App Store region that mas guesses from the macOS
region.

## Default Sort Options

The **version fields** are `minimumOSVersion`, `newVersion` & `version`. `path`
is the sole field whose string content is a path.

Field names' & labels' default sort options are those of non-path string
content.

Version fields' default sort options compare
[versions](fields.md#sort-number-segments) (`v`) & `formattedPrice`'s use the
[App Store locale's conventions & include `a`](#price-sorting), but they
otherwise match the following:

| Format            | String Content | Default              |
|:------------------|:---------------|:---------------------|
| Table / Key-Value | Non-path       | `I+iL:N:`            |
| Table / Key-Value | Path           | `I+iL:N:B/_+space+:` |
| JSON              | Non-path       | `I+sN:B:`            |
| JSON              | Path           | `I+sN:B/:`           |
