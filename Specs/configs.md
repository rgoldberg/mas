# Configs

A [display command](#display-commands) sources its output configuration from
persistent, named configs; each [config kind](#config-kinds) has its own
per-[context](#contexts) lookup hierarchy.

An **app** (software implementing these specs, e.g., mas) may override any
behavior or default that these specs define.

## Commands

A **command** is a node in a CLI tool's command hierarchy: either the root
command (the tool itself) or a subcommand of another command.

## Display Commands

A **display command** is a command whose primary function is to display data.

## Output Formats

Display commands support multiple **output formats**:

- **Table**: Row per item, column per field.
- **Key-Value**: Key-value pair on its own row per field, item separator line
  between items.
- **JSON**: JSON object per item, key-value pair per field.

Output configuration applies to every output format unless otherwise specified.

Each display command has a default output format.

Each output format has a flag that selects it with its
[`default`](#default-configs) config (e.g., `--json`) & an option that selects
it with a config overlaid on its `default` config (e.g., `--json-config P`).
Giving more than 1 such flag or option, even the same one twice (e.g.,
`--json --json` or `--json-config P --table`), is an error.

## Line Terminators

A **line terminator** is a CRLF (U+000D followed by U+000A, which is 1 line
terminator), or any other character from U+000A to U+000D, U+0085, U+2028, or
U+2029.

## Width

Text's **width** is its terminal display width: the sum of its characters'
`wcwidth`s, with 0 substituted for each negative one (e.g., a tab's).

## Option Values

```ebnf
valued-option(NAME, VALUE) = !NAME! <option-value-separator> VALUE

option-value-separator = "=" | _
```

A **valued option** is an option that takes a value; each spec defines one as a
`<valued-option>` (e.g., [`<fields-option>`](fields.md#fields-option)).

A valued option's **value** (`VALUE`) is the rest of its command-line argument
after `=` (e.g., `--fields=name`), or else the next command-line argument (e.g.,
`--fields name`), which a [command-line argument
boundary](ebnf.md#command-line-argument-boundaries) separates from `NAME` iff
that argument is `-` or does not start with `-`, so a value that starts with `-`
must follow `=` (e.g., `--fields=-x`); otherwise, the option is an error (e.g.,
`--fields -x`).

A **flag** is an option that takes no value (e.g., `--json`).

## Command Lists

A **command list** is the list of commands in the command line from root to
leaf; the leaf is the command that actually runs.

## Contexts

A **context** can contain named configs.

A context exists for each command in a command list.

Each context's name is a `.`-separated concatenation of the names of all the
commands from the root through the current command, never of an alias (e.g.,
`mas info`'s leaf context is `mas.lookup`).

## Context Stacks

A **context stack** is the contexts for a command list's commands in reverse
order, i.e., ordered from the most specific (leaf) to the least specific (root)
context, e.g., [`mas`'s context stacks](mas.md#context-stacks).

## Config Kinds

Each **config kind** has its own hierarchy: a config is only ever looked up,
referenced, or extended among configs of its own kind, except that a fields
config may also reference presets. The kinds are:

- [**Fields config**](fields.md#fields-configs): which fields are output & how.
- [**Preset**](fields.md#presets): field spec settings (e.g., a format).
- [**Table config**](table.md#table-config): table output settings.
- [**Key-value config**](key-value.md#key-value-config): key-value output
  settings.
- [**JSON config**](json.md#json-config): JSON output settings.

The rules below apply to every kind unless a kind specifies otherwise.

## Named Configs

A **named config** is **persistent** (i.e., no display command modifies it,
whether it is built-in or custom) & has a case-sensitive name that is unique for
its kind within a context.

A config name is a stem matching the regex `^[_0-9A-Za-z][-_0-9A-Za-z]*$`, so
that it never starts with `-`, which would make it ambiguous with a
[`<preset-removal>`](fields.md#presets) (e.g., `%-x`). A kind may extend the
name syntax, e.g., fields configs' [output format
suffix](fields.md#output-format-specific-named-fields-configs).

A custom config must not be named `standard` or any [built-in
config](#immutable-built-in-named-configs)'s name of its kind (e.g., fields
configs' `none`).

### Referencing Named Configs

A named config may be referenced:

- On the command line
- By other persistent configs of the same kind
- For a preset, by a persistent fields config

A named config is found by returning the 1st config of the given kind found with
the given name while iterating through the context stack from a **starting
context** to the root context; if no match is found, an error is reported. A
reference's starting context is:

- On the command line: the leaf context.
- In a persistent config: the context that contains that config.

A kind may refine how a context matches a name, e.g., fields configs'
[variants](fields.md#output-format-specific-named-fields-configs).

A persistent fields config **extends** `none` if it is an
[`<absolute-config>`](fields.md#absolute-config), else the fields config that
its [`<base-fields-config-section>`](fields.md#base-fields-config-selection)
names; a persistent table, key-value, or JSON config extends `default`, as a
persistent `<relative-config>` without a `<base-fields-config-section>` does; a
preset extends no config.

A persistent config that references a config of its own kind & name (e.g., by
extending it) resolves that config from the next less specific context in the
context stack, so a config may reference its nearest same-named ancestor. In the
root context, which has no less specific context, a `default` that references
`default` references the root context's `standard`. Any other cyclic chain of
references is a **reference cycle**, which is an error.

### Immutable Built-In Named Configs

For each [leaf context](#context-stacks), every kind has a **built-in standard**
config. A kind may define further built-in configs, e.g., fields configs'
[`none` & `all`](fields.md#immutable-built-in-named-fields-configs).

Each context of a command list contains the leaf context's built-in configs,
except its built-in standard, which is accessible only as the root context's
[`standard`](#standard-configs).

### Standard Configs

For a command list, the config named `standard` in:

- The root context is the leaf context's built-in standard.
- Any other context is its parent context's [`default`](#default-configs).

A context's `standard` thus layers the custom `default` of each less specific
context, from the root, over the leaf context's built-in standard (e.g., for
`mas list`, `mas.list`'s `standard` is `mas`'s `default`, which, absent a custom
one, is `mas`'s `standard`: `mas.list`'s built-in standard).

### Custom Named Configs

Users may define & persist named configs.

Every config that extends a config is ultimately derived transitively from a
built-in config.

### Default Configs

A context's `default` is its custom config named `default` iff one exists;
otherwise, [`standard`](#standard-configs) is substituted for `default`, so
`default` is that context's `standard`.

## Output Configs

An **output config** is a table, key-value, or JSON config.

Each output config is specified in its kind's **output config syntax** (e.g.,
[`<json-config>`](json.md#json-config) for a JSON config).

An output config has a separate **setting** per `(* inherited *)` nonterminal in
its kind's output config syntax (e.g., [`<header-setting>`](table.md#header)),
each of whose **alternatives** (e.g., `<header-off>` & `<header-on>`) starts
with its own letter.

An empty or [whitespace](ebnf.md#whitespace)-only [value](#option-values) of an
output format's **output config option** (e.g.,
[`<json-config-option>`](json.md#json-config)) overlays no settings (e.g.,
`--json-config=` ≡ `--json`).

A persistent output config's text is likewise optional (e.g.,
`[ <json-config> ]`), because generated text may contain no setting, so an empty
or whitespace-only one sets no setting, inheriting each from the config that it
extends.

Output sources from the context stack's [`default`](#default-configs) output
config of its output format's kind; an output config option's value is overlaid
on it for the current command line only, without persistently affecting it. Each
setting's [inherited value](ebnf.md#inherited-comments) is the value for it of
the config that its output config extends: for an output config option's value,
the `default` config.

Each kind's [built-in standard](#immutable-built-in-named-configs) output config
sets every setting to its default.

An alternative's **payload** is the expression between its letter & its
[`<setting-termination>`](#setting-termination) (e.g., `<style-specifier>` in
[`<header-on>`](table.md#header)). A payload's tabs & [line
terminators](#line-terminators) are output as is (e.g., a key-value config of
`$'L\n:'` puts each value on the line after its key). A **payloadless**
alternative is the lowercase alternative of a setting whose uppercase
alternative takes a payload (e.g., `h`, but not `t`, in a table config).

### Setting Termination

```ebnf
setting-termination = <setting-terminator> | <end-of-output-config>

setting-terminator   = ":"
end-of-output-config = end
```

E.g., in `--key-value-config Fs`, `s` is interpreted as `<leader-pattern>` text,
not as a separate `<item-separator-setting>`, while in `--table-config Hb` &
`--json-config Pa`, `b` & `a` are errors (because `<style-specifier>` &
`<indentation>` cannot consume them), not a separate `<broken-setting>` or
`<top-level-structure-setting>`.

### Implied Alternatives

A kind may define **implied alternatives**, which an output config's explicit
alternatives imply, directly or via another implied alternative (e.g., a table's
[implied alternatives](table.md#implied-alternatives)), whether that output
config is persistent or an output config option's value (e.g., a persistent
`default` table config of `b` implies `S`, which implies `H`). No inherited or
default alternative implies one (e.g., `--table` implies no separator line from
its default `u`, while, for a persistent `default` table config of `S:h`,
`--table-config c` implies no header row from its inherited `S`).

An explicit alternative of a setting, even "off" (e.g., a table's `h`), always
overrides that setting's implied alternative, regardless of where in its output
config it appears.

An implied alternative overrides an inherited alternative iff the inherited
alternative is payloadless; otherwise, it retains the inherited alternative's
payload, so it never overrides an inherited payload, but remains effective
(e.g., for a persistent `default` table config of `S=:h`, `--table-config b`
implies `H` via an effective `S` that retains its inherited `=` payload).
