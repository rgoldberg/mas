---
paths:
  - Specs/**
---

# Spec Grammar

In specs, terminate every single-letter option's / setting's payload with `:`.

In specs, give each construct's constant syntax (e.g., a prefix) its own
constant nonterminal, named for that construct (e.g.,
`field-order-tiebreaker-prefix`), rather than reusing another construct's, even
if their values are equal.

In specs, annotate an outer bare whitespace treatment on the expression whose
tokens need it (e.g., `-[ <format-block> ]-`), rather than on its neighbors'
constant nonterminals (e.g., not `-"/"` for a following `/`), except on a
terminator that terminates every expression that needs it, which would otherwise
need many annotations (e.g., `block-terminator = -"+"`).

In specs, define an option's syntax over its option value alone (e.g.,
`<fields-config>`), never over its name or its option value separator, because
Swift Argument Parser splits each option from its value (after `=` or as the
next command-line argument), which whitespace treatments cannot model.

In specs, never define a nonterminal as a single optional (e.g., `x = [ <y> ]`);
make its references optional instead, since an expression that consumes no token
is never present.

In specs, make every block reference optional & give every block a direct
default of `{empty string}`.

In specs, give an empty-string default for a block or a text terminal as
`{empty string}` (a value), never as the literal text `""`, which neither a
block nor a text token can consume.

In specs, when 2 constructs express the same concept with similarly complex
syntax (e.g., a format's number coercion & a sort's grouped numbers), share 1
syntax; give a much simpler one its own simpler syntax.

In specs, make an argument list's trailing arguments omissible in its grammar,
by making each `<argument-separator>` trailing-omissible (e.g.,
`[ <a> ] <argument-separator>? [ <b> ] <argument-separator>? [ <c> ]`), never
only in prose; reference a shared argument list (e.g.,
`<number-format-arguments>`) rather than repeating its arguments.

In specs, make an argument list's `<argument-fence>`s optional iff every
argument in it is omissible, because the empty list `::` would otherwise be
required to express all defaults.

In specs, give a sort option that takes arguments an uppercase letter & end its
arguments with its `<sort-option-terminator>`; an empty list argument means
none, while an empty scalar argument means its default.

In specs, attach `(* last wins *)` to the definition of each nonterminal whose
later occurrences override its earlier ones (e.g., `<direction>`), never to a
nonterminal that repeats it (e.g., `<sort-option-set>`).

In specs, give a default as a specific value for the nonterminal it defaults
(e.g., `(* transitive default locale-identifier: "canonical" *)`), using
descendant and/or transitive defaults as needed, rather than as syntax that must
be parsed (e.g., `(* default: "Lcanonical:" *)`), unless only syntax can express
it (e.g., choosing an alternative of a choice).

In specs, prefix each placeholder letter's nonterminal & each compound selected
by letter case with `nullary-` (lowercase: no block follows) or `non-nullary-`
(uppercase: 1 or more blocks follow), except name a letter that other syntax
follows in its lowercase form too (e.g., `m`'s `<branches>`) by its arity (e.g.,
`<unary-match>` & `<binary-match>`).

In specs, refer to a nonterminal without a preceding `the` (e.g., "`<branch>`'s
value", not "the `<branch>`'s value").

In specs, give a nonterminal whose input & output types are equal a single
`type:` comment, rather than both `input type:` & `output type:` comments.

In specs, give each new syntax character only punctuation that no common shell
interprets unquoted: `%`, `+`, `-`, `.`, `/`, `:`, `,`, `@`, or `_`, or `=`
anywhere but at the start of a word.

In specs, give an output config setting whose alternatives differ in whether
they take a payload 1 letter: lowercase for the alternative without a payload
(e.g., off, or the default), uppercase for the one with a payload (e.g., `h` /
`H`).

In `Specs/ebnf.md`, keep the **Required** (`&`) outer bare whitespace treatment,
even while no syntax uses it.
