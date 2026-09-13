# Custom EBNF Grammar

## Meta-Grammar

Within the definition of this custom EBNF grammar:

- All text is case-sensitive.
- Uppercase words represent placeholders for symbols, text, or production rules.
- Whitespace separating tokens in the grammar is insignificant.
- All other characters are used verbatim.

## Grammar

When using this custom EBNF grammar to define a syntax:

- All text is case-sensitive.
- Whitespace separating tokens defined by this grammar is insignificant.
- Whitespace within tokens remains significant.
- Syntaxes defined by this grammar may have their own whitespace rules.

### Multiplicity

A value's multiplicity is either:

- **Scalar**: a single value (e.g., an integer, a string, etc.).
- **Repetition**: a sequence of 0 or more elements. Empty or single-element
  repetitions remain repetitions, not scalars.

A construct's multiplicity is either:

- **Inherently scalar**: Every occurrence of an **inherent scalar** construct
  is a scalar.
- **Inherently repetition**: Every occurrence of an **inherent repetition**
  construct is a repetition.
- **Content-dependent**: The multiplicity of an occurrence of the construct is
  the same as its content.
- **Context-dependent**: The multiplicity of an occurrence of the construct is
  whatever is required by its context.

Convenience multiplicity categories for values include:

- **Implicit scalars**: Scalars whose construct is not an inherent scalar.
- **Implicit repetitions**: Repetitions whose construct is not an inherent
  repetition.

### Null

```ebnf
null
```

Context-dependent multiplicity.

The absence of a value.

### Bare Characters

```ebnf
BARE
```

Inherent scalar.

`BARE` is any character other than `\`.

`BARE` evaluates to `BARE`.

### Escaped Characters

```ebnf
\ESCAPED
```

Inherent scalar.

`ESCAPED` is any character.

`\ESCAPED` evaluates to `ESCAPED` (e.g., `\n` evaluates to `n`).

### Ad Hoc Text

**Ad hoc text** functions as data rather than as syntax.

### Tokens

**Tokens** are contiguous characters that are consumed together as a single
element by the syntax.

**Bare tokens** contain only bare characters.

**Text tokens** are ad hoc text.

**Syntax tokens** are bare tokens matching defined syntax literals; escaping
any character within a token that would otherwise be a syntax token renders it a
text token.

#### Candidate Syntax Literals

The **candidate syntax literals** of a given position in the input are the
literals that the syntax could consume at that position (regardless of the input
starting at that position), which includes the literals that:

- Begin any choice available at that position.
- Continue any enclosing sequence or repetition.
- Close any enclosing construct.

#### Consuming Tokens

Input is consumed as a token iff a syntax token or a text token, as specified
below, matches the input starting at the current position.

Consuming a token commits to the set of constructs that the token begins,
continues, or closes; each subsequently consumed token narrows the set to the
constructs that accept it.

A complete construct is **parsed** once it is the sole element in its set;
disjoint choices guarantee that at most 1 construct per set is parsed.

If a set ever becomes empty, or if the input is exhausted before each set's
construct is parsed, an error is reported.

Input is never reconsidered after it has been consumed.

##### Consuming Syntax Tokens

Input is consumed as a syntax token iff a candidate syntax literal matches the
input starting at the current position; if several match, the longest is
consumed.

##### Consuming Text Tokens

Input is consumed as a text token iff a text token is available at the current
position & no candidate syntax literal matches the input there.

A text token's **candidate text terminators** are the candidate syntax literals
of the position immediately following it.

A text token is the longest non-empty prefix starting at the current position
that does not contain any candidate text terminator; it terminates immediately
before the earliest such terminator, which is then consumed as a syntax token.

### Literal Text

```ebnf
"TEXT"
```

Inherent scalar.

`""` is the escape sequence for an escaped `"` in `TEXT`.

### Scalar Descriptions

```ebnf
{DESCRIPTION}
```

Inherent scalar.

`DESCRIPTION` describes valid literal scalars, e.g., `{non-negative integer}`.

`DESCRIPTION` must not begin with `{` & must not be `text`.

