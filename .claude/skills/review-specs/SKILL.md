---
name: review-specs
description: Review the specs & Temp/* for problems.
disable-model-invocation: true
---

# Review Specs

1. Read every file in `Specs/` & `Temp/`, the [spec grammar
   rules](../../rules/specs.md) & the [rejected spec
   changes](../../rules/rejected-spec-changes.md).
2. Report every problem in them, e.g.: typos, incorrectness, inconsistencies,
   clarity problems, missing functionality & overly complex functionality,
   weighing each fix against the rejected spec changes.
3. Report each fix that would overrule a rejected spec change, with the argument
   for overruling it, in its own section after every other problem.
4. Record each rejected fix, each overruling & each declined overruling in the
   rejected spec changes.
