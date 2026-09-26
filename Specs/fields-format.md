<!--markdownlint-disable-file first-line-heading-->
#### Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-modifier        = <format-modifier-prefix> [ <format-block> ]
format-modifier-prefix = ":"-

format-block = <pipeline> | <format-template> (* direct default: {nullary placeholder for the field's type determinant's type & coercion} *)

pipeline = <named-format> | [ <named-format> ] <format-transform-pipeline> | [ <named-format> ] [ <format-transform-pipeline> ] <value-transform-pipeline>

format-template = [ <template-text> ] ( <placeholder> [ <template-text> ] )+

template-text = ~^{text}^~
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

##### Pipelines

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
string-pipeline = <named-string-format> | [ <named-string-format> ] <string-transform-pipeline>

number-pipeline =
  <named-number-format>
  | [ <named-number-format> ] ( <number-transform-pipeline> | <number-to-string-transform-pipeline> | <unconditional-transform-pipeline> )

chronologic-pipeline = <named-chronologic-format> | [ <named-chronologic-format> ] ( <chronologic-transform-pipeline> | <unconditional-transform-pipeline> )

unconditional-pipeline = <named-unconditional-format> [ <string-transform-pipeline> ] | <unconditional-transform-pipeline>
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
named-chronologic-format   = <name-prefix> <format-name> (* only for: name of a format conforming to <chronologic-block> *)
named-unconditional-format = <name-prefix> <format-name> (* only for: name of a format conforming to <unconditional-block> *)

named-format-reference =
  <named-format>
  | <named-string-format>
  | <named-number-format>
  | <named-chronologic-format>
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
the referenced format's output must also have the transforms' input type (a
template's output is a string, e.g., `:name.round` requires `name` to be a
`<number-transform-pipeline>`). Otherwise, an error is reported.

Because every `<success-block>` includes `<unconditional-block>`, a named
unconditional format satisfies every `<named-format-reference>`.

##### Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
transform-pipeline       = <value-transform-pipeline> | <unconditional-transform-pipeline> | <format-transform-pipeline> (* non-structural *)
value-transform-pipeline = <string-transform-pipeline> | <number-transform-pipeline> | <number-to-string-transform-pipeline> | <chronologic-transform-pipeline>

string-transform-pipeline      = <string-transform-call>+
chronologic-transform-pipeline = <chronologic-transform-call>+

unconditional-transform-pipeline = <coerced-string-transform-call> [ <string-transform-pipeline> ]

number-transform-pipeline           = <number-transform-call>+
number-to-string-transform-pipeline = [ <number-transform-call>+ ] <number-to-string-transform-call>

string-transform-call           = <transform-call-prefix> [ <strict-coercion> ] <string-transform>
number-transform-call           = <transform-call-prefix> [ <strict-coercion> ] <number-transform>
number-to-string-transform-call = <transform-call-prefix> [ <strict-coercion> ] <number-to-string-transform>
chronologic-transform-call      = <transform-call-prefix> [ <strict-coercion> ] <chronologic-transform>

coerced-string-transform-call = <transform-call-prefix> <strict-coercion> <string-transform>

transform-call-prefix = "."!

