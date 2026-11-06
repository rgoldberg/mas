<!--markdownlint-disable-file first-line-heading-->
#### Formatting

```ebnf
format-modifier        = <format-modifier-prefix> -[ <format-block> ]-
format-modifier-prefix = ":"

format-block =
  <named-format-pipeline(<preset-name>)> | <format-template>
  (* direct default: {empty string}; inherited *)

format-template = [ <template-text> ] ( <placeholder> [ <template-text> ] )+

template-text = ~^{string}^~
```

##### Value Types

Each of the following evaluates to a value whose type is:

- `<block>`: its pipeline's or template's type.
- Pipeline: its last `<value-transform>`'s output type; absent any, its named
  format's value's type.
- Placeholder: its inserted value's type.
- Template: if solely 1 placeholder, that placeholder's type; otherwise, string.
- Template text: string.

A field value may also be an array or an object, each a **structured value**. No
predicate whose output type is not any (e.g., `%s` or `%.n`), except `%.s` &
`%.S`, matches a structured value.

A **date** is a date-only or a datetime, either of which an input format may
support alone. An input format **supports** a type iff its field values can have
that type (e.g., JSON supports no version, date-only, datetime, or time-only).

A **default coercion** is a `<coercion>` without arguments.

An **implicit coercion** coerces a field value, at its original type, absent a
`<coercion>`, wherever syntax requires a type that its input format does not
support, iff a default coercion would coerce it to that type, because no value
can otherwise ever satisfy that syntax without a `<coercion>` (e.g., for JSON
input, `%v` matches `"1.2.3"`, `%c` matches `"17:39:23"`, while `%d` &
`.dateOnly` accept `"2020-03-18"` & the Unix time `0`). A `<coercion>` replaces
it, ignoring its defaults (e.g., `%.:iso:d` does not match `0`).

No implicit coercion gives a value a type that its input format supports, so
only a `<coercion>` does (e.g., for JSON input, `%n` does not match `"5"`, while
`%.n` does, and for an input format that supports date-only & datetime, but not
time-only, `%d` would match no string, while `%c` would match `"17:39:23"`, and
for one that supports date-only, but not datetime, `%d` would match `0`, but not
`"2020-03-18"`).

A `<coercion>` to a type that its input format does not support thus remains
useful to choose its `<date-format>`s & to abort formatting, rather than report
an error, for an input that it cannot coerce (e.g., for `"abc"`, `..dateOnly`
aborts, while `.dateOnly` reports an error).

