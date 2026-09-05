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

`none`, `all` & `standard` variants with the same output format suffix for the
same `mas` leaf context differ only in which field specs are hidden.

A `mas` built-in fields config has:

- A user-facing unsuffixed variant.
- A user-facing `@table` variant.
- A user-facing `@key-value` variant.
- A machine-facing `@json` variant.

`standard@json` is always a reference to `all`.

Default labels & formats favor:

- If user-facing: readability.
- If machine-facing: precision & parsability:
  - Label is the field name.
  - Format is `%i`.

## Price Coercion

Price fields' default formats coerce numbers with `.*` as both
`<trivia-prefix-regex>` & `<trivia-suffix-regex>`, and with the **App Store
locale**'s conventions as their [base
conventions](fields-format.md#numberformat).

Price fields' default formats are `%.:…:N%i+%i+`, so they are typed as numbers,
but render the field value as is, whether it conforms (e.g., `$1,299.99`,
retaining its digit group separators, instead of the coerced value `$1299.99`)
or not (e.g., `Free`).

The App Store's locale cannot be determined programmatically, so the App Store
locale is the locale of the App Store region that mas guesses from the macOS
region.

`formattedPrice`'s default sort options include `y`, because its nonconforming
values are almost always `Free` or a translation of it, which equals 0.

## Default Sort Options

Price fields' default formats use [`%.:…:N%i+%i+`](#price-coercion) & version
fields' `%v`, so they are typed & compare per type; the sort options below apply
to string fields:

| Format    | String Content | Default            |
|:----------|:---------------|:-------------------|
| Table     | Non-path       | `Iailg`            |
| Table     | Path           | `IailgB/_:space:+` |
| Key-Value | Non-path       | `Iailg`            |
| Key-Value | Path           | `IailgB/_:space:+` |
| JSON      | Non-path       | `Iascgb`           |
| JSON      | Path           | `IascgB/+`         |
