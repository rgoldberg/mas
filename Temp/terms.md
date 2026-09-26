# Standard Terminology

Each group lists the terms to use for a concept, then the terms not to use for
it under `REJECTED`. A bullet may hold multiple forms of 1 root word.

1. - start: noun & verb
   - REJECTED: begin / beginning
2. - end: noun
   - REJECTED: finish
3. - terminate: verb; an expression or token ends, explicitly at a terminator or
     implicitly
   - REJECTED: end (as a verb) / finish
4. - character
   - single: emphatic adjective; as one unit, not as a count ("a single value",
     "as a single element", "compares as a single number")
   - REJECTED: single character / single (as a count)
5. - only for: restrict scope or target applicability
   - for only: restrict numerical quantities or durations
6. - restrict: narrow scope or applicability
   - constrain: narrow permissible values (`{text: CONSTRAINTS}`)
   - REJECTED: limit
7. - bare character: `x`
   - escape prefix: `\`
   - escape sequence: `\x`
   - escaped character: `x` is the escaped character in the escape sequence `\x`
   - REJECTED: not escaped / unescaped / unescape / escape character
8. - anywhere in: match or constraint applicability at any location
   - throughout: operation or rule applies pervasively to every individual
     element
   - REJECTED: across
9. - entire
   - its entirety
   - REJECTED: entirety of / whole
10. - via: indirect mechanisms, routes, references, or syntactic pathways (e.g.,
      "referenced via index", "reached via rule")
    - by: operational agents, methods, or sorting criteria (e.g., "sorted by
      name", "parsed by the engine")
    - with: structural attributes, settings, or parameters accompanying an item
      (e.g., "defined with modifiers")
    - through: iteration or traversal across a sequence
    - over: iteration or traversal across the elements of a sequence
    - REJECTED: across
11. - iteration / iterate: sequential processing through linear structures
    - traversal / traverse: structural navigation through non-linear structures
      (e.g., trees & graphs)
12. - given: explicitly specified input values or parameters from a caller or
      user
    - attached: comments or metadata structurally bound to a production rule or
      AST node
    - present: concrete occurrence of a token or rule instance in input or parse
      trees
    - exists: abstract state of availability or occurrence (e.g., "a field
      config exists")
    - current: currently selected or governing state during evaluation
    - REJECTED: supplied / provided / active
13. - inherited: from the base fields config
    - existing: already in the working fields config
    - previous: the immediately preceding one (`$previous$`)
    - REJECTED: prior / predefined
14. - side
    - REJECTED: end (as a synonym for side)
15. - 1st
    - initial: only in `initialTitlecase` & its **initial character**
    - REJECTED: first (except in `<trivia-first>`) / leftmost / initial (in
      other senses) / earliest
16. - sole: adjective (the sole element, its sole purpose)
    - only: adverb / adjective
    - REJECTED: final / last (as a synonym for sole)
17. - last: positional element located at the end of a sequence or collection
      (pairs with 1st)
    - REJECTED: rightmost
    - REJECTED: final: irrevocable state, output, or calculated outcome of a
      process
    - REJECTED: terminal: EBNF symbol that cannot be expanded further (pairs
      with nonterminal)
18. - precede: positional relation in a sequence where one element comes before
      another
    - leading: adjective for characters / elements positioned at the start of a
      token or line (e.g., "leading whitespace")
    - before
    - earlier: relative ordering by index, time, or priority
    - former: 1st of 2 explicitly mentioned items
    - immediately: adjacency
19. - succeed: positional relation in a sequence where one element comes after
      another (direct antonym of precede)
    - subsequent
    - after
    - trailing: adjective for characters / elements positioned at the end of a
      token or line (e.g., "trailing whitespace")
    - later: subsequent in execution, evaluation, index, or priority
    - latter: second of 2 explicitly mentioned items
    - follow: prose sequence ("as follows", "the following", "immediately
      followed by")
    - immediately: adjacency
    - REJECTED: follow (regarding elements of token repetitions)
20. - must: mandatory requirement
    - must not: absolute prohibition
    - may: permissible action or choice
    - need not: lack of obligation (optional exemption)
    - can: capability, independent of permission ("JSON output can order each
      item's fields independently", "the literals that the syntax can consume at
      that position")
    - REJECTED: could
21. - allow: permit or enable, with a to-infinitive ("allows a matcher to also
      match")
    - let: enable, with a bare infinitive ("let `--table`'s value select")
    - support: feature availability ("supports escape sequences", "not supported
      for table output")
    - include: membership
    - emit: only as the config value name
    - REJECTED: permit / honor / follow (rules)
22. - require: a spec requirement
    - need: a prerequisite for outstanding work (`Temp/` only)
23. - must not: prohibition
    - forbid: grammar term (`Forbidden` treatment)
    - cannot: inability
    - omit: leave out
    - consume: take input into a token
    - ignore: disregard (`<trivia-ignored>`; outer bare whitespace)
    - REJECTED: disallow / prohibit / prevent / not allow / not let / may not /
      exclude / reject / significant / insignificant
24. - disable
    - enable
25. - disabled
    - invalid
    - REJECTED: inoperative / unused / unreachable / illegal
26. - position: a list position (1, 2, 3, etc.) that an index may reference
    - index: references a position
    - indices: plural
    - located at position
    - location: relative placement without an exact position (e.g.,
      `<nonconforming-location>`: before or after conforming values; distinct
      from `<trivia-order>`, the order in which sort keys are compared)
    - REJECTED: place / indexes
27. - put: verb
    - locate: verb
    - position: verb
    - REJECTED: place
28. - is: immutable classification
    - interpret / interpreted as: circumstance-dependent classification
    - treat as: apply a policy to (ebnf whitespace treatment)
    - REJECTED: considered / processed as / read as / functions as / counts as
29. - text: character sequence in syntax (tokens, `{text}` terminals, template
      text, boundary text)
    - string: the data type of a value (string fields, string transforms,
      `<string-block>`, empty strings)
    - token: syntactic unit (literal or syntax) formed by text
    - occurrence: specific appearance of something
    - value: evaluated content bound to a nonterminal or field
    - content: substance as a whole (of a string, file, or expression)
    - input: raw stream given to a parser or command
    - expression
    - nonterminal
    - terminal
    - compound
    - placeholder: only the defined `%…` fields-format term
    - rule: only a semantic rule in prose
    - REJECTED: contents / instance / usage / use / site / construct /
      projection / rule (as a syntactic element) / placeholder (as a generic
      term) / symbol
30. - meta-grammar: the notation the custom EBNF grammar is defined in
    - grammar: the custom EBNF grammar
    - syntax: a specific option's grammar, defined with the custom EBNF grammar
    - spec: a `Specs/` document
    - REJECTED: language / specification / rules
31. - null: absence of a scalar value
    - empty: repetition containing 0 elements, or text containing 0 characters
    - absent: state of being omitted (union of directly absent & transitively
      absent)
    - none: specific named value
    - blank: null, empty, or whitespace-only (`<nullary-blank-predicate>`); a
      blank line
    - nonexistent: guaranteed not to exist in any input (defined in fields.md)
    - REJECTED: nil / missing
32. - literal: syntactic role functioning as data rather than an operator
    - verbatim: exact character-for-character match without processing escapes
      or evaluation
33. - overlay: merging specific modifiers or fields onto an existing base while
      retaining unspecified attributes
    - override: priority precedence where a higher-level rule supersedes a
      lower-level rule
    - precedence: ordering among peers
    - priority: `<sort-priority>`
    - wins: only in the `(* last wins *)` idiom
    - replace: "replace Y with X" = "substitute X for Y"
    - substitute: "substitute X for Y" = "replace Y with X"
    - REJECTED: overwrite / supersede / replace Y by X / wins (in prose)
34. - remove: general verb
    - prune: remove undesirables
    - deduplicate: remove duplicates
    - truncate: remove beyond a length
    - discard: consume, but do not retain in any value
    - REJECTED: strip / cut off / delete / drop
35. - separator: syntactic token positioned strictly _between_ elements in a
      sequence to divide them without surrounding them (e.g., commas between
      items, or group separators)
    - terminator: syntactic token positioned strictly _after_ an element
    - fence: syntactic token surrounding an expression or list element (e.g.,
      `<argument-fence>`)
    - boundary: sort tokenization term (defined in fields.md)
    - exponent indicator: `e` or `E` in scientific notation
    - REJECTED: delimiter / encloser / marker / signifier
36. - evaluate / evaluation / evaluated: perform the process that returns the
      value of an expression
    - evaluate against: the value a matcher or block is evaluated on
    - calculate: derive a result from inputs
    - render: produce a value's output text
    - output: emit
    - display: a command's purpose
    - source from: take a config or setting from
    - REJECTED: decode / obtain / get / compute / make / resolve (in this sense;
      see 55) / interpolate / interpolation / receives / evaluate on / evaluate
      for
37. - neither … nor: independent prohibition applied individually to multiple
      items (e.g., "Neither `ELEMENT` nor `SEPARATOR` may match empty text")
    - REJECTED: X & Y must not / both … must not (when expressing independent
      prohibitions)
38. - multiple
    - 1 or more
    - REJECTED: two or more / 2 or more / several / one or more
39. - order: sequence items, either manually ordered or sorted
    - sort: order items by comparing them
    - sequence: only the EBNF senses (escape sequence; juxtaposition)
    - REJECTED: ordering / sequence (as a synonym for order)
40. - numeric: adjective
    - number: noun
    - numerically: adverb
    - REJECTED: numerical
41. - digits: all numeric uses ("0 or 1 elements", "1st")
    - one: only as a pronoun
    - REJECTED: zero / one (as an adjective) / two / half-away-from-zero
42. - transform
    - call: noun & verb, for transforms
    - run: noun & verb, for commands
    - REJECTED: function (except in "primary function") / method / execution /
      execute / invocation / invoke
43. - kind: config kinds; block kinds; multiplicity kinds
    - type: value types
    - variant: same-stem fields configs
    - form: matcher forms
    - Unicode general category: Unicode's character classification
    - REJECTED: category (except Unicode general category)
44. - enclosing: adjective, nearest ancestor of a kind ("enclosing matcher")
    - contain: verb, for membership, including throughout a subtree ("contains
      other expressions", "contains no token")
    - REJECTED: containing / enclose
45. - child: direct
    - descendant: transitive
    - REJECTED: enclosed / contained / nested (except for JSON) / sub
46. - block
    - REJECTED: scope / subformat
47. - success
    - failure
    - conforming
    - nonconforming
    - coerce
    - REJECTED: convert
48. - every: universal, no exception
    - each: distributive, per item
    - all: collective
    - any
49. - occur
    - REJECTED: happen
50. - apply to
    - affect
    - REJECTED: operate on / apply for / act on
51. - built-in
    - REJECTED: hardcoded / predefined
52. - custom
    - persisted: saved
    - REJECTED: user-configurable / user-defined / saved
53. - because
    - REJECTED: since / due to / as (causal)
54. - as per: according to
    - per: for each
55. - resolve: look up a name to its referent (resolved fields config)
    - find: search outcome ("if no match is found")
    - REJECTED: look up
56. - context: looking up named fields configs, formats, etc.; grammatical
      position (`context-dependent` multiplicity, `(* only for: CONTEXT *)`)
    - circumstances: situation
    - REJECTED: situation
57. - where: static location
    - when: runtime condition
58. - retain / retained
    - remain / remaining
    - preserve: only in "type-preserving"
    - REJECTED: keep / kept / maintain
59. - define: bind a meaning
    - specify: state a rule
    - set: assign a value
60. - visible
    - hidden
    - hide: verb
    - unhide: verb
    - REJECTED: show / shown / display (for field specs) / make visible
61. - insert: at a position
    - append: at the end
    - prepend: at the start
    - move
    - remove
62. - adjacent: next to
    - contiguous: unbroken run
    - next: the immediately subsequent one
    - REJECTED: consecutive / neighboring
63. - an error is reported: consequence clause after a condition
    - is an error: predicate
    - REJECTED: causes an error to be reported
64. - ensure: obligation on a syntax's author
    - guarantee: property that holds
65. - edit: a `<field-spec-edit>`
    - modify: applied to a value or config
    - REJECTED: change / alter
66. - payload: a modifier's expression after its prefix, or an option's
      expression between its letter & its `<sort-option-terminator>` (defined
      in fields.md)
    - argument: a transform call's argument
    - REJECTED: body / argument (for modifiers & options)
67. - titlecase: verb & adjective
    - uppercase: verb & adjective
    - lowercase: verb & adjective
    - case transform: `initialTitlecase`, `lowercase`, or `uppercase`
    - REJECTED: capitalize / title case / upper case / lower case / sentence
      case
68. - notation: positional or scientific
    - normalized scientific notation: exactly 1 digit before the point, nonzero
      unless the value is 0
    - sign: a leading `-` or `+`
    - halves rounded away from 0: the rounding mode of `round` & `scale`
    - REJECTED: exponential / E notation / fixed-point notation / decimal
      notation (for positional notation)
69. - time zone: noun
    - time-zone: compound adjective (`time-zone-dependent`)
    - system time zone: the time zone of the system running mas
    - output time zone: the time zone a chronologic value is rendered in
    - UTC offset: defined in fields-format.md
    - REJECTED: timezone / zone / TZ / GMT offset / local time zone
70. - date-only: adjective
    - datetime: noun
    - REJECTED: date-time / date time
