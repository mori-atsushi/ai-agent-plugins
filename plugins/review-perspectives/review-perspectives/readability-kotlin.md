---
description: Kotlin readability conventions checked by the readability perspective
perspectives:
  - readability
paths:
  - "**/*.{kt,kts}"
---

# Readability Checklist: Kotlin

Project rules win. This checklist covers what they do not say.

## Naming

- **Potentially swappable same-typed arguments are named.** Use named arguments when
  a reader could swap two or more positional values of the same type. Obvious
  conventions such as `Offset(x, y)` may remain positional.

## Comments

- **Constructor-property documentation uses `@property` KDoc.** Put it in the class
  documentation rather than an inline property comment.

## Types

- **A specific type, generic, or sealed hierarchy preserves type information.** Use
  `Any` only when the function genuinely erases it, such as generic logging.

## Mutability

- **A value without reassignment is a `val`.** Check the whole function or class, not
  only the changed lines.

## Visibility

- **Visibility is no wider than its callers require.** Use `private` instead of
  `internal`, and `internal` instead of `public`, when possible. A member matching
  its enclosing `internal` or `private` class, or narrower, needs no further change.
- **App-module and test-source declarations use `private`, not `internal`.** Nothing
  outside those source sets can use `internal`.
- **A one-call-site extension function is `private`.** Widen it only after a real
  second caller exists.
- **A test that needs wider production visibility uses `@VisibleForTesting` only when
  it cannot test the public API or extract a narrower class.**

## Functions and properties

- **A getter is trivial and derived; stateful or expensive work is a function.**
- **A one-line returning function uses an expression body** when it improves the
  simple form; this is a simplification, not a correctness requirement.
- **A non-`Unit` function has an explicit return type.** A block-body function that
  returns `Unit` is exempt.
- **A default argument serves every production caller.** Do not use one when callers
  must inspect its value; a production default that tests alone override, such as a
  `CoroutineDispatcher`, is appropriate.
- **A function is a private method or a separate class, not local or nested.**
- **A constructor-only lambda uses a constructor reference** such as `::Foo` instead
  of `.map { Foo(it) }`.

## Control flow

- **A multi-line condition or null-check chain has a named intermediate value when it
  clarifies intent.** Short, self-explanatory expressions need none.

## Error handling

- **Error handling catches only the expected failure type.** Do not use `runCatching`
  when it would also catch `CancellationException` or programming errors.

## File and class structure

- **A nested class is `private` rather than `inner` unless it needs its outer
  instance.**
