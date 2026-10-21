---
paths:
  - '**/*.swift'
---

# Swift

Every rule enabled in `.swiftlint.yml` & `.swiftformat` is an official project
rule, whether or not it is also specified in this document.

## Apple Private Frameworks

The `PrivateFrameworks` SwiftPM target exposes the following Apple private
frameworks (via Objective-C headers extracted from the DSC) to deploy App Store
apps:

- **CommerceKit:** Controllers
- **StoreFoundation:** Models

Use private frameworks only when public APIs are insufficient.

Newer Apple private frameworks (e.g., AppStoreDaemon & AppleMediaServices) seem
to supersede the currently used ones, but the newer ones seem usable only by
code with Apple-exclusive entitlements.

## Swift Source Folder Hierarchy

Swift source is organized in subfolders of `Sources/mas`:

- **Commands:** CLI implementation
- **Models:** Data types & suppliers
- **Utilities:** Utilities

## Command Implementation Patterns

Commands follow a consistent structure:

- Commands are nested structs within the `MAS` main command
- Use `@OptionGroup` to compose reusable argument sets from dedicated types that
  conform to `ParsableArguments`
- Never rewrite command-line arguments before Swift Argument Parser parses them;
  rely on its normal parsing, reporting invalid combinations in `validate()`
- Implement `func run() async { … }` as the main command entry point
- Use the static `MAS.printer` for all output to ensure consistent formatting
- Call methods on `AppStoreAction` enum cases (accessible via the `AppStore`
  typealias) to execute business logic, e.g., `await AppStore.install.apps(…)`

## Style Essentials

- Name most function parameters
- Omit a type annotation anywhere it adds nothing beyond what inference could
  determine: binding declarations (`let x = f()`, not `let x: T = f()`), closure
  parameters & closure return types (`{ x in … }`, not `{ x -> T in … }`)
- Capitalize acronym & initialism characters consistently (e.g., `ADAM`, `API`,
  `HTTPRequest`, `JSON`)
- Shadow variables if the respective original will no longer be used
- Strongify weak references instead of evaluating them multiple times
- Group computed properties below stored properties
- Initialize a `let` / `var` from an `if` / `switch` **expression** rather than
  declaring it, then assigning it separately in each branch
- Name an unused parameter `_`, keeping any external label (e.g.,
  `name _: String`); add a `// TODO:` comment if it is only temporarily unused
- 1 `enum` case per line (not `case a, b, c`); order `enum` & `switch` cases
  alphabetically unless grouped by shared behavior, in which case disable the
  applicable rule inline (e.g., `// swiftformat:disable:this sortSwitchCases`)
- Avoid extra / redundant comparisons or operations whose result is already
  known statically; substitute the known result directly rather than re-deriving
  it via an unnecessary runtime operation
- Prefer 1 `return` per function / closure over multiple; condense multiple
  `return`s into a single trailing expression (e.g., an `if` / `switch`
  **expression**) wherever feasible
- Give each protocol conformance that requires explicit implementation (e.g.,
  `CustomStringConvertible`) its own `extension X: Protocol { … }`, separate
  from `X`'s primary declaration (which lists only protocols needing no explicit
  implementation, e.g., `Equatable`); similarly, split a large type's members
  into separate `extension X { … }` blocks by logical grouping, each labeled by
  a `// MARK: …` comment above the extension, rather than by sub-`MARK`s inside
  1 big type body
- Avoid optional collections (`[X]?`); use an empty collection unless `nil`
  carries meaning distinct from empty, in which case silence
  `discouraged_optional_collection` locally with a comment explaining why
- Suffix a `Set`-typed value's name with `Set` (e.g., `terminatorSet`,
  `nameSet`) to distinguish it from an `Array` / other `Sequence`
- Prefer `Self` to spelling out the enclosing type's own name
- Reference a same-named top-level symbol from another module with
  `Module::symbol` (not `Module.symbol`), but only when needed to disambiguate
  it from an instance / extension member found via lookup in the current scope
  (e.g., `Swift::max(...)`, not `Swift.max(...)`)
- Do not preemptively add `// swiftlint:disable` / `// swiftformat:disable`
  comments; add them only after `Scripts/lint` / `Scripts/format` actually flags
  the line, using the exact rule name reported. Prefer, in descending order:
  1. Applying an ignore comment only to the line(s) that actually need it
  2. Appending it to an existing line of code rather than inserting a
     comment-only line, iff that does not itself cause a new violation (e.g., a
     line-length violation)
  3. Using as few ignore comments as possible: ignore individual lines (subject
     to 1 & 2 above) iff only 1 or 2 contiguous lines need the same ignore; use
     a `disable` / `enable` block instead once 3 or more contiguous lines need
     it
  4. Preferring a `:this` ignore comment; if it does not fit, prefer `:next`,
     then `:previous`. If a SwiftLint comment & a SwiftFormat comment must both
     apply to the same line, put SwiftLint's comment on the earlier line &
     SwiftFormat's on the later line unless fitting both without a line-length
     violation or a comment-only line requires reversing that order
