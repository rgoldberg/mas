# Configs

A [display command](#display-commands) sources its output configuration from
persisted, named configs; each [config kind](#config-kinds) has its own
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

## Option Values

An option's **value** is the rest of its command-line argument after `=` (e.g.,
`--fields=name`), or else the next command-line argument (e.g.,
`--fields name`), iff that argument is `-` or does not start with `-`, so a
value that starts with `-` must follow `=` (e.g., `--fields=-x`). Each spec
defines an option's syntax over its value alone.

A **flag** is an option without a value (e.g., `--json`).

## Command Lists

A **command list** is the list of commands in the command line from root to
leaf; the leaf is the command that actually runs.

## Contexts

A **context** can contain named configs.

A context exists for each command in a command list.

Each context's name is a `.`-separated concatenation of all the commands from
the root through the current command.

## Context Stacks

A **context stack** is the contexts for a command list's commands in reverse
order, i.e., ordered from the most specific (leaf) to the least specific (root)
context, e.g., [`mas`'s context stacks](mas.md#context-stacks).

## Config Kinds

Each **config kind** has its own hierarchy: a config is only ever looked up,
referenced, or extended among configs of its own kind. The kinds are:

- [**Fields config**](fields.md#fields-configs): which fields are output & how.
- [**Table config**](table.md#table-config): table output settings.
- [**Key-value config**](key-value.md#key-value-config): key-value output
  settings.
- [**JSON config**](json.md#json-config): JSON output settings.

The rules below apply to every kind unless a kind specifies otherwise.

## Named Configs

A **named config** has been persisted with a case-sensitive name that is unique
for its kind within a context.

A config name is a stem matching the regex `^[-_0-9A-Za-z]+$`. A kind may extend
the name syntax, e.g., fields configs' [output format
suffix](fields.md#output-format-specific-named-fields-configs).

### Referencing Named Configs

A named config may be referenced:

- On the command line
- By other persisted configs of the same kind

A named config is found by returning the 1st config of the given kind found with
the given name while iterating through the context stack from a **starting
context** to the root context; if no match is found, an error is reported. A
reference's starting context is:

- On the command line: the leaf context.
- In a persisted config: the context that contains that config.

A kind may refine how a context matches a name, e.g., fields configs'
[variants](fields.md#output-format-specific-named-fields-configs).

A persisted fields config **extends** the fields config that its
[`<base-fields-config-section>`](fields.md#base-fields-config-selection) names;
a config of any other kind extends no config.

A persisted config that extends a config of its own name resolves that config
from the next less specific context in the context stack, so a config may extend
its nearest same-named ancestor. In the root context, which has no less specific
context, a `default` that extends `default` extends the root context's
`standard`, as it would in a less specific context without a custom `default`,
so an explicit `default` (e.g., `@default`) is equivalent to the implicit one
(e.g., an absent `<base-fields-config-section>`). Any other cyclic chain of
references is an error.

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

`standard` thus layers each context's custom `default`, from the root to the
leaf, over the leaf context's built-in standard (e.g., for `mas list`,
`mas.list`'s `standard` is `mas`'s `default`, which, absent a custom one, is
`mas`'s `standard`: `mas.list`'s built-in standard).

### Custom Named Configs

Users may define & persist named configs.

All configs are ultimately derived transitively from a built-in config.

### Default Configs

In each context that contains no custom config named `default`, `default` is
that context's [`standard`](#standard-configs).
