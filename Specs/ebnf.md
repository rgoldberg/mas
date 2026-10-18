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
character, the **escaped character**; an escape prefix at the end of the input
is an error.

An escape sequence evaluates to its escaped character (e.g., `\n` evaluates to
`n`).

A **bare character** is any character that is not part of an escape sequence.

A syntax may treat the same character differently when bare or escaped, despite
both evaluating to that same character.

### Whitespace

**Whitespace** is any Unicode `White_Space` character: Unicode general category
`Z` characters, `U+0009` to `U+000D` & `U+0085`.

### Ad Hoc Text

**Ad hoc text** is data rather than syntax.

### Multiplicity

A value's multiplicity is one of:

- **Scalar**: a single value (e.g., an integer, a string, etc.).
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
possible occurrences, determined from the grammar instead of the input:

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

A **variable expression** consumes variable text (e.g., a text terminal).

### Compounds Vs. Terminals

A **compound** is an expression that contains other expressions.

A **terminal** is an expression that does not contain other expressions.

### Tokens

**Tokens** are contiguous characters that are consumed together as a single
element by the syntax.

**Bare tokens** contain only bare characters.

**Text tokens** are ad hoc text.

**Syntax tokens** are bare tokens matching [literal text](#literal-text);
escaping any character within a token that would otherwise be a syntax token
renders it a text token.

**Scalar tokens** are bare tokens consumed by [scalar
descriptions](#scalar-descriptions).

**Constant tokens** (e.g., syntax tokens) are consumed by constant expressions.

**Variable tokens** (e.g., text tokens) are consumed by variable expressions.

#### Candidate Syntax Literals

The **candidate syntax literals** of a given position in the input are the
literals that the syntax can consume at that position (regardless of the input
starting at that position), which includes the literals that:

- Start any choice available at that position.
- Continue any enclosing sequence or repetition.
- Close any enclosing expression.

#### Consuming Tokens

Input is consumed as a token iff a syntax token, a scalar token, or a text
token, as specified below, matches the input starting at the current position.

Consuming a token commits to the set of expressions that the token starts,
continues, or closes; each subsequently consumed token narrows the set to the
expressions that consume it.

A complete expression is **parsed** once it is the sole element in its set;
disjoint choices guarantee that at most 1 expression per set is parsed.

If a set ever becomes empty, or if the input is exhausted before every set's
expression is parsed, an error is reported.

Input is never reconsidered after it has been consumed.

##### Consuming Syntax Tokens

Input is consumed as a syntax token iff a candidate syntax literal matches the
input starting at the current position; if multiple match, the longest is
consumed.

##### Consuming Scalar Tokens

Input is consumed as a scalar token iff a scalar description is available at the
current position & the input starting there matches its lexical form; the
longest match is consumed (i.e., maximal munch), then, iff its value is not a
valid literal scalar of the scalar description (e.g., it is out of range), an
error is reported.

A syntax must ensure that no candidate syntax literal of a position at which a
scalar description is available matches the start of the scalar description's
lexical form there.

##### Consuming Text Tokens

Input is consumed as a text token iff a text token is available at the current
position & no candidate syntax literal matches the input there.

A text token's **candidate text terminators** are the candidate syntax literals
of the position immediately following it.

A text token is the longest non-empty prefix starting at the current position
that does not contain any candidate text terminator; it terminates immediately
before the 1st such terminator, less any ignored outer bare whitespace; the
terminator is then consumed as a syntax token.

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

- Character consumed by a constant token.
- Non-bare-whitespace character consumed by a variable token.

A candidate syntax literal is matched before outer bare whitespace is processed,
consuming any bare whitespace that matches its literal.

Unless otherwise specified, expressions do not consume outer bare whitespace.

#### Outer Bare Whitespace Treatment

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literal text](#literal-text):

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

The input's start & end are treated as deferring sides that ignore outer bare
whitespace.

Outer bare whitespace is treated as per its 2 adjacent sides: the preceding
token's end & the following token's start, the following token being the one
that would start after the whitespace if it were ignored (or at the whitespace,
iff a text token starts there). Of those 2 sides:

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

The absence of a value; matches no input.

#### End

```ebnf
end
```

Inherent scalar.

A constant expression that matches no input, only at the end of the input.

#### Literal Text

```ebnf
"TEXT"
```

Inherent scalar.

`""` is the escape sequence for an escaped `"` in `TEXT`.

#### Scalar Descriptions

```ebnf
{DESCRIPTION}
```

Inherent scalar.

`DESCRIPTION` describes valid literal scalars (e.g., `{non-negative integer}`) &
their **lexical form**: the text that may denote them, whether valid or not
(e.g., any run of digits for `{integer from 2 to 36}`).

An **integer description** describes integers (e.g., `{integer}`,
`{non-negative integer}`, or `{integer from 2 to 36}`). Its lexical form is 1 or
more ASCII digits (`0` to `9`, leading `0`s allowed), preceded by an optional
sign (`+` or `-`) iff it describes any negative integer. Its value is the
decimal integer that the digits denote, negated iff the sign is `-` (e.g., `-0`
is `0`), constrained by nothing but the description (e.g., `{integer}` has no
minimum or maximum).

`DESCRIPTION` must not:

- Be bare `text`.
- Start with bare `text:`.

#### Text Terminals

```ebnf
{text}
```

Inherent scalar.

A [text token](#tokens) that supports [escape sequences](#escaping).

#### Constrained Text Terminals

```ebnf
{text: CONSTRAINTS}
```

Inherent scalar.

A [text token](#tokens) that supports [escape sequences](#escaping).

`CONSTRAINTS` describes the valid values (or the text that evaluates to them,
e.g., which characters may be bare). An invalid value is an error, unless only
something outside the [app](configs.md#configs) (e.g., a terminal) can determine
its validity, in which case the app passes it through unchecked.

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

- **Present**: A token is present.
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

#### Empty

```ebnf
empty
```

Inherent repetition.

A repetition of 0 elements; matches no input. Distinct from `null` & from an
empty string.

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

`MNEMONIC` explains how `DEFINITION`'s literal text was chosen, iff that choice
is non-obvious (e.g., the text is not the initial of a word in `NONTERMINAL`). A
mnemonic comment is not a semantic comment; in a comment with multiple parts, it
is the last part.

#### Semantic Comments

Semantic comments follow specific formats to concisely attach semantic
information to expressions. They are not formally part of the custom EBNF
grammar; they are an adjunct custom grammar.

A comment may hold multiple `;`-separated parts; each part that matches a
semantic comment format is a semantic comment; any other part is ordinary
commentary.

##### Default Comments

Default comments specify explicit defaults applicable to absent variable
nonterminals; default comments cannot supply default values for constant
nonterminals.

`DEFAULT` is one of:

- `null` or `empty`.
- A [scalar description](#scalar-descriptions) of the value.
- A literal scalar.
- A [nonterminal reference](#nonterminal-references): if it references an
  alternative of the choice to which the default applies, it selects that
  alternative, as if that alternative were present with every descendant
  directly absent; otherwise, it evaluates to the referenced nonterminal's
  global default for the directly absent state.
- [Literal text](#literal-text), consumed by the nonterminal to which the
  default applies.

All defaults must be valid for the applicable nonterminal.

###### Self Default Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literal text](#literal-text):

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
[choices](#choices) & [literal text](#literal-text):

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

##### Applicability Comments

```ebnf
NONTERMINAL = DEFINITION (* only for: CONTEXT *)
```

`NONTERMINAL` is valid only in the context that `CONTEXT` describes; elsewhere,
an error is reported.

##### Type Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literal text](#literal-text):

```ebnf
NONTERMINAL "=" DEFINITION "(*" [ "input" | "output" ] "type:" TYPE "*)"
```

`TYPE` is the type of `NONTERMINAL`'s input (iff `"input"` is present), value
(iff `"output"` is present), or both (otherwise); a syntax defines the types &
their use.

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
occurrences that share its **last-wins scope**: its enclosing occurrence of a
nonterminal whose definition contains a repetition that, transitively, contains
`NONTERMINAL`.

E.g., per [`<direction>`](fields.md#sort-direction)'s last wins, the [field
order](fields.md#field-order) `-P+` is ascending, but in `D-/+`, `+` does not
override `-`, because `<field-order-tiebreaker>` is not within
`<document-order-option-set>`.

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

- `DEFAULT` from the furthest ancestor from `EXPRESSION` that has an applicable
  descendant default comment whose `DESCENDANT` is `EXPRESSION`.
  - Ancestors further from `EXPRESSION` take precedence because they have more
    context: `NONTERMINAL` knows the defaults appropriate for each of its
    descendants, so overrides them if necessary.
  - `NONTERMINAL`'s descendants that have the same type may be assigned
    different defaults by attaching different default comments along
    `DEFINITION`'s divergent branches.
- `EXPRESSION`'s global default.
