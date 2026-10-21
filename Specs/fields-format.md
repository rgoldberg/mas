<!--markdownlint-disable-file first-line-heading-->
#### Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-modifier        = <format-modifier-prefix> -[ <format-block> ]-
format-modifier-prefix = ":"

format-block = <pipeline> | <format-template> (* direct default: {empty string} *)

pipeline        =
  <named-format>
  | [ <named-format> ] <format-transform-pipeline>
  | [ <named-format> ] [ <format-transform-pipeline> ] <value-transform-pipeline>
format-template = [ <template-text> ] ( <placeholder> [ <template-text> ] )+

template-text = ~^{text}^~
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Value Types

Each of the following evaluates to a value whose type is:

- Block: its pipeline's or template's type.
- Pipeline: its last value transform's output's type; absent any, its named
  format's value's type, or else its input's type.
- Placeholder: its inserted value's type.
- Template: if solely 1 placeholder, that placeholder's type; otherwise, string.
- Template text: string.

A field value may also be an array or an object, each a **structured value**. No
predicate whose output type is not any (e.g., `%s` or `%.n`) matches a
structured value.

A field spec's **formatted value** is its `<format-block>`'s value, at its type,
regardless of the output format, which renders it at its type iff it supports
that type (JSON: string, boolean, `null`, structured value & a number whose
text, including any trivia, is JSON number syntax; table & key-value: string);
otherwise, it renders it coerced to a string.

##### Pipelines

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-pipeline = <named-string-format> | [ <named-string-format> ] <string-transform-pipeline>

number-pipeline =
  <named-number-format>
  | [ <named-number-format> ] ( <number-transform-pipeline> | <number-to-string-transform-pipeline> | <unconditional-transform-pipeline> )

date-pipeline = <named-date-format> | [ <named-date-format> ] ( <date-transform-pipeline> | <unconditional-transform-pipeline> )

time-only-pipeline = <named-time-only-format> | [ <named-time-only-format> ] ( <time-only-transform-pipeline> | <unconditional-transform-pipeline> )

unconditional-pipeline = <named-unconditional-format> | [ <named-unconditional-format> ] <unconditional-transform-pipeline>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Named Formats

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
named-format               = <name-prefix> <format-name> (* only for: name of a format conforming to <format-block> *)
named-string-format        = <name-prefix> <format-name> (* only for: name of a format conforming to <string-block> *)
named-number-format        = <name-prefix> <format-name> (* only for: name of a format conforming to <number-block> *)
named-date-format          = <name-prefix> <format-name> (* only for: name of a format conforming to <date-block> *)
named-time-only-format     = <name-prefix> <format-name> (* only for: name of a format conforming to <time-only-block> *)
named-unconditional-format = <name-prefix> <format-name> (* only for: name of a format conforming to <unconditional-block> *)

named-format-reference =
  <named-format>
  | <named-string-format>
  | <named-number-format>
  | <named-date-format>
  | <named-time-only-format>
  | <named-unconditional-format>
  (* non-structural *)

format-name = {text: format name}
name-prefix = ":"!
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **named format** is a format that:

- Is persisted in the app configuration.
- Can be referenced via `<named-format-reference>`s.

If no named format exists for a referenced name, an error is reported.