- Do not dismiss unimplemented / incomplete work with a bare comment (e.g., "out
  of scope", "not implemented"); write a `// TODO:` comment with actual
  instructions for what fixing / implementing it would involve

## Code Preference Hierarchies

Each subsection contains code preferences in descending order.

Within this section & all subsections, `X` is a placeholder for any type name.

### Naming

1. Standardized name
2. Concise name
3. Verbose name

### Concision / Verbosity

1. Concise code, e.g.:
   - Optional binding shorthand (e.g., `if let x { … }`, not
     `if let x = x{ … }`)
2. Verbose code

### Architecture

1. Composition
2. Protocol conformance
3. Class inheritance

### Typing

1. Inferred type, e.g.:
   - `var a = [X]()`
   - `var o = X?.none`
   - `var c: X { .init() }`
   - `f(array: .init())`
   - `f(dictionary: .init())`
   - `xs.map { x in x.y }`
   - `[("a", X.y), ("b", .z)]` (in a collection literal lacking a contextual
     type, qualify only the 1st element's members that inference needs)
   - `[X?.some(.y), .z, nil]`
2. Cast type, e.g.:
   - `var a = [] as [X]`
   - `var o = nil as X?`
   - `[("a", .y), ("b", .z)] as [(String, X)]`
3. Explicit type, e.g.:
   - `var a: [X] = .init()`
   - `var o: X? = nil`
   - `var c: X { X() }`
   - `f(array: [])`
   - `f(dictionary: [:])`
   - `xs.map { x -> Y in x.y }`

### Functional

1. Functional
2. Non-functional

### Value Inlining / Binding

1. Inlined single-use value
2. `let` multiple-use value
3. `var` multiple-use value

### Code Inlining / Reuse

1. Inlined single-use code (unless inlined code is much more complex)
2. Computed property
3. Function

### Optional Handling

1. Nil-coalescing operator (`??`)
2. Ternary operator
3. `Optional.map(_:)` / `Optional.flatMap(_:)`
4. Single `guard`
5. `if` / `else` (no `else if`)
6. `switch`
7. Multiple `guard`
8. `if` / `else if`… / `else`
9. `preconditionFailure(_:file:line:)`
10. Forced unwrapping (`!` suffix)
11. `fatalError(_:file:line:)`

### Throwing

1. Typed throws (`throws(ErrorType)`)
2. Untyped rethrows (`rethrows`)
3. Untyped throws (`throws`)

### Code Reuse

1. Framework / library call
2. Custom code

### Constants

1. Global `let`
2. `enum` `static let`
3. `struct` `static let`
4. `class` `static let`

### Preferred Types

1. Unaliased infrequent tuple / closure
2. Type-aliased frequent tuple / closure
3. `enum`
4. `struct`
5. `actor`
6. `final class`
7. `class`

### Type Syntax

1. Concision:
   - Generics: `<T: X>`
   - Optional: `X?`
   - Collection: `[X]`
   - Dictionary: `[X:X]`
2. Verbosity:
   - Generics: `where T: X`
   - Optional: `Optional<X>`
   - Collection: `Array<X>`
   - Dictionary: `Dictionary<X, X>`

### Generics

1. `some X` (a parameter used only once, with no need to name its type)
2. `<T: X>` (a named generic parameter, e.g., reused across multiple parameters,
   or referenced in the return type)
3. `where T: X`

### Void Types

1. `Void` instead of `()`.

### Closure Syntax

1. Trailing closure
2. Inline closure

### Closure Arguments

1. Shorthand argument names (e.g., `$0`) iff 1-line closure
2. Explicit argument names for multi-line closure

### Functional Arguments

1. KeyPath
2. Function reference
3. Closure

### Strict Memory Safety

1. Memory-safe code (i.e., not `unsafe`)
2. `unsafe` code iff a memory-safe alternative:
   - Is not available from frameworks / libraries
   - Is too difficult to implement properly & performantly

### Line Wrapping

1. Move an over-long value onto a new line as a whole (disabling the formatter's
   indent adjustment locally if needed), keeping the value itself intact
2. Split the value's own internal structure (e.g., a collection literal's
   brackets & elements) across multiple lines

### Nested Scopes

1. Open only 1 unclosed scope per line
2. Close only 1 scope opened on a previous line per line

## Testing Requirements

- Add or edit tests for all new or changed behavior
- Implement in [Swift Testing](https://github.com/swiftlang/swift-testing)
- Derive test file paths from source file paths:
  - replace the `Sources/mas` source path folder prefix with `Tests/MASTests`
  - prepend `MASTests+` to the source file name
  - e.g., `Sources/mas/Commands/X.swift` ⇒
    `Tests/MASTests/Commands/MASTests+X.swift`
- Use force unwrapping in tests where appropriate
