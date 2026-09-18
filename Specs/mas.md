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

`mas`'s built-in fields configs have `@table` & `@key-value` variants whose
field specs may have human-facing labels & formats. Their `@json` variants'
field specs use each field's name as its label & `%i` as its format. The 3
fields configs for the same leaf context differ only in which field specs are
hidden.

`standard@json` is always a reference to `all`.

## Default Sort Options

Price fields' default formats use `%_n` & version fields' `%v`, so they are
typed & compare per type; the sort options below apply to string fields:

| Format    | Type | Default            |
|:----------|:-----|:-------------------|
| Table     | Text | `Iailg`            |
| Table     | Path | `IailgB/_:space:+` |
| Key-Value | Text | `Iailg`            |
| Key-Value | Path | `IailgB/_:space:+` |
| JSON      | Text | `Iascgb`           |
| JSON      | Path | `IascgB/+`         |
