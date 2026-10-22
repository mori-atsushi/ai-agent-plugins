---
description: Kotlin visibility, value and sealed models, function contracts, and exception handling
perspectives:
  - design
paths:
  - "**/*.{kt,kts}"
---

# Kotlin Design Rules

## Visibility

- **Visibility is no wider than its callers require.** Prefer `private`; widen to
  `internal` for cross-module access and to `public` only when required.
- **`internal` is not used in the app module or in tests** — nothing outside them
  can reference it; use `private`.
- **A member of an `internal` or `private` class omits a modifier only when it would
  repeat the class's own visibility.** Narrowing further with `private` is fine.
- **A one-call-site extension's `private` home** is file level or a `private
  companion object`.
- **Production visibility is not widened for a test** when testing through the public
  API or extracting a narrower class works. Otherwise widen it and annotate it with
  `@VisibleForTesting(otherwise = VisibleForTesting.PRIVATE)`.

## Types and models

- **`Any` appears only where a function genuinely erases the type**, such as generic
  logging; otherwise use a specific type, generic, or sealed hierarchy.
- **A `data class` is a value object.** A class holding mutable state, callbacks, or
  behavior beyond equality and copying is a regular class.
- **A serialized name is explicit and stable**, so a rename in code cannot break
  stored data: a serialized enum case has `@SerialName`, and a serialized sealed
  subtype an explicit discriminator.

## Function contracts

- **A getter property is a cheap derived value**; expensive or stateful work
  (including `@Composable`) is a function.
- **A `suspend` function calls suspend work or implements a suspend API.** Callers
  being `suspend` is not a reason.
- **A default argument exists only when every production caller uses it**; a preview
  passes explicit values. A production default that only tests override, such as a
  `CoroutineDispatcher`, is fine.
- **A dependency is a constructor parameter or an extension receiver, not a function
  argument**, except as the test-overridden default above.

## Errors

- **`runCatching` is not used.** It catches every `Throwable`, including cancellation
  and programming errors; catch the specific expected exception instead.
