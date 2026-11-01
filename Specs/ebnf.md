# Custom EBNF Grammar

## Meta-Grammar

Within the definition of this custom EBNF grammar:

- All text is case-sensitive.
- A word of uppercase letters, digits & `_` is a **metavariable** for an
  expression or text.
- Whitespace separating tokens in the grammar is ignored.
- All other characters are used verbatim.

## Grammar

When using this custom EBNF grammar to define a syntax:

- All text is case-sensitive.
- [Outer bare whitespace treatment](#outer-bare-whitespace-treatment) varies by
  expression.

### Escaping

The **escape prefix** is `\`.

An **escape sequence** is an escape prefix immediately followed by any
character, the **escaped character**; an escape prefix at the end of the syntax
text is an error.

An escape sequence evaluates to its escaped character (e.g., `\n` evaluates to
`n`).

A **bare character** is any character that is not part of an escape sequence.

A syntax may treat the same character differently when bare or escaped, despite
both evaluating to that same character.

### Whitespace

**Whitespace** is any Unicode `White_Space` character: Unicode general category
`Z` characters, `U+0009` to `U+000D` & `U+0085`.

### Multiplicity

A value's multiplicity is one of:

- **Scalar**: a single value (e.g., an integer or a string).
- **Repetition**: a sequence of 0 or more elements. A repetition with 0 or 1
  elements is still a repetition, not a scalar.
- **Tuple**: the values of a [sequence](#sequences)'s children, in order.

An expression's multiplicity determines its occurrences' multiplicity:

- **Inherent scalar** expression: every occurrence is a scalar.
- **Inherent repetition** expression: every occurrence is a repetition.
- **Inherent tuple** expression: every occurrence is a tuple.
- **Content-dependent** expression: each occurrence has its content's
  multiplicity.
- **Context-dependent** expression: each occurrence has the multiplicity
  required by its context.

An expression's **static multiplicity** is the multiplicity shared by all its
possible occurrences, determined from the grammar instead of the syntax text:

- Inherent scalar, repetition, or tuple: that multiplicity.
- [Nonterminal reference](#nonterminal-references): its definition's static
  multiplicity.
- [Grouping](#groupings), [optional](#optionals), or
  [trailing-omissible](#trailing-omissibles): its child's static multiplicity.
- [Sequence](#sequences) with exactly 1 variable child: that child's static
  multiplicity.
- [Choice](#choices): its alternatives' static multiplicity, if they all share
  one; otherwise, **mixed**.

### Constant Vs. Variable Expressions

A **constant expression** consumes invariant text (e.g., a literal).

A **variable expression** consumes variable text (e.g., a typed terminal).

### Compounds Vs. Terminals

A **compound** is an expression that contains other expressions.

A **terminal** is an expression that does not contain other expressions.

### Tokens

**Tokens** are contiguous characters that are consumed together as a single
element by the syntax.

**Bare tokens** contain only bare characters.

**Literal tokens** are bare tokens that match [literals](#literals) & are
consumed by constant expressions; escaping any character within a token that
would otherwise be a literal token renders it a variable token.

**Variable tokens** are tokens that [typed terminals](#typed-terminals) consume;
each may contain both bare characters & escape sequences.

#### Candidate Literals

The **candidate literals** of a given position in the syntax text are the
literals that the syntax can consume at that position (regardless of the syntax
text starting at that position), which includes the literals that:

- Start any choice available at that position.
- Continue any enclosing sequence or repetition.
- Close any enclosing expression.

#### Consuming Tokens

Syntax text is consumed as a token iff a literal token or a variable token, as
specified below, matches the syntax text starting at the current position.

Consuming a token commits to the set of expressions that the token starts,
continues, or closes; each subsequently consumed token narrows the set to the
expressions that consume it.

A complete expression is **parsed** once it is the sole element in its set;
disjoint choices guarantee that at most 1 expression per set is parsed.

If a set ever becomes empty, or if the syntax text is exhausted before every
set's expression is parsed, an error is reported.

Syntax text is never reconsidered after it has been consumed.

##### Consuming Literal Tokens

Syntax text is consumed as a literal token iff a candidate literal matches the
syntax text starting at the current position; if multiple match, the longest is
consumed.

##### Consuming Variable Tokens

Syntax text is consumed as a variable token iff a typed terminal is available at
the current position & no candidate literal matches the syntax text there.

A variable token's **candidate terminators** are the candidate literals of the
position immediately following it.

A variable token is the longest non-empty prefix starting at the current
position that contains no candidate terminator & that its typed terminal
[accepts](#typed-terminals) (i.e., maximal munch; e.g., for
`{integer: 1 to 100}`, `150` consumes `15`, leaving `0` for the next token),
less any ignored outer bare whitespace; iff no such prefix exists, an error is
reported.

Iff multiple typed terminals are available at the current position (e.g., in
`<a> | <b>`), the longest variable token that any of them accepts is consumed,
committing to the expressions whose typed terminals accept it.

### Character Consumption

All characters besides outer bare whitespace are always consumed, which
includes:

- Non-whitespace
- Escaped whitespace
- Inner bare whitespace, which is between a token's 1st non-bare-whitespace
  character & its last non-bare-whitespace character

#### Outer Bare Whitespace

**Outer bare whitespace** exists immediately before the 1st, or immediately
after the last:

- Character consumed by a literal token.
- Non-bare-whitespace character consumed by a variable token.

A candidate literal is matched before outer bare whitespace is processed,
consuming any bare whitespace that it matches.

Unless otherwise specified, expressions do not consume outer bare whitespace.

#### Outer Bare Whitespace Treatment

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literals](#literals):

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
[ [ "~" ] ( "!" | "-" | "^" | "&" ) ] EXPRESSION [ ( "!" | "-" | "^" | "&" ) [ "~" ] ] (* default: "~-" EXPRESSION "-~" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Punctuation attaches directly (i.e., with no intervening whitespace) to
`EXPRESSION`, distinguishing a suffix for an expression from a prefix for the
subsequent expression.

Each side is independent.

Each side of an expression treats adjacent outer bare whitespace as one of:

- `!`: **Forbidden**: iff present, an error is reported.
- `-`: **Ignored**: not consumed.
- `^`: **Consumed**: consumed.
- `&`: **Required**: iff absent, an error is reported; otherwise, not consumed.

`~` **defers**, allowing the side's outer bare whitespace treatment to be
overridden.

The syntax text's start & end are treated as deferring sides that ignore outer
bare whitespace.

Outer bare whitespace is treated per its 2 adjacent sides: the preceding token's
end & the following token's start, the following token being the one that would
start after the whitespace if it were ignored (or at the whitespace, iff a
variable token starts there). Of those 2 sides:

- If both defer: the higher-precedence treatment applies, in descending
  precedence:
  - Required
  - Consumed
  - Ignored
  - Forbidden
- Otherwise: the non-deferring side's treatment applies. A syntax must ensure
  that no 2 potentially adjacent non-deferring sides differ.

Consumed outer bare whitespace is included in the adjacent variable token's
value, if any; otherwise, it is discarded.

A syntax must ensure that no 2 consuming variable tokens are adjacent.

An unannotated side of a compound treats outer bare whitespace as does the same
side of its 1st (for the start) or last (for the end) child. An annotated side
of a compound applies its treatment to the same side of that child, transitively
down to the token on that side, overriding any annotation within; i.e., the
outermost annotation overrides.

### Terminals

#### Bare Characters

```ebnf
BARE
```

Inherent scalar.

A [bare character](#escaping), which evaluates to itself.

#### Escape Sequences

```ebnf
\ESCAPED
```

Inherent scalar.

An [escape sequence](#escaping), which evaluates to `ESCAPED`.

#### Null

```ebnf
null
```

Context-dependent multiplicity.

The absence of a value; matches no syntax text.

#### Empty

```ebnf
empty
```

Inherent repetition.

A [repetition](#multiplicity) of 0 elements; matches no syntax text. Distinct
from `null` & from an empty string.

#### End

```ebnf
end
```

Inherent scalar.

A constant expression that matches no syntax text, only at the end of the syntax
text.

#### Literals

```ebnf
"TEXT"
```

Inherent scalar.

A **literal**, which matches a [literal token](#tokens) of `TEXT`.

Within `TEXT`, `""` denotes a `"`.

#### Typed Terminals

Defined via a modified meta-grammar supporting [optionals](#optionals) &
[literals](#literals):

```ebnf
"{" SUBTYPE [ ":" CONSTRAINTS ] "}"
```

Inherent scalar.

Consumes a [variable token](#tokens), whose value has `SUBTYPE`'s type:

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| `SUBTYPE`   | Type      | Lexical Form                                                                                                                                                                                                 |
|:------------|:----------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `boolean`   | boolean   | `true` or `false`                                                                                                                                                                                            |
| `date`      | date      | An ISO-8601 date-only or datetime                                                                                                                                                                            |
| `integer`   | number    | 1 or more ASCII digits (`0` to `9`), optionally preceded by a sign (`+` or `-`)                                                                                                                              |
| `number`    | number    | An optional sign (`+` or `-`), then 1 or more ASCII digits, a `.` followed by 1 or more ASCII digits, or both, in that order, then optionally `e` or `E` followed by an exponent in `integer`'s lexical form |
| `regex`     | string    | A Swift Regex                                                                                                                                                                                                |
| `string`    | string    | Any characters                                                                                                                                                                                               |
| `time-only` | time-only | An ISO-8601 time-only                                                                                                                                                                                        |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

A `SUBTYPE`'s **lexical form** is the text that denotes its values, each escape
sequence denoting its escaped character (e.g., `\5` denotes `5` for `integer`).

`CONSTRAINTS` describes how its typed terminal narrows its lexical form, in
prose (e.g., `{integer: 1 to 100}`, `{string: no line terminators}`), as a
`/`-delimited Swift Regex that the whole value must match (e.g.,
`{string: /[A-Y]+/}`, which consumes `ABY` from `ABYZ`), or both, separated by
`,`.

A typed terminal **accepts** text iff the text is in its lexical form &
satisfies its `CONSTRAINTS`, unless only something outside the
[app](configs.md#configs) (e.g., a terminal) can determine the value's validity,
in which case the app accepts any text in its lexical form & passes the value
through unchecked.

For an `integer` or a `number`:

- Its value is the decimal number that its digits denote, negated iff its sign
  is `-` (e.g., `-0` is `0`), constrained by nothing but its `CONSTRAINTS`
  (e.g., `{integer}` has no minimum or maximum).
- A sign is accepted iff a valid value can be negative, unless `CONSTRAINTS`
  forbids `+` (e.g., `{integer: no "+"}`) or allows it (e.g.,
  `{integer: non-negative, optional "+"}`).
- Leading `0`s are accepted, unless `CONSTRAINTS` forbids them (e.g.,
  `{integer: positive, no leading 0s}`).

### Nonterminals

#### Nonterminal Definitions

```ebnf
NONTERMINAL = DEFINITION
```

Content-dependent multiplicity.

Binds a nonterminal to its definition.

An absent nonterminal's value is given by [Defaults for Absent
Expressions](#defaults-for-absent-expressions).

#### Nonterminal References

```ebnf
<NONTERMINAL>
```

Content-dependent multiplicity.

References the nonterminal `NONTERMINAL`.

### Groupings

```ebnf
( EXPRESSION )
```

Content-dependent multiplicity.

### Sequences

```ebnf
A B
```

If exactly 1 child is a variable expression: content-dependent multiplicity
based on the variable child; otherwise: inherent tuple.

`A` followed by `B`.

### Choices

```ebnf
A | B
```

Content-dependent multiplicity.

`A` or `B`. `A` & `B` must match disjoint sets of text, unless the enclosing
definition is [non-structural](#non-structural-comments).

### Optionals

```ebnf
[ EXPRESSION ]
```

Content-dependent multiplicity.

0 or 1 occurrence of `EXPRESSION`.

#### Presence States

An expression has 3 mutually exclusive possible presence states:

- **Present**: It contains a consumed token.
- **Transitively absent**: At least one of the expression's ancestors is absent,
  or no consumed token matches the expression as an alternative of a present
  choice or as an element of a present repetition.
- **Directly absent**: Not present & not transitively absent.

An optional's presence state is that of its parent (or present, if it has no
parent), even if the optional contains no token, so the child of an optional
that contains no token is directly absent iff the optional's parent is present.

An expression is **absent** if it is either directly or transitively absent.

### Trailing-Omissibles

```ebnf
EXPRESSION?
```

Content-dependent multiplicity.

An expression's **trailing run** is the longest run of adjacent expressions,
each an optional or a trailing-omissible, that includes it, treating each
nonterminal reference whose definition is a sequence as that sequence's children
written in place.

A trailing-omissible consumes `EXPRESSION`, but may instead consume nothing &
still match iff no expression after it in its trailing run consumes a token
(e.g., `[ "a" ] ","? [ "b" ] ","? [ "c" ]` matches `a,b`, `a,b,`, `,,c` & `a`,
but neither `ac` nor `a,c`).

A trailing-omissible is otherwise an optional.

### Repetitions (1 or More)

```ebnf
ELEMENT+
```

Inherent repetition.

`ELEMENT` must not match empty text.

### Repetitions with Separators (1 or More)

```ebnf
ELEMENT … SEPARATOR
```

Inherent repetition.

E.g.:

- `( "a" | "b" | "c" ) … ","` matches:
  - `b`
  - `c,a,c,b,a,c,b`
- `( "2" | "1" | "3" ) … ( " " | "/" )` matches:
  - `3`
  - `1 3/1/2 2/3`

Neither `ELEMENT` nor `SEPARATOR` may match empty text.

### Precedence

From highest to lowest precedence within a grouping:

- Repetition (`+`) & trailing-omissible (`?`)
- Repetition with separator (`…`)
- Sequence (juxtaposition)
- Choice (`|`)

### Comments

```ebnf
(* COMMENT *)
```

No multiplicity.

#### Mnemonic Comments

```ebnf
NONTERMINAL = DEFINITION (* mnemonic: MNEMONIC *)
```

`MNEMONIC` explains how `DEFINITION`'s literal was chosen, iff that literal
contains a letter or a digit & that choice is non-obvious (e.g., the literal is
not the 1st letter of a word in `NONTERMINAL`), because punctuation is chosen
from few candidates, so it rarely has a mnemonic. A mnemonic comment is not a
semantic comment; in a comment with multiple parts, it is the last part.

#### Semantic Comments

Semantic comments follow specific formats to concisely attach semantic
information to expressions. They are not formally part of the custom EBNF
grammar; they are an adjunct custom grammar.

A comment may hold multiple `;`-separated parts; each part that matches a
semantic comment format is a semantic comment; any other part is ordinary
commentary.

##### Free-Form Descriptions

```ebnf
{DESCRIPTION}
```

A **free-form description** describes a value or a type in prose (e.g.,
`{empty string}` or `{field value}`). Its 1st word must be followed by
whitespace, so that it never matches a [typed terminal](#typed-terminals), even
one of a future `SUBTYPE` (e.g., neither `{empty}` nor `{empty: string}`).

##### Default Comments

Default comments specify explicit defaults applicable to absent variable
nonterminals; they cannot specify defaults for constant nonterminals.

`DEFAULT` is one of:

- `null` or `empty`.
- A [free-form description](#free-form-descriptions) of the value.
- A value (e.g., `100`).
- A [nonterminal reference](#nonterminal-references): if it references an
  alternative of the choice that defines the nonterminal to which the default
  applies, directly or as a [grouping](#groupings)'s child (e.g.,
  `<relative-config>` for [`<fields-config>`](fields.md#fields-option)), it
  selects that alternative, as if that alternative were present but contained no
  token; otherwise, it evaluates to the referenced nonterminal's global default
  for the directly absent state.
- A [literal](#literals), consumed by the nonterminal to which the default
  applies.

All defaults must be valid for the applicable nonterminal.

###### Self Default Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literals](#literals):

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
NONTERMINAL "=" DEFINITION "(*" [ "direct" | "transitive" ] "default:" DEFAULT "*)"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`DEFAULT` is a default applicable for a `NONTERMINAL` that is:

- If `"direct"` is present: directly absent.
- If `"transitive"` is present: transitively absent.
- Otherwise: absent.

Only 1 self default comment may be attached to `NONTERMINAL`'s definition,
unless there are exactly 2, one of which is for `"direct"`, the other of which
is for `"transitive"`.

###### Descendant Default Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literals](#literals):

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
NONTERMINAL "=" DEFINITION "(*" [ "direct" | "transitive" ] "default" DESCENDANT ":" DEFAULT "*)"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`DEFAULT` is a default applicable for a `DESCENDANT` that is:

- One of `NONTERMINAL`'s descendants, actual or virtual.
- If `"direct"` is present: directly absent.
- If `"transitive"` is present: transitively absent.
- Otherwise: absent.

If `DESCENDANT` is not an actual descendant of `NONTERMINAL`, `NONTERMINAL` has
a **virtual descendant** `DESCENDANT`, which is always absent (directly iff
`NONTERMINAL` is present); a virtual descendant's default comment includes
neither `"direct"` nor `"transitive"`.

Only 1 descendant default comment for `DESCENDANT` may be attached to
`NONTERMINAL`'s definition, unless there are exactly 2, one of which is for
`"direct"`, the other of which is for `"transitive"`.

##### Error Comments

```ebnf
NONTERMINAL = DEFINITION (* error: CONDITION *)
```

A present `NONTERMINAL` is an error iff `CONDITION`, which describes its
circumstances in prose, holds (e.g.,
[`<document-order-option-set>`](fields.md#field-order) is an error for table
output iff it sets the resolved fields config's field order). Unlike a typed
terminal's `CONSTRAINTS`, which narrow the text that it accepts, `CONDITION`
does not affect which text is consumed (e.g., for a `{integer}` whose error
comment forbids values above 100, `150` consumes `150`, an error, while
`{integer: 1 to 100}` consumes `15` from it).

##### Type Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literals](#literals):

```ebnf
NONTERMINAL "=" DEFINITION "(*" [ "input" | "output" ] "type:" TYPE "*)"
```

`TYPE` is the type of `NONTERMINAL`'s input (iff `"input"` is present), value
(iff `"output"` is present), or both (otherwise); a syntax defines the types &
how they apply.

##### Value Comments

```ebnf
NONTERMINAL = DEFINITION (* value: VALUE *)
```

`NONTERMINAL`, when present, evaluates to the value that `VALUE` describes
instead of the text it consumes.

##### Non-Structural Comments

```ebnf
NONTERMINAL = DEFINITION (* non-structural *)
```

Marks a nonterminal that is referenced by comments and/or prose, but not by any
structural definition.

##### Last-Wins Comments

```ebnf
NONTERMINAL = DEFINITION (* last wins *)
```

Each occurrence of any of `DEFINITION`'s alternatives (a definition that is not
a choice being its own sole alternative) overrides all preceding such
occurrences that share its **last-wins scope**: its nearest enclosing occurrence
of a nonterminal whose definition contains a repetition that, transitively,
contains `NONTERMINAL`, or, absent one, the entire syntax text.

E.g., per [`<direction>`](fields.md#sort-direction)'s last wins, the [field
order](fields.md#field-order) `-P+` is ascending, but in `D-/+`, `+` does not
override `-`, because `<field-order-tiebreaker>` is not within
`<document-order-option-set>`.

Anything that nothing overrides (e.g., an occurrence that no later one
overrides, or a syntax's implied alternative that no explicit one overrides) is
**effective** (e.g., in `-P+`, `+` is effective, but `-` is not).

##### Inherited Comments

```ebnf
NONTERMINAL = DEFINITION (* inherited *)
```

A transitively absent `NONTERMINAL` may have an **inherited value**, which a
syntax defines (e.g., as the value of the same setting in the config onto which
the syntax text is overlaid). A directly absent `NONTERMINAL` has none, nor does
any of its descendants, so each one's default applies.

##### Default Resolution

###### Explicit & Implicit Defaults

- An **explicit default** is specified by any variant of a default comment.
- An **implicit default** is the value applied when no explicit default value
  applies to an expression, being:
  - For a constant expression: its constant value.
  - For a nonterminal reference: its definition's value evaluated in the
    reference's presence state.
  - For a grouping, optional, trailing-omissible, or sequence with exactly 1
    variable child: its variable child's value evaluated in the expression's
    presence state.
  - For any other variable expression whose [static multiplicity](#multiplicity)
    is repetition:
    - If transitively absent: `null`.
    - Otherwise (i.e., directly absent): `empty`.
  - Otherwise: `null`.

###### Global Defaults

An expression's **global default** for a given presence state is:

- The applicable self default attached to its definition, if any.
- Otherwise: its applicable implicit default.

###### Defaults for Absent Expressions

An absent constant expression's value is always its constant value.

An absent variable expression `EXPRESSION`'s value is, in descending precedence:

- `EXPRESSION`'s [inherited value](#inherited-comments), if any.
- `DEFAULT` from the furthest ancestor from `EXPRESSION` that has an applicable
  descendant default comment whose `DESCENDANT` is `EXPRESSION`.
  - Ancestors further from `EXPRESSION` take precedence because they have more
    context: `NONTERMINAL` knows the defaults appropriate for each of its
    descendants, so overrides them if necessary.
  - `NONTERMINAL`'s descendants that have the same type may be assigned
    different defaults by attaching different default comments along
    `DEFINITION`'s divergent branches.
- `EXPRESSION`'s global default.
