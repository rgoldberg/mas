# mas Field-Selection Configuration

`mas`-specific configuration of the generic [field-selection option](fields.md).

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

Items are apps, except for `config`, which has a single item: the running `mas`
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

`mas`'s built-in `standard` & `all` fields configs have `@table` & `@key-value`
variants whose field specs may have human-facing labels & formats. Their
`@json` variants' field specs use each field's name as its label & `%v` as its
format, since JSON output is machine-consumed.

`standard@json` is always a reference to `all`.

## Default Sort Options

| Format    | Type    | Default              |
|:----------|:--------|:---------------------|
| Table     | Text    | `Iailgn`             |
| Table     | Price   | `Iailgp`             |
| Table     | Version | `Iailuv`             |
| Table     | Path    | `Iailgnb+/_:space:+` |
| Key-Value | Text    | `Iailgn`             |
| Key-Value | Price   | `Iailgp`             |
| Key-Value | Version | `Iailuv`             |
| Key-Value | Path    | `Iailgnb+/_:space:+` |
| JSON      | Text    | `Iascgnb++`          |
| JSON      | Price   | `Iascgpb++`          |
| JSON      | Version | `Iascuvb++`          |
| JSON      | Path    | `Iascgnb+/+`         |
