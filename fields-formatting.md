#### Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-modifier        = <format-modifier-prefix> [ <format> ] (* default: contextual default formatting *)
format-modifier-prefix = ":"

format      = <format-reference> | ( <placeholder> | <format-text> )+
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

##### References

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-reference             = <named-format> [ <string-transform-pipeline> ] | <string-transform-pipeline>
string-placeholder-reference = <named-string-format> [ <string-transform-pipeline> ] | <string-transform-pipeline>
number-placeholder-reference = <named-number-format> [ <number-transform-pipeline> ] | <number-transform-pipeline>
date-placeholder-reference   = <named-date-format> [ <date-transform-pipeline> ] | <date-transform-pipeline>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

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
  displaying it.

##### Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-transform-pipeline = ( <transform-call-prefix> <string-transform> )+
number-transform-pipeline = ( <transform-call-prefix> <number-transform> )+
date-transform-pipeline   = ( <transform-call-prefix> <date-transform> )+

transform-call-prefix = "."

transform        = <string-transform> | <number-transform> | <date-transform>
string-transform = <capitalize> | <lowercase> | <sentence-case> | <trim-whitespace> | <uppercase>
number-transform = <absolute-value> | <round> | <scale>
date-transform   = <iso> | <date-only> | <local-time-zone>

capitalize      = "initialUppercase"
lowercase       = "lowercase"
sentence-case   = "sentenceCase"
trim-whitespace = "trimWhitespace"
uppercase       = "uppercase"

absolute-value  = "absoluteValue"
round           = "round"
scale           = "scale" <scale-parameters>

iso             = "iso"
date-only       = "dateOnly"
local-time-zone = "localTimeZone"

scale-parameters          = <scale-parameter-fence> <radix> <scale-parameter-separator> <exponent> <scale-parameter-separator> [ <significant-digits> ] <scale-parameter-separator> <fractional-digits> <scale-parameter-fence>
scale-parameter-fence     = ":"
scale-parameter-separator = ","

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

- If one or more `<input-date-format>` are present, the earliest that matches
  the input is used.
- Otherwise, the following formats are tried in descending order:
  - Content: integer:
    - Unix epoch
  - Content: string:
    - ISO-8601
    - …
  - Defaults also based on:
    - Field names
    - Field labels
    - Context
    - Etc.?

If `<output-date-format>` is absent, default output format is determined by:

- Context?
- Output format?
- Field label?
- Field name?
- Default: ISO-8601 datetime in local time zone.

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