A field spec's **formatted value** is its `<format-block>`'s value, at its type,
regardless of the output format, which renders it at its type iff it supports
that type (JSON: string, boolean, `null`, structured value & a number whose
text, including any trivia, is in `number`'s [lexical
form](ebnf.md#typed-terminals); table & key-value: string); otherwise, it
renders it coerced to a string.

An output format modifies a value's text only as its syntax requires, when it
renders the value (e.g., [JSON output](json.md#json-config) renders the number
`+01.50` as `1.50`, while table & key-value output render it as is).

##### Pipelines

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
pipeline(NAMED_FORMAT_REFERENCE, NAMED_TRANSFORM_PIPELINE, TRANSFORM_PIPELINE) = TRANSFORM_PIPELINE | NAMED_FORMAT_REFERENCE [ NAMED_TRANSFORM_PIPELINE ]

named-format-pipeline(FORMAT_NAME) = <pipeline(<named-format-reference(FORMAT_NAME)>, <value-transform-pipeline>, <value-transform-pipeline>)>

named-pipeline(FORMAT_NAME, TRANSFORM_PIPELINE) = <named-format-reference(FORMAT_NAME)> [ TRANSFORM_PIPELINE ]

trimmable-pipeline(NAMED_PIPELINE) = NAMED_PIPELINE | <transform-run(<transform-call-prefix> <coercion>, <trim-whitespace>)>

string-pipeline               = <pipeline(<named-format-reference(<string-format-name>)>, <value-transform-pipeline>, <string-input-pipeline>)>
version-pipeline              = <pipeline(<named-format-reference(<version-format-name>)>, <value-transform-pipeline>, <version-input-pipeline>)>
number-pipeline               = <pipeline(<named-format-reference(<number-format-name>)>, <value-transform-pipeline>, <number-input-pipeline>)>
date-pipeline                 = <pipeline(<named-format-reference(<date-format-name>)>, <value-transform-pipeline>, <date-input-pipeline>)>
date-only-pipeline            = <pipeline(<named-format-reference(<date-format-name>)>, <value-transform-pipeline>, <coerced-string-chain>)>
time-only-pipeline            = <pipeline(<named-format-reference(<time-only-format-name>)>, <value-transform-pipeline>, <time-only-input-pipeline>)>
unconditional-pipeline        =
  <pipeline(<named-format-reference(<unconditional-format-name>)>, <unconditional-transform-pipeline>, <unconditional-transform-pipeline>)>
unconditional-string-pipeline =
  <pipeline(
    <named-format-reference(<unconditional-format-name>)>,
    <uncoerced-string-transform-run> | <unconditional-transform-pipeline>,
    <uncoerced-string-transform-run>
  )>
named-unconditional-pipeline  = <named-pipeline(<unconditional-format-name>, <unconditional-transform-pipeline>)>
named-input-pipeline          = <named-pipeline(<preset-name>, <value-transform-pipeline>)>
whitespace-pipeline           = <trimmable-pipeline(<named-unconditional-pipeline>)>
whitespace-input-pipeline     = <trimmable-pipeline(<named-input-pipeline>)>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Named Formats

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
named-format-reference(FORMAT_NAME) = <name-prefix> FORMAT_NAME

format-name(BLOCK) = <preset-name> (* error: its preset's format does not conform to BLOCK *)

string-format-name        = <format-name(<conditional-block(<nullary-string>, <non-nullary-string>, <named-format-pipeline(<string-format-name>)>)>)>
version-format-name       = <format-name(<conditional-block(<nullary-version>, <non-nullary-version>, <named-format-pipeline(<version-format-name>)>)>)>
number-format-name        = <format-name(<conditional-block(<nullary-number>, <non-nullary-number>, <named-format-pipeline(<number-format-name>)>)>)>
date-format-name          = <format-name(<conditional-block(<nullary-date>, <non-nullary-date>, <named-format-pipeline(<date-format-name>)>)>)>
time-only-format-name     = <format-name(<conditional-block(<nullary-time-only>, <non-nullary-time-only>, <named-format-pipeline(<time-only-format-name>)>)>)>
unconditional-format-name = <format-name(<unconditional-block>)>

name-prefix = ":"!
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A `<named-format-reference>` references the format of the
[preset](fields.md#presets) that its `<preset-name>` names, its **named format**
(e.g., `:x` references preset `x`'s format), which is the format that attaching
that preset sets (including via the presets attached within it), or `%i` if it
sets none; it applies none of the preset's other settings (e.g., its alignment).

A `<named-format-reference>` evaluates its named format against the value to
which a `<transform-pipeline>` in its position would be applied (e.g., in
`%+.N:x+`, the coerced number, which a `%n` in `x`'s format inserts).

Because every `<format-name>`'s `BLOCK` includes `<unconditional-block>`'s
syntax, a named unconditional format conforms to every one.

An empty named format (e.g., that of a preset `e` of `:`) conforms to every
`<format-name>`'s `BLOCK`, because a directly absent block evaluates to an empty
string, as an empty named format does (e.g., `%S:e+none+` inserts an empty
string for a string).

##### Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
transform-pipeline = <value-transform-pipeline> | <unconditional-transform-pipeline> | <uncoerced-string-transform-run> (* non-structural *)

value-transform-pipeline =
  <string-chain(<transform-call-prefix>)>
  | <number-chain(<transform-call-prefix>)>
  | <date-chain(<transform-call-prefix>)>
  | <time-only-chain(<transform-call-prefix>)>
  | <coerced-chain>

string-input-pipeline    = <string-chain(<transform-call-prefix>)> | <after-string-run>
number-input-pipeline    = <number-chain(<transform-call-prefix>)> | <coerced-string-chain> | <number-date-chain>
version-input-pipeline   = <coerced-string-chain> | <coerced-number-chain> | <version-date-only-chain> | <unix-time-date-chain>
date-input-pipeline      = <date-chain(<transform-call-prefix>)> | <coerced-string-chain>
time-only-input-pipeline = <time-only-chain(<transform-call-prefix>)> | <coerced-string-chain>

unconditional-transform-pipeline = <coerced-string-transform-call> [ <uncoerced-string-transform-run> ]
uncoerced-string-transform-run   = <transform-run(<transform-call-prefix>, <string-transform>)>
coerced-string-transform-call    = <transform-call(<transform-call-prefix> <coercion>, <string-transform>)>

transform-chain(CALL_PREFIX, TRANSFORM, AFTER_RUN) = <transform-run(CALL_PREFIX, TRANSFORM)> [ AFTER_RUN ]

string-chain(CALL_PREFIX)           = <transform-chain(CALL_PREFIX, <string-transform>, <after-string-run>)>
number-chain(CALL_PREFIX)           = <transform-chain(CALL_PREFIX, <number-transform>, <after-number-run>)> | <number-to-string-chain(CALL_PREFIX)>
number-to-string-chain(CALL_PREFIX) = <transform-call(CALL_PREFIX, <number-to-string-transform>)> [ <string-input-pipeline> ]
date-chain(CALL_PREFIX)             = <transform-chain(CALL_PREFIX, <date-time-zone>, <after-date-run>)> | <date-only-chain(CALL_PREFIX)>
date-only-chain(CALL_PREFIX)        = <transform-chain(CALL_PREFIX, <date-only>, <coerced-string-chain>)>
time-only-chain(CALL_PREFIX)        = <transform-chain(CALL_PREFIX, <time-only-transform>, <coerced-string-chain>)>

coerced-chain = <coerced-string-chain> | <coerced-number-chain> | <coerced-date-chain> | <coerced-date-only-chain> | <coerced-time-only-chain>

coerced-string-chain    = <string-chain(<transform-call-prefix> <coercion>)>
coerced-number-chain    = <number-chain(<transform-call-prefix> <number-coercion>)>
coerced-date-chain      = <date-chain(<transform-call-prefix> <non-date-only-coercion>)>
coerced-date-only-chain = <date-only-chain(<transform-call-prefix> <date-only-coercion>)>
coerced-time-only-chain = <time-only-chain(<transform-call-prefix> <coercion>)>
number-date-chain       = <date-chain(<transform-call-prefix> <number-date-coercion>)>
unix-time-date-chain    = <date-chain(<transform-call-prefix> <unix-time-coercion>)>
version-date-only-chain = <date-only-chain(<transform-call-prefix> <version-date-only-coercion>)>

after-string-run = <coerced-number-chain> | <coerced-date-chain> | <coerced-date-only-chain> | <coerced-time-only-chain>
after-number-run = <number-to-string-chain(<transform-call-prefix>)> | <coerced-string-chain> | <number-date-chain>
after-date-run   = <date-only-chain(<transform-call-prefix>)> | <coerced-string-chain>

transform-run(CALL_PREFIX, TRANSFORM) = <transform-call(CALL_PREFIX, TRANSFORM)> [ <transform-call(<transform-call-prefix>, TRANSFORM)>+ ]

transform-call(CALL_PREFIX, TRANSFORM) =
  CALL_PREFIX TRANSFORM
  (* error: CALL_PREFIX lacks a coercion & its input is not null, absent, of TRANSFORM's input type, or implicitly coercible to it *)

transform-call-prefix = "."!

argument-fence     = ":" (* fences an argument list *)
argument-separator = "," (* separates an argument list's arguments *)

value-transform = <string-transform> | <number-transform> | <number-to-string-transform> | <date-transform> | <time-only-transform> (* non-structural *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A `<transform-pipeline>` `t` is a pipeline of transformations applied to:
  - If a `<named-format-reference>` `n` immediately precedes `t` in its
    pipeline: `n`'s value.
  - Otherwise: the value against which its enclosing block is evaluated (i.e.,
    in a `<success-clause>`, the enclosing matcher's value; elsewhere, the
    [format input](#success--failure)).

A **transform run** is a `<transform-run>`'s contiguous calls of 1 value type. A
call whose value's type the syntax text determines takes a `<coercion>` only if
its input type differs from that type, because it otherwise has nothing to
coerce. A call whose value's type the syntax text does not determine (e.g., a
`<format-block>`'s 1st call, `%I`'s 1st call outside an `<unconditional-block>`,
or one that a `<named-format-reference>` immediately precedes, whose preset
determines it) may take one regardless. A date or a time-only coerces only to a
string, neither a number nor a version coerces to a time-only & a number coerces
to a date only as a Unix time, because its rendering is otherwise not a value of
that type, so a pipeline that means to parse it must coerce it to a string 1st
(e.g., `%.D..uppercase..:,,,,,.*:round++`).

A later `<coercion>` parses only the text rendered so far, using only its own
arguments (e.g., for `"1234.5"`, `..numberFormat:de:..:de:round` evaluates to
`1235`, while `..numberFormat:de:..round` aborts formatting, because `1.234,5`
is not a number in the canonical conventions).

An **argument** is an element of an argument list: a transform's, a [number
coercion's](#coercion), a [date coercion's](#chronologic-formatting),
[`N`'s](fields.md#sort-number-segments), or
[`C`'s](fields.md#sort-chronologic-segments).

An argument ignores its outer bare whitespace, which must be escaped to be
consumed (e.g., `.numberFormat:,\ ,3:` separates digit groups with a space).

An argument that is empty after ignoring its outer bare whitespace is absent,
which is an error iff the argument is required (e.g., `.scale:,,0:` is an error,
but `.scale:6, ,0:` omits `<significant-digits>`).

###### Value Coercion

A `null` or [absent](fields.md#absent-values) value remains unmodified through
every transform, with or without `<coercion>`, so it is never an error (e.g.,
`..uppercase` evaluates to `null` for `null`).

A `<coercion>` attempts to coerce an input value into the correct input type for
the annotated transform. If the coercion is successful, the transform is applied
to the coerced input; otherwise, formatting [aborts](#success--failure).

A number or number-to-string transform's coercion may take
[`<number-coercion-arguments>`](#coercion) (e.g., `..:de:round`), and a date
transform's may take [`<date-coercion-arguments>`](#chronologic-formatting)
(e.g., `..:unix-time:dateOnly`).

A transform's `<coercion>` to a string always succeeds, so an
`<unconditional-transform-pipeline>`, whose sole `<coercion>` is in its 1st
call, cannot fail, while one to any other type may. A value coerced to a string
is:

- `null` or [absent](fields.md#absent-values): an empty string, except as a
  transform's input, through which it remains unmodified, or for a [string
  coercion](#coercion), which does not match it.
- A boolean: `true` or `false`.
- A number: its trivia prefix, its text, then its trivia suffix (e.g., `1.50`,
  or, with [trivia](#coercion), `$1.50`).
- A date or time-only: its [rendering](#chronologic-formatting) (e.g.,
  `2020-03-18T17:39:23Z`).
- A version: its text.
- A [structured value](#value-types): its compact JSON text, with non-ASCII
  characters verbatim (e.g., `["é",{"a":null}]`).

###### String Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-transform = <initial-titlecase> | <lowercase> | <trim-whitespace> | <uppercase> (* type: string *)

initial-titlecase = 'initialTitlecase'
lowercase         = 'lowercase'
trim-whitespace   = 'trimWhitespace'
uppercase         = 'uppercase'
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Case transforms use Unicode's full, locale-independent case mappings, which can
modify a string's length (e.g., `ß` uppercases to `SS`).

<!--editorconfig-checker-disable-->
- `initialTitlecase`: titlecases the string's **initial character**, retaining
  the rest. The initial character is the 1st letter (excluding uncased modifier
  letters), number, symbol (Unicode general category `S`), or private-use
  character, per [ICU's default titlecasing index adjustment](
    https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/stringoptions_8h.html#a4975f537b9960f0330b233061ef0608d
  ). Titlecasing leaves an uncased number, symbol, or private-use character
  unmodified, but titlecases a cased one (e.g., `hello` becomes `Hello` &
  `ⓐbc` becomes `Ⓐbc`, but `1st` & `$abc` are unaffected).
- `lowercase`: lowercases every character.
- `trimWhitespace`: removes leading & trailing
  [whitespace](ebnf.md#whitespace).
- `uppercase`: uppercases every character.
<!--editorconfig-checker-enable-->

###### Number Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
number-transform           = <absolute-value> | <round> | <scale> (* type: number *)
number-to-string-transform = <number-format> (* input type: number; output type: string *)

absolute-value = 'absoluteValue'
round          = 'round'
scale          = 'scale' <scale-arguments>
number-format  = 'numberFormat' [ <argument-fence> <number-format-arguments> <argument-fence> ]
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A number transform retains its value's notation (positional or scientific),
except `scale`, whose arguments define its rendering.

###### `absoluteValue`

`absoluteValue` removes the value's leading sign (`-` or `+`), if any, retaining
the rest of its representation, e.g.:

- `-1.50` becomes `1.50`.
- `-1.5e-3` becomes `1.5e-3`.

###### `round`

`round` rounds the value exactly to the nearest integer, with halves rounded
away from 0, rendering it in the value's notation:

- Positional: as an integer (e.g., `-2.5` becomes `-3` & `007` becomes `7`).
- Scientific: in normalized scientific notation, retaining the value's exponent
  indicator (`e` or `E`) & whether a non-negative exponent has a `+` (e.g.,
  `1.25E1` becomes `1.3E1`, `9.96e+1` becomes `1e+2`, `4e-1` becomes `0e0` &
  `1.5e3` remains `1.5e3`).

A leading `+` is retained, while a leading `-` is retained iff the result is
nonzero (e.g., `+2.4` becomes `+2`, and `-0.4` becomes `0`).

###### `numberFormat`

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
number-format-arguments =
  [ <locale-identifier> ]
  <argument-separator>? [ <digit-group-separator> ]
  <argument-separator>? [ <digit-group-size> ]
  <argument-separator>? [ <secondary-digit-group-size> ]
  <argument-separator>? [ <decimal-separator> ]
  (* error: its digit group separator equals its decimal separator, each after defaulting to the base conventions *)

digit-group-separator      = {string}                (* default: {base conventions' digit group separator} *)
digit-group-size           = {integer: non-negative} (* default: {base conventions' digit group size} *)
secondary-digit-group-size = {integer: non-negative} (* default: {base conventions' secondary digit group size} *)
decimal-separator          = {string}                (* default: {base conventions' decimal separator} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The **number format arguments** are those of `<number-format-arguments>`.

`numberFormat` inserts `<digit-group-separator>` between the **digit groups** of
its input's integer part, counting from its least significant digit: the least
significant (**primary**) group has `<digit-group-size>` digits, and each other
(**secondary**) group has `<secondary-digit-group-size>` digits, or
`<digit-group-size>` digits if `<secondary-digit-group-size>` is `0`; the most
significant group may have fewer digits (e.g., `.numberFormat:canonical,,3,2:`
renders `12345678` as `1,23,45,678`).

`numberFormat` also replaces the `.` between its input's integer & fractional
parts with `<decimal-separator>` (e.g., `.numberFormat:de:` renders `1234.5` as
`1.234,5`), retaining its input's sign & leading `0`s (e.g., it renders
`+01234.50` as `+01.234,50` & `.5` as `,5`).

`numberFormat` retains scientific notation, applying to its significand &
rendering its exponent indicator & exponent verbatim (e.g., `.numberFormat:de:`
renders `12345.6E3` as `12.345,6E3`); `scale` renders positional notation before
it (e.g., `.scale:0,,2:.numberFormat:de:` renders `1.5e3` as `1.500,00`).

A `<digit-group-size>` of `0` inserts no separators, ignoring
`<secondary-digit-group-size>`.

The **base conventions** are those that
[`<locale-identifier>`](fields.md#sort-locale) identifies, per its default if it
is absent, even if other number format arguments are present. `numberFormat`'s
default is the system locale, because rendered output is for people, while a
[number coercion's](#coercion) is the [canonical](fields.md#sort-locale)
conventions, because parsed input is data, which, like sorting's default
canonical conventions, must not depend on the system.

###### `scale`

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
scale-arguments =
  <argument-fence> <exponent>
  <argument-separator>? [ <significant-digits> ]
  <argument-separator>? [ <fractional-digits> ]
  <argument-fence>

exponent           = {integer}           (* divides the input by 10 to this power before rendering *)
significant-digits = {integer: 1 to 100} (* rounds to this many significant digits; absent: no rounding *)
fractional-digits  = {integer: 0 to 100} (* exactly this many digits after the point; 0: integer; absent: exact *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`scale` applies its arguments in order, then renders its result in positional
notation (e.g., `.scale:3:` renders `1500` as `1.5`, while `.scale:6,3:` renders
`1234567` as `1.23` & `123456789` as `123`).

- Both roundings (to `<significant-digits>`, then to `<fractional-digits>`)
  round halves away from 0.
- A result's integer part has at least 1 digit & no `0` before another digit;
  absent `<fractional-digits>`, its fractional part has no trailing `0`s (e.g.,
  `.scale:0:` renders `01.50` as `1.5`, while `.scale:3:` renders `500` as
  `0.5`).
- A leading `+` is retained, while a leading `-` is retained iff the result is
  nonzero (e.g., `.scale:0,,0:` renders `+2.4` as `+2` & `-0.4` as `0`), as for
  `round`.
- A value that would render with more than 100 digits before the decimal point,
  or, absent `<fractional-digits>`, after it, [aborts](#success--failure)
  formatting, with or without `<coercion>`, because that restricts rendering,
  not a number (e.g., `.scale:0,,0:` for `1e100`, or `.scale:0:` for `1e-101`).
- E.g., a byte count as integer megabytes: `.scale:6,,0:`, or as megabytes to 3
  significant digits: `.scale:6,3:`; a ratio as an integer percentage:
  `.scale:-2,,0:` (e.g., `0.25` as `25`).

###### Chronologic Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
date-transform      = <date-only> | <date-time-zone> (* non-structural *)
time-only-transform = <time-only-time-zone> (* type: time-only *)

date-only           = 'dateOnly' (* input type: date; output type: date-only *)
date-time-zone      = 'timeZone' [ <date-time-zone-arguments> ] (* type: date; sets the output time zone; last wins *)
time-only-time-zone = 'timeOnlyTimeZone' [ <time-only-time-zone-arguments> ] (* sets the output time zone; last wins *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A date's or a time-only's contiguous transforms jointly set how it is rendered,
until a `<coercion>` renders it:

- `dateOnly`: renders only the date, in the output time zone.
- `timeZone` (for a date) & `timeOnlyTimeZone` (for a time-only): set the output
  time zone to the one that their `<time-zone-code>` identifies.

Absent `timeZone` & `timeOnlyTimeZone`, the output time zone is the system time
zone.

A date-only value's date is independent of time zones, so `timeZone` does not
affect it.

A time-only value is rendered in the output time zone as if on the last
`timeOnlyTimeZone`'s `<reference-date>`, because a time zone's UTC offset can
vary by date (e.g., for daylight saving time), or, absent `timeOnlyTimeZone`, on
the current date in the system time zone. A UTC offset `<time-zone-code>` has a
fixed UTC offset, but a Foundation time zone abbreviation may identify a time
zone whose UTC offset varies (e.g., `EST` identifies `America/New_York`).

###### `timeZone` & `timeOnlyTimeZone`

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
date-time-zone-arguments      = <argument-fence> [ <time-zone-code> ] <argument-fence>
time-only-time-zone-arguments = <argument-fence> [ <time-zone-code> ] <argument-separator>? [ <reference-date> ] <argument-fence>

time-zone-code =
  <system-time-zone>
  | {string: IANA Time Zone Database identifier, Foundation time zone abbreviation, or UTC offset, each case-insensitive}
  (* default: <system-time-zone> *)

system-time-zone = 'system'

reference-date = {date: ISO-8601 date-only} (* default: {current date in the system time zone} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<system-time-zone>` identifies the system time zone.

<!--editorconfig-checker-disable-->
A `<time-zone-code>` that is both [an IANA Time Zone Database
identifier](https://www.iana.org/time-zones) & [a Foundation time zone
abbreviation](
  https://developer.apple.com/documentation/foundation/timezone/abbreviationdictionary
) (e.g., `EST`) identifies the latter.
<!--editorconfig-checker-enable-->

A **UTC offset** is either:

- `Z`, for UTC.
- An optional `UTC` or `GMT` prefix, then `+` or `-`, then either a 2-digit hour
  & a 2-digit minute (e.g., `+0530`), or a 1- or 2-digit hour, then, optionally,
  `:` followed by a 2-digit minute (e.g., `+5` or `+05:30`, which
  `.timeZone:+05\:30:` sets, escaping its `:`); each minute is from `00` to
  `59`, and the offset is at most 18 hours from UTC (e.g., `+18`, but not
  `+18:01`).

A `GMT`-prefixed UTC offset is ahead of UTC for `+` & behind UTC for `-`, but
the IANA Time Zone Database's signed `Etc/GMT` identifiers are the reverse, per
POSIX (e.g., `GMT+5` is 5 hours ahead of UTC, while `Etc/GMT+5` is 5 hours
behind).

##### Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
placeholder = <fallible-unconditional-placeholder> | <conditional-placeholder>

matcher   = [ <placeholder-prefix> ] <modifiers> <predicate> (* non-structural *)
modifiers =
  [ <abort-on-success> | <abort-on-failure> | <branch-negation> ]
  [ <coercion> | <number-coercion> | <non-date-only-coercion> | <date-only-coercion> ]
  (* non-structural *)
predicate = <nullary-predicate> | <non-nullary-predicate> | <unary-match> | <binary-match> (* non-structural *)

nullary-predicate =
  <nullary-input>
  | <nullary-label>
  | <nullary-name>
  | <nullary-null>
  | <nullary-empty>
  | <nullary-whitespace>
  | <nullary-boolean>
  | <nullary-true>
  | <nullary-false>
  | <nullary-string>
  | <nullary-number>
  | <nullary-version>
  | <nullary-date>
  | <nullary-time-only>
  (* non-structural *)

non-nullary-predicate =
  <non-nullary-input>
  | <non-nullary-label>
  | <non-nullary-name>
  | <non-nullary-null>
  | <non-nullary-empty>
  | <non-nullary-whitespace>
  | <non-nullary-boolean>
  | <non-nullary-true>
  | <non-nullary-false>
  | <non-nullary-string>
  | <non-nullary-number>
  | <non-nullary-version>
  | <non-nullary-date>
  | <non-nullary-time-only>
  (* non-structural *)

placeholder-prefix = "%"!

block-terminator = -"+"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Success & Failure

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
block = <format-block> | <success-block> | <failure-block> (* non-structural *)

success-block = <conditional-input-block> (* non-structural *)
failure-block = <unconditional-block> (* direct default: {empty string} *)

success-pipeline =
  <string-pipeline>
  | <version-pipeline>
  | <number-pipeline>
  | <date-pipeline>
  | <date-only-pipeline>
  | <time-only-pipeline>
  | <unconditional-pipeline>
  | <unconditional-string-pipeline>
  | <named-unconditional-pipeline>
  | <named-input-pipeline>
  | <whitespace-pipeline>
  | <whitespace-input-pipeline>
  | <named-format-pipeline(<preset-name>)>
  (* non-structural *)
success-clause   = <success-block> | <success-pipeline> (* non-structural *)

non-nullary-success(NULLARY, NON_NULLARY, PIPELINE) =
  <non-nullary-input-success(NULLARY, NON_NULLARY, PIPELINE, <named-format-pipeline(<preset-name>)>)>
non-nullary-input-success(NULLARY, NON_NULLARY, PIPELINE, INPUT_PIPELINE) =
  NON_NULLARY -<conditional-input-block(NULLARY, NON_NULLARY, PIPELINE, INPUT_PIPELINE)>

conditional-block(NULLARY, NON_NULLARY, PIPELINE) =
  <conditional-input-block(NULLARY, NON_NULLARY, PIPELINE, <named-format-pipeline(<preset-name>)>)>
  (* direct default: {empty string} *)
conditional-input-block(NULLARY, NON_NULLARY, PIPELINE, INPUT_PIPELINE) =
  PIPELINE | <block-template(<block-placeholder(NULLARY, NON_NULLARY, PIPELINE)> | <unconditional-placeholder(INPUT_PIPELINE, <string-pipeline>)>)>
  (* direct default: {empty string} *)
unconditional-block = <unconditional-pipeline> | <block-template(<infallible-unconditional-placeholder>)> (* direct default: {empty string} *)

block-template(PLACEHOLDER) = <block-leading-text> | [ <block-leading-text> ] ( PLACEHOLDER [ <template-text> ] )+

block-leading-text = {string: no bare "." at its start}^~

block-placeholder(NULLARY, NON_NULLARY, PIPELINE) = <placeholder-prefix> ( NULLARY | NON_NULLARY PIPELINE <block-terminator> )

abort-on-success = "-"!
abort-on-failure = "+"!
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<block-leading-text>` cannot start with a bare `.`, so a transform that a
block's pipeline cannot take is an error, rather than text, even where no
pipeline of that block starts with `.` (e.g., `%U..uppercase+-+` is an error,
while `%U\.x+-+` outputs `.x`).

A placeholder or branch is a **matcher** (`<matcher>`) immediately followed by
its success clause, blocks, or branches, which define the matcher's **form**:

- **Nullary**: nothing.
- **Unary**: a `<success-pipeline>`.
- **Binary**: a `<success-block>` & a `<failure-block>`, at least 1 of which is
  present, because a binary placeholder without either (e.g., `%S++`) would
  always insert an empty string, so its matcher cannot affect what it means.
- **Abort-on-failure**: a `<success-block>`.
- **Abort-on-success**: a `<failure-block>`.
- **Negated** (`-…`, in a non-nullary branch): a `<failure-block>`.
- **Unary match** (`%m`): `<branches>`.
- **Binary match** (`%M`): `<branches>` & a `<failure-block>`.

A matcher succeeds iff it matches the value against which it is evaluated.

Unconditional matchers always succeed.

A `<success-clause>` is evaluated iff its enclosing matcher succeeds.

A `<failure-block>` is evaluated iff its enclosing matcher fails.

Within a `<conditional-input-block>`, a `<block-placeholder>` is evaluated
against the enclosing matcher's value (coerced, if it coerces), so it always
succeeds. A `<conditional-placeholder>`, a `%i` & a `%I` are each evaluated
against the **format input**, which no block modifies: in a field spec's format,
the field value, at its original type; in a named format, the value against
which its `<named-format-reference>` evaluates it (e.g., `%.:de:N%n (%i)++`
renders `"1.234,5"` as `1234.5 (1.234,5)`, while `%+.:de:N:x+`, where preset `x`
sets no format, renders it as `1234.5`).

A matcher's **value** is given by its `<predicate>`'s `value:` comment part, in
which the field value is the value against which the matcher is evaluated, as
its [coerced value](#coercion) iff the matcher coerces (e.g., `%.:de:n`
evaluates to `1234.5` for `"1.234,5"`, as does `%n` in `%.:de:N%n++`).

- If a placeholder succeeds, the following is inserted in situ:
  - If it has `<abort-on-success>`: formatting aborts.
  - If it is nullary, unary match, or binary match: the placeholder's value.
  - Otherwise: its `<success-clause>`'s evaluated value.
- If a placeholder fails (e.g., `%u` is evaluated against a non-`null`):
  - If it has `<abort-on-success>` & a nullary predicate: the format input.
  - If it is binary, binary match, or abort-on-success: its `<failure-block>`'s
    evaluated value.
  - Otherwise: formatting aborts.

In a template that is not solely 1 placeholder, each inserted value is [coerced
to a string](#value-coercion).

Formatting **aborts** by making the formatted value
[absent](fields.md#absent-values), ignoring the rest of `<format-block>`, both
preceding & succeeding.

###### Unconditional Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
fallible-unconditional-placeholder   = <unconditional-placeholder(<named-format-pipeline(<preset-name>)>, <string-pipeline>)>
infallible-unconditional-placeholder = <unconditional-placeholder(<unconditional-pipeline>, <unconditional-string-pipeline>)>

unconditional-placeholder(INPUT_PIPELINE, NAME_PIPELINE) =
  <nullary-unconditional-placeholder>
  | <non-nullary-unconditional-placeholder(INPUT_PIPELINE, NAME_PIPELINE)>

nullary-unconditional-placeholder                                    = <placeholder-prefix> <nullary-unconditional-predicate>
non-nullary-unconditional-placeholder(INPUT_PIPELINE, NAME_PIPELINE) =
  <placeholder-prefix>
  ( <non-nullary-input> INPUT_PIPELINE | ( <non-nullary-label> | <non-nullary-name> ) NAME_PIPELINE )
  <block-terminator>

nullary-unconditional-predicate = <nullary-input> | <nullary-label> | <nullary-name>

nullary-input     = "i" (* output type: any; value: {format input} *)
non-nullary-input = "I" (* output type: any; value: {format input} *)
nullary-label     = "l" (* output type: string; value: {field label} *)
non-nullary-label = "L" (* output type: string; value: {field label} *)
nullary-name      = "k" (* output type: string; value: {field name}; mnemonic: key *)
non-nullary-name  = "K" (* output type: string; value: {field name}; mnemonic: key *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

An unconditional placeholder's matcher always succeeds, but a `<coercion>` in
its pipeline may abort formatting, except in an `<unconditional-block>`, because
a `<failure-block>` must never abort. A `<fallible-unconditional-placeholder>`
lets a label, a name, or a format input that no matcher can match be coerced
(e.g., `%L..:,,,,,.*:round+` renders the label `Size 5.6` as `Size 6`), and lets
a template insert any named format, which may abort formatting (e.g., if preset
`bytes` is `%+.N.scale:6,,0:+ MB`, `Size: %I:bytes+` renders `1500000` as
`Size: 2 MB`).

###### Conditional Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
conditional-placeholder = <nullary-scalar-conditional-placeholder> | <non-nullary-scalar-conditional-placeholder> | <match-placeholder>

nullary-scalar-conditional-placeholder     = <placeholder-prefix> [ <abort-on-success> ] <nullary-scalar-matcher>
non-nullary-scalar-conditional-placeholder =
  <placeholder-prefix>
  (
    <non-nullary-scalar-blocked-success> <block-terminator> -[ <failure-block> ] <block-terminator>
    | <non-nullary-scalar-blockless-success> <block-terminator> -<failure-block> <block-terminator>
    | <abort-on-success> <non-nullary-scalar-matcher> -[ <failure-block> ] <block-terminator>
    | <abort-on-failure> <non-nullary-scalar-success> <block-terminator>
  )

nullary-scalar-matcher =
  <nullary-standard-matcher>
  | <nullary-number-matcher>
  | <nullary-version-matcher>
  | <nullary-date-matcher>
  | <nullary-time-only-matcher>

non-nullary-scalar-matcher =
  <non-nullary-standard-matcher>
  | <non-nullary-number-matcher>
  | <non-nullary-version-matcher>
  | <non-nullary-date-matcher>
  | <non-nullary-time-only-matcher>

non-nullary-scalar-success           = <non-nullary-scalar-blocked-success> | <non-nullary-scalar-blockless-success>
non-nullary-scalar-blockless-success = <non-nullary-scalar-matcher> (* default success-block: {empty string} *)
non-nullary-scalar-blocked-success   =
  <non-nullary-standard-success>
  | <non-nullary-number-success>
  | <non-nullary-version-success>
  | <non-nullary-date-success>
  | <non-nullary-time-only-success>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Standard Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nullary-standard-matcher     = <nullary-blank-predicate> | [ <coercion> ] <nullary-coercible-standard-predicate>
non-nullary-standard-matcher = <non-nullary-blank-predicate> | [ <coercion> ] <non-nullary-coercible-standard-predicate>

non-nullary-standard-success =
  [ <coercion> ]
    (
      <non-nullary-success(<nullary-string>, <non-nullary-string>, <string-pipeline>)>
      | <non-nullary-success(<nullary-boolean>, <non-nullary-boolean>, <unconditional-pipeline>)>
      | <non-nullary-success(<nullary-true>, <non-nullary-true>, <unconditional-pipeline>)>
      | <non-nullary-success(<nullary-false>, <non-nullary-false>, <unconditional-pipeline>)>
    )
  | <non-nullary-input-success(<nullary-null>, <non-nullary-null>, <named-unconditional-pipeline>, <named-input-pipeline>)>
  | <non-nullary-input-success(<nullary-empty>, <non-nullary-empty>, <named-unconditional-pipeline>, <named-input-pipeline>)>
  | <non-nullary-input-success(<nullary-whitespace>, <non-nullary-whitespace>, <whitespace-pipeline>, <whitespace-input-pipeline>)>

nullary-coercible-standard-predicate     = <nullary-string> | <nullary-boolean> | <nullary-true> | <nullary-false>
non-nullary-coercible-standard-predicate = <non-nullary-string> | <non-nullary-boolean> | <non-nullary-true> | <non-nullary-false>

nullary-blank-predicate     = <nullary-null> | <nullary-empty> | <nullary-whitespace>
non-nullary-blank-predicate = <non-nullary-null> | <non-nullary-empty> | <non-nullary-whitespace>

nullary-null           = "u" (* is null;                                               output type: any; value: {field value}; mnemonic: 2nd letter of null *)
non-nullary-null       = "U" (* is null;                                               output type: any; value: {field value}; mnemonic: 2nd letter of null *)
nullary-empty          = "e" (* is null or an empty string;                            output type: any; value: {field value} *)
non-nullary-empty      = "E" (* is null or an empty string;                            output type: any; value: {field value} *)
nullary-whitespace     = "w" (* is null, an empty string, or a whitespace-only string; output type: any; value: {field value} *)
non-nullary-whitespace = "W" (* is null, an empty string, or a whitespace-only string; output type: any; value: {field value} *)
nullary-boolean        = "b" (* is boolean;                                            output type: boolean; value: {field value} *)
non-nullary-boolean    = "B" (* is boolean;                                            output type: boolean; value: {field value} *)
nullary-true           = "t" (* is true;                                               output type: boolean; value: {field value} *)
non-nullary-true       = "T" (* is true;                                               output type: boolean; value: {field value} *)
nullary-false          = "f" (* is false;                                              output type: boolean; value: {field value} *)
non-nullary-false      = "F" (* is false;                                              output type: boolean; value: {field value} *)
nullary-string         = "s" (* is string;                                             output type: string; value: {field value} *)
non-nullary-string     = "S" (* is string;                                             output type: string; value: {field value} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`%U`'s & `%E`'s values are `null` or an empty string, which no transform can
modify, and `%W`'s also a whitespace-only string, which only `trimWhitespace`
can modify, so any other transform must follow a `<named-format-reference>`,
whose named format may output other text, whether in the placeholder's pipeline
or in a `%I`'s in its `<success-block>`, whose format input is that value (e.g.,
`%W..trimWhitespace+-+`, `%U:x..uppercase+-+`, `%W%I..trimWhitespace++-+`,
`%U%I:x..uppercase++-+` & `%U+%I..uppercase++`, but none of `%U..uppercase+-+`,
`%W..uppercase+-+` & `%U%I..uppercase++-+`).

###### Number Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nullary-number-matcher     = [ <number-coercion> ] <nullary-number>
non-nullary-number-matcher = [ <number-coercion> ] <non-nullary-number>
non-nullary-number-success = [ <number-coercion> ] <non-nullary-success(<nullary-number>, <non-nullary-number>, <number-pipeline>)>

nullary-number     = "n" (* is number; output type: number; value: {field value} *)
non-nullary-number = "N" (* is number; output type: number; value: {field value} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Version Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nullary-version-matcher     = [ <coercion> ] <nullary-version>
non-nullary-version-matcher = [ <coercion> ] <non-nullary-version>
non-nullary-version-success = [ <coercion> ] <non-nullary-success(<nullary-version>, <non-nullary-version>, <version-pipeline>)>

nullary-version     = "v" (* is version; output type: version; value: {field value} *)
non-nullary-version = "V" (* is version; output type: version; value: {field value} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **version** is 1 or more `.`-separated components, each an ASCII digit
followed by any Unicode general category `L` or `N` characters, `+`s & `-`s
(e.g., `1.2.3-beta`). `<coercion>` parses a value whose entire content is a
version (e.g., `%.v` matches `"1.2.3-beta"` & `1.2`), as does an [implicit
coercion](#value-types), so a branch that means to match a number must precede
`%v`'s (e.g., `%mnv+`, but not `%mvn+`, which would render the number `1.2` as
the string `1.2`).

###### Coercion

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
coercion        = "."!
number-coercion = <coercion> [ <number-coercion-arguments> ] (* default locale-identifier: <canonical-locale> *)

number-coercion-arguments =
  <argument-fence>
  <number-format-arguments>
  <argument-separator>? [ <trivia-prefix-regex> ]
  <argument-separator>? [ <trivia-suffix-regex> ]
  <argument-fence>

trivia-prefix-regex = {regex} (* default: {empty string} *)
trivia-suffix-regex = {regex} (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<coercion>` allows a matcher to also match a value whose entire content parses
as the matcher's type, instead of requiring the input's type to match (e.g.,
`%.n` matches `4.5` & `"4.50"`, but not `"4.5a"`), replacing the input with the
**coerced value**. For a type unsupported by the input format, a default
coercion matches what an [implicit coercion](#value-types) matches (e.g., `%.v`
& `%v`, for JSON input).

A string coercion matches every value except a `null` or an absent one, which
has no text to coerce, and coerces it as [specified](#value-coercion) (e.g., for
JSON output, `%.s` renders `5` as `"5"` & `" a "` as `" a "`, `%.S%s+none+`
renders `null` as `none`, and `%m.su+` retains `null`).

A boolean coercion parses only `true` & `false`, verbatim.

A number coercion parses a number's separators & digit group sizes per its
number format arguments (e.g., `%.:de:n` matches `"1.234,56"`, coercing it to
`1234.56`). A digit group separator is accepted only between digit groups of the
given sizes; a `<digit-group-size>` of `0` accepts groups of any size. A digit
group separator adjacent to a digit group of any other size thus terminates the
number before that separator (e.g., `%.:,,,,,,.*:n` matches `"1,2345"` as the
number `1` followed by the trivia suffix `,2345`).

A number coercion accepts both positional & scientific notation (an exponent
indicator, `e` or `E`, followed by an optionally signed integer exponent). The
coerced value's text retains the number's sign, leading & trailing `0`s &
notation, but has no digit group separators & has `.` as its decimal separator
(e.g., `%.n` coerces `"+01.50e+03"` to `+01.50e+03` & `".5"` to `.5`, while
`%.:de:n` coerces `"1.234,50"` to `1234.50`), because each later transform reads
that 1 syntax, while an [output format](#value-types) modifies it only as its
syntax requires.

A number coercion also allows **trivia** around the number, matching a string
iff it splits into the following, using the shortest trivia prefix for which
such a split exists:

<!--editorconfig-checker-disable-->
1. A **trivia prefix**: a [Swift Regex](
     https://github.com/swiftlang/swift-evolution/blob/main/proposals/0355-regex-syntax-run-time-construction.md
   ) whole match of `<trivia-prefix-regex>`.
2. The longest number there.
3. A **trivia suffix**: the rest of the string, a whole match of
   `<trivia-suffix-regex>` (e.g., `%.:,,,,,.*:n` matches `"a1b2"` as the trivia
   prefix `a1b` & the number `2`).
<!--editorconfig-checker-enable-->

The default regexes match only an empty string, allowing no trivia (e.g.,
`%.:,,,,,[A-Z]*[$]:n` matches `"US$4.99"` & `"$4.99"`, but not `"4.99"`). Number
transforms & number-to-string transforms are applied to the number alone,
retaining the trivia unmodified (e.g., `..:,,,,,[$]:numberFormat:de:` renders
`"$1234.5"` as `$1.234,5`).

Because `\` escapes the next character in every variable token, a regex's own
`\` is written `\\` (e.g., `\\d` for the regex `\d` & `\\$` for `\$`), and
`<trivia-prefix-regex>`'s `,` & `:` & `<trivia-suffix-regex>`'s `:` must be
escaped.

###### Chronologic Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
date-coercion-arguments(DATE_FORMATS) = <argument-fence> DATE_FORMATS <argument-fence>

non-date-only-coercion     =
  <coercion> [ <date-coercion-arguments(<non-date-only-formats>)> ]
  (* default non-date-only-formats: {what <iso> matches, or a number as a Unix time} *)
date-only-coercion         = <coercion> <date-coercion-arguments(<date-only-formats>)>
version-date-only-coercion = <coercion> [ <date-coercion-arguments(<version-date-only-formats>)> ] (* default version-date-only-formats: 'iso' *)
number-date-coercion       = <coercion> [ <date-coercion-arguments(<unix-time-date-formats>)> ] (* default unix-time-date-formats: {a number as a Unix time} *)
unix-time-coercion         = <coercion> <date-coercion-arguments(<unix-time-date-formats>)>

non-date-only-formats     = [ ( <iso-date> <argument-separator> )+ ] ( <iso> | <iso-datetime> | <unix-time> ) [ ( <argument-separator> <date-format> )+ ]
date-only-formats         = <iso-date> … <argument-separator>
version-date-only-formats = [ ( <iso-datetime> <argument-separator> )+ ] ( <iso> | <iso-date> ) [ ( <argument-separator> <date-iso-format> )+ ]
unix-time-date-formats    = [ ( <date-iso-format> <argument-separator> )+ ] <unix-time> [ ( <argument-separator> <date-format> )+ ]

date-format     = <date-iso-format> | <unix-time>
date-iso-format = <iso> | <iso-date> | <iso-datetime>

nullary-date-matcher          = [ <non-date-only-coercion> | <date-only-coercion> ] <nullary-date>
non-nullary-date-matcher      = [ <non-date-only-coercion> | <date-only-coercion> ] <non-nullary-date>
non-nullary-date-success      =
  [ <non-date-only-coercion> ] <non-nullary-success(<nullary-date>, <non-nullary-date>, <date-pipeline>)>
  | <date-only-coercion> <non-nullary-success(<nullary-date>, <non-nullary-date>, <date-only-pipeline>)>
nullary-time-only-matcher     = [ <coercion> ] <nullary-time-only>
non-nullary-time-only-matcher = [ <coercion> ] <non-nullary-time-only>
non-nullary-time-only-success = [ <coercion> ] <non-nullary-success(<nullary-time-only>, <non-nullary-time-only>, <time-only-pipeline>)>

nullary-date          = "d" (* is date;      output type: date; value: {ISO date / datetime, per input, in system time zone} *)
non-nullary-date      = "D" (* is date;      output type: date; value: {ISO date / datetime, per input, in system time zone} *)
nullary-time-only     = "c" (* is time-only; output type: time-only; value: {ISO time, in system time zone}; mnemonic: clock *)
non-nullary-time-only = "C" (* is time-only; output type: time-only; value: {ISO time, in system time zone}; mnemonic: clock *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A `<coercion>` to a chronologic type auto-detects a string as an ISO-8601
datetime, date-only, or time-only (trying them in that order), among those that
its type & its `<date-format>`s allow; this does not depend on field name,
label, output format, or any other context.

No predicate matches both a date & a time-only value (e.g., `%m.d.c+` coerces to
either).

**Unix time** is the number of seconds since 1970-01-01T00:00:00Z, ignoring leap
seconds.

A **decimal number** is text in `number`'s [lexical
form](ebnf.md#typed-terminals) (e.g., `-1`, `.5`, or `1.5e9`).

A `<coercion>` to a date parses what any of its `<date-format>`s
[matches](fields.md#sort-chronologic-segments), except that `<iso>` does not
match a time-only, which is not a date, and `<unix-time>` also matches a number
without trivia (e.g., `%.:iso-date:d` matches `"2020-03-18"`, but not
`"2020-03-18 17:39"`, and `%.:iso,unix-time:D` matches `0`, `"0"` &
`"2020-03-18"`, while `%.:unix-time:D` matches only the 1st 2).

A default coercion to a date parses what `<iso>` matches & a number without
trivia as a Unix time, as a datetime, because a number has no other meaning as a
date (e.g., `%.D` matches `0` & `"2020-03-18"`, but not `"0"`).

A decimal number coerces to a date only per `<unix-time>`, because a string that
holds a number is rarely a time (e.g., `%m.ds+` would otherwise render the
string `5.6` as a date).

`%.d`, and `%d` for an input format that does not support datetime, thus match
every chronologic number, so a branch that means to match a number must precede
theirs or follow a `<coercion>` that omits `<unix-time>` (e.g., `%mn.d+` or
`%m.:iso:d.n+`, but not `%m.d.n+`, which would render the price `5.6` as a
date). A call whose input the syntax text determines to be a number must omit
`<date-coercion-arguments>` or list `<unix-time>` (e.g., `.round..dateOnly` or
`.round..:iso,unix-time:dateOnly`, but not `.round..:iso:dateOnly`, which can
only abort).

A `<date-only-coercion>`'s value is always a date-only, which no time zone
affects, so no `timeZone` may follow it (e.g., `%.:iso-date:D.timeZone:UTC:+-+`
is an error, as `.dateOnly.timeZone:UTC:` is). Nor may `dateOnly` start the
pipeline of a matcher's `<date-only-coercion>`, because it cannot affect that
value (e.g., `%.:iso-date:D.dateOnly+-+` is an error, while `%.:iso-date:D%d+-+`
outputs the date-only).

A version has no `:`, so it is never a datetime, so a call whose input the
syntax text determines to be a version must list a `<date-format>` other than
`<iso-datetime>` (e.g., `%.V..:iso,iso-datetime:dateOnly+-+`, but not
`%.V..:iso-datetime:dateOnly+-+`, which can only abort), and only `<unix-time>`
lets `timeZone` affect its value (e.g., `%.V..:unix-time:timeZone:UTC:+-+`, but
not `%.V..:iso:timeZone:UTC:+-+`, whose value can only be a date-only).

A `<coercion>` to a time-only takes no arguments, because a time-only has only 1
format.

An ISO-8601:

- Date-only is an extended-format calendar date, whose year is 4 digits (e.g.,
  `2020-03-18`) or, per ISO-8601's expanded representation, a sign & at least 5
  digits (e.g., `+10000-01-01` or `-00001-12-31`).
- Time-only is an extended-format complete time (e.g., `17:39:23`), with
  optional fractional seconds (after `.` or `,`) & an optional UTC offset (`Z`,
  `z` per RFC 3339, `±hh`, `±hhmm`, or `±hh:mm`).
- Datetime is a date-only, `T` (or, per RFC 3339, `t` or a space), then a
  time-only, optionally without its seconds & fractional seconds (e.g.,
  `2020-03-18T17:39:23Z` or `2020-03-18 17:39`).

Each of their fields must be in range:

- Month: `01` to `12`.
- Day: `01` to its month's last day.
- Hour: `00` to `23` (e.g., `24:00:00` is invalid).
- Minute: `00` to `59`, including a UTC offset's.
- Second: `00` to `59` (e.g., the leap second `23:59:60` is invalid, because
  Unix time ignores leap seconds).
- UTC offset: at most 18 hours from UTC, as for
  [`timeZone`](#timezone--timeonlytimezone).

No other ISO-8601 representation is detected (e.g., basic format, ordinal dates,
week dates, or reduced precision other than a datetime without seconds).

A datetime or time-only without a UTC offset is in the system time zone.

A time-only value has no date, so `%C`'s block cannot apply `dateOnly` or
`timeZone` to it, and a [`<coercion>`](#coercion) to a date fails for it (e.g.,
`..dateOnly` aborts formatting for `"17:39:23"`, while `%.D.dateOnly+-+` outputs
`-` for it). Likewise, a `<coercion>` to a time-only fails for a date (e.g.,
`..timeOnlyTimeZone:UTC:` aborts formatting for `"2020-03-18"`).

Every date is in the proleptic Gregorian calendar, as ISO-8601 requires (e.g.,
year `0000` is 1 BCE, and `1500-02-29` does not exist).

A Unix time is chronologic iff it is at least `-9223372036854775.808` & less
than `9223372036854775.808` (i.e., its whole milliseconds, rounded down, fit in
a signed 64-bit integer); an ISO-8601 date-only or datetime is chronologic iff
its instant, as a Unix time, is, a date-only's instant being its start in the
system time zone (e.g., `+292278994-08-17` is chronologic in UTC, but not at
UTC-8).

A datetime's or time-only's fractional seconds are truncated or padded with `0`s
to exactly 3 digits, which are omitted iff all are `0` (e.g., in the UTC output
time zone, `2020-03-18T17:39:23.1234Z` renders as `2020-03-18T17:39:23.123Z`,
`2020-03-18T17:39:23.5Z` as `2020-03-18T17:39:23.500Z` &
`2020-03-18T17:39:23.0004Z` as `2020-03-18T17:39:23Z`).

A chronologic value renders in the output time zone, in ISO-8601 extended format
(as RFC 3339 profiles it for a year from 0000 to 9999):

- Date-only: `YYYY-MM-DD`, its year being, outside 0000 to 9999, a sign & at
  least 5 digits (e.g., `+10000-01-01`).
- Time-only: `hh:mm:ss`, any fractional seconds, then its UTC offset.
- Datetime: its date, `T`, then its time, as for a time-only.

Seconds always render (e.g., in the UTC output time zone, `2020-03-18 17:39Z`
renders as `2020-03-18T17:39:00Z`), so every rendered datetime or time-only has
the same form. A UTC offset renders as `Z` iff it is 0, else as `±hh:mm`.

###### Branched Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
match-placeholder = <unary-match-placeholder> | <binary-match-placeholder>

unary-match-placeholder  = <placeholder-prefix> <unary-match> <branches> <block-terminator>
binary-match-placeholder = <placeholder-prefix> <binary-match> <branches> <block-terminator> -[ <failure-block> ] <block-terminator>

unary-match  = "m" (* matches a branch in <branches>; output type: {matched branch value's type}; value: {matched branch value} *)
binary-match = "M" (* matches a branch in <branches>; output type: {matched branch value's type}; value: {matched branch value} *)

branches = <branch> <branch>+
branch   = <nullary-branch> | <non-nullary-branch>

nullary-branch     = [ <branch-negation> ] <nullary-scalar-matcher>
non-nullary-branch =
  <non-nullary-scalar-success> <block-terminator>
  | <branch-negation> <non-nullary-scalar-matcher> -[ <failure-block> ] <block-terminator>

branch-negation = "-"!
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- The branches in `<branches>` are evaluated sequentially against the format
  input, returning as `<match-placeholder>`'s value:
  - If a branch has `<branch-negation>`:
    - If it fails: its `<failure-block>`'s evaluated value if it is non-nullary,
      otherwise the format input.
  - Otherwise:
    - If it succeeds: its block's evaluated value if it is non-nullary,
      otherwise its matcher's value.
- If no branch returns a value:
  - For `%m`: the placeholder fails & aborts formatting.
  - For `%M`: returns its `<failure-block>`'s value.

Every branch is conditional, because an unconditional last branch would mean
what a `%M` whose `<failure-block>` holds that branch as a placeholder means
(e.g., `%MN.absoluteValue+b+%I..uppercase++`).

Examples:

- `%mN.absoluteValue+b+`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, aborts formatting.
- `%MN.absoluteValue+b+Status Unknown+`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, outputs `Status Unknown`.
- `%MN.absoluteValue+b+%I..uppercase++`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, outputs the uppercased value.
