# Standard Terminology

Each group lists the terms to use for a concept, then the terms not to use for
it under `REJECTED`. A bullet may hold multiple forms of 1 root word.

1. - start: noun & verb
   - REJECTED: begin / beginning
2. - end: noun; also the `end` terminal ([defined](../Specs/ebnf.md#end))
   - REJECTED: finish
3. - terminate: verb; an expression or token ends, explicitly at a terminator or
     implicitly
   - REJECTED: end (as a verb) / finish
4. - character
   - single: emphatic adjective; as one unit, not as a count ("a single value",
     "as a single element", "compares as a single number")
   - REJECTED: single character / single (as a count)
5. - only for: restrict scope or target applicability
   - for only: restrict numeric quantities or durations
6. - restrict: narrow scope or applicability
   - constrain: narrow permissible values (`{text: CONSTRAINTS}`)
   - describe: state valid values in prose (`{DESCRIPTION}`,
     `{text: CONSTRAINTS}`)
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
   - whole match: a Swift Regex match of an entire string
   - whole: integral (e.g., "its whole milliseconds")
   - REJECTED: entirety of / whole (for entire)
10. - via: indirect mechanisms, routes, references, or syntactic pathways (e.g.,
      "referenced via index", "reached via rule")
    - by: operational agents, methods, or sorting criteria (e.g., "sorted by
      name", "parsed by the engine")
    - with: structural attributes, settings, or parameters accompanying an item
      (e.g., "defined with modifiers")
    - through: iteration or traversal of a sequence
    - over: iteration or traversal of the elements of a sequence
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
13. - inherited: from a base or working config
    - existing: already in the working fields config
    - previous: the immediately preceding one (`$previous$`)
    - REJECTED: prior / predefined
14. - side
    - REJECTED: end (as a synonym for side)
15. - 1st
    - initial: only in `initialTitlecase` & its **initial character**
    - REJECTED: first (except in `<text-first>`) / leftmost / initial (in other
      senses) / earliest
16. - sole: adjective (the sole element, its sole purpose)
    - only: adverb / adjective
    - REJECTED: final / last (as a synonym for sole)
17. - last: positional element located at the end of a sequence or collection
      (pairs with 1st)
    - REJECTED: rightmost / final / terminal (as synonyms for last)
18. - precede: positional relation in a sequence where one element comes before
      another
    - leading: adjective for characters / elements positioned at the start of a
      token or line (e.g., "leading whitespace")
    - before
    - earlier: relative order by index, time, or priority
    - former: 1st of 2 explicitly mentioned items
    - immediately: adjacency
19. - succeed: positional relation in a sequence where one element comes after
      another (direct antonym of precede)
    - subsequent
    - after
    - trailing: adjective for characters / elements positioned at the end of a
      token or line (e.g., "trailing whitespace")
    - later: subsequent in execution, evaluation, index, or priority
    - latter: 2nd of 2 explicitly mentioned items
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
    - let: enable, with a bare infinitive ("let `--table-config`'s value
      select")
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
    - ignore: disregard (outer bare whitespace)
    - exclude: leave out of a comparison (`<text-excluded>`)
    - REJECTED: disallow / prohibit / prevent / not allow / not let / may not /
      reject / significant / insignificant (for whitespace)
24. - disable
    - enable
25. - disabled
    - invalid
    - REJECTED: inoperative / unused / unreachable / illegal
26. - position: a list position (1, 2, 3, etc.) that an index may reference
    - index: references a position
    - indices: plural
    - located at position
    - location: relative placement without an exact position
    - REJECTED: place (except in the idiom "in place", e.g., `<text-in-place>`)
      / indexes
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
    - REJECTED: contents / instance / usage (except as in 105) / use / site /
      construct / projection / rule (as a syntactic element) / placeholder (as a
      generic term) / symbol
30. - meta-grammar: the notation the custom EBNF grammar is defined in
    - grammar: the custom EBNF grammar
    - syntax: a specific option's grammar, defined with the custom EBNF grammar
    - spec: a `Specs/` document
    - REJECTED: language / specification / rules
31. - null: absence of a scalar value
    - empty: repetition containing 0 elements, or text containing 0 characters
    - absent: state of being omitted (union of directly absent & transitively
      absent); of a formatted value: omitted from key-value & JSON output
      ([defined](../Specs/fields.md#absent-values))
    - none: specific named value
    - blank: null, empty, or whitespace-only (`<nullary-blank-predicate>`); a
      blank line
    - nonexistent: guaranteed not to exist in any input
      ([defined](../Specs/fields.md#nonexistent-fields))
    - REJECTED: nil / missing
32. - literal: syntactic role functioning as data rather than an operator
    - verbatim: exact character-for-character match without processing escapes
      or evaluation
33. - overlay: merging specific modifiers or fields onto an existing base while
      retaining unspecified attributes
    - override: priority precedence where a higher-level rule prevails over a
      lower-level rule, including an app's behavior or default prevailing over a
      spec's
    - precedence: order among peers
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
    - boundary: sort tokenization term
      ([defined](../Specs/fields.md#sort-boundaries))
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
    - REJECTED: zero / one (as an adjective) / two
42. - transform
    - call: noun & verb, for transforms
    - run: noun & verb, for commands
    - REJECTED: function (except in "primary function") / method / execution /
      execute / invocation / invoke
43. - kind: config kinds; block kinds; multiplicity kinds
    - type: value types
    - variant: same-stem fields configs
    - unsuffixed variant: the variant whose name has no output format suffix,
      which the `@unsuffixed` reference suffix selects
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
    - absent block: a block or `<format-block>` that consumes no token, which
      defaults to an empty string
    - REJECTED: scope / subformat / empty template
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
    - built-in standard: a leaf context's built-in config of a kind, which is
      the root context's `standard`
      ([defined](../Specs/configs.md#immutable-built-in-named-configs))
    - starting context: the context from which a reference's lookup iterates
      through the context stack
      ([defined](../Specs/configs.md#referencing-named-configs))
    - REJECTED: hardcoded / predefined
52. - custom: a user-given alternative to a built-in, default, or locale-sourced
      value (e.g., a `<locale-identifier>`)
    - explicit: only in "explicit default" & in contrast with implied
    - persisted: saved
    - REJECTED: user-configurable / user-defined / saved / manual / explicit (as
      synonyms for custom)
53. - because
    - REJECTED: since / due to / as (causal)
54. - as per: according to
    - per: for each
55. - resolve: map a name to its referent (resolved fields config)
    - find: search outcome ("if no match is found")
    - look up / lookup: search a context stack for a named config (name lookup)
56. - context: resolving named fields configs, formats, etc.; grammatical
      position (`context-dependent` multiplicity, `(* only for: CONTEXT *)`)
    - circumstances: situation
    - REJECTED: situation
57. - where: static location
    - when: runtime condition
58. - retain / retained
    - remain / remaining
    - REJECTED: keep (except in `<all-conforming>`'s mnemonic) / kept / maintain
      / preserve
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
      expression between its letter & its `<sort-option-terminator>`
      ([defined](../Specs/fields.md#payloads))
    - argument: an element of an argument list (a transform's, a number
      coercion's, `N`'s, or `C`'s)
    - REJECTED: body / argument (for other modifiers & options)
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
    - REJECTED: half-away-from-zero / exponential / E notation / fixed-point
      notation / decimal notation (for positional notation)
69. - time zone: noun
    - time-zone: compound adjective (`time-zone-dependent`)
    - system time zone: the time zone of the system running mas
    - output time zone: the time zone a chronologic value is rendered in
    - UTC offset:
      [defined](../Specs/fields-format.md#timezone--timeonlytimezone)
    - time zone abbreviation: a Foundation `TimeZone.abbreviationDictionary` key
    - REJECTED: timezone / zone / TZ / GMT offset / local time zone
70. - date-only: adjective & noun (e.g., "a date-only")
    - time-only: adjective & noun (e.g., "a time-only"); also the type of a
      time-only value (`%c`'s output type)
    - datetime: noun
    - date: the type of a date-only or a datetime (`%d`'s output type)
    - REJECTED: date-time / date time
71. - app: software implementing the specs (e.g., mas;
      [defined](../Specs/configs.md#configs))
    - REJECTED: application / program
72. - least: compares less than all others (`<nonconforming-least>`,
      `<absent-fields-least>`)
    - greatest: compares greater than all others (`<nonconforming-greatest>`,
      `<absent-fields-greatest>`)
    - relative: of a location that `<direction>` reverses
      (`<relative-nonconforming>`, `<relative-absent-fields>`)
    - fixed: of a location that `<direction>` does not affect
      (`<fixed-nonconforming>`, `<fixed-absent-fields>`)
    - REJECTED: lowest / highest / smallest / largest / minimum / maximum /
      pinned / anchored / directional (for relative or fixed)
73. - code span: backtick-delimited inline code (CommonMark)
    - link text: the bracketed text of a Markdown link
    - inline HTML tag: an HTML tag inside a Markdown paragraph
    - REJECTED: inline code block / link anchor / anchor text
74. - clean up: verb
    - cleanup: noun
    - REJECTED: cleanup (as a verb)
75. - positional order: field specs ordered by position (`<positional-order>`)
    - document order: field specs ordered by their fields' order in an input
      item (`<document-order>`)
    - REJECTED: base fields config order / listed order / original input order /
      source order
76. - leader: the fill between a key & its value (`<leader-setting>`)
    - leading spacing: spacing after a key, before its leader
      (`<leading-spacing>`)
    - trailing spacing: spacing before a value, after its leader
      (`<trailing-spacing>`)
    - REJECTED: padding / key-value spacing / before spacing / after spacing
77. - default comment: a semantic comment specifying an explicit default
    - virtual descendant: a descendant default comment's `DESCENDANT` that is
      not an actual descendant of its `NONTERMINAL`
    - REJECTED: default value comment
78. - style specifier: terminal-specific text styling a header row or a key
      (`<style-specifier>`)
    - style prefix: precedes a style specifier (`<style-prefix>`)
    - style suffix: follows a style specifier (`<style-suffix>`)
    - style reset: follows a styled string (`<style-reset>`)
    - REJECTED: style terminator / style end
79. - width: text's terminal display width (as per `wcwidth`)
    - wide: adjective, for a character whose width is 2 (e.g., `中`)
    - space-fill: fill any remaining width with spaces
    - REJECTED: columns / cells (as units of width) / padding (for space-fill)
80. - maximal munch: consuming the longest input that matches (e.g., a scalar
      token)
    - lexical form: the text that may denote a scalar description's literal
      scalars, whether valid or not
    - REJECTED: greedy matching / longest match / how far a token extends
81. - tuple: the multiplicity of a sequence's children's values
      ([defined](../Specs/ebnf.md#multiplicity))
    - static multiplicity: the multiplicity shared by all of an expression's
      possible occurrences ([defined](../Specs/ebnf.md#multiplicity))
    - mixed: the static multiplicity of a choice whose alternatives' static
      multiplicities differ
    - REJECTED: product / record (for a tuple)
82. - tie & fall through: compare as equal for a sort key, leaving the order to
      the next sort key ([used](../Specs/fields.md#sort-source))
    - REJECTED: retain their input order
83. - field occurrence index: `<field-occurrence-index>`, an index into only the
      field specs for 1 field
      ([defined](../Specs/fields.md#field-spec-references))
    - field spec index: `<field-spec-index>`, an index into all field specs
    - REJECTED: named field spec index / indexed field spec index
84. - default field spec: the field spec selected for a field that the base
      fields config lacks ([defined](../Specs/fields.md#default-field-specs))
    - REJECTED: field spec with default settings
85. - segment: a part of a run of non-boundary text that sorting compares as 1
      element ([defined](../Specs/fields.md#sort-segments))
    - typed segment: a chronologic or number segment
    - text segment: a maximal sequence of non-boundary characters that is in no
      typed segment
    - piece: a run of non-boundary text or a boundary, which sorting compares as
      1 element of a value ([defined](../Specs/fields.md#sort-segments))
    - REJECTED: chunk / token (for a segment) / trivia (for text segments)
86. - ungrouped numeric: comparing each run of digits as a number
      (`<ungrouped-numeric>`)
    - grouped numeric: comparing each grouped number as a number
      (`<grouped-numeric>`)
    - lexicographic: comparing numbers as text (`<lexicographic>`)
    - REJECTED: natural / numeric (for ungrouped numeric) / lexical (for
      lexicographic)
87. - word-initial: at the start of the value or after whitespace
      (`<word-initial-signs>`)
    - REJECTED: leading / standalone / attached
88. - reference date: the date as if on which a time-only value is rendered in a
      time zone (`<reference-date>`)
    - REJECTED: mode / daylight saving mode
89. - number format arguments: the arguments of `<number-format-arguments>`
      ([defined](../Specs/fields-format.md#numberformat))
    - REJECTED: number conventions arguments
90. - trailing-omissible: an expression that may consume nothing iff no
      expression after it in its trailing run consumes a token (`EXPRESSION?`;
      [defined](../Specs/ebnf.md#trailing-omissibles))
    - trailing run: the longest run of adjacent optionals & trailing-omissibles
      that includes an expression, through nonterminal references
    - REJECTED: omissible (for trailing-omissible)
91. - axis: a concept that a setting sets (e.g., a header row), whose
      `(* last wins *)` nonterminal (e.g., `<header-setting>`) overrides its
      preceding occurrences
    - last-wins scope: the nearest enclosing occurrence (else the entire input)
      within which a `(* last wins *)` nonterminal's occurrences override each
      other ([defined](../Specs/ebnf.md#last-wins-comments))
92. - Unix time: the number of seconds since 1970-01-01T00:00:00Z, ignoring leap
      seconds ([defined](../Specs/fields-format.md#chronologic-formatting))
    - decimal number: a Unix time's text syntax
      ([defined](../Specs/fields-format.md#chronologic-formatting))
    - REJECTED: Unix epoch (for a Unix time) / epoch / epoch time / Unix
      timestamp / numeric timestamp
93. - input type: the type of a nonterminal's input
      ([defined](../Specs/ebnf.md#type-comments))
    - output type: the type of a nonterminal's value
      ([defined](../Specs/ebnf.md#type-comments))
94. - formatted value: a field spec's `<format-block>`'s value, at its type,
      before the output format renders it
      ([defined](../Specs/fields-format.md#value-types))
    - REJECTED: field spec output / passthrough
95. - structured value: a field value that is an array or an object
      ([defined](../Specs/fields-format.md#value-types))
    - REJECTED: nested value / composite value / complex value
96. - extended format: ISO-8601's representation with `-` & `:` separators
    - basic format: ISO-8601's representation without `-` & `:` separators
    - reduced precision: an ISO-8601 representation omitting its trailing
      components (e.g., seconds)
    - REJECTED: compact format (for basic format) / truncated (for reduced
      precision)
97. - whitespace: any Unicode `White_Space` character
      ([defined](../Specs/ebnf.md#whitespace))
    - REJECTED: blank space / white space
98. - collation: a locale's rules for comparing text
    - CLDR root collation: the Unicode Collation Algorithm with CLDR's root
      collation order & settings, per which the canonical conventions compare
      text ([used](../Specs/fields.md#sort-locale))
    - REJECTED: code point order / Unicode order (for the canonical conventions'
      text comparison)
99. - character class: a `<character-class-name>`'s characters, per UTS #18
      Annex C's POSIX Compatible definitions
      ([used](../Specs/fields.md#sort-boundaries))
    - REJECTED: GNU Extended POSIX character class / bracket expression class
100. - date block: `%D`'s block (`<date-block>`), whose pipeline's transforms
       can be only `dateOnly`s & `timeZone`s, or string transforms after
       coercing to a string
     - time-only block: `%C`'s block (`<time-only-block>`), whose pipeline's
       transforms can be only `timeOnlyTimeZone`s, or string transforms after
       coercing to a string
     - REJECTED: clock block / time block
101. - expanded representation: ISO-8601's year of a sign & at least 5 digits,
       for a year outside 0000 to 9999
     - proleptic Gregorian calendar: the Gregorian calendar extended before
       1582-10-15, as ISO-8601 requires
     - instant: a point in time, in milliseconds since 1970-01-01T00:00:00Z
     - REJECTED: extended year (for an expanded representation) / timestamp (for
       an instant)
102. - nullary: of a form, or of a lowercase predicate letter other than `m`,
       followed by no block
     - non-nullary: of an uppercase predicate letter other than `M`, followed by
       1 or more blocks
     - unary match / binary match: `%m` (`<unary-match>`) / `%M`
       (`<binary-match>`), named by arity, because `%m`'s `<branches>` make it
       not nullary
     - REJECTED: concise / verbose (the letters have equal length) / bare / full
       / block (for letter case) / nullary match / non-nullary match
103. - success pipeline: a unary form's pipeline-only block
       (`<success-pipeline>`), e.g., `%I…+`'s
       ([defined](../Specs/fields-format.md#success--failure))
     - success clause: a `<success-block>` or a `<success-pipeline>`
       (`<success-clause>`), evaluated iff its enclosing matcher succeeds
104. - member: 1 of a field's name / value pairs in an item, of which there may
       be multiple ([defined](../Specs/fields.md#members))
     - REJECTED: duplicate / instance / occurrence (for a member)
105. - option value: the rest of an option's command-line argument after `=`, or
       else the next command-line argument, iff it is `-` or does not start with
       `-` ([defined](../Specs/configs.md#option-values))
     - option value separator: the `=` between a long option & its value (e.g.,
       in `--fields=name`)
     - flag: an option that takes no value (e.g., `--json`)
       ([defined](../Specs/configs.md#option-values))
     - usage: Swift Argument Parser's synopsis of a command's arguments (e.g.,
       `[--json | --json-config <json-config> | …]`)
     - REJECTED: option-argument / option-argument separator (the specs use
       "argument" for an argument list's elements)
106. - line terminator: a CRLF, or any other character from U+000A to U+000D,
       U+0085, U+2028, or U+2029
       ([defined](../Specs/configs.md#line-terminators))
     - newline: the LF that ends an output line (e.g., after a JSON object)
     - REJECTED: line break / line ending / EOL (for a line terminator)
