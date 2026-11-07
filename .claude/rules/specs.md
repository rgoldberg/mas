---
paths:
  - Specs/**
---

# Spec Grammar

In specs, design each change for what is best for users, never merely as the
smallest change that fits the existing spec (e.g., give transposed syntax, i.e.,
the same tokens in another order, consistent semantics).

In specs, terminate every single-letter option's / setting's payload with `:`.

In specs, give each expression's constant syntax (e.g., a prefix) its own
constant nonterminal, named for that expression (e.g.,
`field-order-tiebreaker-prefix`), rather than reusing another expression's, even
if their values are equal.

In specs, annotate an outer bare whitespace treatment on the expression whose
tokens need it (e.g., `-[ <format-block> ]-`), rather than on adjacent
expressions' constant nonterminals (e.g., not `-"/"` for a following `/`),
except on a terminator that terminates every expression that needs it, which
would otherwise need many annotations (e.g., `block-terminator = -"+"`).

In `Specs/shell.md`, define each option that takes a value as a
`<valued-option>` (e.g.,
`fields-option = <valued-option("--fields", <fields-config>)>`), whose
command-line argument boundary (`_`) models Swift Argument Parser's split of an
option from its value as the next command-line argument, so that the grammar
specifies each option's whole command-line syntax, including whether its value
may be empty (e.g., `[ <json-config> ]`).

In specs, never define a nonterminal as a single optional (e.g., `x = [ <y> ]`);
make its references optional instead, because an expression that consumes no
token is never present.

In specs, make every block reference optional, except one that is:

1. A block's entire definition (e.g., `failure-block = <unconditional-block>`),
   which a single optional cannot define.
2. An argument (e.g., `<conditional-block>` in
   `<format-name(<conditional-block>)>`), whose parameterized nonterminal's
   definition makes it optional wherever it consumes text.
3. One whose absence a sibling alternative, with a default for it, expresses
   instead (e.g., `<conditional-block>` in `<non-nullary-success>`, whose
   absence `<non-nullary-scalar-blockless-success>` expresses), so that a
   grammar can require at least 1 of multiple blocks (e.g., to forbid `%S++`).

In specs, give every block not marked `(* non-structural *)` a direct default of
`{empty string}`, because no syntax references a non-structural block, so none
can omit it.

In specs, define nonterminals whose definitions differ only in the expressions
that they reference as 1 [parameterized
nonterminal](../../Specs/ebnf.md#parameterized-nonterminals) (e.g.,
`transform-call(CALL_PREFIX, TRANSFORM)`), rather than repeating the definition,
when that definition is long enough for its copies to drift (e.g.,
`<transform-call>`'s error comment), because the shared definition states the
shared syntax & semantic comments once; repeat a short sequence or choice only
if each use has a name of its own that documents it (e.g., `<field-spec-move>`
or `<style-prefix-setting>`), because a parameter would hide it for no gain.

In specs, write a literal that selects 1 of a set of names, rather than
structuring the syntax (e.g., a transform name, `unix-time`, a config name, or
`@unsuffixed`), as a [name literal](../../Specs/ebnf.md#name-literals) (e.g.,
`'round'`), and write each other literal (e.g., a prefix, a terminator, a
predicate letter, or an option name) as a literal (e.g., `"%"`), because how a
name is written cannot affect what it selects, while an escaped structural
character means something else, and Swift Argument Parser does not evaluate an
option name's escape sequences.

In specs, give an empty-string default for a block or a typed terminal as
`{empty string}` (a free-form description), never as the literal `""`, which
neither a block nor a variable token can consume.

In specs, when 2 expressions denote the same concept with similarly complex
syntax (e.g., a format's number coercion & a sort's grouped numbers), share 1
syntax; give a much simpler one its own simpler syntax.

In specs, make an argument list's trailing arguments omissible in its grammar,
by making each `<argument-separator>` trailing-omissible (e.g.,
`[ <a> ] <argument-separator>? [ <b> ] <argument-separator>? [ <c> ]`), never
only in prose; reference a shared argument list (e.g.,
`<number-format-arguments>`) rather than repeating its arguments.

In specs, make an argument list's `<argument-fence>`s optional iff every
argument in it is omissible or defaults when the whole list is absent (e.g.,
`..dateOnly`, but not `..::dateOnly`), because the empty list `::` would
otherwise be required to express all defaults.

In specs, give a sort option that takes arguments an uppercase letter &
terminate its arguments with its `<sort-option-terminator>`; an empty list
argument means none, while an empty scalar argument means its default.

In specs, attach `(* inherited *)` to the definition of each nonterminal whose
transitively absent occurrences retain the value of the same setting in the
config onto which the syntax text is overlaid (e.g., `<label>`), rather than
listing such nonterminals in prose.

In specs, attach `(* last wins *)` to the definition of each nonterminal whose
later occurrences override its earlier ones (e.g., `<direction>`), never to a
nonterminal that repeats it (e.g., `<sort-option-set>`).

In specs, give a default as a specific value for the nonterminal it defaults
(e.g., `(* transitive default chronologic-formats: 'iso' *)`), using descendant
and/or transitive defaults as needed, rather than as syntax that must be parsed
(e.g., `(* default: "Lcanonical:" *)`), giving a chosen alternative as a
reference to it (e.g., `(* default: <ascending> *)`), unless only syntax can
express it (e.g., `(* default: "B+space+:" *)`, which both chooses an
alternative & sets its payload).

In specs, prefix each placeholder letter's nonterminal & each compound selected
by letter case with `nullary-` (lowercase: no success clause or block follows)
or `non-nullary-` (uppercase: a success clause or 1 or more blocks follow),
except name a letter that other syntax follows in its lowercase form too (e.g.,
`m`'s `<branches>`) by its arity (e.g., `<unary-match>` & `<binary-match>`).

In specs, write each example of a `<field-spec-edit>` with its
`<field-spec-edits-section-prefix>` (e.g., `.-a,a=X`, not `-a,a=X`), and show
each example of a `<field-spec-reference>` inside such an edit (e.g., "`@2` in
`.@2`", not "`@2`"), because without it, the example is an `<absolute-config>`
or a `<relative-config>` that means something else.

In specs, refer to a nonterminal without a preceding `the` (e.g., "`<branch>`'s
value", not "the `<branch>`'s value").

In specs, never write prose that merely restates a definition or a comment,
because a restatement can drift from what it restates; state in prose only what
neither says (e.g., a reason, a consequence, or an example).

In specs, give a nonterminal whose input & output types are equal a single
`type:` comment, rather than both `input type:` & `output type:` comments.

In specs, never restrict a consideration of input or output formats to those
that exist (e.g., by treating a number's leading `+` as unreachable because JSON
input cannot have one), because an app may add others later.

In specs, give each new syntax character only punctuation that no common shell
interprets unquoted, in case a syntax is used from a shell: `%`, `+`, `-`, `.`,
`/`, `:`, `,`, `@`, or `_`, or `=` anywhere but at the start of a word.

In specs other than `Specs/shell.md` & `Specs/mas.md`, never mention a standard
stream, a shell, a command line, or a command-line option (e.g., write normal
output, error output, a transient config, or `H1:`, rather than standard output,
standard error, the command line, or `--table-config H1:`), because a syntax may
be used outside of a command line.

In specs, give an output config setting whose alternatives differ in whether
they take a payload 1 letter: lowercase for the alternative without a payload
(e.g., off, or the default), uppercase for the one with a payload (e.g., `h` /
`H`).

In specs, call an alternative that nothing overrides **effective** (e.g., "an
effective `f`"), rather than describing it as not overridden (e.g., not "an `f`
that no later `<leader-setting>` overrides").

In `Specs/ebnf.md`, retain the **Required** (`&`) outer bare whitespace
treatment, even while no syntax uses it.

In specs, allow syntax unless 1 or more of the following apply, because an error
should report a likely mistake, not harmless verbosity (e.g., allow `%+N%n+`,
`%T..lowercase+-+`, `%Sx+x+`, `005`, or a tab in a `<leader-pattern>`, whose
output shows its effect):

1. **Ambiguous:** the syntax text, or what it parses, cannot be read reliably
   (e.g., `@x/`, or a digit group separator that equals the decimal separator).
2. **Ill-typed:** an expression's or a token's type does not fit what surrounds
   it (e.g., `%S.round+-+`, `%.D..round++`, `%N%s++`, or `P<FF>:`).
3. **Dangling:** it refers to something that does not exist (e.g., a
   `<preset-name>` of no preset, or `@9` in `.@9` for fewer than 9 field specs).
4. **Unsupported in context, whatever it holds:** its context cannot do what it
   asks (e.g., `%S.uppercase+%L..round++`, whose `<failure-block>` can abort,
   `<document-order>` for table output, or an effective `k` in a
   `<field-order-adjustment-set>` that is per `<positional-order-option-set>`).
5. **Redundant, whatever it holds:** a part has no effect, or its output cannot
   depend on anything but its own text (e.g., `%S..uppercase++`, `%+s`, `%S++`,
   `K:`, `%I+`, `%m+`, or `plain`).

In that list, an expression **holds** each name, argument, or block content in
it (e.g., `%+N…+` is not redundant, because it can hold something other than
`%n`, such as `.round`). An absent expression holds nothing. A list holds its
elements, and its own prefix or fences are never redundant, because generated
syntax may hold no elements (e.g., `@x.`, but not `%m+`, whose `%m` is a
predicate, not a prefix). A template is not a list, because it mixes text &
placeholders.

That list judges occurrences of expressions & spellings that a spec defines, so
it adds neither; add an expression only for output that existing syntax cannot
give (e.g., not `%S%.N.round+-+++`, because `%M-S+.N.round++-+` gives its
output).

Forbid syntax in the grammar when the syntax text alone decides it & the grammar
would need no separate syntax per case; otherwise, attach an error comment.
