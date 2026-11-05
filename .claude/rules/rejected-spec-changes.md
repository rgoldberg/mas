---
paths:
  - Specs/**
---

# Rejected Spec Changes

Each rule below forbids a rejected spec change & gives the reason for rejecting
it, in the form "In specs, never …, because …".

When a rejection is overruled, rewrite its rule to forbid reverting the
overruling change, giving both the overruling reason & the overruled one (e.g.,
"In specs, never …, because …, which outweighs the overruled reason for
rejecting it: …").

When an overruling is declined, add its argument & the reason for declining it
to the rule.

Record a spec change deferred to a later version in `Temp/todo.md`, never here,
because it is not rejected.

In specs, never make an effective `<all-conforming>` in a
`<field-order-adjustment-set>` that is per `<positional-order-option-set>` or
`<document-order-option-set>` a no-op, nor make `<all-conforming>` a
`<non-adjustment-sort-option>` (so that `@none/k` sorts fields by label),
because each silently accepts text that cannot express what was meant, while an
error reports it.

In specs, never make an overridden `<all-conforming>` an error (e.g., `@x/ka` if
`x` has `/P`), because a later alternative's override means that it cannot
affect what the set means, so `/ka` clearly expresses `a`, which outweighs the
overruled reason for rejecting its allowance: it silently accepts text that
cannot express what was meant.

In specs, never forbid a repeated `<disabled-sort-prefix>` (e.g., `005`) or a
repeated `<disable-all-sorts>` (e.g., `//00`), because each is redundant, not
contradictory.

In specs, never forbid an empty `<field-spec-edits-section>` (e.g., `@x.`),
because it is redundant, not contradictory, and it lets a script append edits
that may be empty to a `<field-spec-edits-section-prefix>`.

In specs, never forbid a `<chronologic-formats>` whose formats overlap (e.g.,
`Ciso,iso:` or `Ciso,iso-date:`), because each is redundant, not contradictory,
and detecting the overlap depends on what each format matches, not on the
syntax.

In specs, never allow a `<match-placeholder>` with only 1 branch (e.g.,
`%mN.round++` or `%MN.round++none+`), because it means what its branch's own
placeholder means (e.g., `%+N.round+` or `%N.round+none+`), so its `%m` or `%M`
cannot affect what it means.

In specs, never allow `<abort-on-failure>` on a nullary conditional placeholder
or on an unconditional placeholder (e.g., `%+s` or `%+I.uppercase+`), because
the former already aborts on failure & the latter's matcher cannot fail, so it
cannot affect what either means.

In specs, never make `<styled-key>`'s `<style-specifier>` optional (e.g., `K:`),
because `K:` would style keys by nothing, which contradicts `K` & means what `k`
means, while `<header-on>`'s is optional because `H:` (an unstyled header row)
means something other than `h` (no header row).

In specs, never let a non-nullary unconditional placeholder take an empty
pipeline or a template block (e.g., `%I+` or `%I(%i)+`), because `%I+` always
outputs an empty string & `%I(%i)+` means what `(%i)` means, so its `%I` cannot
affect what it means.

In specs, never allow a binary placeholder whose `<success-block>` &
`<failure-block>` are both absent (e.g., `%S++`), because it always inserts an
empty string, so its matcher cannot affect what it means.

In specs, never remove a typed terminal subtype merely because no syntax uses it
(e.g., `boolean`, `number`, or `time-only`), because each mirrors a value type
(e.g., `%b`'s boolean), so a future syntax can use it without extending the
grammar, while being unused alone does not make it worth removing.

In specs, never forbid a tab or a line terminator in an output config payload
(e.g., `$'L\t:'` while `F` is effective, `$'F.\t:'`, `$'S-\t:'`, `$'O\t:'` while
`K` & `F` are effective, or `$'L\n:'`), unless it would make the output invalid
in its output format, because it means what it says, and its output shows any
misalignment or line split that it causes, while forbidding it needs a special
rule per payload.

In specs, never allow a line terminator other than an LF or a CR in
`<indentation>` (e.g., `$'P\f:'`), because it is not JSON whitespace, so the
output would not be JSON, which outweighs the overruled reason for rejecting its
forbidding: it means what it says.

In specs, never allow an empty `<field-order-section>` (e.g., `@x/`), because,
unlike an empty `<item-sort-section>` or `<field-spec-edits-section>`, nothing
can follow it reliably: `@x///0` would consume `//`, the longest candidate
literal, leaving `/0`, which is an error, so generated syntax that appends a
section to it would still fail.

In specs, never allow a `<coercion>` on a call whose value's type equals its
input type, unless a `<named-format-reference>` immediately precedes it (e.g.,
`.round..round` or `%S..uppercase++`), because it cannot affect what the call
means, nor require one on a call whose types match (e.g.,
`.numberFormat.uppercase`), because it would add nothing.

In specs, never let an `<unconditional-block>` take a `<coercion>` that can fail
(e.g., `%S.uppercase+%L..round++` or
`%S.uppercase+%I..trimWhitespace..round++`), because a `<failure-block>` must
never abort, nor forbid one in a `<format-template>` or a `<conditional-block>`
(e.g., `%L..round+`), because no matcher can otherwise coerce a label, a name,
or a format input that it cannot match.

In specs, never allow a `<coercion>` from a date or a time-only to anything but
a string, nor from a number or a version to a time-only (e.g.,
`.dateOnly..timeOnlyTimeZone:UTC:`, `%.D..round++`, or
`%N..timeOnlyTimeZone:UTC:++`), because its rendering is not a value of that
type, so it would abort, while a pipeline that means to parse it can coerce it
to a string 1st.

In specs, never let a `<coercion>` or an argument choose whether `scale` reports
an error or aborts formatting for a value that it cannot render (e.g.,
`.scale:0,,0:` for `1e100`), because that value is a number, so no coercion
affects it, while an argument would add syntax for a value that almost never
occurs, and an aborted value shows its effect without failing other items.

In specs, never make a value need a `<coercion>` to match a predicate, or to
conform to an input type, whose type its input format does not support (e.g.,
`%d`, `%c`, or `.dateOnly` for `"2020-03-18"`, or `%v` for `"1.2.3"`, for JSON
input), because such syntax could otherwise never succeed without a
`<coercion>`, which outweighs the overruled reason for rejecting its allowance:
a `<coercion>` would then coerce nothing, so it would only choose between an
error & an abort.

In specs, never implicitly coerce a value to a type that its input format
supports (e.g., `%n` for `"5"`, or `%b` for `"true"`, for JSON input), because
the value then has its own type, so an implicit coercion would misread it.

In specs, never let `timeZone` follow `dateOnly`, nor a `<coercion>` to a date
whose only `<date-format>` is `<iso-date>`, nor a `<coercion>` of a version to a
date without `<unix-time>` (e.g., `.dateOnly.timeZone:UTC:`,
`%.:iso-date:D.timeZone:UTC:+-+`, or `%.V..:iso:timeZone:UTC:+-+`), because its
value is a date-only, which no time zone affects.

In specs, never let `dateOnly` start the pipeline of a matcher's
`<date-only-coercion>` (e.g., `%.:iso-date:D.dateOnly+-+`), because that value
is already a date-only, so `dateOnly` cannot affect what it means.

In specs, never let a call whose input is a version take a `<coercion>` to a
date whose only `<date-format>` is `<iso-datetime>` (e.g.,
`%.V..:iso-datetime:dateOnly+-+`), because a version has no `:`, so it is never
a datetime, so the coercion can only abort.

In specs, never let a number coercion normalize its coerced value's text,
whether only for a string (e.g., `%.n` giving `1.5` for `"1.50"`, but `1.50` for
the number `1.50`) or for every number (e.g., `%.n` giving `1.5` for both),
because it loses text that a format may mean to output, while only an output
format's syntax requires a modified number, so that output format modifies it
only as necessary when rendering it (e.g., JSON output renders `+01.50` as
`1.50`).

In specs, never let a `<coercion>` to a time-only take a list of formats (e.g.,
`%.:iso-time:c`), because a time-only has only 1 ISO-8601 format, so a list
cannot affect what it means.

In specs, never add a transform that only coerces a value's type (e.g., `toDate`
in `.toDate.dateOnly`, or `toNumber` in `.toNumber:de:.round`), because a
matcher must still coerce before any pipeline runs (e.g., `%.N`), so it would
add a 2nd syntax for 1 concept, while a `<coercion>` already coerces without any
other transform (e.g., `%.n`), and it would lengthen even the simplest pipeline
(e.g., `.toString.uppercase` instead of `..uppercase`).

In specs, never let a default coercion or an implicit coercion to a date accept
a decimal number (e.g., `%.d` or `%d` for `"1.2"`), because a string that holds
a number is rarely a time, so it would match a value that a later branch (e.g.,
`%m.ds+`) means to match.

In specs, never make a number need `<unix-time>` for a default coercion or an
implicit coercion to a date (e.g., `%.d`, `%d`, or `.dateOnly` for `0`), because
a number has no other meaning as a date, while a branch that means to match a
number can precede it or follow a coercion that omits `<unix-time>` (e.g.,
`%mn.d+` or `%m.:iso:d.n+`), which outweighs the overruled reason for rejecting
its allowance: a number is rarely a time, so it would match a value that a later
branch (e.g., `%m.d.n+`) means to match.