### Repetition Descriptions

```ebnf
{{DESCRIPTION}}
```

Inherent repetition.

`DESCRIPTION` describes valid literal elements for a repetition, e.g.,
`{{non-negative integer}}`.

### Value Placeholders (Non-Terminal Symbols)

#### Value Placeholder Definitions

```ebnf
PLACEHOLDER = DEFINITION
```

Content-dependent multiplicity.

Binds a placeholder symbol to its definition.

A placeholder's default value, when absent, is its
[implicit or explicit default](#explicit--implicit-defaults).

#### Value Placeholder References

```ebnf
<PLACEHOLDER>
```

Content-dependent multiplicity.

References the placeholder `PLACEHOLDER`.

### Text Placeholders

```ebnf
{text}
```

Inherent scalar.

A [text token](#tokens), which supports
[escaped characters](#escaped-characters).

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
- **Directly absent**: All ancestors of the expression are present, but the
  expression is itself absent.
- **Transitively absent**: At least one ancestor of the expression is absent.

An optional expression is **absent** if it is either directly absent or
transitively absent.

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

A repetition containing zero elements. Distinct from `null` & from the empty
string (`""`).

### Delimited Repetitions (1 or More)

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
- Delimited repetition (`…`)
- Sequence (juxtaposition)
- Choice (`|`)

### Comments

```ebnf
(* COMMENT *)
```

No multiplicity.

#### Semantic Comments

Semantic comments follow specific formats to concisely attach semantic
information to syntax constructs. They are not formally part of the custom EBNF
grammar; they are an adjunct custom grammar.

##### Default Value Comments

Default value comments specify explicit defaults applicable to optional
placeholders.

###### Self Default Value Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literal text](#literal-text):

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
PLACEHOLDER "=" DEFINITION "(*" [ "direct" | "transitive" ] "default:" DEFAULT "*)"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`DEFAULT` is a default applicable for a `PLACEHOLDER` that is:

- If `"direct"` is present: directly absent.
- If `"transitive"` is present: transitively absent.
- Otherwise: absent.

Only 1 self default value comment may be attached to `PLACEHOLDER`'s definition,
unless there are exactly 2, one of which is for `"direct"`, the other of which
is for `"transitive"`.

###### Descendant Default Value Comments

Defined via a modified meta-grammar supporting [optionals](#optionals),
[choices](#choices) & [literal text](#literal-text):

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
PLACEHOLDER "=" DEFINITION "(*" [ "direct" | "transitive" ] "default" DESCENDANT ":" DEFAULT "*)"
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`DEFAULT` is a default applicable for a `DESCENDANT` that is a descendant of a
`PLACEHOLDER` that is:

- If `"direct"` is present: directly absent.
- If `"transitive"` is present: transitively absent.
- Otherwise: absent.

Only 1 descendant default value comment for `DESCENDANT` may be attached to
`PLACEHOLDER`'s definition, unless there are exactly 2, one of which is for
`"direct"`, the other of which is for `"transitive"`.

###### Explicit & Implicit Defaults

- An **explicit default** is specified by any variant of a default value
  comment.
- An **implicit default** is the value applied when no explicit default value
  applies to a token.
  - The implicit default for scalars is `null`.
  - The implicit default for repetitions is:
    - If transitively absent: `null`.
    - If directly absent: `empty`.

###### Global Defaults

A token's **global default** for a given presence state is:

- The applicable self default attached to its definition, if any.
- Otherwise: its applicable implicit default.

###### Defaults for Absent Tokens

An absent `TOKEN` token's value is, in descending precedence:

- `DEFAULT` from the furthest ancestor from `TOKEN` that has an applicable
  descendant default value comment whose `DESCENDANT` is `TOKEN`.
  - Ancestors further from `TOKEN` take precedence because they have more
    context: `PLACEHOLDER` knows the defaults appropriate for each of its
    descendants, so overrides them if necessary.
  - Descendants of `PLACEHOLDER` that have the same type may be assigned
    different defaults by attaching different default value comments along
    divergent branches of `DEFINITION`.
- `TOKEN`'s global default.
