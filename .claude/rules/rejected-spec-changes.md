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
