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

In specs, never make `<all-conforming>` in a `<field-order-adjustment-set>` that
is per `<positional-order-option-set>` or `<document-order-option-set>` a no-op,
nor make `<all-conforming>` a `<non-adjustment-sort-option>` (so that `@none/k`
sorts fields by label), because each silently accepts text that cannot express
what was meant, while an error reports it.

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
the former already aborts on failure & the latter cannot fail, so it cannot
affect what either means.

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
`K` & `F` are effective, or `$'L\n:'`), because it means what it says, and its
output shows any misalignment or line split that it causes, while forbidding it
needs a special rule per payload.
