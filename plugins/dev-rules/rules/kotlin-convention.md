---
description: Kotlin idioms — named arguments, val, function form, null checks, @property docs, and file and nested-class layout
perspectives:
  - readability
paths:
  - "**/*.{kt,kts}"
---

# Kotlin Conventions

## Call sites

- **Swappable same-typed arguments are named.** Use named arguments when a reader
  could swap two or more positional values of the same type. Obvious conventions
  such as `Offset(x, y)` stay positional.

## Values and functions

- **A value without reassignment is a `val`.**
- **A function declares its return type**, except a block-body function returning
  `Unit`.
- **A single-expression function uses an expression body.**
- **No local functions**: extract to a private function or a separate class.
- **A lambda that only calls a constructor is a constructor reference** (`::Foo`).
- **A null check uses `if` or a null-safe scope function, not `when`.**

## Comments

- **A constructor property is documented with a class-level `@property` tag**, not an
  inline comment.

## Files and classes

- **`XxxExt.kt` holds extensions on `Xxx`.** A `public` or `internal` extension on
  another receiver goes in a file named for that receiver; a `private` one may stay
  in the file that uses it.
- **Sealed subtypes nest inside their sealed type** unless one is large enough that
  nesting hurts readability; then it is top-level in its own file and imported by
  name. One hierarchy does not mix both arrangements.
- **A nested class is `private` rather than `inner`** unless it needs its outer
  instance.
