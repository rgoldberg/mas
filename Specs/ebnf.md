# Custom EBNF Grammar

## Meta-Grammar

Within the definition of this custom EBNF grammar:

- All text is case-sensitive.
- A word of uppercase letters, digits & `_` is a **metavariable** for an
  expression or text.
- Whitespace separating tokens in the grammar is insignificant.
- All other characters are used verbatim.

## Grammar

When using this custom EBNF grammar to define a syntax:

- All text is case-sensitive.
- [Whitespace significance](#character-significance) varies by expression.

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

### Ad Hoc Text

**Ad hoc text** is data rather than syntax.

### Multiplicity

A value's multiplicity is either:

- **Scalar**: a single value (e.g., an integer, a string, etc.).
- **Repetition**: a sequence of 0 or more elements. Empty or single-element
  repetitions remain repetitions, not scalars.

An expression's multiplicity is either:

- **Inherently scalar**: Each occurrence of an **inherent scalar** expression is
  a scalar.
- **Inherently repetition**: Each occurrence of an **inherent repetition**
  expression is a repetition.
- **Content-dependent**: The multiplicity of an occurrence of the expression is
  the same as its content.
- **Context-dependent**: The multiplicity of an occurrence of the expression is
  whatever is required by its context.

Convenience multiplicity kinds for values include:

- **Implicit scalars**: Scalars whose expression is not an inherent scalar.
- **Implicit repetitions**: Repetitions whose expression is not an inherent
  repetition.

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

**Constant tokens** (e.g., syntax tokens) are consumed by constant expressions.

**Variable tokens** (e.g., text tokens) are consumed by variable expressions.

#### Candidate Syntax Literals

The **candidate syntax literals** of a given position in the input are the
literals that the syntax may consume at that position (regardless of the input
beginning at that position), which includes the literals that:

- Begin any choice available at that position.
- Continue any enclosing sequence or repetition.
- Close any enclosing expression.

#### Consuming Tokens

Input is consumed as a token iff a syntax token or a text token, as specified
below, matches the input beginning at the current position.

Consuming a token commits to the set of expressions that the token begins,
continues, or closes; each subsequently consumed token narrows the set to the
expressions that accept it.

A complete expression is **parsed** once it is the sole element in its set;
disjoint choices guarantee that at most 1 expression per set is parsed.

If a set ever becomes empty, or if the input is exhausted before each set's
expression is parsed, an error is reported.

Input is never reconsidered after it has been consumed.

##### Consuming Syntax Tokens

Input is consumed as a syntax token iff a candidate syntax literal matches the
input beginning at the current position; if multiple match, the longest is
consumed.

##### Consuming Text Tokens

Input is consumed as a text token iff a text token is available at the current
position & no candidate syntax literal matches the input there.

A text token's **candidate text terminators** are the candidate syntax literals
of the position immediately following it.

A text token is the longest non-empty prefix beginning at the current position
that does not contain any candidate text terminator; it finishes immediately
before the earliest such terminator, less any insignificant outer bare
whitespace; the terminator is then consumed as a syntax token.

### Character Significance

A **significant** character affects the parse or a value.

An **insignificant** character affects neither.

All characters besides outer bare whitespace are always significant, which
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

Outer bare whitespace is significant iff consumed.

A candidate syntax literal is matched before outer bare whitespace is processed,
consuming any bare whitespace that matches its literal.

Unless otherwise specified, expressions do not consume outer bare whitespace.

#### Outer Bare Whitespace Treatment

Defined via a modified meta-grammar supporting [optionals](#optionals) &
[choices](#choices):

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
[ [ "~" ] ( "!" | "-" | "^" | "&" ) ] EXPRESSION [ ( "!" | "-" | "^" | "&" ) [ "~" ] ] (* default: "~-" EXPRESSION "-~" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Punctuation attaches directly (i.e., with no intervening whitespace) to
`EXPRESSION`, distinguishing a suffix for 1 expression from a prefix for the
subsequent expression.

Each side is independent.

Each side of an expression treats adjacent outer bare whitespace as one of:

- `!` **Forbidden**: iff present, an error is reported.
- `-` **Insignificant**: not consumed.
- `^` **Significant**: consumed.
- `&` **Required**: iff absent, an error is reported; otherwise, not consumed.

`~` **defers**, allowing the side's outer bare whitespace treatment to be
overridden.

The input's start & end are deferring insignificant sides.

Outer bare whitespace is treated as per its 2 adjacent sides: the preceding
token's end & the following token's start, the following token being the one
that would begin after the whitespace if it were skipped (or at the whitespace,
iff a text token begins there). Of those 2 sides:

- If both defer: the higher-precedence treatment applies, in descending
  precedence:
  - Required
  - Significant
  - Insignificant
  - Forbidden
- Otherwise: the non-deferring side's treatment applies. A syntax must ensure
  that no 2 potentially adjacent non-deferring sides differ.

Consumed outer bare whitespace is included in the adjacent variable token's
value, if any; otherwise, it is not retained.

A syntax must ensure that no 2 consuming variable tokens are adjacent.

An unannotated side of a compound treats outer bare whitespace as does the same
side of its 1st (for the left side) or last (for the right side) enclosed
expression. An annotated side of a compound applies its treatment to the same
side of that enclosed expression, transitively down to the token on that side,
overriding any annotation within; i.e., the outermost annotation overrides.

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

`DESCRIPTION` describes valid literal scalars, e.g., `{non-negative integer}`.

`DESCRIPTION` must not begin with `{` & must not be `text`.

#### Repetition Descriptions

```ebnf
{{DESCRIPTION}}
```

Inherent repetition.

`DESCRIPTION` describes valid literal elements for a repetition, e.g.,
`{{non-negative integer}}`.

#### Text Terminals

```ebnf
{text}
```

Inherent scalar.

A [text token](#tokens), which supports [escape sequences](#escaping).

### Nonterminals

#### Nonterminal Definitions

```ebnf
NONTERMINAL = DEFINITION
```

Content-dependent multiplicity.

Binds a nonterminal to its definition.

A nonterminal's default value, when absent, is its
[implicit or explicit default](#explicit--implicit-defaults).

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

### Choices

```ebnf
A | B
```

Content-dependent multiplicity.

`A` or `B`. `A` & `B` must match disjoint sets of text.

### Optionals

```ebnf
[ EXPRESSION ]
```

Content-dependent multiplicity.

0 or 1 occurrence of `EXPRESSION`.

#### Optionality States

An expression has 3 mutually exclusive possible optionality states:

- **Required**: Neither the expression nor any of its ancestors are optional.
- **Directly optional**: The expression is, or is a child of, an optional.
- **Transitively optional**: Neither the expression nor its parent are an
  optional, but one of its other ancestors is an optional.

An expression is **optional** if it is either directly optional or transitively
optional.

#### Presence States

An optional expression has 3 mutually exclusive possible presence states:

- **Present**: A token is present.
- **Directly absent**: All the expression's ancestors are present, but the
  expression is itself absent.
- **Transitively absent**: At least one of the expression's ancestors is absent.

An optional expression is **absent** if it is either directly or transitively
absent.

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

A repetition containing 0 elements; matches no input. Distinct from `null` &
from the empty string (`""`).

### Repetitions with Separators (1 or More)

```ebnf
ELEMENT … SEPARATOR
```

Inherent repetition.

e.g.:

- `( "a" | "b" | "c" ) … ","` matches:
  - `b`
  - `c,a,c,b,a,c,b`
- `( "2" | "1" | "3" ) … ( " " | "/" )` matches:
  - `3`
  - `1 3/1/2 2/3`

Neither `ELEMENT` nor `SEPARATOR` may match empty text.

### Precedence

From highest to lowest precedence within a grouping:

- Repetition (`+`)
- Repetition with separator (`…`)
- Sequence (juxtaposition)
- Choice (`|`)

### Comments

```ebnf
(* COMMENT *)
```

No multiplicity.

#### Semantic Comments

Semantic comments follow specific formats to concisely attach semantic
information to expressions. They are not formally part of the custom EBNF
grammar; they are an adjunct custom grammar.

A comment may hold multiple `;`-separated parts; each part that matches a
semantic comment format is a semantic comment; any other part is ordinary
commentary.

##### Default Value Comments

Default value comments specify explicit defaults applicable to optional
nonterminals.

###### Self Default Value Comments

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

Only 1 self default value comment may be attached to `NONTERMINAL`'s definition,
unless there are exactly 2, one of which is for `"direct"`, the other of which
is for `"transitive"`.

###### Descendant Default Value Comments

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

- One of `NONTERMINAL`'s descendants.
- If `"direct"` is present: directly absent.
- If `"transitive"` is present: transitively absent.
- Otherwise: absent.

Only 1 descendant default value comment for `DESCENDANT` may be attached to
`NONTERMINAL`'s definition, unless there are exactly 2, one of which is for
`"direct"`, the other of which is for `"transitive"`.

##### Applicability Comments

```ebnf
NONTERMINAL = DEFINITION (* only for: CONTEXT *)
```

`NONTERMINAL` is valid only in the context that `CONTEXT` describes; elsewhere,
an error is reported.

##### Non-Structural Comments

```ebnf
NONTERMINAL = DEFINITION (* non-structural *)
```

Marks a nonterminal that is referenced by comments and/or prose, but not by any
definitions.

##### Last-Wins Comments

Defined via a modified meta-grammar supporting [choices](#choices):

```ebnf
NONTERMINAL = A | B (* last wins *)
```

Where `NONTERMINAL` is a valid element of any repetition, the last occurrence of
any of the choice's alternatives overrides all preceding occurrences of any of
the choice's alternatives.

##### Default Resolution

###### Explicit & Implicit Defaults

- An **explicit default** is specified by any variant of a default value
  comment.
- An **implicit default** is the value applied when no explicit default value
  applies to an expression.
  - The implicit default for scalars is `null`.
  - The implicit default for repetitions is:
    - If transitively absent: `null`.
    - If directly absent: `empty`.

###### Global Defaults

An expression's **global default** for a given presence state is:

- The applicable self default attached to its definition, if any.
- Otherwise: its applicable implicit default.

###### Defaults for Absent Expressions

An absent expression `EXPRESSION`'s value is, in descending precedence:

- `DEFAULT` from the furthest ancestor from `EXPRESSION` that has an applicable
  descendant default value comment whose `DESCENDANT` is `EXPRESSION`.
  - Ancestors further from `EXPRESSION` take precedence because they have more
    context: `NONTERMINAL` knows the defaults appropriate for each of its
    descendants, so overrides them if necessary.
  - `NONTERMINAL`'s descendants that have the same type may be assigned
    different defaults by attaching different default value comments along
    `DEFINITION`'s divergent branches.
- `EXPRESSION`'s global default.
