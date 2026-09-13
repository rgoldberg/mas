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

### Text Classification

#### Text Character Composition

- Text described as bare contains only bare characters.
- Text described as escaped contains at least one escaped character.
- Text not described as bare or escaped may contain any mixture of bare &
  escaped characters.

The underlying grammar may assign different semantics to bare text & escaped
text.

#### Text Function

##### Literal Text

**Literal text** functions as syntactic operands (i.e., data). Literal text may
consist of bare and/or escaped characters.

##### Syntax Text

**Syntax text** functions as syntactic operators. Syntax text consists strictly
of bare characters.

Escaping any character within a token that (taken in its entirety) would
otherwise be syntax text renders that token literal text.

The context of bare text may influence whether it is syntax text or literal
text.

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

`DESCRIPTION` must not begin with `{`.

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

Defined via a modified meta-grammar supporting [optionals](#optionals):

```ebnf
<PLACEHOLDER[\INITIAL][\\ANYWHERE][\\\ENTIRE]>
```

Content-dependent multiplicity.

`INITIAL`, `ANYWHERE` & `ENTIRE` restrict values for `PLACEHOLDER` as
[specified for Escaping Text Placeholders](#escaping-text-placeholders), except
`\}` is not supported as an escape sequence; the only supported escape sequence
is `\>`, which evaluates to `>`.

`PLACEHOLDER` must not contain any escape sequences or an unescaped `\`;
consecutive `\` exclusively separate `PLACEHOLDER`, `INITIAL`, `ANYWHERE` &
`ENTIRE`.

### Token Sets

A **token set** is a set of literal tokens.

#### Token Set Productions

```ebnf
[:NAME:] = EXPRESSION
```

Context-dependent multiplicity.

#### Token Set References

```ebnf
[:NAME:]
```

Context-dependent multiplicity.

References a token set `NAME`.

`NAME` is a bare token that must not contain `:]`.

#### Placeholder Token Sets

```ebnf
[:<PLACEHOLDER>:]
```

Context-dependent multiplicity.

A token set containing the tokens permissible as values for placeholder
`PLACEHOLDER`.

### Escaping Text Placeholders

Defined via a modified meta-grammar supporting [optionals](#optionals):

```ebnf
{text[\INITIAL][\\ANYWHERE][\\\ENTIRE]}
```

Inherent scalar.

Non-empty text that supports [escaped characters](#escaped-characters).

`INITIAL`, `ANYWHERE` & `ENTIRE` specify bare tokens that are interpreted as
syntax text.

`INITIAL`, `ANYWHERE` & `ENTIRE`:

- Must not be empty.
- Must not contain any `\` except as a member of `\}`.

Tokens in `INITIAL`, `ANYWHERE` & `ENTIRE` are specified via:

- `[:NAME:]` includes all tokens from token set `NAME`. Each `[:` must pair with
  a `:]`.
- `\}` includes `}`.
- Any other character includes itself.

If the entire bare text matches a token in `ENTIRE`, the entire text is a syntax
token.

Otherwise, syntax tokens are found by iterating over characters from start to
end:

- On each iteration, the longest bare token starting at the current character
  that matches any of the following tokens, if any, is a syntax token:
  - Any token in `ANYWHERE`.
  - If the current character is the first character: any token in `INITIAL`.
- If the current character, or the last character of any found syntax token, is
  the last character, the iteration terminates.
- Otherwise, the iteration continues with the current character set to:
  - If a syntax token was found: the character after the syntax token.
  - Otherwise: the character after the current character.

#### Examples

```ebnf
{text\@.\\=:/,}
```

- `\` must always be escaped, as it must be in any `{text...}`.
- `@` & `.` must be escaped if first (from `INITIAL`).
- `=`, `:`, `/` & `,` must be escaped throughout (from `ANYWHERE`).

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

Defined via the custom EBNF grammar, instead of via the meta-grammar:

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
