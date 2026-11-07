# mas Configuration

`mas`-specific configuration of the generic [configs](configs.md) & [field
selection](fields.md), which `mas` exposes via its [command-line
interface](command-line.md).

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

For `config`, `mas` [lists](fields.md#unlisted-fields) every field of its item;
for any other command, each field for which its built-in standard's user-facing
variants have a visible field spec (e.g., only `adamID`, `name` & `version` for
`mas list`).

`config` specifies all of its item's potential fields up front, so any other
field is [nonexistent](fields.md#nonexistent-fields) for it; no other command
can determine that, so no field is nonexistent for it.

For the same `mas` leaf context & output format suffix (or its absence), every
listed field has a field spec in each of [`all` &
`none`](fields.md#immutable-built-in-named-fields-configs) & the [built-in
standard](configs.md#immutable-built-in-named-configs).

Each user-facing variant of the built-in standard has only visible field specs &
hides unlisted fields.

A `mas` built-in fields config has:

- A user-facing unsuffixed variant.
- A user-facing `@table` variant.
- A user-facing `@key-value` variant.
- A machine-facing `@json` variant.

For the same output format, its unsuffixed, `@table` & `@key-value` variants are
identical.

The built-in standard's `@json` variant is a reference to `all@json`, so, unlike
the [generic built-in
standard](fields.md#immutable-built-in-named-fields-configs), it outputs
unlisted fields & sorts its field specs by label.

Default labels & formats favor:

- If user-facing: readability, per the [built-in field
  specs](#built-in-field-specs).
- If machine-facing: precision & parsability:
  - Label is the field name.
  - Output is formatted as `%i`.

Built-in field specs for `adamID` & `fileSizeBytes` are
[end-aligned](fields.md#alignment); all other built-in field specs are
start-aligned.

## Built-In Field Specs

No built-in field spec has a `<sort>`, so only a custom `default` preset that
sets an enabled sort makes a built-in fields config other than `none` sort items
(e.g., absent one, `mas list` outputs apps in input order). No built-in fields
config has a built-in field order, so `all` orders its field specs [by
label](fields.md#immutable-built-in-named-fields-configs), while `none` & each
built-in standard's user-facing variants order theirs by `<positional-order>`.

Every variant of `all` & of `none` positions its field specs as the built-in
standard's user-facing variants do (e.g., `mas list --fields @none.version,name`
outputs `name`, then `version`).

`config`'s built-in standard's user-facing variants have a visible field spec
for every field, in order, `mas`, `slice`, `slices`, `dist`, `origin`, `rev`,
`swift`, `driver`, `store`, `region`, `macos`, `build`, `mac`, `cpu` & `arch`,
each labeled by its field name & formatted as `%i`.

Every other command's built-in standard's user-facing variants have the
following visible field specs, at the given positions:

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Field                       | Label         | Format                              | `list` | `lookup` | `outdated` | `search` |
|:----------------------------|:--------------|:------------------------------------|-------:|---------:|-----------:|---------:|
| `adamID`                    | `ADAM ID`     | `%i`                                |      1 |        2 |          1 |        1 |
| `name`                      | `Name`        | `%i`                                |      2 |        1 |          2 |        2 |
| `version`                   | `Version`     | `%i`                                |      3 |        4 |          3 |        3 |
| `newVersion`                | `New Version` | `%i`                                |        |          |          4 |          |
| `bundleID`                  | `Bundle ID`   | `%i`                                |        |        3 |            |          |
| `formattedPrice`            | `Price`       | `%i`                                |        |        5 |            |          |
| `sellerName`                | `By`          | `%i`                                |        |        6 |            |          |
| `currentVersionReleaseDate` | `Released`    | `%+D.dateOnly+`                     |        |        7 |            |          |
| `minimumOSVersion`          | `Minimum OS`  | `%i`                                |        |        8 |            |          |
| `fileSizeBytes`             | `Size`        | `%+.N.scale:6,,0:.numberFormat+ MB` |        |        9 |            |          |
| `appStorePageURL`           | `From`        | `%i`                                |        |       10 |            |          |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

In every `mas` built-in fields config's user-facing variants, a field spec for a
field that the table above lists has that row's label & format; any other
field's built-in field spec is labeled by its field name & formatted as `%i`.

Wherever the base fields config is, or transitively
[extends](configs.md#referencing-named-configs), one of those variants, each of
the variant's field specs & each field's [default field
spec](fields.md#default-field-specs) (e.g., for an unlisted field) is the
field's built-in field spec with the [`default` preset](fields.md#presets)
attached (e.g., for a custom `default` of `%centerStart:..uppercase`,
`mas list --fields @all` outputs `bundleID` labeled `Bundle ID`, uppercased &
center-aligned, while for one of `:..uppercase`, `mas search --fields @all`
outputs `fileSizeBytes` end-aligned).

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

The **version fields** are `minimumOSVersion`, `newVersion` & `version`.

Version fields' default sort options compare
[versions](fields.md#sort-number-segments) (`v`), and `formattedPrice`'s are
[those for price sorting](#price-sorting), but they otherwise match the
following:

| Output Format     | Field  | Default              |
|:------------------|:-------|:---------------------|
| Table / Key-Value | Other  | `I+iL:N:`            |
| Table / Key-Value | `path` | `I+iL:N:B/_+space+:` |
| JSON              | Other  | `I+sN:B:`            |
| JSON              | `path` | `I+sN:B/:`           |

## Default Field Orders

mas's [default field orders](fields.md#immutable-built-in-named-fields-configs)
of kinds `I` & `O` are those that the field order sections of each row below
save, so they compare field names & labels as the `Other` rows of the [default
sort options](#default-sort-options) compare a field's content; it has none of
kinds `P` & `D`:

| Output Format     | Field Order Sections |
|:------------------|:---------------------|
| Table / Key-Value | `/iL:N:I/iL:N:O`     |
| JSON              | `/sN:B:I/sN:B:O`     |