If a `<transform-pipeline>` immediately follows a `<named-format-reference>`,
the referenced format's value must also have its 1st transform's input type,
unless that transform call has a `<coercion>` (e.g., `:name.round` requires
`name`'s value to be a number, but `:name..round` does not). Otherwise, an error
is reported.

Because every `<success-block>` alternative's syntax includes
`<unconditional-block>`'s, a named unconditional format satisfies every
`<named-format-reference>`, except that `<named-format>` also requires a
`<format-template>` to contain a placeholder.

##### Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
transform-pipeline = <value-transform-pipeline> | <unconditional-transform-pipeline> | <format-transform-pipeline> (* non-structural *)

value-transform-pipeline = <string-transform-pipeline> | <number-transform-pipeline> | <number-to-string-transform-pipeline> | <date-transform-pipeline>

unconditional-transform-pipeline = <coerced-string-transform-call> [ <string-transform-pipeline> ]

coerced-string-transform-call = <transform-call-prefix> <coercion> <string-transform>

transform-call-prefix = "."!

argument-fence     = ":" (* fences an argument list *)
argument-separator = "," (* separates an argument list's arguments *)

value-transform = <string-transform> | <number-transform> | <number-to-string-transform> | <date-transform> (* non-structural *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A `<transform-pipeline>` `t` is a pipeline of transformations applied to:
  - If a `<named-format-reference>` `n` immediately precedes `t`: `n`'s value.
  - Otherwise: the value against which its enclosing block is evaluated (i.e.,
    in a `<success-block>`, the enclosing matcher's value; elsewhere, the field
    value).

An **argument** is an element of an argument list: a transform's, a [number
coercion's](#coercion), [`N`'s](fields.md#sort-number-segments), or
[`C`'s](fields.md#sort-chronologic-segments).

An argument ignores its outer bare whitespace, which must be escaped to be
consumed (e.g., `.numberFormat:,\ ,3:` separates digit groups with a space).

An argument that is empty after ignoring its outer bare whitespace is absent,
which is an error iff the argument is required (e.g., `.scale:,6,,0:` is an
error, but `.scale:10,6, ,0:` omits `<significant-digits>`).

###### Value Coercion

A transform without `<coercion>` requires its input to already be of its input
type; otherwise, an error is reported.

A `null` or [absent](fields.md#absent-values) value remains unchanged through
every transform, with or without `<coercion>`, so it is never an error (e.g.,
`..uppercase` evaluates to `null` for `null`).

A `<coercion>` attempts to coerce an input value into the correct input type for
the annotated transform. If the coercion is successful, the transform is applied
to the coerced input; otherwise, formatting [aborts](#success--failure).

A number or number-to-string transform's coercion may take
[`<number-coercion-arguments>`](#coercion) (e.g., `..:de:round`).

Coercing any value to a string always succeeds (`null` becomes the empty string,
and a [structured value](#value-types) becomes its compact JSON text, with
non-ASCII characters verbatim, e.g., `["é",{"a":null}]`), so an
`<unconditional-transform-pipeline>`, which starts with a
`<coerced-string-transform-call>`, cannot fail.

###### String Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-transform-pipeline = <string-transform-call>+
string-transform-call     = <transform-call-prefix> [ <coercion> ] <string-transform>
string-transform          = <initial-titlecase> | <lowercase> | <trim-whitespace> | <uppercase> (* type: string *)

initial-titlecase = "initialTitlecase"
lowercase         = "lowercase"
trim-whitespace   = "trimWhitespace"
uppercase         = "uppercase"
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
  unchanged, but titlecases a cased one (e.g., `"hello"` becomes `"Hello"` &
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
number-transform-pipeline           = <number-transform-call>+
number-to-string-transform-pipeline = [ <number-transform-call>+ ] <number-to-string-transform-call>

number-transform-call           = <transform-call-prefix> [ <number-coercion> ] <number-transform>
number-to-string-transform-call = <transform-call-prefix> [ <number-coercion> ] <number-to-string-transform>

number-transform           = <absolute-value> | <round> | <scale> (* type: number *)
number-to-string-transform = <number-format> (* input type: number; output type: string *)

absolute-value = "absoluteValue"
round          = "round"
scale          = "scale" <scale-arguments>
number-format  = "numberFormat" [ <argument-fence> <number-format-arguments> <argument-fence> ]
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

- Positional: as an integer (e.g., `-2.5` becomes `-3`).
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

digit-group-separator      = {text}                 (* default: {base conventions' digit group separator} *)
digit-group-size           = {non-negative integer} (* default: {base conventions' digit group size} *)
secondary-digit-group-size = {non-negative integer} (* default: {base conventions' secondary digit group size} *)
decimal-separator          = {text}                 (* default: {base conventions' decimal separator} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

The **number format arguments** are those of `<number-format-arguments>`, which
[number coercion's](#coercion) & [`N`'s](fields.md#sort-number-segments)
argument lists start with.

`numberFormat` inserts `<digit-group-separator>` between the **digit groups** of
its input's integer part, counting from its least significant digit: the least
significant (**primary**) group has `<digit-group-size>` digits, and each other
(**secondary**) group has `<secondary-digit-group-size>` digits, or
`<digit-group-size>` digits if `<secondary-digit-group-size>` is `0`; the most
significant group may have fewer digits (e.g., `.numberFormat:,\,,3,2:` renders
`12345678` as `1,23,45,678`).

`numberFormat` also replaces the `.` between its input's integer & fractional
parts with `<decimal-separator>` (e.g., `.numberFormat:de:` renders `1234.5` as
`1.234,5`).

`numberFormat` retains scientific notation, applying to its significand &
rendering its exponent indicator & exponent verbatim (e.g., `.numberFormat:de:`
renders `12345.6E3` as `12.345,6E3`); `scale` renders positional notation before
it (e.g., `.scale:10,0,,2:.numberFormat:de:` renders `1.5e3` as `1.500,00`).

Number format arguments whose digit group separator equals their decimal
separator, each after defaulting to the base conventions, are an error, whether
they are `numberFormat`'s, a number coercion's, or `N`'s.

A `<digit-group-size>` of `0` inserts no separators, ignoring
`<secondary-digit-group-size>`.

The **base conventions** are those that
[`<locale-identifier>`](fields.md#sort-locale) identifies, or, if
`<locale-identifier>` is absent (even if other number format arguments are
present):

- For `numberFormat`: the system locale's, because rendered output is for
  people.
- For a [number coercion](#coercion): the [canonical](fields.md#sort-locale)
  conventions, because parsed input is data, which, like sorting's default
  canonical conventions, must not depend on the system.
- For [`<grouped-numeric>`](fields.md#sort-number-segments): those that
  `<locale>`'s `<locale-identifier>` identifies.

###### `scale`

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
scale-arguments =
  <argument-fence> <radix>
  <argument-separator> <exponent>
  <argument-separator> [ <significant-digits> ]
  <argument-separator> <fractional-digits>
  <argument-fence>

radix              = {integer from 2 to 36}  (* base for `<exponent>` & the rendered digits *)
exponent           = {non-negative integer}  (* divides the input by `<radix>` to this power before rendering *)
significant-digits = {integer from 1 to 100} (* rounds to this many total `<radix>` digits; absent: no rounding *)
fractional-digits  = {integer from 0 to 100} (* exactly this many `<radix>` digits after the point; `0`: integer *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`scale` divides its input by `<radix>` to the power of `<exponent>`, optionally
rounds it to `<significant-digits>` total `<radix>` digits, then renders it in
positional notation, base `<radix>`, with exactly `<fractional-digits>` digits
after the radix point.

- Both roundings (to `<significant-digits>`, then to `<fractional-digits>`)
  round halves away from 0.
- A `<fractional-digits>` of `0` renders a plain integer, with no radix point.
- For a `<radix>` greater than 10, digits beyond `9` are lowercase `a` to `z`.
- `0` renders as `0`, followed, iff `<fractional-digits>` is positive, by a
  radix point & `<fractional-digits>` `0`s.
- A leading `+` is retained, while a leading `-` is retained iff the result is
  nonzero (e.g., `.scale:10,0,,0:` renders `+2.4` as `+2` & `-0.4` as `0`), as
  for `round`.
- A value that would render with more than 100 digits before the radix point
  does not conform to `scale`'s input type, so [value coercion](#value-coercion)
  applies (e.g., `.scale:10,0,,0:` reports an error for `1e100`, while
  `..scale:10,0,,0:` aborts formatting).
- E.g., a byte count as integer decimal megabytes: `.scale:10,6,,0:`.

###### Chronologic Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
date-transform-pipeline = <date-transform-call>+
date-transform-call     = <transform-call-prefix> [ <coercion> ] <date-transform>
date-transform          = <date-only> | <time-zone> (* type: date *)

time-only-transform-pipeline = <time-only-transform-call>+
time-only-transform-call     = <transform-call-prefix> [ <coercion> ] <time-only-transform>
time-only-transform          = <time-zone> (* type: time-only *)

date-only = "dateOnly"
time-zone = "timeZone" [ <time-zone-arguments> ] (* sets the output time zone; last wins *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A `<date-transform-pipeline>`'s or `<time-only-transform-pipeline>`'s transforms
jointly set how its value is rendered, regardless of where `dateOnly` appears:

- `dateOnly`: renders only the date, in the output time zone.
- `timeZone`: sets the output time zone to the one that its `<time-zone-code>`
  identifies.

Absent `timeZone`, the output time zone is the system time zone.

A date-only value's date is independent of time zones, so `timeZone` does not
affect it.

A time-only value is rendered in the output time zone as if on the last
`timeZone`'s `<reference-date>`, because a time zone's UTC offset can vary by
date (e.g., for daylight saving time), or, absent `timeZone`, on the current
date in the system time zone. Only a UTC offset `<time-zone-code>` has a fixed
UTC offset: a Foundation time zone abbreviation identifies a time zone whose UTC
offset can vary (e.g., `EST` identifies `America/New_York`).

###### `timeZone`

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
time-zone-arguments = <argument-fence> [ <time-zone-code> ] <argument-separator>? [ <reference-date> ] <argument-fence>

time-zone-code = {text: case-insensitive IANA Time Zone Database identifier, Foundation time zone abbreviation, UTC offset, or "system"} (* default: "system" *)
reference-date = {text: ISO-8601 extended-format date} (* default: {current date in the system time zone} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

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
  `:` followed by a 2-digit minute (e.g., `+5` or `+05:30`); each minute is from
  `00` to `59`.

A UTC offset of more than 18 hours from UTC is an error.

A `GMT`-prefixed UTC offset is ahead of UTC for `+` & behind UTC for `-`, but
the IANA Time Zone Database's signed `Etc/GMT` identifiers are the reverse, per
POSIX (e.g., `GMT+5` is 5 hours ahead of UTC, while `Etc/GMT+5` is 5 hours
behind).

##### Format Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-transform-pipeline = ( <transform-call-prefix> <format-transform> )+
format-transform          = <justify>

justify = <start-justify> | <center-start-justify> | <center-end-justify> | <end-justify> (* default: {inherited justify}; last wins *)

start-justify        = "startJustify"
center-start-justify = "centerStartJustify"
center-end-justify   = "centerEndJustify"
end-justify          = "endJustify"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Unlike a `<value-transform>`, a `<format-transform>` does not transform any
value; it sets a property of the field spec itself, currently just its table
output column alignment. It therefore does not affect the field's rendered
value: it is a no-op for JSON / key-value output (which have no columns to
align); it accepts a value of any type & does not modify it, unlike every
`<value-transform>`.

`centerStartJustify` & `centerEndJustify` differ only when the column's padding
is odd-width: `centerStartJustify` puts the extra padding character after the
value (leaving it nearer the column's start); `centerEndJustify` puts it before
the value (leaving it nearer the column's end).

An absent `<justify>` is inherited from the working fields config; absent any
justification to inherit, it is `<start-justify>`.

##### Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
placeholder = <unconditional-placeholder> | <conditional-placeholder>

matcher   = [ <placeholder-prefix> ] <modifiers> <predicate> (* non-structural *)
modifiers = [ <abort-on-success> | <abort-on-failure> | <branch-negation> ] [ <number-coercion> ] (* non-structural *)
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

success-block =
  <string-block>
  | <boolean-block>
  | <number-block>
  | <date-block>
  | <time-only-block>
  | <any-block>
  | <unconditional-block>
  (* non-structural *)
failure-block = <unconditional-block>

success-pipeline = <string-pipeline> | <number-pipeline> | <date-pipeline> | <time-only-pipeline> | <unconditional-pipeline> (* non-structural *)

string-block        = <string-pipeline> | <string-template>               (* direct default: {empty string} *)
boolean-block       = <unconditional-pipeline> | <boolean-template>       (* direct default: {empty string} *)
number-block        = <number-pipeline> | <number-template>               (* direct default: {empty string} *)
date-block          = <date-pipeline> | <date-template>                   (* direct default: {empty string} *)
time-only-block     = <time-only-pipeline> | <time-only-template>         (* direct default: {empty string} *)
any-block           = <unconditional-pipeline> | <any-template>           (* direct default: {empty string} *)
unconditional-block = <unconditional-pipeline> | <unconditional-template> (* direct default: {empty string} *)

string-template        = <template-text> | [ <template-text> ] ( ( <string-block-placeholder> | <unconditional-placeholder> ) [ <template-text> ] )+
boolean-template       = <template-text> | [ <template-text> ] ( ( <boolean-block-placeholder> | <unconditional-placeholder> ) [ <template-text> ] )+
number-template        = <template-text> | [ <template-text> ] ( ( <number-block-placeholder> | <unconditional-placeholder> ) [ <template-text> ] )+
date-template          = <template-text> | [ <template-text> ] ( ( <date-block-placeholder> | <unconditional-placeholder> ) [ <template-text> ] )+
time-only-template     = <template-text> | [ <template-text> ] ( ( <time-only-block-placeholder> | <unconditional-placeholder> ) [ <template-text> ] )+
any-template           = <template-text> | [ <template-text> ] ( ( <any-block-placeholder> | <unconditional-placeholder> ) [ <template-text> ] )+
unconditional-template = <template-text> | [ <template-text> ] ( <unconditional-placeholder> [ <template-text> ] )+

block-placeholder =
  <string-block-placeholder>
  | <boolean-block-placeholder>
  | <number-block-placeholder>
  | <date-block-placeholder>
  | <time-only-block-placeholder>
  | <any-block-placeholder>
  (* non-structural *)

string-block-placeholder =
  <placeholder-prefix>
  ( <nullary-string> | <nullary-version> | ( <non-nullary-string> | <non-nullary-version> ) -<string-pipeline> <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

boolean-block-placeholder =
  <placeholder-prefix>
  ( <nullary-coercible-standard-predicate> | <non-nullary-coercible-standard-predicate> -<unconditional-pipeline> <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

number-block-placeholder =
  <placeholder-prefix>
  ( <nullary-number> | <non-nullary-number> -<number-pipeline> <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

date-block-placeholder =
  <placeholder-prefix>
  ( <nullary-date> | <non-nullary-date> -<date-pipeline> <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

time-only-block-placeholder =
  <placeholder-prefix>
  ( <nullary-time-only> | <non-nullary-time-only> -<time-only-pipeline> <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

any-block-placeholder =
  <placeholder-prefix>
  ( <nullary-blank-predicate> | <non-nullary-blank-predicate> -<unconditional-pipeline> <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

abort-on-success = "-"!
abort-on-failure = "+"!
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **matcher** is a `<placeholder-prefix>` (in a placeholder), its `<modifiers>`
& its `<predicate>`; a placeholder or branch is a matcher immediately followed
by its blocks, which define the matcher's **form**:

- **Nullary**: no blocks.
- **Unary**: either a `<success-block>` or a `<success-pipeline>`.
- **Binary**: a `<success-block>` & a `<failure-block>`.
- **Abort-on-failure** (`%+…`): a `<success-block>`.
- **Abort-on-success** (`%-…`): a `<failure-block>`.
- **Unary match** (`%m`): `<branches>`.
- **Binary match** (`%M`): `<branches>` & a `<failure-block>`.

A matcher succeeds iff it matches the value against which it is evaluated.

Unconditional matchers always succeed.

A `<success-block>` is evaluated iff its enclosing matcher succeeds.

A `<failure-block>` is evaluated iff its enclosing placeholder fails.

A `<success-block>`'s kind follows the matched value's type; where that is
boolean or can be any type, the block's pipeline must start, after any named
format, by coercing to a string.

`<unconditional-block>` differs from `<any-block>` only by forbidding
`<block-placeholder>`s.

Within a `<success-block>`, a `<block-placeholder>` is evaluated against the
enclosing matcher's value (coerced, if it coerces), so it always succeeds; `%i`
/ `%I` are evaluated against the original input, at its original type (e.g.,
`%.N%n (%i)++` renders `"4.50"` as `4.5 (4.50)`).

A matcher's **value** is given by its `<predicate>`'s `value:` comment part.

- If a placeholder succeeds, the following is inserted in situ:
  - If it has `<abort-on-success>`: formatting aborts.
  - If it is nullary, unary match, or binary match: the placeholder's value.
  - Otherwise: its `<success-block>`'s evaluated value.
- If a placeholder fails (e.g., `%u` is evaluated against a non-`null`):
  - If it has `<abort-on-success>` & a nullary predicate: the field value.
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
unconditional-placeholder = <nullary-unconditional-placeholder> | <non-nullary-unconditional-placeholder>

nullary-unconditional-placeholder     = <placeholder-prefix> <nullary-unconditional-predicate>
non-nullary-unconditional-placeholder =
  <placeholder-prefix>
  ( <non-nullary-input> -<unconditional-pipeline> | ( <non-nullary-label> | <non-nullary-name> ) -<string-pipeline> )
  <block-terminator>

nullary-unconditional-predicate = <nullary-input> | <nullary-label> | <nullary-name>

nullary-input     = "i" (* output type: any; value: {field value} *)
non-nullary-input = "I" (* output type: any; value: {field value} *)
nullary-label     = "l" (* output type: string; value: {field label} *)
non-nullary-label = "L" (* output type: string; value: {field label} *)
nullary-name      = "k" (* output type: string; value: {field name}; mnemonic: key *)
non-nullary-name  = "K" (* output type: string; value: {field name}; mnemonic: key *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Conditional Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
conditional-placeholder = <nullary-scalar-conditional-placeholder> | <non-nullary-scalar-conditional-placeholder> | <match-placeholder>

nullary-scalar-conditional-placeholder     = <placeholder-prefix> [ <abort-on-success> ] <nullary-scalar-matcher>
non-nullary-scalar-conditional-placeholder =
  <placeholder-prefix>
  (
    <non-nullary-scalar-success> <block-terminator> -[ <failure-block> ] <block-terminator>
    | <abort-on-success> <non-nullary-scalar-matcher> -[ <failure-block> ] <block-terminator>
    | <abort-on-failure> <non-nullary-scalar-success> <block-terminator>
  )

nullary-scalar-matcher = <nullary-standard-matcher> | <nullary-number-matcher> | <nullary-version> | <nullary-date-matcher> | <nullary-time-only>

non-nullary-scalar-matcher =
  <non-nullary-standard-matcher>
  | <non-nullary-number-matcher>
  | <non-nullary-version>
  | <non-nullary-date-matcher>
  | <non-nullary-time-only>

non-nullary-scalar-success =
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
nullary-standard-matcher     = <nullary-incoercible-standard-predicate> | [ <coercion> ] <nullary-coercible-standard-predicate>
non-nullary-standard-matcher = <non-nullary-incoercible-standard-predicate> | [ <coercion> ] <non-nullary-coercible-standard-predicate>

non-nullary-standard-success =
  <non-nullary-string> -[ <string-block> ]
  | [ <coercion> ] <non-nullary-coercible-standard-predicate> -[ <boolean-block> ]
  | <non-nullary-blank-predicate> -[ <any-block> ]

nullary-incoercible-standard-predicate     = <nullary-blank-predicate> | <nullary-string>
non-nullary-incoercible-standard-predicate = <non-nullary-blank-predicate> | <non-nullary-string>
nullary-coercible-standard-predicate       = <nullary-boolean> | <nullary-true> | <nullary-false>
non-nullary-coercible-standard-predicate   = <non-nullary-boolean> | <non-nullary-true> | <non-nullary-false>

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

###### Number Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nullary-number-matcher     = [ <number-coercion> ] <nullary-number>
non-nullary-number-matcher = [ <number-coercion> ] <non-nullary-number>
non-nullary-number-success = <non-nullary-number-matcher> -[ <number-block> ]

nullary-number     = "n" (* is number; output type: number; value: {field value} *)
non-nullary-number = "N" (* is number; output type: number; value: {field value} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Version Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
non-nullary-version-success = <non-nullary-version> -[ <string-block> ]

nullary-version     = "v" (* is version; output type: string; value: {field value} *)
non-nullary-version = "V" (* is version; output type: string; value: {field value} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **version** is 1 or more `.`-separated components, each an ASCII digit
followed by any Unicode general category `L` or `N` characters, `+`s & `-`s
(e.g., `1.2.3-beta`). `%v` & `%V` match a string whose entire content is a
version.

###### Coercion

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
coercion        = "."!
number-coercion = <coercion> [ <number-coercion-arguments> ] (* default locale-identifier: "canonical" *)

number-coercion-arguments =
  <argument-fence>
  <number-format-arguments>
  <argument-separator>? [ <trivia-prefix-regex> ]
  <argument-separator>? [ <trivia-suffix-regex> ]
  <argument-fence>

trivia-prefix-regex = {text: Swift Regex} (* default: {empty string} *)
trivia-suffix-regex = {text: Swift Regex} (* default: {empty string} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<coercion>` allows a matcher to also match a string whose entire content parses
as the matcher's type, instead of requiring the input's type to match (e.g.,
`%.n` matches `4.5` & `"4.50"`, but not `"4.5a"`), replacing the input with the
**coerced value**.

A boolean coercion parses only `true` & `false`, verbatim.

A number coercion parses a number's separators & digit group sizes per its
number format arguments, with defaults from the [base
conventions](#numberformat) (e.g., `%.:de:n` matches `"1.234,56"`, coercing it
to `1234.56`). A digit group separator is accepted only between digit groups of
the given sizes; a `<digit-group-size>` of `0` accepts groups of any size. A
digit group separator adjacent to a digit group of any other size thus
terminates the number before that separator (e.g., `%.:,,,,,,.*:n` matches
`"1,2345"` as the number `1` followed by the trivia suffix `,2345`).

A number coercion accepts both positional & scientific notation (an exponent
indicator, `e` or `E`, followed by an optionally signed integer exponent). The
coerced value retains the input's notation, without `+` signs, a `-` sign on 0,
or trailing fractional `0`s, in either its significand or its exponent; its
integer part & its exponent each have no leading `0`s, being `0` iff they have
no nonzero digit (e.g., `%.n` coerces `"+01.50e+03"` to `1.5e3`, `".5"` to
`0.5`, `"-0.0"` to `0` & `"1e-00"` to `1e0`).

A number coercion also allows **trivia** around the number, matching a string
iff the string is, for the shortest trivia prefix for which such a string
exists:

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
retaining the trivia unchanged (e.g., `..:,,,,,[$]:numberFormat:de:` renders
`"$1234.5"` as `$1.234,5`).

Because `\` escapes the next character in every text token, a regex's own `\` is
written `\\` (e.g., `\\d` for the regex `\d` & `\\$` for `\$`), and
`<trivia-prefix-regex>`'s `,` & `:` & `<trivia-suffix-regex>`'s `:` must be
escaped.

###### Chronologic Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nullary-date-matcher          = [ <coercion> ] <nullary-date>
non-nullary-date-matcher      = [ <coercion> ] <non-nullary-date>
non-nullary-date-success      = <non-nullary-date-matcher> -[ <date-block> ]
non-nullary-time-only-success = <non-nullary-time-only> -[ <time-only-block> ]

nullary-date          = "d" (* is chronologic with a date; output type: date; value: {ISO date / datetime, per input, in system time zone} *)
non-nullary-date      = "D" (* is chronologic with a date; output type: date; value: {ISO date / datetime, per input, in system time zone} *)
nullary-time-only     = "c" (* is time-only;               output type: time-only; value: {ISO time, in system time zone}; mnemonic: clock *)
non-nullary-time-only = "C" (* is time-only;               output type: time-only; value: {ISO time, in system time zone}; mnemonic: clock *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Input is always auto-detected: a string as an ISO-8601 datetime, date-only, or
time-only (trying them in that order) & a number as a Unix time; this does not
depend on field name, label, output format, or any other context.

`%d` & `%D` match a chronologic value that has a date (i.e., a date-only, a
datetime, or a Unix time); `%c` & `%C` match a time-only value. No predicate
matches both (e.g., `%mdc+` matches either).

**Unix time** is the number of seconds since 1970-01-01T00:00:00Z, ignoring leap
seconds.

A **decimal number** is an optional sign (`-` or `+`); ASCII digits, a `.`
followed by ASCII digits, or both, in that order; then optionally an exponent
indicator (`e` or `E`) & an optionally signed integer exponent (e.g., `-1`,
`.5`, or `1.5e9`).

[`<coercion>`](#coercion) also allows a string that is not an ISO-8601 value but
whose entire content is a decimal number, as a Unix time (e.g., `%.D` matches
`"0"`, but `%D` does not).

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
- UTC offset: at most 18 hours from UTC, as for [`timeZone`](#timezone).

No other ISO-8601 representation is detected (e.g., basic format, ordinal dates,
week dates, or reduced precision other than a datetime without seconds).

A datetime or time-only without a UTC offset is in the system time zone.

A time-only value has no date, so `%C`'s block cannot apply `dateOnly` to it,
and elsewhere, it does not conform to `dateOnly`'s input type, so [value
coercion](#value-coercion) applies (e.g., `.dateOnly` reports an error for
`17:39:23`, while `..dateOnly` aborts formatting); `%D.dateOnly+-+` outputs `-`
for `17:39:23`.

Every date is in the proleptic Gregorian calendar, as ISO-8601 requires (e.g.,
year `0000` is 1 BCE, and `1500-02-29` does not exist).

A Unix time is chronologic iff it is at least `-9223372036854775.808` & less
than `9223372036854775.808` (i.e., its whole milliseconds, rounded down, fit in
a signed 64-bit integer); an ISO-8601 date-only or datetime is chronologic iff
its instant, as a Unix time, is.

A datetime's or time-only's fractional seconds are truncated to 3 digits, which
are omitted iff all are `0` (e.g., in the UTC output time zone,
`2020-03-18T17:39:23.1234Z` renders as `2020-03-18T17:39:23.123Z`, but
`2020-03-18T17:39:23.0004Z` renders as `2020-03-18T17:39:23Z`).

A chronologic value renders in the output time zone, in ISO-8601 extended format
(as RFC 3339 profiles it for a year from 0000 to 9999):

- Date-only: `YYYY-MM-DD`, its year being, outside 0000 to 9999, a sign & at
  least 5 digits (e.g., `+10000-01-01`).
- Time-only: `hh:mm:ss`, any fractional seconds, then its UTC offset.
- Datetime: its date, `T`, then its time, as for a time-only.

Seconds always render (e.g., in the UTC output time zone, `2020-03-18 17:39`
renders as `2020-03-18T17:39:00Z`), so every rendered datetime or time-only has
the same form. A UTC offset renders as `Z` iff it is 0, else as `±hh:mm`.

###### Branched Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
match-placeholder = <unary-match-placeholder> | <binary-match-placeholder>

unary-match-placeholder  = <placeholder-prefix> <unary-match> <branches> <block-terminator>
binary-match-placeholder = <placeholder-prefix> <binary-match> <branches> <block-terminator> -[ <failure-block> ] <block-terminator>

unary-match  = "m" (* matches a branch in `<branches>`; output type: {matched branch value's type}; value: {matched branch value} *)
binary-match = "M" (* matches a branch in `<branches>`; output type: {matched branch value's type}; value: {matched branch value} *)

branches = <conditional-branch>+ <branch>
branch   = <conditional-branch> | <unconditional-branch>

conditional-branch   = <nullary-conditional-branch> | <non-nullary-conditional-branch>
unconditional-branch = <nullary-unconditional-predicate> | <non-nullary-unconditional-branch>

nullary-conditional-branch     = [ <branch-negation> ] <nullary-scalar-matcher>
non-nullary-conditional-branch =
  <non-nullary-scalar-success> <block-terminator>
  | <branch-negation> <non-nullary-scalar-matcher> -[ <unconditional-block> ] <block-terminator>

branch-negation = "-"!

non-nullary-unconditional-branch =
  <non-nullary-input> -[ <unconditional-block> ] <block-terminator>
  | ( <non-nullary-label> | <non-nullary-name> ) -[ <string-block> ] <block-terminator>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `<branch>`s in `<branches>` are evaluated sequentially against the field
  value, returning as `<match-placeholder>`'s value:
  - If `<branch>` has `<branch-negation>`:
    - If it fails: its `<unconditional-block>`'s evaluated value if it is
      non-nullary, otherwise the field value.
  - Otherwise:
    - If it succeeds: its block's evaluated value if it is non-nullary,
      otherwise its matcher's value.
- If no `<branch>` returns a value:
  - For `%m`: the placeholder fails & aborts formatting.
  - For `%M`: returns its `<failure-block>`'s value.

Examples:

- `%mN.absoluteValue+bI..uppercase++`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, outputs the uppercased value.
- `%MN.absoluteValue+b+Status Unknown+`:
  - If number, outputs the absolute value.
  - If boolean, outputs the boolean value.
  - Otherwise, outputs `Status Unknown`.
