# Configs

A [display command](#display-commands) sources its output configuration from
persistent, named configs; each [config kind](#config-kinds) has its own
per-[context](#contexts) lookup hierarchy.

An **app** (software implementing these specs, e.g., mas) may override any
behavior or default that these specs define.

Uses the [custom EBNF grammar](ebnf.md).

## Commands

A **command** is a node in an app's command hierarchy: either the root command
(the app itself) or a subcommand of another command.

## Display Commands

A **display command** is a command whose primary function is to display data.

A display command's input is a list of **items**, each of which has fields, in
an **input format** (e.g., JSON).

## Output Formats

Display commands support multiple **output formats**:

- **Table**: Row per item, column per field.
- **Key-Value**: Key-value pair on its own row per field, item separator line
  between items.
- **JSON**: JSON object per item, key-value pair per field.

A fields config applies to every output format unless otherwise specified.

Each display command has a default output format.

A run of a display command may select an output format, either with its
[`default`](#default-configs) config or with a [transient](#transient-configs)
output config overlaid on its `default` config. Selecting more than 1, even the
same one twice, is an error.

An **item error** is an error that depends on an item's field value (e.g.,
`.round` for `"abc"`, per [`<transform-call>`](fields-format.md#transforms)'s
error comment). A format that no output & no [`<output>`](fields.md#sort-source)
sort key evaluates has no item error (e.g., a hidden field spec without a
[`<sort>`](fields.md#sorting), or a non-last member for table output). Only an
item's 1st item error is reported, which does not stop its command: the command
outputs every other item as if that item were not in the input, because 1 item's
value should not hide any other item (e.g., if only the 2nd of 3 items has an
item error, the 1st & 3rd are output, with 1 item separator line between them
for key-value output, and, for table output, a field of only the 2nd has no
column). An item's item errors are ordered by its `<output>` sort keys' [sort
precedence](fields.md#sort-priority), then by its output order (e.g., for
`a:.round,b:.round/O`, if `a` & `b` are strings, only `b`'s is reported). A
command that reports an item error **fails**, so that its caller can detect an
omitted item.

## Normal & Error Output

**Normal output** is where a display command outputs its items. **Error
output**, which is separate from normal output, is where an app reports every
error, so that no error mixes with output (e.g., no error text can break a
parser of JSON output).

An **output device** is what renders normal output for a user. Normal output
**supports styling** iff an app determines that its output device can render
styled text.

## Line Terminators

A **line terminator** is a CRLF (U+000D followed by U+000A, which is 1 line
terminator), or any other character from U+000A to U+000D, U+0085, U+2028, or
U+2029.

## Width

Text's **width** is its display width: the sum of its characters' `wcwidth`s,
with 0 substituted for each negative one (e.g., a tab's).

## Command Lists

A **command list** is the list of commands in a run from root to leaf; the leaf
is the command that actually runs.

## Transient Configs

A **transient config** is a fields config or an output config that is given for
1 run of a display command, rather than persisted; an app chooses how one is
given.

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

A config name is a **stem** matching the regex `^[_0-9A-Za-z][-_0-9A-Za-z]*$`,
so that it never starts with `-`, which would make it ambiguous with a
[`<preset-removal>`](fields.md#presets) (e.g., `%-x`). A kind may extend the
name syntax, e.g., fields configs' [output format
suffix](fields.md#output-format-specific-named-fields-configs).

A custom config must not be named `standard` or any [built-in
config](#immutable-built-in-named-configs)'s name of its kind (e.g., fields
configs' `none`).

### Referencing Named Configs

A named config may be referenced:

- By a transient config
- By other persistent configs of the same kind
- For a preset, by a persistent fields config

A named config is found by returning the 1st config of the given kind found with
the given name while iterating through the context stack from a **starting
context** to the root context; if no match is found, an error is reported. A
reference's starting context is:

- In a transient config: the leaf context.
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

An output config's text is optional (e.g., `[ <json-config> ]`), because
generated text may contain no setting, so an empty or
[whitespace](ebnf.md#whitespace)-only one sets no setting, inheriting each from
the config that it extends.

Output sources from the context stack's [`default`](#default-configs) output
config of its output format's kind; a transient output config is overlaid on it
for its run only, without persistently affecting it. Each setting's [inherited
value](ebnf.md#inherited-comments) is the value for it of the config that its
output config extends: for a transient output config, the `default` config.

Each kind's [built-in standard](#immutable-built-in-named-configs) output config
sets every setting to its default.

An alternative's **payload** is the expression between its letter & its
[`<setting-termination>`](#setting-termination) (e.g., `<styling-specifier>` in
[`<header-on>`](table.md#header)). A payload's characters, including control
characters (e.g., a tab, a [line terminator](#line-terminators), or an ESC), are
output as is (e.g., a key-value config of `L<LF>:` puts each value on the line
after its key). A **payloadless** alternative is the lowercase alternative of a
setting whose uppercase alternative takes a payload (e.g., `h`, but not `t`, in
a table config).

### Setting Termination

```ebnf
setting-termination = <setting-terminator> | <end-of-output-config>

setting-terminator   = ":"
end-of-output-config = end
```

E.g., in the key-value config `Fs`, `s` is interpreted as `<leader-pattern>`
text, not as a separate `<item-separator-setting>`, while in the table config
`Hb` & the JSON config `Pa`, `b` & `a` are errors (because `<styling-specifier>`
& `<indentation>` cannot consume them), not a separate `<broken-setting>` or
`<top-level-structure-setting>`.

### Implied Alternatives

A kind may define **implied alternatives**, which an output config's explicit
alternatives imply, directly or via another implied alternative (e.g., a table's
[implied alternatives](table.md#implied-alternatives)), whether that output
config is persistent or transient (e.g., a persistent `default` table config of
`b` implies `S`, which implies `H`). No inherited or default alternative implies
one (e.g., an empty table config implies no separator line from its default `u`,
while, for a persistent `default` table config of `S:h`, a transient `c` implies
no header row from its inherited `S`).

An explicit alternative of a setting, even "off" (e.g., a table's `h`), always
overrides that setting's implied alternative, regardless of where in its output
config it appears.

An implied alternative overrides an inherited alternative iff the inherited
alternative is payloadless; otherwise, it retains the inherited alternative's
payload, so it never overrides an inherited payload, but remains effective
(e.g., for a persistent `default` table config of `S=:h`, a transient `b`
implies `H` via an effective `S` that retains its inherited `=` payload).
