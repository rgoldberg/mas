# Command-Line Interface

How an [app](configs.md#configs) run from a command line exposes the other
specs: which standard stream each output uses, what its styling defaults are,
what its exit status means & which command-line options take which syntax.

Uses the [custom EBNF grammar](ebnf.md).

## Standard Streams

[Normal output](configs.md#normal--error-output) is standard output, and [error
output](configs.md#normal--error-output) is standard error (e.g., an item
error's text does not reach `jq` in `app --json | jq .`).

A terminal that standard output is connected to is normal output's [output
device](configs.md#normal--error-output), so normal output [supports
styling](configs.md#normal--error-output) iff standard output is connected to a
terminal.

## Styling Defaults

A terminal renders ANSI SGR control sequences, so the **ANSI SGR styling
defaults** override [`p`, `x` & `o`'s defaults](table.md#styling):

- `p`'s `<styling-prefix>`: `ESC[` (the ANSI control sequence introducer, where
  `ESC` is U+001B).
- `x`'s `<styling-suffix>`: `m` (the ANSI SGR control sequence's final byte).
- `o`'s `<styling-reset>`: `ESC[0m` (the ANSI SGR reset).

Thus, with these defaults, a `<styling-specifier>` holds ANSI SGR parameters
(e.g., `1` for bold, `1;4` for bold & underlined).

## Exit Status

A command that [fails](configs.md#output-formats) exits with a nonzero **exit
status**, so that a script can detect its failure.

## Command Lines

A **command line** is text that specifies a [command
list](configs.md#command-lists) & its arguments to run; its [transient
configs](configs.md#transient-configs) are the values of its options.

## Option Values

```ebnf
valued-option(NAME, VALUE) = !NAME! <option-value-separator> VALUE

option-value-separator = "=" | _
```

A **valued option** is an option that takes a value; this spec defines each as a
`<valued-option>` (e.g., [`<fields-option>`](#fields-option)).

A valued option's **value** (`VALUE`) is the rest of its command-line argument
after `=` (e.g., `--fields=name`), or else the next command-line argument (e.g.,
`--fields name`), which a [command-line argument
boundary](ebnf.md#command-line-argument-boundaries) separates from `NAME` iff
that argument is `-` or does not start with `-`, so any other value that starts
with `-` must follow `=` (e.g., `--fields=-x`); otherwise, the option is an
error (e.g., `--fields -x`).

A **flag** is an option that takes no value (e.g., `--json`).

## Output Format Options

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
table-config-option     = <valued-option("--table-config", [ <table-config> ])>
key-value-config-option = <valued-option("--key-value-config", [ <key-value-config> ])>
json-config-option      = <valued-option("--json-config", [ <json-config> ])>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Every [display command](configs.md#display-commands) has an optional flag per
[output format](configs.md#output-formats), which selects it with its
[`default`](configs.md#default-configs) config (`--table`, `--key-value`, or
`--json`), and an optional **output config option** per output format, which
selects it with its value as a transient output config (e.g.,
`--json-config P`).

Because only 1 output format can be selected, giving more than 1 such flag or
option, even the same one twice (e.g., `--json --json` or
`--json-config P --table`), is an error.

Because [an output config's text is optional](configs.md#output-configs),
`--json-config=` ≡ `--json`.

## Fields Option

```ebnf
fields-option = <valued-option("--fields", <fields-config>)>
```

Every display command has an optional `<fields-option>`, whose value is a
[transient](configs.md#transient-configs) fields config (e.g.,
`--fields name/I`), so giving it more than once is an error.

## Quoting

Most [syntax text](ebnf.md#grammar) needs no quoting, because the syntaxes avoid
punctuation that a common shell interprets unquoted. Other text does, such as a
space or an escape sequence (e.g., `--table-config 'H\b'`), or a control
character, which an example in another spec names (e.g.,
`--table-config $'C\t:'` in zsh for `C<TAB>:`).
