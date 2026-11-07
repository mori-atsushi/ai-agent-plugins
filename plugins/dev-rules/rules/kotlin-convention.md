---
description: Kotlin idioms — named arguments, val, function form, null checks, Boolean names, @property docs, and file and nested-class layout
perspectives:
  - readability
paths:
  - "**/*.{kt,kts}"
---

# Kotlin Conventions

## Call sites

- [KC-1] **Swappable same-typed arguments are named.** Use named arguments when a reader
  could swap two or more positional values of the same type. Obvious conventions
  such as `Offset(x, y)` stay positional.

## Values and functions

- [KC-2] **A value without reassignment is a `val`.**
- [KC-3] **A function declares its return type**, except a block-body function returning
  `Unit`.
- [KC-4] **A single-expression function uses an expression body.**
- [KC-5] **No local functions**: extract to a private function or a separate class.
- [KC-6] **A lambda that only calls a constructor is a constructor reference** (`::Foo`).
- [KC-7] **A null check uses `if` or a null-safe scope function, not `when`.**

## Naming

- [KC-12] **A `Boolean` property, parameter, or function reads as an assertion.** Any of
  these forms is fine:
  - a predicate prefix: `isEmpty`, `hasNext`, `canUndo`, `shouldRetry`
  - a third-person verb: `handlesBack`, `containsKey(…)`
  - one of these bare state adjectives or participles: `enabled`, `visible`, `selected`,
    `checked`, `expanded`, `closed`

  Not a bare noun or an imperative (`editMode`, `refresh`). Any other adjective or
  participle takes a predicate prefix (`isSilent`, `isRelinkRequired`).

## Comments

- [KC-8] **A constructor property is documented with a class-level `@property` tag**, not an
  inline comment.

## Files and classes

- [KC-9] **`XxxExt.kt` holds extensions on `Xxx`.** A `public` or `internal` extension on
  another receiver goes in a file named for that receiver; a `private` one may stay
  in the file that uses it.
- [KC-10] **Sealed subtypes nest inside their sealed type** unless one is large enough that
  nesting hurts readability; then it is top-level in its own file and imported by
  name. One hierarchy does not mix both arrangements.
- [KC-11] **A nested class is `private` rather than `inner`** unless it needs its outer
  instance.
