# Project Guidelines

## Purpose & Scope

This file & the rule files that it links in `.claude/rules` are the canonical
source of project conventions for humans & agents. Each rule file applies only
to the files that its `paths` front matter matches, so Claude loads it only when
working on them. Read this file before making repository changes, and read each
applicable rule file before changing a matching file.

Record each convention that a change settles in this file or in the applicable
rule file, in the same change.

## Minimum Versions

- **Swift:** 6.4
- **Xcode:** 27
- **macOS:** 15

## Quick Entry Points

- `Scripts/bootstrap`
- `Scripts/format`
- `Scripts/lint`, with flags:
  - `-A`: skip SwiftLint Analyzer rules.
  - `-L`: skip Layout linting.
  - `-V`: skip Vale prose linting.
- `Scripts/build` (debug)
- `Scripts/build '' -c release` (release)
- `Scripts/test`
- `Scripts/package`

## Git Workflow

- `main` is the trunk
- Branch topics from `main`
- Before committing:
  1. Add or edit tests for all new or changed behavior
  2. Repeatedly run `Scripts/format` until no modifications are made, reviewing
     each run's modifications before the next run (each run stops after the 1st
     tool that modifies any file, so that no 2 tools modify files in the same
     run)
  3. Repeatedly run `Scripts/lint` & fix all violations until no violations are
     reported (to conserve tokens & to save time, agents should run
     `Scripts/lint -A` instead)
  4. Run `Scripts/build` & `Scripts/test`, fixing every failure
  5. Manually check rules that linters do not enforce: Oxford commas; `second` &
     adjective `one` written as digits; & judgment-based rules (e.g., 1 `return`
     per function, `if` / `switch` expressions)
- **Commit messages:** Follow [commit message conventions](
    https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
  ), except end each subject line with a period (or with a colon iff the subject
  introduces a list)
- Sign off every commit (`git commit -s`)
- Tag releases as `vX.Y.Z`

## File Naming

Give each file the longest standard extension for its file type that works for
its purpose (e.g., `.swiftlint.yml` works but `.swiftlint.yaml` does not, so the
former is chosen, while `ci.yaml` & `ci.yml` both work, so the former is
chosen), except always use `.md` for Markdown.

## Content Formatting

- **Newlines:** Unix (i.e., `\n`)
- **Indentation:** Tabs (2 characters wide) for all files unless otherwise
  specified; 2 spaces for YAML; 1 space for Markdown
- **Max line length:** 120 characters for all files unless otherwise specified;
  unlimited for header, JSON & swiftformat. Tabs count as 2 characters each; the
  trailing newline does not count. Fill each line up to the limit before
  wrapping
  - **Markdown:** 80 characters
  - **Swift comments:** 80 characters for a comment-only line (`///` DocC or
    `//`) of prose. Code always sets its line's max to 120, even with a trailing
    comment (i.e., any non-whitespace before the comment overrides the
    80-character limit). A comment-only line that is a linter / formatter marker
    (e.g., `// swiftformat:disable:next indent`) rather than prose also wraps at
    120
- **Unnecessary trailing whitespace:** Remove
- **File ends:** Single newline
- **Quoting:** Quote strings only when necessary, preferring the most literal
  format that works over more interpreted formats; if multiple quote syntaxes
  are functionally equivalent, prefer the visually lightest, e.g., prefer single
  quotes over double quotes if they are functionally equivalent
- **Comment periods:** End each sentence of a DocC (`///`) comment with a
  period; omit the period from the end of an ordinary (`//`) comment
- **Text:** Applies to all prose, wherever it appears: Swift, zsh, GHA
  workflows, etc. comments & string; Markdown & other markup; commit messages;
  documentation; & so on:
  - **Commas:** Use Oxford commas for lists
  - **Ampersands:** Prefer `&` to `and` (omit Oxford comma before `&`)
  - **Exceptions:** `and` should be used in `and/or` & after a comma that
    separates distinct clauses (but not in a list)
  - **Quotes**: The enclosing quotations marks of a quote at the end of a
    sentence (iff the whole sentence is not a quote) should not enclose the
    terminal punctuation mark of the encompassing sentence
  - **Iff**: Use `iff` as `if & only if`
  - **Slashes:** Pad a `/` joining 2 words / terms with spaces on both sides
    (e.g., `field-order / item-sort`, `format- / type-defaulted`), except
    `and/or` (never `&/or`); do not pad slashes in file paths, URLs, or literal
    characters
  - **Word choice:** Avoid `curate` / `curated` / `curation`; prefer `select`,
    `handle`, etc.
  - **Output formats:** Name an output format in prose as table, key-value, or
    JSON (e.g., `JSON output`), never as a code span (e.g., not `json` output),
    except as an output format suffix (e.g., `@json`)
  - **Em dashes:** Do not use em dashes, except in `CODE_OF_CONDUCT.md`
  - **Contractions:** Never use contractions (e.g., write `it is`, not `it's`;
    `do not`, not `don't`), not even in test data (e.g., App Store data in test
    fixtures)
  - **Numbers:** Write numbers as digits (e.g., `at most 1`, `3 kinds`, `1st`),
    except the pronoun `one` (e.g., `the last one wins`)
  - `e.g.` & `i.e.` should always be immediately followed by a punctuation,
    e.g., `,` or `:`

