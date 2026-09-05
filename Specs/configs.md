# Configs

A [display command](#display-commands) sources its output configuration from
persisted, named configs; each [config kind](#config-kinds) has its own
per-[context](#contexts) lookup hierarchy.

## Commands

A **command** is a node in a CLI tool's command hierarchy: either the root
command (the tool itself) or a subcommand of another command.

## Display Commands

A **display command** is a command whose primary function is to display data.

## Output Formats

Display commands support multiple **output formats**:

- **Table**: Row per item, column per field.
- **Key-Value**: Key-value pair on its own row per field, blank line between
  items.
- **JSON**: JSON object per item, key-value pair per field.

Output configuration applies to every output format unless otherwise specified.

Each display command has a default output format.

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

- [**Fields config**](fields.md#fields-configs): which fields are output, & how.
- [**Table config**](table.md#table-config): table output settings.
- **Key-value config**: key-value output settings, of which there are currently
  none.
- **JSON config**: JSON output settings, of which there are currently none.

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
a given name while iterating through the context stack from most to least
specific context; if no match is found, an error is reported.

A persisted config whose base config name is its own name resolves its base
config from the context above its own, so a config may extend its nearest
same-named ancestor. Any other cyclic chain of references is an error.

### Immutable Built-In Named Configs

For each [leaf context](#context-stacks), every kind has a built-in config named
`standard`. A kind may define further built-in configs, e.g., fields configs'
[`none` & `all`](fields.md#immutable-built-in-named-fields-configs).

### Custom Named Configs

Users may define & persist named configs.

All configs are ultimately derived transitively from a built-in config.

### Default Configs

If no custom config named `default` is found in the context stack, `standard` is
substituted.
