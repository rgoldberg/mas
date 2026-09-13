#### Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-modifier        = <format-modifier-prefix> [ <format> ] (* default: contextual default formatting *)
format-modifier-prefix = ":"

format = <named-format> [ <format-transform-pipeline> ] [ <value-transform-pipeline> ]
       | <format-transform-pipeline> [ <value-transform-pipeline> ]
       | <value-transform-pipeline>
       | [ <named-format> ] [ <format-transform-pipeline> ] [ <non-terminal-value-transform-pipeline> ] <parameterized-value-transform-call> <template>
       | [ <named-format> ] [ <format-transform-pipeline> ] [ <non-terminal-value-transform-pipeline> ] <unparameterized-value-transform-call> <pipeline-terminator> <template>
       | [ <named-format> ] <format-transform-pipeline> <pipeline-terminator> <template>
       | <named-format> <pipeline-terminator> <template>
       | <template>

(* Unrelated to <argument-fence> (also ":"), despite sharing a character: see
   "Pipeline Terminator" under "Transforms" below. *)
pipeline-terminator = "::"

template      = [ <template-text> ] ( <placeholder> [ <template-text> ] )+
template-text = {text}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

If `<format-modifier>` is absent, then a user-configurable per-field per-context
default formatting is applied.

If the user hasn't configured a default formatting for the field for the
context, then a standard formatting for the field in the context is applied:
`%v` (the field's verbatim value), unless the context defines a more specific
standard format for that field.

If `<format-modifier>` is present, but `<format>` is absent, the field's format
is reset to its contextual default. Formatting has no separate global-default
tier (unlike item sorting's `<reset-to-contextual>` / `<reset-to-global>`
distinction).

`<format>`, if present, is at least 1 of `<named-format>`,
`<format-transform-pipeline>` (see "Format Transforms" below),
`<value-transform-pipeline>` (applied to `<named-format>`'s value, or `%v`'s
if `<named-format>` is absent) & `<template>` (`<placeholder>` /
`<template-text>`), always in that order, with no separator of any kind
between adjacent parts, except where "Pipeline Terminator" below requires a
`<pipeline-terminator>` right before a `<template>`. A `<value-transform-
pipeline>` alone renders as its own output. Followed by a `<template>`, the
`<template>` renders against the pipeline's own output instead of the
field's original value: a `<placeholder>` inside it (e.g., `%v` / `%V`)
reads the transformed value, not the raw 1, so nothing is duplicated; write
`%v` to include the transformed value in the `<template>` (a `<template>`
needs at least 1 `<placeholder>` regardless; see "Templates Need a
Placeholder" under "Transforms" below).

Unlike every other `<*-transform-pipeline>` site (a placeholder's own
success / failure sub-format always knows its kind up front from its own
grammar position (e.g., `%N`'s own success sub-format is always number-kind,
so it may contain a `<number-transform-pipeline>` but never a
`<string-transform-pipeline>`)), `<value-transform-pipeline>` infers kind from
its own 1st `<value-transform>` instead, since a field's raw value has no
fixed type. This is never ambiguous: no 2 kinds define the same
`<value-transform>` name, so the 1st `<value-transform>`'s name alone
determines kind for the rest of the pipeline (mixing kinds in 1 pipeline is a
`<value-transform>` name error, same as
using any other unrecognized name would be).

Neither a name nor a transform name stops at `<placeholder-prefix>` on its
own: `<name-prefix>someFormat%v` is an attempt at a named format literally
called `someFormat%v` (& fails as one if it doesn't exist), not `someFormat`
followed by a `%v` placeholder. A `<pipeline-terminator>` (needed even right
after a bare `<named-format>`, with nothing else in between, since
`<named-format>` never ends with `:` on its own (see "Pipeline Terminator"
below)) or `<transform-call-prefix>` (for a `<value-transform-pipeline>`) is
what actually separates them: `<name-prefix>someFormat<pipeline-terminator>%v`
is `someFormat` followed by a `%v` placeholder.

##### References

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-placeholder-reference = <named-string-format> [ <string-transform-pipeline> ] | <string-transform-pipeline>
number-placeholder-reference = <named-number-format> [ <number-transform-pipeline> ] | <number-transform-pipeline>
date-placeholder-reference   = <named-date-format> [ <date-transform-pipeline> ] | <date-transform-pipeline>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A placeholder's own success / failure sub-format uses these placeholder-level
references, not `<format>` itself, so a `<format-transform-pipeline>` (only
ever part of `<format>`) never applies inside one.

##### Named Formats

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
named-format = <name-prefix> <format-name>
format-name  = {text}

named-string-format     = <name-prefix> <placeholder-format-name>
named-number-format     = <name-prefix> <placeholder-format-name>
placeholder-format-name = {text}

named-date-format = <name-prefix> <date-format-name>
date-format-name  = {text}

name-prefix = ":"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

**Named formats** can be saved in the app configuration; they can be referenced
via `<named-format>`, `<named-string-format>`, `<named-number-format>`, or
`<named-date-format>`.

If no named format exists for a referenced name, an error is reported.

###### Built-in Named Formats

- `hidden`: Omits the field from output, allowing sorting by a field without
  displaying it. Unlike any other named format, `hidden` must be the entire
  `<format>`; no `<format-transform-pipeline>`, `<pipeline-terminator>`,
  `<value-transform-pipeline>`, or `<template>` may follow it, since a hidden
  field is never rendered; anything following it would be dead configuration.

##### Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
(* Only `<format>` itself uses this directly; every other `<*-transform-
   pipeline>` site (a placeholder's own success / failure sub-format) already
   knows its kind statically & uses 1 of the 3 alternatives below directly
   instead. *)
value-transform-pipeline = <string-transform-pipeline> | <number-transform-pipeline> | <date-transform-pipeline>

(* Like `<value-transform-pipeline>`, but excludes a `<number-transform-
   pipeline>` ending in `<terminal-number-transform-call>`; `<format>` uses
   this for its own optional leading pipeline right before its own mandatory
   final transform-call, so that final call can never follow 1 that already
   ended a `<number-transform-pipeline>` of its own. *)
non-terminal-value-transform-pipeline = <string-transform-pipeline> | <non-terminal-number-transform-pipeline> | <date-transform-pipeline>

string-transform-pipeline = <string-transform-call>+
date-transform-pipeline   = <date-transform-call>+

(* A `<terminal-number-transform>` (currently just `group`) produces a value
   no other `<non-terminal-number-transform>` can operate on further (see
   `group`'s own note below), so it may only ever appear last: either alone,
   or after 1+ `<non-terminal-number-transform>`s. This is the 1 exception to
   `<value-transform>` ordering being unconstrained; the grammar enforces it
   directly, rather than leaving it to prose. *)
number-transform-pipeline              = <non-terminal-number-transform-pipeline> [ <terminal-number-transform-call> ]
                                        | <terminal-number-transform-call>
non-terminal-number-transform-pipeline = <non-terminal-number-transform-call>+

(* Composes a `<transform-call-prefix>`, an optional `<value-transform-
   coercion>` & the transform itself. `<value-transform-call>` is the
   generic form; each other `*-transform-call` below parallels 1 specific
   subset of `<value-transform>`, for use wherever only that subset is
   valid. *)
value-transform-call = <transform-call-prefix> [ <value-transform-coercion> ] <value-transform>

string-transform-call              = <transform-call-prefix> [ <value-transform-coercion> ] <string-transform>
non-terminal-number-transform-call = <transform-call-prefix> [ <value-transform-coercion> ] <non-terminal-number-transform>
terminal-number-transform-call     = <transform-call-prefix> [ <value-transform-coercion> ] <terminal-number-transform>
date-transform-call                = <transform-call-prefix> [ <value-transform-coercion> ] <date-transform>

parameterized-value-transform-call   = <transform-call-prefix> [ <value-transform-coercion> ] <parameterized-value-transform>
unparameterized-value-transform-call = <transform-call-prefix> [ <value-transform-coercion> ] <unparameterized-value-transform>

(* Meaningful only on `<format>`'s own top-level `<value-transform-pipeline>`'s
   1st `<value-transform-call>`; see "Value Coercion" above. Harmless but
   inert on every other `<*-transform-call>`, since the shared parsing logic
   doesn't special-case position. *)
value-transform-coercion = "."

transform-call-prefix = "."

value-transform                = <string-transform> | <non-terminal-number-transform> | <terminal-number-transform> | <date-transform>
string-transform               = <capitalize> | <lowercase> | <sentence-case> | <trim-whitespace> | <uppercase>
non-terminal-number-transform  = <absolute-value> | <round> | <scale>
terminal-number-transform      = <group>
date-transform                 = <iso> | <date-only> | <local-time-zone>

(* `<scale>` always closes a `:`-fenced argument list of its own; `<parameter-
   ized-group>` does too, since it's the alternative of `<group>` that
   requires 1; see "Pipeline Terminator" below. *)
parameterized-value-transform = <parameterized-group> | <scale>
(* Every other `<value-transform>`: never closes a `:`-fenced argument list
   of its own; `<unparameterized-group>` is `<group>`'s other alternative,
   the 1 with no arguments at all. *)
unparameterized-value-transform = <string-transform> | <absolute-value> | <round> | <date-transform> | <unparameterized-group>

capitalize      = "initialUppercase"
lowercase       = "lowercase"
sentence-case   = "sentenceCase"
trim-whitespace = "trimWhitespace"
uppercase       = "uppercase"

absolute-value = "absoluteValue"
round          = "round"
scale          = "scale" <scale-arguments>

group                 = <parameterized-group> | <unparameterized-group>
parameterized-group   = "group" <group-arguments>
unparameterized-group = "group"

iso             = "iso"
date-only       = "dateOnly"
local-time-zone = "localTimeZone"

group-arguments          = <argument-fence> ( <group-locale-name> | <explicit-group-arguments> ) <argument-fence>
explicit-group-arguments = <group-separator> <argument-separator> <group-digit-count>

scale-arguments    = <argument-fence> <radix> <argument-separator> <exponent> <argument-separator> [ <significant-digits> ] <argument-separator> <fractional-digits> <argument-fence>
argument-fence     = ":" (* fences any transform's argument list; generic, not `scale`-specific *)
argument-separator = "," (* separates a transform's own arguments; generic, not `scale`-specific *)

group-locale-name = {text} (* default: {system default locale name} *)
group-separator   = {text}
group-digit-count = {positive integer}

radix              = {positive integer}     (* 2-36; base for `exponent` & the rendered digits *)
exponent           = {non-negative integer} (* divides the field's value by `radix^exponent` before rendering *)
significant-digits = {positive integer}     (* rounds to this many total `radix` digits; absent: no rounding *)
fractional-digits  = {non-negative integer} (* exactly this many `radix` digits after the point; `0`: integer *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `<string-transform-pipeline>`, `<number-transform-pipeline>`, or
  `<date-transform-pipeline>` `t` is a pipeline of data transformations applied
  to:
  - If `<named-format>`, `<named-string-format>`, `<named-number-format>`, or
    `<named-date-format>` `n` immediately precedes `t`: `n`'s value.
  - Otherwise: the field's value.

###### Value Coercion

A `<value-transform-pipeline>` (`<format>`'s own top-level pipeline, per its
inferred kind) may coerce its input value first, controlled by a
`<value-transform-coercion>` (a 2nd `.` right after the pipeline's own 1st
`<value-transform-call>`'s `<transform-call-prefix>`, i.e., `..` instead of
`.`), conceptually the same marker as `<placeholder-coercion>` (see
"Coercion" under "Placeholders" below), & spelled with the same character,
just in a different position (there's no placeholder-letter syntax slot at
`<format>`'s own top level to attach `<placeholder-coercion>` to directly).
Only `<number-transform-pipeline>` may be coerced this way: coerced, it also
accepts a JSON string that itself parses as a number (not just a real JSON
number); uncoerced (the default, no `..`), it requires a real JSON number,
same as plain `%n`. `<value-transform-coercion>` on a `<string-transform-
pipeline>` or `<date-transform-pipeline>` is a parse error: a
`<string-transform-pipeline>`'s field's `stringValue` (its rendered
representation) always exists, even for `null` (`""`), so it never needs
coercion; a `<date-transform-pipeline>` accepts anything `%d` would (ISO-8601
datetime, ISO-8601 date-only, or a Unix epoch numeric timestamp, as a real
JSON number or a JSON string) unconditionally, the same way `%d` itself
never supports `<placeholder-coercion>` either; there's no uncoerced form
to distinguish it from.

Only the pipeline's own 1st `<value-transform-call>` currently affects
rendering, since `<value-transform-pipeline>`'s kind & coercion are both
decided once, up front, from it. A `<value-transform-coercion>` is
nonetheless syntactically permitted (parsed, with no effect) on a later
`<value-transform-call>` in the same pipeline too, since a later,
wrongly-typed `<value-transform>` would already have failed regardless of
whether it too was marked, so this is reserved for a
possible future where coercion could apply mid-pipeline, not a currently
meaningful position.

If coercion fails, the entire `<format>` renders blank, mimicking an
unhandled placeholder failure (see "Success & Failure" under "Placeholders"
below); this applies even when a `<template>` follows the
`<value-transform-pipeline>` (see "Pipeline Terminator" next): the
`<template>` is never rendered either.

###### Pipeline Terminator

Whichever of `<named-format>`, `<format-transform-pipeline>`, or
`<value-transform-pipeline>` is last present may be followed directly by a
`<template>` (see "Value Coercion" above for what the `<template>` then
renders against, & "Templates Need a Placeholder" below for a constraint on
the `<template>` itself). A `<pipeline-terminator>` (`::`) must separate the
2 UNLESS that last-present part already ends with `:` on its own, which
only ever happens when it's a `<value-transform-pipeline>` ending in a
`<parameterized-value-transform>` (`group` / `scale`) called with explicit
arguments, closing its own `<argument-fence>` (also `:`); ending in an
`<unparameterized-value-transform>` instead never does. `<named-format>` &
`<format-transform-pipeline>` never end with `:` on their own either, so a
`<template>` after either always needs the full `<pipeline-terminator>`.

- If the last-present part closed its own `<argument-fence>`: that closing
  `:` already unambiguously ends things, so nothing extra is needed at all;
  the `<template>` starts right after it. Any further `:` there is just
  literal `<template>` text (`<template-text>`), not a `<pipeline-terminator>`:
  e.g., `.group:de_DE:::%v` is `group`, then the `<template>` `::%v`:
  literal `::`, then a `%v` placeholder reading `group`'s own output.
- Otherwise: nothing about the last-present part's own name-scan can tell
  "more pipeline content" apart from "a `<template>` follows" on its own
  (`group` / `scale` also use `:` for their own `<argument-fence>`, and even a
  `<format-transform>` / bare `<named-format>` name-scan must still stop at
  `:` for this same reason), so a `<pipeline-terminator>` is required. A
  single stray `:` there (not doubled) is an error, not a lenient no-op: after
  a `<format-transform-pipeline>` or `<value-transform-pipeline>`, nothing
  accepts it; after a `<named-format>`, it's simply part of `<format-name>`
  (only `::` ends a `<format-name>`), which then doesn't exist.

E.g., all of the following are valid:

- `.round.absoluteValue` (no `<template>`: no `<pipeline-terminator>`
  needed either)
- `.round.absoluteValue::%v` (`<pipeline-terminator>`, then a `%v`
  placeholder reading `absoluteValue`'s own output, not the field's original
  value, so this isn't a redundant "the value twice")
- `.rightJustify::%v` (`<format-transform-pipeline>` never ends with `:` on
  its own, so this needs the full `<pipeline-terminator>` too, unlike a
  `<value-transform-pipeline>` ending in a closed `<argument-fence>`)
- `.round.absoluteValue/1d` (`<sort-modifier>` follows, not a `<template>`: no
  `<pipeline-terminator>` needed)
- `.round.absoluteValue,name` (`<field-spec-separator>` follows: likewise)

Once a `<pipeline-terminator>` (or a closed `<argument-fence>`) ends
the last-present part, whatever follows is ordinary `<template>` content,
even 1 starting with `<transform-call-prefix>` (`.`): `.round::.absoluteValue`
parses `.absoluteValue` as literal `<template-text>`, not as another
`<value-transform-call>`. It's still rejected, but for a
different, more general reason: see "Templates Need a Placeholder" below.

###### Templates Need a Placeholder

A `<template>` with no `<placeholder>` at all (pure `<template-text>`)
renders identically no matter what the field's value is, which is never
useful, so it's a parse error (`<template>`'s own grammar requires a
`<placeholder>`): whether the `<template>` is `<format>`'s
entire content (no `<named-format>`, no `<format-transform-pipeline>`, no
`<value-transform-pipeline>`), follows a `<format-transform-pipeline>`
(justify; even though justify itself never reads the field's value, its
`<template>` is still `<format>`'s entire rendering), or follows a
`<named-format>` and/or a `<value-transform-pipeline>`. E.g.,
`adamID:some literal text`, `.rightJustify:: MB` & `.round::.absoluteValue`
(see above) are all errors for this reason.

A `<*-placeholder-reference>` (a bare transform pipeline, e.g., `%V.uppercase+`)
isn't a `<template>` at all, so none of this applies to it: it already
depends on the field's value (it transforms it), the same way a bare
`<value-transform-pipeline>` does at `<format>`'s own top level.

A placeholder's own success sub-format that IS a `<template>` (& a fallible
placeholder's own failure sub-format) is exempt from needing a `<placeholder>`
whenever a bare literal couldn't stand in for it with identical behavior for
every value:

- A `%b` `<branches>` entry is always exempt, fallible or not: reaching it at
  all already depends on every earlier branch having failed, an ordering no
  bare literal placed anywhere else could replicate. E.g.,
  `%bNnumber+Oboolean+Vother++`: the `V` branch's `other` is exactly the
  point (a fixed catch-all for anything not a number or boolean), not an
  oversight, even though `V`, like `v` / `l` / `L`, is infallible.
- Outside `%b`, a fallible placeholder's (`%n` / `%N`, `%d` / `%D` & the
  standard placeholders `%u` / `%U` etc.) own success & failure are exempt for
  the same reason: reaching either one already depends on the value, e.g.,
  `%.TYes+No+` (a coerced, verbose `isTrue` placeholder: success `Yes`,
  failure `No`).
- Outside `%b`, an infallible placeholder's (`%v` / `%V`, `%l` / `%L`) own
  success is not exempt: it always applies regardless of the value, so
  `%Vconstant+` is exactly as replaceable by a bare `constant` as a bare
  `<template>` would be, & is exactly as much an error.

###### `group`

`group` inserts `<group-separator>` into the field's integer part every
`<group-digit-count>` digits, counting from the right (e.g., a `<group-
separator>` of `,` & a `<group-digit-count>` of `3` renders `1234567` as
`1,234,567`); any fractional part (after a literal `.`) & a leading `-` sign
are left untouched.

- `group` is a `<terminal-number-transform>`: its own output (digits
  interspersed with `<group-separator>`) generally isn't itself a valid
  number, so no further `<non-terminal-number-transform>` could meaningfully
  operate on it. It may still be preceded by 1 or more of those (e.g., a byte
  count scaled to megabytes, then grouped: `.scale:10,6,,0:.group`), just
  never followed by another transform.
- Absent `<group-arguments>` entirely, or given only `<group-locale-name>`,
  `<group-separator>` & `<group-digit-count>` come from the system default
  locale, or the named locale, respectively.
- `<group-locale-name>` & `<explicit-group-arguments>` are distinguished by
  content, not position: text with no bare `<argument-separator>` is a locale
  name; text with exactly 1 is `<group-separator>` & `<group-digit-count>`.
  Escape `,` or `:` to use either in a `<group-separator>` (e.g.,
  `.group:\,,3:`).
- E.g., `.group` (system locale; note the absent `<argument-fence>`: bare
  `group`, not `group:`, since an empty `<group-arguments>` is invalid),
  `.group:de_DE:` (a named locale's separator & digit count), `.group: ,3:`
  (explicit: a space every 3 digits).

###### `scale`

`scale` divides the field's value by `radix^exponent`, optionally rounds it to
`significant-digits` total `radix` digits, then renders it in positional
notation, base `radix`, with exactly `fractional-digits` digits after the
radix point.

- Both roundings (to `significant-digits` & the final rounding to
  `fractional-digits`) are half-away-from-zero.
- `fractional-digits` of `0` renders a plain integer, with no radix point.
- For `radix` > 10, digits beyond `9` are lowercase `a`-`z`.
- `0` always renders as `0` (`0` followed by `fractional-digits` `0`s, if
  any), never spelled out.
- E.g., a byte count as whole decimal megabytes: `.scale:10,6,,0:`.

##### Format Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-transform-pipeline = ( <transform-call-prefix> <format-transform> )+

format-transform     = <left-justify> | <center-start-justify> | <center-end-justify> | <right-justify>
left-justify         = "leftJustify"
center-start-justify = "centerStartJustify"
center-end-justify   = "centerEndJustify"
right-justify        = "rightJustify"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Unlike a `<value-transform>`, a `<format-transform>` doesn't act on any
value; it sets a property of the field itself, currently just its
`table`-output column
alignment (default: `leftJustify`). So it has no effect on the field's
rendered value: it's a no-op for `json` / `key-value` output (which have no
column to align), & doesn't force `%v` / `%V`'s type-preserving `json`
passthrough into a string, unlike every other transform. For this reason, a
`<format-transform-pipeline>` may only appear where `<format>` itself allows
it (right after the field's own optional `<named-format>`, before anything
else), never inside a placeholder's own success / failure sub-format, where
only ordinary `<value-transform>`s are valid.

`centerStartJustify` & `centerEndJustify` differ only when the column's
padding is odd-width: `centerStartJustify` puts the extra padding character
after the value (leaving it nearer the column's start); `centerEndJustify`
puts it before the value (leaving it nearer the column's end).

If more than 1 `<format-transform>` appears in the pipeline, the last 1 wins.

A `<format-transform-pipeline>` never ends with `:` on its own (a
`<format-transform>` never takes arguments, so it has no `<argument-fence>`
to close), so a `<template>` following 1 always needs the full
`<pipeline-terminator>` (`::`) first; see "Pipeline Terminator" under
"Transforms" above, which states this rule once, for `<named-format>`,
`<format-transform-pipeline>` & `<value-transform-pipeline>` alike, rather
than 3 separate times.

###### `iso` & `localTimeZone`

The output side's default time zone is local. `iso`, absent `localTimeZone`,
switches it to UTC. `localTimeZone` (with or without `iso`) keeps it local,
i.e., it overrides `iso`'s zone switch when both are given.

##### Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
placeholder = <infallible-placeholder> | <fallible-placeholder>

placeholder-header = <placeholder-prefix> [ <placeholder-negation> ] [ <placeholder-coercion> ]

placeholder-prefix   = "%"
placeholder-negation = "-"
placeholder-coercion = "."

format-delimiter = "+"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Success & Failure

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
standard        = <string-placeholder-reference> | <standard-format>
standard-format = ( <placeholder> | <standard-text> )+
standard-text   = {text}

failure        = <string-placeholder-reference> | <failure-format>
failure-format = ( <placeholder> | <failure-text> )+
failure-text   = {text}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A placeholder succeeds if it matches the value against which it is evaluated.

A placeholder fails if it does not match the value against which it is
evaluated.

Infallible placeholders cannot fail.

- If a placeholder succeeds, the following is inserted in situ:
  - If a success format is present for the placeholder: its evaluated value.
  - Otherwise: the placeholder's default.
- If a placeholder fails (e.g., `%-u` is evaluated against a `null`):
  - If `<failure>` is present for the placeholder, its evaluated value is
    inserted in situ.
  - Otherwise: formatting aborts, outputting an empty string, ignoring the rest
    of `<format>`, both preceding & succeeding.

###### Infallible Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
infallible-placeholder = <concise-infallible-placeholder> | <verbose-infallible-placeholder>

concise-infallible-placeholder = <concise-value-placeholder> | <concise-label-placeholder>
verbose-infallible-placeholder = <verbose-value-placeholder> | <verbose-label-placeholder>

concise-value-placeholder = <placeholder-prefix> <concise-value>
verbose-value-placeholder = <placeholder-prefix> <verbose-value> [ <standard> ] <format-delimiter>
concise-label-placeholder = <placeholder-header> <concise-label>
verbose-label-placeholder = <placeholder-header> <verbose-label> [ <standard> ] <format-delimiter>

concise-value = "v" (* always; default: verbatim field value; empty string if `null` *)
verbose-value = "V" (* always; default: verbatim field value; empty string if `null` *)
concise-label = "l" (* always; default: verbatim field label; negated default: field name *)
verbose-label = "L" (* always; default: verbatim field label; negated default: field name *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Fallible Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
fallible-placeholder = <concise-fallible-placeholder> | <verbose-fallible-placeholder>

concise-fallible-placeholder = <concise-scalar-fallible-placeholder> | <concise-branches-placeholder>
verbose-fallible-placeholder = <verbose-scalar-fallible-placeholder> | <verbose-branches-placeholder>

concise-scalar-fallible-placeholder = <concise-standard-placeholder> | <concise-number-placeholder> | <concise-date-placeholder>
verbose-scalar-fallible-placeholder = <verbose-standard-placeholder> | <verbose-number-placeholder> | <verbose-date-placeholder>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Standard Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
concise-standard-placeholder = <placeholder-header> <concise-standard-placeholder-character>
verbose-standard-placeholder = <placeholder-header> <verbose-standard-placeholder-character> [ <standard> ] <format-delimiter> [ <failure> ] <format-delimiter>

concise-standard-placeholder-character = <concise-null> | <concise-empty> | <concise-whitespace> | <concise-boolean> | <concise-true> | <concise-false> | <concise-string>
verbose-standard-placeholder-character = <verbose-null> | <verbose-empty> | <verbose-whitespace> | <verbose-boolean> | <verbose-true> | <verbose-false> | <verbose-string>

concise-null       = "u" (* is null;                       default: empty string; negated default: verbatim field value *)
verbose-null       = "U" (* is null;                       default: empty string; negated default: verbatim field value *)
concise-empty      = "e" (* is null or an empty string;              default: empty string; negated default: verbatim field value *)
verbose-empty      = "E" (* is null or an empty string;              default: empty string; negated default: verbatim field value *)
concise-whitespace = "w" (* is null, an empty string, or a string of only whitespace; default: empty string; negated default: verbatim field value *)
verbose-whitespace = "W" (* is null, an empty string, or a string of only whitespace; default: empty string; negated default: verbatim field value *)

concise-boolean    = "o" (* is boolean;                    default: verbatim field value *)
verbose-boolean    = "O" (* is boolean;                    default: verbatim field value *)
concise-true       = "t" (* is true;                       default: verbatim field value *)
verbose-true       = "T" (* is true;                       default: verbatim field value *)
concise-false      = "f" (* is false;                      default: verbatim field value *)
verbose-false      = "F" (* is false;                      default: verbatim field value *)
concise-string     = "s" (* is string;                     default: verbatim field value *)
verbose-string     = "S" (* is string;                     default: verbatim field value *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Number Formatting (`%n` & `%N`)

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
number-placeholder = <concise-number-placeholder> | <verbose-number-placeholder>

concise-number-placeholder = <placeholder-header> <concise-number>
verbose-number-placeholder = <placeholder-header> <verbose-number> [ <number> ] <format-delimiter> [ <failure> ] <format-delimiter>

concise-number = "n" (* is number; default: verbatim field value *)
verbose-number = "N" (* is number; default: verbatim field value *)

number               = <number-placeholder-reference> | <number-format>
number-format        = ( <placeholder> | <inline-number-format> )+
inline-number-format = {text}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Coercion

`<placeholder-coercion>` broadens a placeholder's match to also accept a field
value stored as a JSON string that itself parses as the placeholder's target
type, instead of requiring the field value's own JSON type to already match:

- `%.n` / `%.N`: matches a JSON number, or a JSON string containing a valid
  number.
- `%.o` / `%.O`: matches a JSON boolean, or a JSON string equal to `true` or
  `false`.
- `%.t` / `%.T`: matches JSON `true`, or the JSON string `"true"`.
- `%.f` / `%.F`: matches JSON `false`, or the JSON string `"false"`.

`<placeholder-coercion>` doesn't change a placeholder's default rendering
(still the field's verbatim value) or a success format's input (still the
field's own value; e.g., a `<number-transform-pipeline>` in `%.n`'s success
format parses & transforms a coerced string exactly as it would a real JSON
number); it only widens which raw values count as a match.

`<placeholder-coercion>` is valid only on `%n` / `%N` & the boolean-ish
standard placeholders (`%o` / `%O` / `%t` / `%T` / `%f` / `%F`); using it on
any other placeholder is an error.

###### Date Formatting (`%d` & `%D`)

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
date-placeholder = <concise-date-placeholder> | <verbose-date-placeholder>

concise-date-placeholder = <placeholder-header> <concise-date>
verbose-date-placeholder = <placeholder-header> <verbose-date> [ <date> ] <format-delimiter> [ <failure> ] <format-delimiter>

concise-date = "d" (* matches a specified date format; default: depending on input, ISO date / datetime / time in system time zone; negated default: verbatim field value *)
verbose-date = "D" (* matches a specified date format; default: depending on input, ISO date / datetime / time in system time zone; negated default: verbatim field value *)

date               = <input-date-format> … <date-input-format-separator> <date-input-output-separator> [ <output-date-format> ] | <output-date-format>
input-date-format  = <date-format>
output-date-format = <date-format> (* default: ISO-8601 datetime in local time zone *)

date-format        = <date-placeholder-reference> | <inline-date-format>
inline-date-format = {text}

date-input-format-separator = ","
date-input-output-separator = "_"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Input is always auto-detected, trying, in order: ISO-8601 datetime, ISO-8601
date-only, then a Unix epoch (seconds) numeric timestamp. If
`<output-date-format>` is absent, output defaults to ISO-8601 datetime in the
local time zone. Neither depends on field name, label, output format, or any
other context.

A custom `<input-date-format>` & an `<output-date-format>` that isn't a bare
`<date-transform-pipeline>` (i.e., a named-format reference, or literal
pattern text) aren't implemented yet; using either is a parse error, rather
than silently falling back to the defaults above:

- `<input-date-format>` needs a defined pattern language for
  `<inline-date-format>`, which doesn't exist yet.
- A named `<output-date-format>` needs persisted named formats (see
  "Named Formats" above); a literal one needs the same pattern language
  `<input-date-format>` does.

###### Branched Formatting (`%b` & `%B`)

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
branches-placeholder = <concise-branches-placeholder> | <verbose-branches-placeholder>

concise-branches-placeholder = <placeholder-prefix> <concise-branches> <branches> <format-delimiter>
verbose-branches-placeholder = <placeholder-prefix> <verbose-branches> <branches> <format-delimiter> [ <failure> ] <format-delimiter>

concise-branches = "b" (* matches a branch in `<branches>`; default: matched branch value *)
verbose-branches = "B" (* matches a branch in `<branches>`; default: matched branch value *)

(* At least 2 branches total (a single branch is just an ordinary
   placeholder, with no need for `%b` / `%B`): 1+ `<fallible-branch>`s,
   then 1 final `<branch>`, fallible or not. *)
branches = <fallible-branch>+ <branch>
branch   = <fallible-branch> | <infallible-branch>

fallible-branch         = <concise-fallible-branch> | <verbose-fallible-branch>
concise-fallible-branch = [ <placeholder-negation> ] [ <placeholder-coercion> ] ( <concise-standard-placeholder-character> | <concise-number> | <concise-date> )
verbose-fallible-branch = <verbose-standard-branch> | <verbose-number-branch> | <verbose-date-branch>
verbose-standard-branch = [ <placeholder-negation> ] [ <placeholder-coercion> ] <verbose-standard-placeholder-character> [ <standard> ] <format-delimiter>
verbose-number-branch   = [ <placeholder-negation> ] [ <placeholder-coercion> ] <verbose-number> [ <number> ] <format-delimiter>
verbose-date-branch     = [ <placeholder-negation> ] <verbose-date> [ <date> ] <format-delimiter>

infallible-branch         = <concise-infallible-branch> | <verbose-infallible-branch>
concise-infallible-branch = <concise-value> | [ <placeholder-negation> ] <concise-label>
verbose-infallible-branch = ( <verbose-value> | [ <placeholder-negation> ] <verbose-label> ) [ <standard> ] <format-delimiter>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- Branches in `<branches>` are evaluated sequentially against the field value:
  - If a branch succeeds, its value is returned as `<branches-placeholder>`'s
    value.
  - If a branch fails, the next branch in `<branches>` is evaluated.
- Fallible placeholders may be used for any branch, but infallible placeholders
  may be used only as the last branch.
- `<branches>` needs at least 2 branches: with only 1, `<branches-placeholder>`
  is exactly as good as just using that 1 branch's own placeholder directly,
  since there's nothing else to sequentially fall through to.
- `%b` & `%B` may not themselves be used as branches.
- `<placeholder-coercion>` on a branch follows the same restriction as on a
  top-level placeholder (see "Coercion" above): valid only on a number or
  boolean-ish standard branch.
- If all branches fail:
  - For `%b`: the placeholder fails & aborts formatting.
  - For `%B`: returns its `<failure>`'s value.

Examples:

- `%bN.absoluteValue+oV.uppercase++`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, outputs the uppercased value.
- `%BN.absoluteValue+o+Status Unknown+`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, outputs `"Status Unknown"`.