### Markdown Guidelines

- **Style:** GitHub-Flavored Markdown (GFM), ATX headings, backtick-fenced code
  blocks with language identifier, underscore emphasis, asterisk strong & hyphen
  bullets
- **HTML:** Limit to HTML supported by GFM that does not have a native GFM
  equivalent
- **Scope:** Also governs Markdown written inside DocC (`///`) comments in Swift
  source, not just `.md` files
- **Tables:** Align pipes; pad each column to its longest cell (excluding the
  delimiter row) plus 1 space on each side
- **Wide blocks:** Measuring width as for max line length, surround each table
  whose widest line is wider than 80 characters & each fenced block whose widest
  line is 81 to 160 characters wide with `<!--editorconfig-checker-disable-->` &
  `<!--markdownlint-disable line-length-->` lines before it &
  `<!--markdownlint-enable line-length-->` &
  `<!--editorconfig-checker-enable-->` lines after it; surround no other table
  or fenced block with them; split each fenced block line wider than 160
  characters into lines no wider than 160 characters
- **Inline wrapping:** Fill emphasis, strong, strikethrough, link text & image
  alt text like other prose; never split a code span, URL, or inline HTML tag
  across lines: if one does not fit on the current line, move it whole to the
  next line, even if that line then exceeds the max line length
- **Links:** Fill link text like other prose. If a URL does not fit on a line,
  end the line with `](`, put the URL on its own line, indented 2 spaces deeper
  than the text's continuation lines, then put `)` on the next line at the
  continuation lines' indentation
- **Cross-references:** Link a referenced file from relevant inline text, never
  from the file's name (a word naming a general concept, e.g., `README`, is not
  a file name, even if a file is named after it); reference a section only via a
  link whose URL fragment targets it, never by naming the section in text,
  except in a code comment, which cannot hold a link, so it names the file &
  quotes the section's heading (e.g., `Temp/todo.md "Sorting"`)

## Specs

`Specs/*.md` define mas's option syntaxes & semantics. Whenever a spec changes,
make every other file (code, tests, docs, completions, `Temp/`, etc.) consistent
with it.

Follow the [spec grammar rules](.claude/rules/specs.md) in specs.

Keep all prose about input (in specs, code comments, `Temp/*`, etc.)
input-format agnostic (e.g., "a number", not "a JSON number"; "as a string", not
"as its JSON text"), since input need not be JSON.

## Temp Files

`Temp/*` track in-progress work: `Temp/progress.md` (implementation status &
history), `Temp/todo.md` (open issues & questions) & `Temp/terms.md` (standard
terminology). Whenever any change (to specs, code, tests, docs, etc.) affects
anything a `Temp/*` file says, update every affected `Temp/*` file in the same
change, so that each:

- Uses only the current specs' nonterminal names & syntax, and the code's
  current identifiers, never vestigial ones.
- Describes the current implementation state accurately.
- Omits issues that the change resolves & includes issues that it raises but
  does not resolve.

Add each term that a change introduces to `Temp/terms.md` in the same change. A
term that `Temp/terms.md` rejects may still be used for a use case that no
existing term covers; document that use case in `Temp/terms.md`.

## Refactoring Rules

Unless absolutely necessary for functionality or fixes, or unless violations of
standards are discovered, do not:

- reformat
- rename
- reorder
- respace
- reword
- remove comments
- refactor if it worsens the caller interface

Refactoring should:

- Keep clean abstractions
- Inline a utility iff it is single-use
- Replace a utility iff the new version is more correct, performant, and/or
  simpler than the existing version, in descending order of priority

Apply every rename throughout the repository (specs, `Temp/*`, code identifiers,
comments, tests, docs, etc.), including to every name derived from the renamed
one (e.g., renaming a type renames the nonterminals, block kinds & identifiers
named after it), so that everything remains consistent.

## Scripting

Follow the [scripting rules](.claude/rules/scripting.md) in scripts & GHA
workflows.

## Swift

mas is a SwiftPM project that uses Swift Argument Parser to interact with the
command-line. Follow the [Swift rules](.claude/rules/swift.md) in Swift source.
