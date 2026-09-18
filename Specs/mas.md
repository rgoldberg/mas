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

Items are apps, except for `config`, which has 1 item: the running `mas`
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

- A user-facing `@table` variant.
- A user-facing `@key-value` variant.
- A machine-facing `@json` variant.

`standard@json` is always a reference to `all`.

Default labels & formats favor:

- If user-facing: readability.
- If machine-facing: precision & parseability:
  - Label is the field name.
  - Format is `%i`.

## Default Sort Options

Price fields' default formats use `%_n` & version fields' `%v`, so they are
typed & compare per type; the sort options below apply to string fields:

| Format    | Field Kind | Default            |
|:----------|:-----------|:-------------------|
| Table     | Non-path   | `Iailg`            |
| Table     | Path       | `IailgB/_:space:+` |
| Key-Value | Non-path   | `Iailg`            |
| Key-Value | Path       | `IailgB/_:space:+` |
| JSON      | Non-path   | `Iascgb`           |
| JSON      | Path       | `IascgB/+`         |
