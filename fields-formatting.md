#### Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-modifier        = <format-modifier-prefix> [ <format> ] (* default: contextual default formatting *)
format-modifier-prefix = ":"

format      = [ <named-format> ] [ <format-transform-pipeline> ] [ <chain-terminator> ] [ <string-transform-pipeline> | ( <placeholder> | <format-text> )+ ]
format-text = {text\[:<name-prefix>:][:<transform-call-prefix>:]\\[:<placeholder-prefix>:][:<sort-modifier-prefix>:][:<field-spec-separator>:]}
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

`<named-format>`, if present, is the base value; `<format-transform-pipeline>`
(see "Format Transforms" below), if present, always comes next, before
anything else. What follows is either a `<string-transform-pipeline>` (applied
to `<named-format>`'s value, or `%v`'s if `<named-format>` is absent) or an
inline template (`<placeholder>` / `<format-text>`); never both.

Neither a name nor a transform name stops at `<placeholder-prefix>` on its
own: `<name-prefix>someFormat%v` is an attempt at a named format literally
called `someFormat%v` (& fails as one if it doesn't exist), not `someFormat`
followed by a `%v` placeholder. A `<chain-terminator>` (see "Format
Transforms") — needed even with 0 `<format-transform>`s, e.g., right after a
bare `<named-format>` — or `<transform-call-prefix>` (for another transform)
is what actually separates them: `<name-prefix>someFormat<chain-terminator>%v`
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

A placeholder's own `<success>` / `<failure>` sub-format uses these
placeholder-level references, not `<format>` itself — so a
`<format-transform-pipeline>` (only ever part of `<format>`) never applies
inside one.

##### Named Formats

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
named-format = <name-prefix> <format-name>
format-name  = {text\\[:<transform-call-prefix>:][:<sort-modifier-prefix>:][:<field-spec-separator>:]}

named-string-format     = <name-prefix> <placeholder-format-name>
named-number-format     = <name-prefix> <placeholder-format-name>
placeholder-format-name = {text\\[:<transform-call-prefix>:][:<format-delimiter>:]}

named-date-format = <name-prefix> <date-format-name>
date-format-name  = {text\\[:<transform-call-prefix>:][:<format-delimiter>:][:<date-input-format-separator>:][:<date-input-output-separator>:]}

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
  `<format>` — no `<format-transform-pipeline>`, `<chain-terminator>`,
  `<string-transform-pipeline>`, or template may follow it, since a hidden
  field is never rendered, & anything following it would be dead
  configuration.

##### Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-transform-pipeline = ( <transform-call-prefix> <string-transform> )+
date-transform-pipeline   = ( <transform-call-prefix> <date-transform> )+

(* A `<terminal-number-transform>` (currently just `group`) produces a value
   no other `<number-transform>` can operate on further (see `group`'s own
   note below), so it may only ever appear last: either alone, or after 1+
   `<non-terminal-number-transform>`s. This is the 1 exception to `<transform>`
   ordering being unconstrained; the grammar enforces it directly, rather than
   leaving it to prose. *)
number-transform-pipeline = ( <transform-call-prefix> <non-terminal-number-transform> )+ [ <transform-call-prefix> <terminal-number-transform> ]
                          | <transform-call-prefix> <terminal-number-transform>

transform-call-prefix = "."

transform                     = <string-transform> | <non-terminal-number-transform> | <terminal-number-transform> | <date-transform>
string-transform              = <capitalize> | <lowercase> | <sentence-case> | <trim-whitespace> | <uppercase>
non-terminal-number-transform = <absolute-value> | <round> | <scale>
terminal-number-transform     = <group>
date-transform                = <iso> | <date-only> | <local-time-zone>

capitalize      = "initialUppercase"
lowercase       = "lowercase"
sentence-case   = "sentenceCase"
trim-whitespace = "trimWhitespace"
uppercase       = "uppercase"

absolute-value = "absoluteValue"
round          = "round"
scale          = "scale" <scale-arguments>
group          = "group" [ <group-arguments> ]

iso             = "iso"
date-only       = "dateOnly"
local-time-zone = "localTimeZone"

group-arguments          = <argument-fence> ( <group-locale-name> | <explicit-group-arguments> ) <argument-fence>
explicit-group-arguments = <group-separator> <argument-separator> <group-digit-count>

scale-arguments    = <argument-fence> <radix> <argument-separator> <exponent> <argument-separator> [ <significant-digits> ] <argument-separator> <fractional-digits> <argument-fence>
argument-fence     = ":" (* fences any transform's argument list; generic, not `scale`-specific *)
argument-separator = "," (* separates a transform's own arguments; generic, not `scale`-specific *)

group-locale-name = {text} (* must not contain `,` / `:`; default: {system default locale name} *)
group-separator   = {text} (* must not contain `,` / `:` *)
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
  content, not position: text with no `<argument-separator>` is a locale
  name; text with exactly 1 is `<group-separator>` & `<group-digit-count>`.
  Neither supports escaping (unlike most other `{text}` values in this spec),
  so `<group-separator>` can't itself be `,` / `:` / `.` / `+` / `%`; use a
  `<group-locale-name>` instead if you need 1 of those (e.g., a locale using
  `.` for grouping).
- E.g., `.group` (system locale; note the absent `<argument-fence>` — bare
  `group`, not `group:`, since an empty `<group-arguments>` is invalid),
  `.group:de_DE:` (a named locale's separator & digit count), `.group: ,3:`
  (explicit: a space every 3 digits).

###### `scale`

`scale` divides the field's value by `radix^exponent`, optionally rounds it to
`significant-digits` total `radix` digits, then renders it in positional
notation, base `radix`, with exactly `fractional-digits` digits after the
radix point.

- Both roundings (to `significant-digits`, & the final rounding to
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

chain-terminator = ":"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Unlike a `<transform>`, a `<format-transform>` doesn't act on any value — it
sets a property of the field itself, currently just its `table`-output column
alignment (default: `leftJustify`). So it has no effect on the field's
rendered value: it's a no-op for `json` / `key-value` output (which have no
column to align), & doesn't force `%v` / `%V`'s type-preserving `json`
passthrough into a string, unlike every other transform. For this reason, a
`<format-transform-pipeline>` may only appear where `<format>` itself allows
it (right after the field's own optional `<named-format>`, before anything
else) — never inside a placeholder's own `<success>` / `<failure>`
sub-format, where only ordinary `<transform>`s are valid.

`centerStartJustify` & `centerEndJustify` differ only when the column's
padding is odd-width: `centerStartJustify` puts the extra padding character
after the value (leaving it nearer the column's start); `centerEndJustify`
puts it before the value (leaving it nearer the column's end).

If more than 1 `<format-transform>` appears in the pipeline, the last 1 wins.

`<chain-terminator>` (see `<format>` above; it's not part of
`<format-transform-pipeline>` itself, since it can appear even with 0
`<format-transform>`s, e.g., right after a bare `<named-format>`) closes off
naming / transforms before whatever follows (a `<string-transform-pipeline>`
or a template). It's needed only when what follows wouldn't otherwise
unambiguously do so (i.e., isn't itself `<transform-call-prefix>`, or an
existing `<format>` terminator, e.g., `<sort-modifier-prefix>` /
`<field-spec-separator>`) — otherwise, whatever follows (a `<placeholder>`
included) is read as (part of) an attempted, likely invalid, name. E.g.,
`.rightJustify:` unambiguously ends a pipeline before literal template text or
a `%v` placeholder; `.rightJustify` alone doesn't need it before a sort
modifier, since that already unambiguously ends it.

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
placeholder-coercion = "c"

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
standard-text   = {text\[:<name-prefix>:][:<transform-call-prefix>:]\\[:<placeholder-prefix>:][:<format-delimiter>:]}

failure        = <string-placeholder-reference> | <failure-format>
failure-format = ( <placeholder> | <failure-text> )+
failure-text   = {text\[:<name-prefix>:][:<transform-call-prefix>:]\\[:<placeholder-prefix>:][:<format-delimiter>:]}
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
inline-number-format = {text\[:<name-prefix>:][:<transform-call-prefix>:]\\[:<placeholder-prefix>:][:<format-delimiter>:]}
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Coercion

`<placeholder-coercion>` broadens a placeholder's match to also accept a field
value stored as a JSON string that itself parses as the placeholder's target
type, instead of requiring the field value's own JSON type to already match:

- `%cn` / `%cN`: matches a JSON number, or a JSON string containing a valid
  number.
- `%co` / `%cO`: matches a JSON boolean, or a JSON string equal to `true` or
  `false`.
- `%ct` / `%cT`: matches JSON `true`, or the JSON string `"true"`.
- `%cf` / `%cF`: matches JSON `false`, or the JSON string `"false"`.

`<placeholder-coercion>` doesn't change a placeholder's default rendering
(still the field's verbatim value) or a success format's input (still the
field's own value; e.g., a `<number-transform-pipeline>` in `%cn`'s success
format parses & transforms a coerced string exactly as it would a real JSON
number) — it only widens which raw values count as a match.

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

concise-date = "d" (* matches a specified date format; default: depending on input, ISO date/datetime/time in system time zone; negated default: verbatim field value *)
verbose-date = "D" (* matches a specified date format; default: depending on input, ISO date/datetime/time in system time zone; negated default: verbatim field value *)

date               = <input-date-format> … <date-input-format-separator> <date-input-output-separator> [ <output-date-format> ] | <output-date-format>
input-date-format  = <date-format>
output-date-format = <date-format> (* default: ISO-8601 datetime in local time zone *)

date-format        = <date-placeholder-reference> | <inline-date-format>
inline-date-format = {text\[:<name-prefix>:][:<transform-call-prefix>:]\\[:<date-input-format-separator>:][:<date-input-output-separator>:][:<format-delimiter>:]}

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

A custom `<input-date-format>`, & an `<output-date-format>` that isn't a bare
`<date-transform-pipeline>` (i.e., a named-format reference, or literal
pattern text), aren't implemented yet — using either is a parse error, rather
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

branches = [ <fallible-branch>+ ] <branch>
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
