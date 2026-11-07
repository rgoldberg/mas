# Command-Line Interface

How an [app](configs.md#configs) run from a command line exposes the other
specs: which standard stream each output uses, what its exit status means &
which command-line options take which syntax.

Uses the [custom EBNF grammar](ebnf.md).

## Standard Streams

[Normal output](configs.md#normal--error-output) is standard output, and [error
output](configs.md#normal--error-output) is standard error (e.g., an item
error's text does not reach `jq` in `app --json | jq .`).

## Exit Status

A command that [fails](configs.md#output-formats) exits with a nonzero **exit
status**, so that a script can detect its failure.

## Command Lines

A **command line** is a run of a [command list](configs.md#command-lists), whose
[transient configs](configs.md#transient-configs) are the values of its options.

## Command-Line Argument Boundaries

This spec extends the custom EBNF grammar with:

```ebnf
_
```

A **command-line argument boundary**: a constant expression that matches no
syntax text, only between 2 adjacent command-line arguments, iff the latter is
`-` or does not start with `-`, as an [option value](#option-values) requires
(e.g., `"--fields" _ "x"` matches the arguments `--fields` & `x`, but
`"--fields" _ "-x"` matches no arguments). Syntax text spans multiple
command-line arguments only where a command-line argument boundary separates
them. Each side of a command-line argument boundary treats outer bare whitespace
as the syntax text's start & end do.

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
boundary](#command-line-argument-boundaries) separates from `NAME` iff that
argument is `-` or does not start with `-`, so any other value that starts with
`-` must follow `=` (e.g., `--fields=-x`); otherwise, the option is an error
(e.g., `--fields -x`).

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

An empty or whitespace-only value of an output config option sets no setting
(e.g., `--json-config=` ≡ `--json`).

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
