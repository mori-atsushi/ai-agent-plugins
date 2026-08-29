# Perspective: Simplify

Find code that can be simpler without losing clarity or correctness. Prefer structural
changes that reduce maintenance work. Do not chase micro-optimizations.

Stay within one scope. Leave cross-module extraction, naming, and responsibility
splits to design. This perspective evaluates local duplication and complexity only.

## Required state

- **Repeated local computation or conditions have one function or property** when the
  extraction preserves clarity.
- **Code uses an existing Kotlin, Android, imported-library, or named project utility
  when it already expresses the operation.** Examples include `chunked`, `groupBy`,
  `fold`, and `mapNotNull`.
- **Unreachable and unused functions, properties, parameters, imports, and branches
  are removed.**
- **Every abstraction provides a current benefit.** An interface or wrapper with one
  use needs a reason to exist; remove an uncalled capability rather than renaming it.
- **Null checks and casts add information the type system cannot already prove.**

## What NOT to flag

- Style differences that don't reduce complexity
- Minor naming suggestions
- Things that are verbose by convention (e.g., explicit type annotations on public
  API surfaces)