argument-fence     = ":" (* fences a transform's argument list *)
argument-separator = "," (* separates a transform's arguments *)

value-transform            = <string-transform> | <number-transform> | <number-to-string-transform> | <chronologic-transform> (* non-structural *)
string-transform           = <initial-titlecase> | <lowercase> | <trim-whitespace> | <uppercase> (* type: string *)
number-transform           = <absolute-value> | <round> | <scale> (* type: number *)
number-to-string-transform = <group> (* type: number *)
chronologic-transform      = <date-only> | <time-zone> (* type: chronologic *)

initial-titlecase = "initialTitlecase"
lowercase         = "lowercase"
trim-whitespace   = "trimWhitespace"
uppercase         = "uppercase"

absolute-value = "absoluteValue"
round          = "round"
scale          = "scale" <scale-arguments>

group = "group" [ <group-arguments> ]

date-only = "dateOnly"
time-zone = "timeZone" <time-zone-arguments> (* sets the output time zone *)

group-arguments          = <argument-fence> ( <locale-identifier> | <explicit-group-arguments> ) <argument-fence>
explicit-group-arguments = <digit-group-separator> <argument-separator> <digit-group-size>

scale-arguments =
  <argument-fence> <radix>
  <argument-separator> <exponent>
  <argument-separator> [ <significant-digits> ]
  <argument-separator> <fractional-digits>
  <argument-fence>

time-zone-arguments = <argument-fence> <time-zone-code> <argument-fence>

digit-group-separator = ^{text}^
digit-group-size      = {positive integer}

radix              = {integer from 2 to 36} (* base for `exponent` & the rendered digits *)
exponent           = {non-negative integer} (* divides the field's value by `radix^exponent` before rendering *)
significant-digits = {positive integer}     (* rounds to this many total `radix` digits; absent: no rounding *)
fractional-digits  = {non-negative integer} (* exactly this many `radix` digits after the point; `0`: integer *)

time-zone-code = {text: case-insensitive IANA Time Zone Database identifier, Foundation `TimeZone.abbreviationDictionary` key, UTC offset, or "system"} (* default: "system" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- A `<transform-pipeline>` `t` is a pipeline of transformations applied to:
  - If a `<named-format-reference>` `n` immediately precedes `t`: `n`'s value.
  - Otherwise: the field's value.

###### Value Coercion

A transform without `<strict-coercion>` requires its input to already be of its
input type; otherwise, an error is reported.

A `<strict-coercion>` attempts to coerce an input value into the correct input
type for the annotated transform. If the coercion is successful, the transform
is applied to the coerced input; otherwise, formatting
[aborts](#success--failure).

Coercing any value to a string always succeeds (`null` becomes the empty
string), so an `<unconditional-transform-pipeline>`, which starts with a
`<coerced-string-transform-call>`, cannot fail.

###### String Transforms

Case transforms use Unicode's full, locale-independent case mappings, which can
modify a string's length (e.g., `ß` uppercases to `SS`).

<!--editorconfig-checker-disable-->
- `initialTitlecase`: titlecases the string's **initial character**, retaining
  the rest. The initial character is the 1st letter (excluding uncased modifier
  letters), number, symbol (Unicode general category `S`), or private-use
  character, per [ICU's default titlecasing index adjustment](
    https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/stringoptions_8h.html#a4975f537b9960f0330b233061ef0608d
  ). Titlecasing leaves a number, symbol, or private-use character unchanged
  (e.g., `"hello"` becomes `"Hello"`, but `1st` & `$abc` are unaffected).
- `lowercase`: lowercases every character.
- `trimWhitespace`: removes leading & trailing whitespace (Unicode general
  category `Z` characters, `U+0009` to `U+000D` & `U+0085`).
- `uppercase`: uppercases every character.
<!--editorconfig-checker-enable-->

###### Number Transforms

A number transform retains its value's notation (positional or scientific),
except `scale`, whose arguments define its rendering.

- `absoluteValue`: removes the value's leading sign (`-` or `+`), if any,
  retaining the rest of its representation (e.g., `-1.50` becomes `1.50`, and
  `-1.5e-3` becomes `1.5e-3`).
- `round`: the value rounded exactly to the nearest integer, with halves rounded
  away from 0, rendered in the value's notation:
  - Positional: as an integer (e.g., `-2.5` becomes `-3`).
  - Scientific: in normalized scientific notation, retaining the value's
    exponent marker (`e` or `E`) & whether a nonnegative exponent has a `+`
    (e.g., `1.25E1` becomes `1.3E1`, `9.96e+1` becomes `1e+2` & `1.5e3` remains
    `1.5e3`).

  A leading `+` is retained, while a leading `-` is retained iff the result is
  nonzero (e.g., `+2.4` becomes `+2`, and `-0.4` becomes `0`).
- `scale`: see [`scale`](#scale).

###### `group`

`group` inserts `<digit-group-separator>` into the field's integer part every
`<digit-group-size>` digits, counting from its least significant digit.

If `<digit-group-separator>` & `<digit-group-size>` are absent, they are sourced
from:

- If [`<locale-identifier>`](fields.md#sort-localization) is present: the
  identified locale.
- Otherwise: the system locale.

###### `scale`

`scale` divides the field's value by `radix^exponent`, optionally rounds it to
`significant-digits` total `radix` digits, then renders it in positional
notation, base `radix`, with exactly `fractional-digits` digits after the radix
point.

- Both roundings (to `significant-digits`, then to `fractional-digits`) are
  half-away-from-zero.
- `fractional-digits` of `0` renders a plain integer, with no radix point.
- For `radix` > 10, digits beyond `9` are lowercase `a`-`z`.
- `0` always renders as `0` (or `0` followed by `fractional-digits` `0`s, if
  any), never spelled out.
- E.g., a byte count as integer decimal megabytes: `.scale:10,6,,0:`.

###### Chronologic Transforms

A `<chronologic-transform-pipeline>`'s transforms jointly set how its value is
rendered, regardless of their order:

- `dateOnly`: renders only the date, in the output time zone.
- `timeZone`: sets the output time zone to the one that its `<time-zone-code>`
  identifies; if the pipeline contains multiple `timeZone`s, the last one takes
  precedence.

Absent `timeZone`, the output time zone is the system time zone.

###### `timeZone`

A `<time-zone-code>` that is both an IANA Time Zone Database identifier & a
`TimeZone.abbreviationDictionary` key (e.g., `EST`) identifies the latter.

A **UTC offset** is either:

- `Z`, for UTC.
- An optional `UTC` or `GMT` prefix, then `+` or `-`, then a 1- or 2-digit hour,
  then, optionally, `:` followed by a 2-digit minute from `00` to `59`.

A UTC offset of more than 18 hours from UTC is an error.

A `GMT`-prefixed UTC offset is ahead of UTC for `+` & behind UTC for `-`, but
the IANA Time Zone Database's signed `Etc/GMT` identifiers are the reverse, per
POSIX (e.g., `GMT+5` is 5 hours ahead of UTC, while `Etc/GMT+5` is 5 hours
behind).

##### Format Transforms

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
format-transform-pipeline = ( <transform-call-prefix> <format-transform> )+ (* last wins *)

format-transform     = <justify>
justify              = <start-justify> | <center-start-justify> | <center-end-justify> | <end-justify> (* default: <start-justify> *)
start-justify        = "startJustify"
center-start-justify = "centerStartJustify"
center-end-justify   = "centerEndJustify"
end-justify          = "endJustify"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Unlike a `<value-transform>`, a `<format-transform>` does not transform any
value; it sets a property of the field itself, currently just its `table`-output
column alignment. It therefore does not affect the field's rendered value: it is
a no-op for `json` / `key-value` output (which have no columns to align); it
does not force `%i` / `%I`'s type-preserving `json` passthrough into a string,
unlike every other transform.

`centerStartJustify` & `centerEndJustify` differ only when the column's padding
is odd-width: `centerStartJustify` puts the extra padding character after the
value (leaving it nearer the column's start); `centerEndJustify` puts it before
the value (leaving it nearer the column's end).

##### Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
placeholder = <unconditional-placeholder> | <conditional-placeholder>

matcher   = [ <placeholder-prefix> ] <modifiers> <predicate> (* non-structural *)
modifiers = [ <abort-on-success> | <abort-on-failure> | <branch-negation> ] [ <coercion> ] (* non-structural *)
predicate = <nullary-predicate> | <non-nullary-predicate> (* non-structural *)

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
  | <nullary-chronologic>
  | <nullary-match>
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
  | <non-nullary-chronologic>
  | <non-nullary-match>
  (* non-structural *)

coercible-modifiers = [ <strict-coercion> ]
number-modifiers    = [ <coercion> ]

coercion = <strict-coercion> | <lenient-coercion>

placeholder-prefix = "%"!

abort-on-success = "-"!
abort-on-failure = "+"!
strict-coercion  = "."!
lenient-coercion = "_"!

block-terminator = -"+"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A matcher's **nullary form** replaces its `<non-nullary-predicate>` with the
corresponding `<nullary-predicate>` (e.g., `%._N` → `%._n`).

###### Success & Failure

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
block = <format-block> | <success-block> | <failure-block> (* non-structural *)

success-block = <string-block> | <boolean-block> | <number-block> | <chronologic-block> | <any-block> | <unconditional-block> (* non-structural *)

string-block        = <string-pipeline> | <string-template>
boolean-block       = <unconditional-pipeline> | <boolean-template>
number-block        = <number-pipeline> | <number-template>
chronologic-block   = <chronologic-pipeline> | <chronologic-template> (* default: {ISO date / datetime / time, per input, in system time zone} *)
any-block           = <unconditional-pipeline> | <any-template>
unconditional-block = <unconditional-pipeline> | <unconditional-template>

failure-block = <unconditional-block> (* default: "" *)

string-template        = ( <string-block-placeholder> | <unconditional-placeholder> | <template-text> )+
boolean-template       = ( <boolean-block-placeholder> | <unconditional-placeholder> | <template-text> )+
number-template        = ( <number-block-placeholder> | <unconditional-placeholder> | <template-text> )+
chronologic-template   = ( <chronologic-block-placeholder> | <unconditional-placeholder> | <template-text> )+
any-template           = ( <any-block-placeholder> | <unconditional-placeholder> | <template-text> )+
unconditional-template = ( <unconditional-placeholder> | <template-text> )+

block-placeholder =
  <string-block-placeholder>
  | <boolean-block-placeholder>
  | <number-block-placeholder>
  | <chronologic-block-placeholder>
  | <any-block-placeholder>
  (* non-structural *)

string-block-placeholder =
  <placeholder-prefix>
  ( <nullary-string> | <non-nullary-string> -[ <string-pipeline> ] <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

boolean-block-placeholder =
  <placeholder-prefix>
  ( <nullary-coercible-standard-predicate> | <non-nullary-coercible-standard-predicate> -[ <unconditional-pipeline> ] <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

number-block-placeholder =
  <placeholder-prefix>
  ( <nullary-number> | <non-nullary-number> -[ <number-pipeline> ] <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

chronologic-block-placeholder =
  <placeholder-prefix>
  ( <nullary-chronologic> | <non-nullary-chronologic> -[ <chronologic-pipeline> ] <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)

any-block-placeholder =
  <placeholder-prefix>
  ( <nullary-scalar-conditional-predicate> | <non-nullary-scalar-conditional-predicate> -[ <unconditional-pipeline> ] <block-terminator> )
  (* only for: enclosing matcher's <predicate>, nullary or non-nullary *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A **matcher** is a `<placeholder-prefix>` (in a placeholder), its `<modifiers>`
& its `<predicate>`; a placeholder or branch is a matcher immediately followed
by its blocks, which define the matcher's **form**:

- **Nullary**: no blocks.
- **Unary**: a `<success-block>`.
- **Binary**: a `<success-block>` & a `<failure-block>`.
- **Abort-on-failure** (`%+…`): a `<success-block>`.
- **Abort-on-success** (`%-…`): a `<failure-block>`.
- **Unary match** (`%m`): `<branches>`.
- **Binary match** (`%M`): `<branches>` & a `<failure-block>`.

A matcher succeeds iff it matches the value against which it is evaluated.

Unconditional matchers always succeed.

A `<success-block>` is evaluated iff its enclosing matcher succeeds.

A `<failure-block>` is evaluated iff its enclosing placeholder fails.

A `<success-block>`'s kind follows the matched value's type; where that can be
any type, the block's pipeline must start by coercing to a string.

`<unconditional-block>` differs from `<any-block>` only by forbidding
`<block-placeholder>`s.

Within a `<success-block>`, a `<block-placeholder>` is evaluated against the
enclosing matcher's value (coerced, if it coerces), so it always succeeds; `%i`
/ `%I` are evaluated against the original input, at its original type (e.g.,
`%.N%n (%i)++` renders `4.50` as `4.5 (4.50)`).

A matcher's **value** is given by its `<predicate>`'s `value:` comment part.

- If a placeholder succeeds, the following is inserted in situ:
  - If it has `<abort-on-success>`: formatting aborts.
  - If its `<success-block>` is present: its evaluated value.
  - Otherwise: the placeholder's value.
- If a placeholder fails (e.g., `%u` is evaluated against a non-`null`):
  - If it has `<abort-on-success>` & a nullary predicate: the field value.
  - If its grammar includes a `<failure-block>`: its evaluated value, or `""` if
    absent.
  - Otherwise: formatting aborts.

Formatting **aborts** by outputting an empty string, ignoring the rest of
`<format-block>`, both preceding & succeeding.

###### Unconditional Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
unconditional-placeholder = <nullary-unconditional-placeholder> | <non-nullary-unconditional-placeholder>

nullary-unconditional-placeholder = <placeholder-prefix> <nullary-unconditional-predicate>

non-nullary-unconditional-placeholder =
  <placeholder-prefix>
  ( <non-nullary-input> -[ <unconditional-pipeline> ] | ( <non-nullary-label> | <non-nullary-name> ) -[ <string-pipeline> ] )
  <block-terminator>

nullary-unconditional-predicate = <nullary-input> | <nullary-label> | <nullary-name>

nullary-input     = "i" (* type: any; value: {field value}; "" if null *)
non-nullary-input = "I" (* type: any; value: {field value}; "" if null *)
nullary-label     = "l" (* type: any; value: {field label} *)
non-nullary-label = "L" (* type: any; value: {field label} *)
nullary-name      = "k" (* type: any; value: {field name} *)
non-nullary-name  = "K" (* type: any; value: {field name} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Conditional Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
conditional-placeholder = <nullary-conditional-placeholder> | <non-nullary-conditional-placeholder>

nullary-conditional-placeholder     = <nullary-scalar-conditional-placeholder> | <nullary-match-placeholder>
non-nullary-conditional-placeholder = <non-nullary-scalar-conditional-placeholder> | <non-nullary-match-placeholder>

nullary-scalar-conditional-placeholder = <placeholder-prefix> [ <abort-on-success> ] <nullary-scalar-matcher>
non-nullary-scalar-conditional-placeholder =
  <placeholder-prefix>
  (
    <non-nullary-scalar-success> <block-terminator> -[ <failure-block> ] <block-terminator>
    | <abort-on-success> <non-nullary-scalar-matcher> -[ <failure-block> ] <block-terminator>
    | <abort-on-failure> <non-nullary-scalar-success> <block-terminator>
  )

nullary-scalar-matcher     = <nullary-standard-matcher> | <nullary-number-matcher> | <nullary-version> | <nullary-chronologic>
non-nullary-scalar-matcher = <non-nullary-standard-matcher> | <non-nullary-number-matcher> | <non-nullary-version> | <non-nullary-chronologic>
non-nullary-scalar-success = <non-nullary-standard-success> | <non-nullary-number-success> | <non-nullary-version-success> | <non-nullary-chronologic-success>

nullary-scalar-conditional-predicate     = <nullary-standard-predicate> | <nullary-number> | <nullary-version> | <nullary-chronologic>
non-nullary-scalar-conditional-predicate = <non-nullary-standard-predicate> | <non-nullary-number> | <non-nullary-version> | <non-nullary-chronologic>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Standard Placeholders

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
nullary-standard-matcher     = <nullary-incoercible-standard-predicate> | <coercible-modifiers> <nullary-coercible-standard-predicate>
non-nullary-standard-matcher = <non-nullary-incoercible-standard-predicate> | <coercible-modifiers> <non-nullary-coercible-standard-predicate>

non-nullary-standard-success =
  <non-nullary-string> -[ <string-block> ]
  | <coercible-modifiers> <non-nullary-coercible-standard-predicate> -[ <boolean-block> ]
  | <non-nullary-blank-predicate> -[ <any-block> ]

nullary-standard-predicate     = <nullary-incoercible-standard-predicate> | <nullary-coercible-standard-predicate>
non-nullary-standard-predicate = <non-nullary-incoercible-standard-predicate> | <non-nullary-coercible-standard-predicate>

nullary-incoercible-standard-predicate     = <nullary-blank-predicate> | <nullary-string>
non-nullary-incoercible-standard-predicate = <non-nullary-blank-predicate> | <non-nullary-string>
nullary-blank-predicate                    = <nullary-null> | <nullary-empty> | <nullary-whitespace>
non-nullary-blank-predicate                = <non-nullary-null> | <non-nullary-empty> | <non-nullary-whitespace>
nullary-coercible-standard-predicate       = <nullary-boolean> | <nullary-true> | <nullary-false>
non-nullary-coercible-standard-predicate   = <non-nullary-boolean> | <non-nullary-true> | <non-nullary-false>

nullary-null           = "u" (* is null;                                                  type: any; value: "" *)
non-nullary-null       = "U" (* is null;                                                  type: any; value: "" *)
nullary-empty          = "e" (* is null or an empty string;                               type: any; value: "" *)
non-nullary-empty      = "E" (* is null or an empty string;                               type: any; value: "" *)
nullary-whitespace     = "w" (* is null, an empty string, or a string of only whitespace; type: any; value: "" *)
non-nullary-whitespace = "W" (* is null, an empty string, or a string of only whitespace; type: any; value: "" *)
nullary-boolean        = "b" (* is boolean;                                               type: boolean; value: {field value} *)
non-nullary-boolean    = "B" (* is boolean;                                               type: boolean; value: {field value} *)
nullary-true           = "t" (* is true;                                                  type: boolean; value: {field value} *)
non-nullary-true       = "T" (* is true;                                                  type: boolean; value: {field value} *)
nullary-false          = "f" (* is false;                                                 type: boolean; value: {field value} *)
non-nullary-false      = "F" (* is false;                                                 type: boolean; value: {field value} *)
nullary-string         = "s" (* is string;                                                type: string; value: {field value} *)
non-nullary-string     = "S" (* is string;                                                type: string; value: {field value} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

###### Number Formatting

```ebnf
nullary-number-matcher     = <number-modifiers> <nullary-number>
non-nullary-number-matcher = <number-modifiers> <non-nullary-number>
non-nullary-number-success = <non-nullary-number-matcher> -[ <number-block> ]

nullary-number     = "n" (* is number; type: number; value: {field value} *)
non-nullary-number = "N" (* is number; type: number; value: {field value} *)
```

###### Version Formatting

```ebnf
non-nullary-version-success = <non-nullary-version> -[ <any-block> ]

nullary-version     = "v" (* is version; type: version; value: {field value} *)
non-nullary-version = "V" (* is version; type: version; value: {field value} *)
```

A **version** is a string of 1 or more `.`-separated components, each a
non-negative integer optionally followed by non-`.` characters.

###### Coercion

`<strict-coercion>` allows a matcher to also match a string whose entire content
parses as the matcher's type, instead of requiring the input's type to match
(e.g., `%.n` matches `4.5` & `"4.50"`, but not `"4.5a"`), replacing the input
with the **coerced value**.

`<lenient-coercion>` allows a matcher to match a string with more lenient
matching requirements than for `<strict-coercion>`, in a manner specific to the
matcher type:

- `%_n` & `%_N` match a string iff it contains exactly 1 number, regardless of
  any **trivia** surrounding it (e.g., a `US$` / `$` prefix or an `MB` suffix).
  Number transforms may be applied to the number alone, retaining the trivia
  unchanged.

###### Types

A field's **type** is that of its **type determinant**: the 1st matcher or
transform of the most specific type in its `<format-block>` (including every
branch). A predicate's or transform's type is given by its `type:` comment part,
except that a coerced `<string-transform>` is "any". In descending specificity:

- Chronologic
- Version
- Number
- Boolean
- String
- Any (which is also the type of a `<format-block>` with no type determinant)

A value [**conforms**](fields.md#sort-nonconforming-values) to a type iff the
type's predicate, with the type determinant's coercion, matches it; all values
conform to "any".

###### Chronologic Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
non-nullary-chronologic-success = <non-nullary-chronologic> -[ <chronologic-block> ]

nullary-chronologic     = "c" (* is chronologic; type: chronologic; value: {ISO date / datetime / time, per input, in system time zone} *)
non-nullary-chronologic = "C" (* is chronologic; type: chronologic; value: {ISO date / datetime / time, per input, in system time zone} *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Input is always auto-detected, trying, in order: ISO-8601 datetime, ISO-8601
date-only, then a Unix epoch (seconds) numeric timestamp; this does not depend
on field name, label, output format, or any other context.

###### Branched Formatting

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
match-placeholder = <nullary-match-placeholder> | <non-nullary-match-placeholder> (* non-structural *)

nullary-match-placeholder     = <placeholder-prefix> <nullary-match> <branches> <block-terminator>
non-nullary-match-placeholder = <placeholder-prefix> <non-nullary-match> <branches> <block-terminator> -[ <failure-block> ] <block-terminator>

nullary-match     = "m" (* matches a branch in `<branches>`; value: {matched branch value} *)
non-nullary-match = "M" (* matches a branch in `<branches>`; value: {matched branch value} *)

branches = <conditional-branch>+ <branch>
branch   = <conditional-branch> | <unconditional-branch>

conditional-branch         = <nullary-conditional-branch> | <non-nullary-conditional-branch>
nullary-conditional-branch = [ <branch-negation> ] <nullary-scalar-matcher>
non-nullary-conditional-branch =
  <non-nullary-scalar-success> <block-terminator>
  | <branch-negation> <non-nullary-scalar-matcher> -[ <unconditional-block> ] <block-terminator>

branch-negation = "-"!

unconditional-branch = <nullary-unconditional-predicate> | <non-nullary-unconditional-branch>

non-nullary-unconditional-branch =
  <non-nullary-input> -[ <unconditional-block> ] <block-terminator>
  | ( <non-nullary-label> | <non-nullary-name> ) -[ <string-block> ] <block-terminator>
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

- `<branch>`s in `<branches>` are evaluated sequentially against the field
  value, returning as `<match-placeholder>`'s value:
  - If the `<branch>` has `<branch-negation>`:
    - If it fails: its `<unconditional-block>`'s evaluated value if present,
      otherwise the field value.
  - Otherwise:
    - If it succeeds: the `<branch>`'s value.
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
  - Otherwise, outputs `"Status Unknown"`.
