---
description: Jetpack Compose readability conventions checked by the readability perspective
perspectives:
  - readability
paths:
  - "**/*.kt"
---

# Readability Checklist: Jetpack Compose

Skip this file when the change has no `@Composable`. Its `paths` can narrow only to
Kotlin, not Compose. Project rules win. This checklist covers what they do not say.

## Parameters

- **Composable parameters have a consistent order:** required parameters, one
  `modifier: Modifier = Modifier`, optional parameters, then a trailing
  `@Composable` lambda. The lambda stays last even with a default.

## Naming

- **A `Unit`-returning composable is named as a noun phrase, not a verb.** This
  covers both a composable that emits UI and one that only runs a side effect
  (e.g. a thin wrapper around `LaunchedEffect`, like `BackHandler`):
  `ProfileHeaderLayout`, `RippleEffect`, `BackHandler`, not `ShowProfileHeader`,
  `AnimateRipple`, `HandleBackPress`.

## Recomposition

- **Per-frame animated state is read in a lambda modifier, not the composable body.**
  For example, use `Modifier.offset { ... }`, `graphicsLayer { ... }`, `layout { ... }`,
  or `drawBehind { ... }` instead of `Modifier.padding(bottom = animatedDp)`. A
  one-time state change and its one recomposition are not a concern.

## Semantics

- **An interaction modifier always provides an action.** A no-op callback, including
  one that does nothing in some state, creates misleading accessibility and hit-test
  semantics. Model optional interaction with a nullable callback and apply the
  modifier only when it is non-null.

## Values

- **A named size or dimension has more than one use or names a shared design concept.**
  Inline a one-use value otherwise.

## Previews

- **Preview-only defaults stay in the preview call.** A production composable does
  not gain a default parameter solely for `@Preview`.
- **A `@Preview` function is `private`.**
- **A `@Preview` function names the displayed composable and variant:**
  `<ComposableName>Preview`, or `<ComposableName><Variant>Preview` for a variant.
