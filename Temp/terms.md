# Standard Terminology

Counts in parentheses are whole-word, case-insensitive matches in `Specs/` &
`Temp/todo.md` before replacement, excluding `<!--` marker lines.

1. - start (5): noun
   - begin (9): verb
   - REJECTED: starting (5) → beginning
2. - end (11): noun
   - REJECTED: finish
3. - finish (0): verb
   - REJECTED: end / terminate (1)
4. - character (62)
   - REJECTED: single character (0) / a single X (6) → 1 X
5. - only for (13): restrict scope or target applicability
   - for only (0): restrict numerical quantities or durations
6. - restrict (0): narrow scope, applicability, or permissible values
   - REJECTED: constrain / limit
7. - bare character (31): `x`
   - escape prefix (3): `\`
   - escape sequence (7): `\x`
   - escaped character (2): `x` is the escaped character in the escape sequence
     `\x`
   - REJECTED: not escaped / unescaped
   - REJECTED: unescape
   - REJECTED: escape character
8. - anywhere in (0): match or constraint applicability at any location
   - throughout (1): operation or rule applies pervasively to every individual
     element
   - REJECTED: across (3) → throughout / in
9. - entire (1)
   - its entirety (0)
   - REJECTED: entirety of / whole (6) / whole point (1) → sole purpose
10. - via (7): indirect mechanisms, routes, references, or syntactic pathways
      (e.g., "referenced via index", "reached via rule")
    - by (61): operational agents, methods, or sorting criteria (e.g., "sorted
      by name", "parsed by the engine")
    - with (28): structural attributes, settings, or parameters accompanying an
      item (e.g., "defined with modifiers")
    - through (3): iteration or traversal across a sequence
    - over (4): iteration or traversal across the elements of a sequence
    - REJECTED: across (3)
11. - iteration / iterate (1): sequential processing through linear structures
    - traversal / traverse (0): structural navigation through non-linear
      structures (e.g., trees & graphs)
12. - given (16): explicitly specified input values or parameters from a caller
      or user
    - attached (5): comments or metadata structurally bound to a production rule
      or AST node
    - present (10): concrete occurrence of a token or rule instance in input or
      parse trees
    - exists (15): abstract state of availability or occurrence (e.g., "a field
      config exists")
    - current (14): currently selected or governing state during evaluation
    - REJECTED: supplied / provided / active (0 each) → given / current
13. - inherited (5): from the base fields config
    - existing (1): already in the working fields config
    - previous (8): the immediately preceding one (`$previous$`)
    - REJECTED: prior (0) / predefined (1) → inherited
14. - side (15)
    - REJECTED: end (as synonym for side)
15. - 1st (6)
    - REJECTED: first (7; ok in `<trivia-first>`) / leftmost
16. - sole (1): adjective (the sole element)
    - only (39): adverb / adjective
    - REJECTED: final / last
17. - last (18): positional element located at the end of a sequence or
      collection (pairs with first)
    - REJECTED: rightmost
    - REJECTED: final: irrevocable state, output, or computed outcome of a
      process
    - REJECTED: terminal: EBNF symbol that cannot be expanded further (pairs
      with nonterminal)
18. - precede (11): positional relation in a sequence where one element comes
      before another
    - leading (2): adjective for characters / elements positioned at the start
      of a token or line (e.g., "leading whitespace")
    - before (19)
    - earlier (0): relative ordering by index, time, or priority
    - former (0): 1st of 2 explicitly mentioned items
    - immediately (18): adjacency
19. - succeed (10): positional relation in a sequence where one element comes
      after another (direct antonym of precede)
    - subsequent (5)
    - after (17)
    - trailing (2): adjective for characters / elements positioned at the end of
      a token or line (e.g., "trailing whitespace")
    - later (1): subsequent in execution, evaluation, index, or priority
    - latter (0): second of 2 explicitly mentioned items
    - follow (16): prose sequence ("as follows", "the following", "immediately
      followed by")
    - REJECTED: follow (regarding elements of token repetitions)
    - immediately
20. - must (11): mandatory requirement
    - must not (3): absolute prohibition
    - may (25): permissible action or choice
    - need not (0): lack of obligation (optional exemption)
    - REJECTED: can (7) / could (2) → may
21. - allow (2): generic permission
    - support (5): feature availability ("supports escape sequences", "not
      supported for table output")
    - include (12): membership
    - emit (1): only as the config value name
    - REJECTED: permit / let (1) → allow / honor (3) → apply / follow (rules)
22. - must
    - require (10)
    - REJECTED: need (4) → require
23. - must not (3): rule
    - forbid (4): grammar term (`Forbidden` treatment)
    - cannot (2): inability
    - omit (2): leave out
    - ignore (4): disregard (`<trivia-ignored>`)
    - REJECTED: disallow / prohibit / prevent (1) / not allow / not let / may
      not (1) → must not / exclude / reject / ignored (36, whitespace) →
      insignificant
24. - disable (6)
    - enable (6)
25. - disabled
    - invalid (3)
    - REJECTED: inoperative / unused / unreachable / illegal
26. - position (28): a list position (1, 2, 3, etc.) that an index may reference
    - index (28): references a position
    - indices (3): plural
    - located at position (1)
    - location (3): relative placement without an exact position (e.g.,
      `<nonconforming-location>`: before or after conforming values; distinct
      from `<trivia-order>`, the order in which sort keys are compared)
    - REJECTED: place (1) / indexes (1) → indices
27. - put (2): verb
    - locate (0)
    - position
    - REJECTED: place
28. - is: immutable classification
    - interpret
    - interpreted as: circumstance-dependent classification
    - treat as (9): apply a policy to (ebnf whitespace treatment)
    - REJECTED: considered / processed as / read as (1) / functions as (1) /
      counts as (1) → is / interpreted as
29. - text (79): character sequence in syntax (tokens, `{text}` terminals,
      template text, boundary text)
    - string (84): the data type of a value (string fields, string transforms,
      `<string-block>`, empty strings)
    - token (47): syntactic unit (literal or syntax) formed by text
    - occurrence (10): specific appearance of something
    - value (170): evaluated content bound to a nonterminal or field
    - input (74): raw stream given to a parser or command
    - REJECTED: instance / usage / use / site (1)
    - expression (61)
    - nonterminal (24)
    - terminal (12)
    - compound (4)
    - placeholder (78): only the defined `%…` fields-format term
    - rule (4): only a semantic rule in prose
    - REJECTED: construct / projection / rule (as syntactic element) /
      placeholder (as generic term) / symbol
30. - meta-grammar (5): the notation the custom EBNF grammar is defined in
    - grammar (15): the custom EBNF grammar
    - syntax (22): a specific option's grammar, defined with the custom EBNF
      grammar
    - spec (3): a `Specs/` document
    - REJECTED: language (3) → syntax / specification (1) → spec / rules
31. - null (30): absence of a scalar value
    - empty (22): repetition containing 0 elements, or text containing 0
      characters
    - absent (33): state of being omitted (union of directly absent &
      transitively absent)
    - none (9): specific named value
    - blank (8): null, empty, or whitespace-only (`<nullary-blank-predicate>`);
      a blank line
    - nonexistent (4): guaranteed not to exist in any input (defined in
      fields.md)
    - REJECTED: nil / missing
32. - literal (21): syntactic role functioning as data rather than an operator
    - verbatim (1): exact character-for-character match without processing
      escapes or evaluation
33. - overlay (12): merging specific modifiers or fields onto an existing base
      while retaining unspecified attributes
    - override (6): priority precedence where a higher-level rule supersedes a
      lower-level rule
    - precedence (10): ordering among peers
    - priority (13): `<sort-priority>`
    - wins (11): only in the `(* last wins *)` idiom
    - replace (4): "replace Y with X" = "substitute X for Y"
    - substitute (2): "substitute X for Y" = "replace Y with X"
    - REJECTED: overwrite / supersede / replace Y by X / wins (in prose, 2) →
      overrides
34. - remove (11): general verb
    - prune (0): remove undesirables
    - deduplicate (0): remove duplicates
    - truncate (0): remove beyond a length
    - REJECTED: strip (1) / discard (1) → not retain / cut off (1) → truncate /
      delete / drop
35. - separator (58): syntactic token positioned strictly _between_ elements in
      a sequence to divide them without surrounding them (e.g., commas between
      items, or group separators)
    - terminator (31): syntactic token positioned strictly _after_ an element
    - fence (14): syntactic token surrounding an expression or list element
      (e.g., `<argument-fence>`)
    - boundary (47): sort tokenization term (defined in fields.md)
    - REJECTED: delimiter (3, all in the separator sense) → separator / encloser
      / marker / signifier
36. - evaluate (14): perform the process that returns the value of an expression
    - render (14): produce a value's output text
    - output (85): emit
    - display (14): a command's purpose
    - source from (4): take a config or setting from
    - REJECTED: calculate / decode / resolve (see 60) / obtain (1) → source from
      / get / compute (3) → evaluate / source from / make (4)
37. - evaluation / evaluated
    - REJECTED: interpolation / interpolated
38. - evaluate against (3)
    - REJECTED: receives (1) / evaluate on / evaluate for
39. - neither … nor (5): independent prohibition applied individually to
      multiple items (e.g., "Neither `ELEMENT` nor `SEPARATOR` may match empty
      text")
    - REJECTED: X & Y must not / both … must not (when expressing independent
      prohibitions)
40. - multiple (1)
    - 1 or more (3)
    - REJECTED: two or more / 2 or more / several (3) → multiple / one or more
      (1) → 1 or more
41. - order (76): sequence items, either manually ordered or sorted
    - sort (111): order items by comparing them
    - sequence (10): only the EBNF senses (escape sequence; juxtaposition)
    - REJECTED: ordering / sequence (as synonym for order)
42. - numeric (9): adjective
    - number (82): noun
    - numerically (3): adverb
    - REJECTED: numerical
43. - numbers:
    - spelled: "one" only as pronoun
    - digital: all numeric uses
    - REJECTED: zero (1) → 0 / one (as adjective, 1) → 1
44. - transform (83)
    - call (19): noun & verb, for transforms
    - run (3): noun & verb, for commands
    - REJECTED: function (2; ok in "primary function") / method / execution /
      execute / invocation / invoke
45. - kind (17): config kinds; block kinds; multiplicity kinds
    - type (64): value types
    - variant (7): output format variants
    - form (2): matcher forms
    - REJECTED: category (1) → kind
46. - enclosing (10)
    - contain (10): verb, for membership ("contains other expressions")
    - REJECTED: containing (2) → enclosing
47. - enclosed
    - REJECTED: contained (2) → enclosed / nested (1, ok for JSON) / sub
48. - block (105)
    - REJECTED: scope / subformat
49. - success (39)
    - failure (21)
    - conforming (17)
    - nonconforming (9)
    - coerce (48)
    - REJECTED: convert
50. - every (12): universal, no exception
    - each (35): distributive, per item
    - all (34): collective
    - any (70)
    - some
51. - occur (0)
    - REJECTED: happen
52. - apply to (8)
    - affect (12)
    - REJECTED: operate on / apply for / act on (1) → apply to
53. - built-in (13)
    - REJECTED: hardcoded / predefined (1) → inherited
54. - custom (17)
    - persisted (7): saved
    - REJECTED: user-configurable / user-defined / saved (1) → persisted
55. - because (3)
    - REJECTED: since (2) / due to (1) / as (causal)
56. - as per (4): according to
    - per (20): for each
57. - context (40): looking up named fields configs, formats, etc.; grammatical
      position (`context-dependent` multiplicity, `(* only for: CONTEXT *)`)
    - circumstances (0): situation
    - REJECTED: situation
58. - where (8): static location
    - when (7): runtime condition
59. - retain / retained (4)
    - remain / remaining (2)
    - REJECTED: keep / kept / preserve (1) → retain / maintain (1) → retain
60. - resolve (9): look up a name to its referent (resolved fields config)
    - find (2): search outcome ("if no match is found")
    - REJECTED: look up
61. - define (7): bind a meaning
    - specify (10): state a rule
    - set (31): assign a value
    - given (16): supplied (see 12)
62. - visible (7)
    - hidden (12)
    - hide (12): verb
    - unhide (0): verb
    - REJECTED: show / shown / display (for field specs) / make visible (2) →
      unhide
63. - insert (17): at a position
    - append (5): at the end
    - prepend (2): at the start
    - move (11)
    - remove (11)
64. - adjacent (6): next to
    - contiguous (3): unbroken run
    - neighboring
    - REJECTED: consecutive
