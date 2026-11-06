# Standard Terminology

Each group lists the terms to use for a concept, then the terms not to use for
it under `REJECTED`. A bullet may hold multiple forms of 1 root word.

1. - start: noun & verb
   - REJECTED: begin / beginning
2. - end: noun; also the `end` terminal ([defined](../Specs/ebnf.md#end))
   - REJECTED: finish
3. - terminate: verb; an expression or token reaches its end, explicitly at a
     terminator or implicitly
   - REJECTED: end (as a verb) / finish
4. - character
   - single: emphatic adjective; as a unit, not as a count ("a single value",
     "as a single element", "compares as a single number")
   - REJECTED: single character / single (as a count)
5. - only for: restrict scope or target applicability
   - for only: restrict numeric quantities or durations
6. - restrict: narrow scope or applicability
   - constrain: narrow permissible values (`{SUBTYPE: CONSTRAINTS}`)
   - describe: state valid values in prose (`{DESCRIPTION}`,
     `{SUBTYPE: CONSTRAINTS}`)
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
   - whole: integral (e.g., "its whole milliseconds"); also entire, of what a
     Swift Regex must match (e.g., "that the whole value must match"), as in a
     whole match
   - REJECTED: entirety of / whole (for entire, except of what a Swift Regex
     must match)
10. - via: indirect mechanisms, routes, references, or syntactic pathways (e.g.,
      "referenced via index", "reached via rule")
    - by: operational agents, methods, or sorting criteria (e.g., "sorted by
      name", "parsed by the engine")
    - with: structural attributes, settings, or parameters accompanying an item
      (e.g., "defined with modifiers")
    - through: iteration through a sequence (e.g., "iterating through the
      context stack")
    - over: precedence or layering (e.g., "takes sort precedence over", "layers
      … over")
    - REJECTED: across
11. - iteration / iterate: sequential processing through linear structures
    - traversal / traverse: structural navigation through non-linear structures
      (e.g., trees & graphs)
12. - given: explicitly specified input values or parameters from a caller or
      user
    - attached: comments or metadata structurally bound to a nonterminal
      definition; also a preset in a field spec's list of presets (see 110)
    - present: an occurrence of a token or an expression in the syntax text
    - exists: abstract state of availability or occurrence (e.g., "a fields
      config exists")
    - current: currently selected or governing state during evaluation
    - REJECTED: supplied / provided / active
13. - inherited: from the config onto which syntax text is overlaid (e.g., the
      working fields config, or the `default` config for an output config
      option's value)
    - inherited value: a transitively absent `(* inherited *)` nonterminal's
      value from the config onto which syntax text is overlaid
      ([defined](../Specs/ebnf.md#inherited-comments))
    - existing: that exists (e.g., "an existing preset"), or already in the
      working fields config
    - previous: the immediately preceding one (`$previous$`)
    - REJECTED: prior / predefined
14. - side
    - REJECTED: end (as a synonym for side)
15. - 1st
    - initial: only in `initialTitlecase`, its **initial character** &
      word-initial (see 87)
    - REJECTED: first (except in `<text-first>`) / leftmost / initial (in other
      senses) / earliest
16. - sole: adjective (the sole element, its sole purpose)
    - only: adverb / adjective
    - REJECTED: final / last (as a synonym for sole)
17. - last: positional element located at the end of a sequence or collection
      (pairs with 1st)
    - REJECTED: rightmost / final / terminal (as synonyms for last)
18. - precede: positional relation in a sequence where an element comes before
      another
    - leading: adjective for characters / elements positioned at the start of a
      token or line (e.g., "leading whitespace")
    - before
    - earlier: relative order by index, time, or priority
    - former: 1st of 2 explicitly mentioned items
    - immediately: adjacency
19. - succeed: positional relation in a sequence where an element comes after
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
    - support: feature availability ("supports escape sequences")
    - unsupported: not supported ("unsupported for table output", "a type
      unsupported by its input format")
    - include: membership
    - emit: only as the config value name
    - REJECTED: permit / honor / follow (rules)
22. - require: a spec requirement
    - need: a prerequisite for outstanding work (`Temp/` only)
23. - must not: prohibition
    - forbid: make syntax invalid, via a treatment (`Forbidden`), a constraint,
      or a grammar
    - cannot: inability
    - omit: leave out
    - consume: take syntax text into a token
    - ignore: disregard (outer bare whitespace)
    - exclude: leave out of a comparison (`<text-excluded>`)
    - REJECTED: disallow / prohibit / prevent / not allow / not let / may not /
      reject / significant / insignificant (for whitespace)
24. - disable
    - enable
    - disabled sort prefix: a `0` that disables a sort
      (`<disabled-sort-prefix>`)
25. - disabled
    - invalid
    - unreachable: of syntax that no evaluation can reach (e.g., a
      `<failure-block>` whose matcher always succeeds)
    - REJECTED: inoperative / unused / illegal
26. - position: a list position (1, 2, 3, etc.) that an index may reference
    - index: references a position
    - normalized index: the position that an index references, accessing which
      is an error iff it is invalid
      ([defined](../Specs/fields.md#positions--indices))
    - indices: plural
    - located at position
    - location: where something is relative to others, without an exact position
    - placement: a setting that chooses a location (`<nonconforming-placement>`,
      `<unpositioned-field-placement>`)
    - REJECTED: place (except in the idiom "in place", e.g., `<text-in-place>`)
      / indexes / effective index (for a normalized index)
27. - put: verb
    - locate: verb
    - position: verb
    - REJECTED: place
28. - is: immutable classification
    - interpret / interpreted as: circumstance-dependent classification
    - treat as: apply a policy to (ebnf whitespace treatment)
    - REJECTED: considered / processed as / read as / functions as / counts as
29. - text: character sequence in syntax (tokens, `{string}` terminals, template
      text, boundary text)
    - syntax text: the text that a syntax parses (e.g., an option value), as
      opposed to an app's input (e.g., its items)
    - synonymous syntax text: syntax text that means what other syntax text
      means (e.g., `%+N%n+` & `%n`)
    - REJECTED: parsed text (too generic: an app's input is parsed too) / input
      (for syntax text)
    - string: the data type of a value (string fields, string transforms,
      `<string-pipeline>`, empty strings)
    - token: contiguous characters consumed together as 1 element: a literal,
      name, or variable token ([defined](../Specs/ebnf.md#tokens))
    - typed terminal: a `{SUBTYPE}` or `{SUBTYPE: CONSTRAINTS}` terminal, which
      consumes a variable token ([defined](../Specs/ebnf.md#typed-terminals))
    - subtype: a typed terminal's `SUBTYPE` (e.g., `integer`), which determines
      its value's type (e.g., number) & its lexical form
    - accept: of a typed terminal, to allow text as its variable token
    - free-form description: a `{DESCRIPTION}` that describes a value or a type
      in prose in a semantic comment
      ([defined](../Specs/ebnf.md#free-form-descriptions))
    - REJECTED: syntax token / constant token (for a literal token) / scalar
      token / text token (for a variable token) / ad hoc text (for a variable
      token's text) / scalar description / text terminal / constrained text
      terminal (for a typed terminal) / ad hoc description (for a free-form
      description)
    - occurrence: specific appearance of something
    - value: evaluated content bound to a nonterminal or field
    - content: substance as a whole (of a string, file, or expression)
    - input: data given to an app or a command (e.g., its items), as opposed to
      syntax text
    - expression
    - nonterminal
    - terminal
    - compound
    - placeholder: only the defined `%…` fields-format term
    - rule: only a semantic rule in prose
    - REJECTED: contents / instance / usage (except as in 104) / use (as a noun)
      / site / construct / projection / rule (as a syntactic element) /
      placeholder (as a generic term) / symbol (except a Unicode general
      category `S` character)
30. - meta-grammar: the notation the custom EBNF grammar is defined in
    - grammar: the custom EBNF grammar
    - syntax: a specific option's grammar, defined with the custom EBNF grammar
    - spec: a `Specs/` document
    - REJECTED: language / specification / rules
31. - null: absence of a scalar value
    - empty: a repetition of 0 elements, or text of 0 characters
    - absent: state of being omitted (union of directly absent & transitively
      absent); of a formatted value: omitted from key-value & JSON output
      ([defined](../Specs/fields.md#absent-values))
    - none: specific named value
    - blank: null, empty, or whitespace-only (`<nullary-blank-predicate>`); a
      blank line
    - nonexistent: guaranteed not to exist in any input
      ([defined](../Specs/fields.md#nonexistent-fields))
    - REJECTED: nil / missing
32. - literal: a `"TEXT"` terminal, which literal tokens match
      ([defined](../Specs/ebnf.md#literals))
    - name literal: a `'TEXT'` terminal, which name tokens match
      ([defined](../Specs/ebnf.md#name-literals))
    - name token: a token, which may contain escape sequences, that evaluates to
      a name literal's text ([defined](../Specs/ebnf.md#tokens))
    - candidate literal: a literal or a name literal that the syntax can consume
      at a given position ([defined](../Specs/ebnf.md#candidate-literals))
    - REJECTED: literal text (for a literal) / candidate syntax literal /
      literal (as an adjective for as-is data, e.g., "a literal tab character")
    - verbatim: exact character-for-character match without processing escapes
      or evaluation
33. - overlay: merging specific modifiers or fields onto an existing base while
      retaining unspecified attributes
    - override: priority precedence where a higher-level rule prevails over a
      lower-level rule, including an app's behavior or default prevailing over a
      spec's
    - effective: not overridden (e.g., "an effective `f`";
      [defined](../Specs/ebnf.md#last-wins-comments))
    - precedence: order among peers
    - priority: `<sort-priority>`
    - wins: only in the `(* last wins *)` idiom
    - replace: "replace Y with X" = "substitute X for Y"
    - substitute: "substitute X for Y" = "replace Y with X"
    - REJECTED: overwrite / supersede / replace Y by X / wins (in prose) / not
      overridden (for effective)
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
    - regex literal: Swift's `/`-fenced Regex syntax (e.g., `/[A-Y]+/`)
    - boundary: what splits a value's text outside typed segments into pieces
      ([defined](../Specs/fields.md#sort-boundaries))
    - exponent indicator: `e` or `E` in scientific notation
    - REJECTED: delimiter / encloser / marker / signifier
36. - evaluate / evaluation / evaluated: perform the process that returns the
      value of an expression
    - evaluate against: evaluate a matcher or block relative to a value
    - calculate: derive a result from inputs
    - render: produce a value's output text
    - output: write to standard output
    - display: a command's purpose
    - source from: take a config or setting from
    - read: take in input (e.g., an item) from its source
    - REJECTED: decode / obtain / get / compute / make / print (except the
      `print` character class & pretty-printing) / resolve (in this sense; see
      55) / interpolate / interpolation / receives / evaluate on / evaluate for
37. - neither … nor: independent prohibition applied individually to multiple
      items (e.g., "Neither `ELEMENT` nor `SEPARATOR` may match empty text")
    - REJECTED: X & Y must not / both … must not (when expressing independent
      prohibitions)
38. - multiple
    - 1 or more
    - REJECTED: two or more / 2 or more / several / one or more
39. - order: arrange items, either manually or by sorting them
    - sort: order items by comparing them
    - sequence: an EBNF sequence (juxtaposition), an escape sequence, or a
      series of elements (e.g., "a maximal sequence of segments")
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
    - transform run: a `<transform-run>`'s contiguous calls of 1 value type
      ([defined](../Specs/fields-format.md#transforms))
    - transform pipeline: a `<transform-pipeline>`, whose transforms are applied
      to a value ([defined](../Specs/fields-format.md#transforms))
    - REJECTED: function (except in "primary function") / method / execution /
      execute / invocation / invoke
43. - kind: config kinds; block kinds
    - type: value types
    - stem: a config name, without any output format suffix
      ([defined](../Specs/configs.md#named-configs))
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
    - directly absent block: a [directly
      absent](../Specs/ebnf.md#presence-states) `<block>` (e.g.,
      `<format-block>` in `name:`), which defaults to an empty string
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
    - explicit: of a default that a default comment specifies ("explicit
      default"), of an alternative in contrast with an implied one ("an explicit
      alternative"), or of a setting in contrast with one that an attached
      preset sets ("an explicit modifier")
    - REJECTED: user-configurable / user-defined / saved / manual / explicit (as
      synonyms for custom)
53. - because
    - REJECTED: since / due to / as (causal)
54. - per: according to (e.g., "per `<text-order>`"), or for each (e.g., "1 per
      line")
    - REJECTED: as per
55. - resolve: map a name to its referent (resolved fields config)
    - find: search outcome ("if no match is found")
    - look up / lookup: search a context stack for a named config (name lookup)
    - reference cycle: a cyclic chain of references among named configs, other
      than a reference to a same-named ancestor, which is an error
      ([defined](../Specs/configs.md#referencing-named-configs))
56. - context: resolving named fields configs, formats, etc.; grammatical
      position (`context-dependent` multiplicity)
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
      ([defined](../Specs/fields.md#payloads)); also an output config
      alternative's expression between its letter & its termination
      ([defined](../Specs/configs.md#output-configs))
    - payloadless: of a setting's lowercase alternative, which takes no payload,
      unlike its uppercase one (e.g., a table's `h`;
      [defined](../Specs/configs.md#output-configs))
    - argument: an element of an argument list (a transform's, a number
      coercion's, a date coercion's, `N`'s, or `C`'s); also an expression that a
      parameterized nonterminal's reference passes for a parameter
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
    - datetime: noun; also the type of a datetime value
    - date: a date-only or a datetime, either of which `%d` matches (`%d`'s
      output type)
    - REJECTED: date-time / date time
71. - app: software implementing the specs (e.g., mas;
      [defined](../Specs/configs.md#configs))
    - REJECTED: application / program
72. - least: compares less than all others (`<nonconforming-least>`,
      `<unpositioned-fields-least>`)
    - greatest: compares greater than all others (`<nonconforming-greatest>`,
      `<unpositioned-fields-greatest>`)
    - relative: of a location that `<direction>` reverses
      (`<relative-nonconforming>`, `<relative-unpositioned-fields>`)
    - fixed: of a location that `<direction>` does not affect
      (`<fixed-nonconforming>`, `<fixed-unpositioned-fields>`)
    - REJECTED: lowest / highest / smallest / largest / minimum / maximum /
      pinned / anchored / directional (for relative or fixed)
73. - code span: inline code between backticks (CommonMark)
    - link text: the bracketed text of a Markdown link
    - inline HTML tag: an HTML tag inside a Markdown paragraph
    - REJECTED: inline code block / link anchor / anchor text
74. - clean up: verb
    - cleanup: noun
    - REJECTED: cleanup (as a verb)
75. - field order: the order in which each item's fields are output, per
      `<field-order-option-set>` ([defined](../Specs/fields.md#field-order))
    - positional order: field specs ordered by position (`<positional-order>`)
    - document order: field specs ordered by their fields' order in an input
      item (`<document-order>`)
    - adjustment sort option: a `<direction>`, `<nonconforming-comparison>`, or
      `<nonconforming-placement>`, which, in a field-order adjustment set,
      adjusts the working field order (`<adjustment-sort-option>`)
    - field-order adjustment set: only adjustment sort options, which set only
      the working field order's direction & its comparison & placement of
      unpositioned fields or nonconforming values
      (`<field-order-adjustment-set>`)
    - REJECTED: base fields config order / listed order / original input order /
      source order
76. - leader: the fill between a key & its value (`<leader-setting>`)
    - leading spacing: spacing after a key, before its leader
      (`<leading-spacing>`)
    - trailing spacing: spacing before a value, after its leader
      (`<trailing-spacing>`)
    - REJECTED: padding / key-value spacing / before spacing / after spacing
77. - default comment: a semantic comment specifying an explicit default
    - error comment: a semantic comment specifying when its nonterminal is an
      error (`(* error: CONDITION *)`;
      [defined](../Specs/ebnf.md#error-comments))
    - virtual descendant: a descendant default comment's `DESCENDANT` that is
      not an actual descendant of its `NONTERMINAL`
    - parameterized nonterminal: a nonterminal whose definition names
      parameters, each of which a reference replaces with its argument
      ([defined](../Specs/ebnf.md#parameterized-nonterminals))
    - parameter / argument: a parameterized nonterminal's metavariable-like word
      / the expression that a reference passes for it (the standard pair of
      terms; an argument list's element is an argument in the syntax, while this
      is one in the grammar)
    - REJECTED: default value comment / applicability comment (for an error
      comment) / actual parameter (for an argument)
78. - style specifier: terminal-specific text styling a header row or a key
      (`<style-specifier>`)
    - style prefix: precedes a style specifier (`<style-prefix>`)
    - style suffix: follows a style specifier (`<style-suffix>`)
    - style reset: follows a styled string (`<style-reset>`)
    - stylable string: a header row or a key, which a style specifier may style
      ([defined](../Specs/table.md#styling))
    - final byte: ECMA-48's term for the character that terminates a control
      sequence (e.g., SGR's `m`)
    - REJECTED: style terminator / style end / final character
79. - width: text's terminal display width
      ([defined](../Specs/configs.md#width))
    - wide: adjective, for a character whose width is 2 (e.g., `中`)
    - column width: the width of a table column's widest rendered cell,
      including its header cell iff the header row is rendered
      ([defined](../Specs/table.md#table-config))
    - table width: the sum of a table's column widths, plus the column spacing's
      width once per pair of adjacent columns
      ([defined](../Specs/table.md#table-config))
    - space-fill: fill any remaining width with spaces
    - REJECTED: columns / cells (as units of width) / padding (for space-fill)
80. - maximal munch: consuming the longest syntax text that a typed terminal
      accepts as a variable token
    - lexical form: the text that denotes a subtype's values
      ([defined](../Specs/ebnf.md#typed-terminals))
    - candidate terminator: a candidate literal of the position immediately
      following a variable token
    - REJECTED: literal scalar (for a value) / candidate text terminator /
      greedy matching / longest match / how far a token extends
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
    - default sort options: the app's per-output-format replacements for sort
      options' defaults, for field names, field labels, or a field's content
      ([defined](../Specs/fields.md#sort-options))
83. - field occurrence index: `<field-occurrence-index>`, an index into only the
      field specs for 1 field
      ([defined](../Specs/fields.md#field-spec-references))
    - field spec index: `<field-spec-index>`, an index into all field specs
    - REJECTED: named field spec index / indexed field spec index
84. - default field spec: the field spec selected for a field that has no field
      spec in the baseline fields config, or for an unlisted field
      ([defined](../Specs/fields.md#default-field-specs))
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
91. - last-wins scope: the nearest enclosing occurrence (else the entire syntax
      text) within which a `(* last wins *)` nonterminal's occurrences override
      each other ([defined](../Specs/ebnf.md#last-wins-comments))
    - implied alternative: an alternative that an output config's explicit
      alternatives imply, directly or via another implied alternative
      ([defined](../Specs/configs.md#implied-alternatives))
92. - Unix time: the number of seconds since 1970-01-01T00:00:00Z, ignoring leap
      seconds ([defined](../Specs/fields-format.md#chronologic-formatting))
    - decimal number: text in `number`'s lexical form (e.g., a Unix time's text)
      ([defined](../Specs/fields-format.md#chronologic-formatting))
    - date coercion: a `<coercion>` to a date, which parses a date that any of
      its `<date-format>`s matches or, absent any, a date that `<iso>` matches &
      a number as a Unix time
    - date-only coercion: a date coercion whose only `<date-format>` is
      `<iso-date>`, so its value is a date-only (`<date-only-coercion>`)
    - non-date-only coercion: a date coercion that omits its `<date-format>`s or
      lists 1 other than `<iso-date>`, so its value may be a datetime
      (`<non-date-only-coercion>`)
    - version date-only coercion: a date coercion of a version without
      `<unix-time>`, so its value is a date-only
      (`<version-date-only-coercion>`)
    - number date coercion: a date coercion of a number, which omits its
      `<date-format>`s or includes `<unix-time>`, so it coerces the number as a
      Unix time (`<number-date-coercion>`)
    - Unix time coercion: a date coercion that includes `<unix-time>`, so it
      coerces a number or a decimal number as a Unix time
      (`<unix-time-coercion>`)
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
    - canonical conventions: the conventions that `<canonical-locale>`
      identifies, which are independent of every real-world locale
      ([defined](../Specs/fields.md#sort-locale))
    - system locale: the locale of the system running mas (`<system-locale>`;
      [used](../Specs/fields.md#sort-locale))
    - REJECTED: code point order / Unicode order (for the canonical conventions'
      text comparison)
99. - character class: a `<character-class-name>`'s characters, per UTS #18
      Annex C's POSIX Compatible definitions
      ([used](../Specs/fields.md#sort-boundaries))
    - REJECTED: GNU Extended POSIX character class / bracket expression class
100. - expanded representation: ISO-8601's year of a sign & at least 5 digits,
       for a year outside 0000 to 9999
     - proleptic Gregorian calendar: the Gregorian calendar extended before
       1582-10-15, as ISO-8601 requires
     - instant: a point in time
     - REJECTED: extended year (for an expanded representation) / timestamp (for
       an instant)
101. - nullary: of a form, or of a lowercase predicate letter other than `m`,
       followed by no success clause or block
     - non-nullary: of an uppercase predicate letter other than `M`, followed by
       a success clause or 1 or more blocks
     - unary match / binary match: `%m` (`<unary-match>`) / `%M`
       (`<binary-match>`), named by arity, because `%m`'s `<branches>` make it
       not nullary
     - REJECTED: concise / verbose (the letters have equal length) / bare / full
       / block (for letter case) / nullary match / non-nullary match
102. - success pipeline: a unary form's pipeline-only success clause
       (`<success-pipeline>`), e.g., `%I…+`'s
       ([defined](../Specs/fields-format.md#success--failure))
     - success clause: a `<success-block>` or a `<success-pipeline>`
       (`<success-clause>`), evaluated iff its enclosing matcher succeeds
     - fallible / infallible unconditional placeholder: an unconditional
       placeholder whose pipeline may / may not abort formatting, the latter of
       which an `<unconditional-block>` requires
       (`<fallible-unconditional-placeholder>` /
       `<infallible-unconditional-placeholder>`)
     - blocked / blockless: of a non-nullary success with / without a success
       block (`<non-nullary-scalar-blocked-success>` /
       `<non-nullary-scalar-blockless-success>`, e.g., `S` in `%S+none+`)
     - block leading text: the text that starts a `<block-template>`, which
       cannot start with a bare `.` (`<block-leading-text>`;
       [defined](../Specs/fields-format.md#success--failure))
     - named pipeline: a named format reference & any transforms after it
       (`<named-pipeline>`; [defined](../Specs/fields-format.md#pipelines))
     - string transform pipeline: the string transforms after a named format
       reference whose named format is unconditional, the 1st of which may take
       a `<coercion>` (`<string-transform-pipeline>`;
       [defined](../Specs/fields-format.md#transforms))
     - trimmable pipeline: a named pipeline or a `trimWhitespace` run
       (`<trimmable-pipeline>`; [defined](../Specs/fields-format.md#pipelines))
103. - member: 1 of a field's name / value pairs in an item, of which there may
       be multiple ([defined](../Specs/fields.md#members))
     - REJECTED: duplicate / instance / occurrence (for a member)
104. - option value: the rest of an option's command-line argument after `=`, or
       else the next command-line argument, iff it is `-` or does not start with
       `-` ([defined](../Specs/configs.md#option-values))
     - option value separator: the `=` or the command-line argument boundary
       between a long option & its value (`<option-value-separator>`; e.g., in
       `--fields=name` or `--fields name`)
     - command-line argument boundary: `_`, which matches between 2 adjacent
       command-line arguments, iff the latter is `-` or does not start with `-`
       ([defined](../Specs/ebnf.md#command-line-argument-boundaries))
     - valued option: an option that takes a value, defined as a
       `<valued-option>` ([defined](../Specs/configs.md#option-values))
     - flag: an option that takes no value (e.g., `--json`)
       ([defined](../Specs/configs.md#option-values))
     - usage: Swift Argument Parser's synopsis of a command's arguments (e.g.,
       `[--json | --json-config <json-config> | …]`)
     - REJECTED: option-argument / option-argument separator (the specs use
       "argument" for an argument list's elements)
105. - line terminator: a CRLF, or any other character from U+000A to U+000D,
       U+0085, U+2028, or U+2029
       ([defined](../Specs/configs.md#line-terminators))
     - newline: the LF that terminates an output line (e.g., after a JSON
       object)
     - REJECTED: line break / line ending / EOL (for a line terminator)
106. - negated: the form of a non-nullary branch with `<branch-negation>`
       (`-…`), whose `<failure-block>` is evaluated iff its matcher fails
       ([defined](../Specs/fields-format.md#success--failure))
     - non-negated: the form of a non-nullary branch without
       `<branch-negation>`, whose `<success-block>` is evaluated iff its matcher
       succeeds ([defined](../Specs/fields-format.md#success--failure))
107. - list: verb; an app lists each field that it knows before reading any
       input, while a fields config lists those & each field that a field name
       in its, or in an extended fields config's, `<fields-config>` names
       ([defined](../Specs/fields.md#unlisted-fields))
     - unlisted field: an item's field that the fields config does not list,
       output iff visible, per a default field spec without a position
       ([defined](../Specs/fields.md#unlisted-fields))
     - REJECTED: dynamic field / discovered field / unknown field (for an
       unlisted field)
108. - unpositioned field: a field without a position in the field order, which
       compares as less or greater than every positioned one: for
       `<document-order>`, the field of a field spec whose field an item lacks;
       for `<positional-order>`, a visible unlisted field
       ([defined](../Specs/fields.md#field-order))
     - REJECTED: absent field (for an unpositioned field)
109. - output config: a table, key-value, or JSON config
       ([defined](../Specs/configs.md#output-configs))
     - output config option: an output format's option that selects it with a
       config overlaid on its `default` config (e.g., `--json-config`)
       ([defined](../Specs/configs.md#output-configs))
     - output config syntax: the syntax of an output config kind's configs
       (e.g., `<json-config>`) ([defined](../Specs/configs.md#output-configs))
110. - preset: a named config of `<field-modifiers>`, which a
       `<preset-modifier>` attaches to a field spec
       ([defined](../Specs/fields.md#presets))
     - attach / detach: add a preset to, or remove one from, a field spec's list
       of presets, which sets its settings, or re-exposes the values that they
       overrode
     - preset list: a field spec's list of attached presets, which its
       `<preset-list>` sets
     - absolute presets / relative presets: a `<preset-list>` that replaces a
       field spec's attached presets / that applies `<preset-delta>`s to them
       (as an absolute config / a relative config does to a fields config)
     - preset delta: 1 preset's addition or removal in relative presets
     - preset clearing: a bare `%`, which detaches every preset
     - named format: a preset's format, which a `<named-format-reference>`
       references ([defined](../Specs/fields-format.md#named-formats))
     - format input: the value against which a format is evaluated, which `%i` /
       `%I` insert: for a field spec's format, the field value; for a named
       format, the value that its `<named-format-reference>` evaluates it
       against ([defined](../Specs/fields-format.md#success--failure))
     - REJECTED: named spec (the specs use "spec" for a `Specs/` document) /
       field style / template (for a preset)
111. - alignment: where a field spec's label & values are in its table output
       column (`start`, `centerStart`, `centerEnd`, or `end`;
       [defined](../Specs/fields.md#alignment))
     - align / aligned: verb & adjective
     - REJECTED: justification / justify / justified
112. - setting: a separate value of a field spec, per `(* inherited *)`
       nonterminal in `<field-modifiers>` & its alignment
       ([defined](../Specs/fields.md#field-modifiers)); of a fields config, per
       field spec setting & per `(* inherited *)` nonterminal in
       `<field-order-section>` & `<item-sort-section>`
       ([defined](../Specs/fields.md#inherited-values)); or of an output config,
       per `(* inherited *)` nonterminal in its kind's output config syntax
       ([defined](../Specs/configs.md#output-configs))
     - alternative: one of the alternatives of an output config setting's
       nonterminal, each starting with its own letter (e.g., `<header-off>`, as
       `h`; [defined](../Specs/configs.md#output-configs))
     - REJECTED: axis (for a setting)
113. - persistent: of a named config, built-in or custom, which no display
       command modifies ([defined](../Specs/configs.md#named-configs))
     - persist: verb; save a custom config
     - REJECTED: persisted (as an adjective for a config) / saved / stored
114. - C0 control character: a character from U+0000 to U+001F
     - DEL: U+007F
     - C1 control character: a character from U+0080 to U+009F
     - 7-bit equivalent: ECMA-48's 2-character representation of a C1 control
       character: an ESC followed by the character 64 code points below it
       (e.g., ESC `[` for U+009B)
     - Control Pictures symbol: the symbol in Unicode's Control Pictures block
       for a C0 control character or DEL (e.g., `␉` for a tab;
       [used](../Specs/table.md#table-config))
     - REJECTED: control code / control picture (for a Control Pictures symbol)
115. - reference fields config: a semi-mutable copy of the baseline fields
       config, whose field spec order is immutable, in which each removed field
       spec is replaced with `null`; each `<field-spec-reference>` index
       references its field specs
       ([defined](../Specs/fields.md#field-spec-references))
116. - digit group: a run of digits of a number's integer part, between each 2
       of which `numberFormat` inserts `<digit-group-separator>`
       ([defined](../Specs/fields-format.md#numberformat))
     - primary group: the least significant digit group, of `<digit-group-size>`
       digits
     - secondary group: each other digit group, of
       `<secondary-digit-group-size>` digits, or `<digit-group-size>` digits if
       that is `0`
     - base conventions: the conventions from which number format arguments
       default: those that `<locale-identifier>` identifies, else those of the
       system locale, the canonical conventions, or `<locale>`'s, depending on
       the argument list ([defined](../Specs/fields-format.md#numberformat))
117. - abort: verb; of formatting, make the formatted value absent, ignoring the
       rest of `<format-block>`
       ([defined](../Specs/fields-format.md#success--failure))
118. - coerced value: the value, at a matcher's type, that `<coercion>` parses
       from a value, replacing the input
       ([defined](../Specs/fields-format.md#coercion))
     - matched value: the value against which a matcher is evaluated, as its
       coerced value iff it coerces
       ([defined](../Specs/fields-format.md#success--failure))
     - default coercion: a `<coercion>` without arguments
       ([defined](../Specs/fields-format.md#value-types))
     - implicit coercion: what coerces a field value, absent a `<coercion>`, to
       a type unsupported by its input format, iff a default coercion would
       ([defined](../Specs/fields-format.md#value-types))
     - support: of an input format, can have field values of a type; of an
       output format, can render a value at a type
       ([defined](../Specs/fields-format.md#value-types))
     - string coercion: a `<coercion>` to a string (e.g., in `%.s`), which
       matches every value except a `null` or an absent one
       ([defined](../Specs/fields-format.md#coercion))
     - trivia: the text around the number that a number coercion allows
       ([defined](../Specs/fields-format.md#coercion))
     - trivia prefix / trivia suffix: the trivia before / after the number
119. - version: 1 or more `.`-separated components, each an ASCII digit followed
       by any Unicode general category `L` or `N` characters, `+`s & `-`s (e.g.,
       `1.2.3-beta`; [defined](../Specs/fields-format.md#version-formatting));
       also the type of a version value (`%v`'s output type)
     - version fields: `minimumOSVersion`, `newVersion` & `version`
       ([defined](../Specs/mas.md#default-sort-options))
120. - App Store locale: the locale of the App Store region that mas guesses
       from the macOS region, because the App Store's locale cannot be
       determined programmatically ([defined](../Specs/mas.md#price-sorting))
121. - display command: a command whose primary function is to display data
       ([defined](../Specs/configs.md#display-commands))
     - command list: the list of commands in the command line from root to leaf
       (the command that actually runs)
       ([defined](../Specs/configs.md#command-lists))
     - alias: another name of a command, which never names a context (e.g.,
       `info` for `lookup`; [used](../Specs/configs.md#contexts))
122. - metavariable: a word of uppercase letters, digits & `_` that starts with
       an uppercase letter & stands for an expression or text in the
       meta-grammar ([defined](../Specs/ebnf.md#meta-grammar))
     - constant expression / variable expression: an expression that consumes
       text that evaluates to invariant text / variable text
       ([defined](../Specs/ebnf.md#constant-vs-variable-expressions))
     - bare token: a token of only bare characters
       ([defined](../Specs/ebnf.md#tokens))
123. - inherent scalar / inherent repetition / inherent tuple: of an expression
       each of whose occurrences is a scalar / a repetition / a tuple
       ([defined](../Specs/ebnf.md#multiplicity))
     - content-dependent / context-dependent: of an expression each of whose
       occurrences has its content's multiplicity / the multiplicity that its
       context requires ([defined](../Specs/ebnf.md#multiplicity))
124. - outer bare whitespace: bare whitespace immediately before the 1st, or
       after the last, character that a literal or name token consumes, or
       non-bare-whitespace character that a variable token consumes; also all of
       a variable token without such a character
       ([defined](../Specs/ebnf.md#outer-bare-whitespace))
     - inner bare whitespace: bare whitespace between a token's 1st & last
       non-bare-whitespace characters
       ([defined](../Specs/ebnf.md#character-consumption))
     - defer: of a side of an expression, to let an adjacent side override its
       outer bare whitespace treatment (`~`;
       [defined](../Specs/ebnf.md#outer-bare-whitespace-treatment))
125. - presence state: present, transitively absent, or directly absent
       ([defined](../Specs/ebnf.md#presence-states))
     - directly absent: not present, but not transitively absent (e.g.,
       `<label>` in `name=`)
     - transitively absent: of an expression an ancestor of which is absent, or
       that no consumed token matches as an alternative of a present choice or
       as an element of a present repetition
126. - semantic comment: a comment part that matches a semantic comment format
       ([defined](../Specs/ebnf.md#semantic-comments))
     - mnemonic comment: a comment part that explains how a nonterminal's
       literal was chosen ([defined](../Specs/ebnf.md#mnemonic-comments))
     - non-structural: of a nonterminal that comments and/or prose reference,
       but no structural definition does
       ([defined](../Specs/ebnf.md#non-structural-comments))
     - implicit default: the value of an expression to which no explicit default
       applies ([defined](../Specs/ebnf.md#explicit--implicit-defaults))
     - global default: an expression's applicable self default, else its
       applicable implicit default ([defined](../Specs/ebnf.md#global-defaults))
127. - matcher: a placeholder's or branch's `<placeholder-prefix>`, modifiers &
       predicate (`<matcher>`), which succeeds iff it matches the value against
       which it is evaluated
       ([defined](../Specs/fields-format.md#success--failure))
     - abort-on-failure / abort-on-success: the form of a matcher with
       `<abort-on-failure>` / `<abort-on-success>`, which aborts formatting iff
       the matcher fails / succeeds
     - boundary group: a `<boundary-group>`'s boundaries, which share 1 sort
       precedence ([defined](../Specs/fields.md#sort-boundaries))
128. - named config: a config that has a name, unique for its kind within a
       context ([defined](../Specs/configs.md#named-configs))
     - named fields config: a named config of the fields kind
       ([defined](../Specs/fields.md#named-fields-configs))
     - config kind: a hierarchy among which a config is looked up, referenced &
       extended (e.g., fields configs)
       ([defined](../Specs/configs.md#config-kinds))
     - context stack: a command list's contexts, from most to least specific
       ([defined](../Specs/configs.md#context-stacks))
129. - base fields config: the named fields config that a command line
       references or implicitly selects
       ([defined](../Specs/fields.md#base-fields-config))
     - working fields config: a mutable copy of the fields config that a
       `<fields-config>` extends, as modified by it so far
       ([defined](../Specs/fields.md#working-fields-config))
     - baseline fields config: an immutable snapshot of the working fields
       config immediately before `<field-spec-edits-section>`
       ([defined](../Specs/fields.md#baseline-fields-config))
     - resolved fields config: the working fields config after the command line
       has been parsed, which is used to render output
       ([defined](../Specs/fields.md#resolved-fields-config))
130. - sort key: a field spec with an enabled `<sort>`
       ([defined](../Specs/fields.md#sorting))
     - run of non-boundary text: a maximal sequence of segments between
       boundaries ([defined](../Specs/fields.md#sort-segments))
     - grouped number: a number segment of `<grouped-numeric>`, which compares
       as a single number ([defined](../Specs/fields.md#sort-number-segments))
