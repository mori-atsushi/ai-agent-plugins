---
description: Kotlin visibility, value and sealed models, function contracts, and exception handling
perspectives:
  - design
paths:
  - "**/*.{kt,kts}"
---

# Kotlin Design Rules

## Visibility

- [KD-1] **Visibility is no wider than its callers require.** Prefer `private`; widen to
  `internal` for cross-module access and to `public` only when required.
- [KD-2] **`internal` is not used in the app module or in tests** — nothing outside them
  can reference it; use `private`.
- [KD-3] **A member of an `internal` or `private` class omits a modifier only when it would
  repeat the class's own visibility.** Narrowing further with `private` is fine.
- [KD-4] **A one-call-site extension's `private` home** is file level or a `private
  companion object`.
- [KD-5] **Production visibility is not widened for a test** when testing through the public
  API or extracting a narrower class works. Otherwise widen it and annotate it with
  `@VisibleForTesting(otherwise = VisibleForTesting.PRIVATE)`.

## Types and models

- [KD-6] **`Any` appears only where a function genuinely erases the type**, such as generic
  logging; otherwise use a specific type, generic, or sealed hierarchy.
- [KD-7] **A `data class` is a value object.** A class holding mutable state, callbacks, or
  behavior beyond equality and copying is a regular class.
- [KD-8] **A function-type parameter forwarded through two or more classes or layers is a
  named type, not a lambda.** A bare `(String) -> Int` can be swapped with any other
  function of the same shape. Define an `interface` (a `fun interface` when it has one
  method) when tests substitute a fake, and a plain class otherwise. A callback used in
  one place stays a lambda, and so do Compose event callbacks such as `onClick`.
- [KD-9] **A serialized name is explicit and stable**, so a rename in code cannot break
  stored data: a serialized enum case has `@SerialName`, and a serialized sealed
  subtype an explicit discriminator.

## Function contracts

- [KD-10] **A one-shot result is a `suspend` function, not a `Flow`.** Use `Flow` only where the
  caller needs multiple values over time.
- [KD-11] **A getter property is a cheap derived value**; expensive or stateful work
  (including `@Composable`) is a function.
- [KD-12] **A `suspend` function calls suspend work or implements a suspend API.** Callers
  being `suspend` is not a reason.
- [KD-13] **A default argument exists only when every production caller uses it**; a preview
  passes explicit values. A production default that only tests override, such as a
  `CoroutineDispatcher`, is fine.
- [KD-14] **A dependency is a constructor parameter or an extension receiver, not a function
  argument**, except as the test-overridden default above.

## Errors

- [KD-15] **`runCatching` is not used.** It catches every `Throwable`, including cancellation
  and programming errors; catch the specific expected exception instead.
