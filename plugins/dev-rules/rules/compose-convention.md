---
description: Jetpack Compose conventions — file layout, parameter order, naming, and recomposition-friendly reads, and previews
perspectives:
  - readability
paths:
  - "**/*.kt"
---

# Jetpack Compose Conventions

Applies to `@Composable` code only; a path glob cannot narrow further than Kotlin.

## Files

- [CC-1] **Each public or internal composable has its own file**, named
  `<MainComposableName>.kt`. Private composables, helpers, and the types its
  parameters use may share it.
- [CC-2] **The main composable is the first declaration after constants**; classes and
  private helpers (including private composables) follow it, and previews sit at the
  bottom.

## Parameters

- [CC-3] **Parameters follow this order:** required, one `modifier: Modifier = Modifier`,
  optional, then a trailing `@Composable` lambda — last even when it has a default.

## Naming

- [CC-4] **A `Unit`-returning composable is a noun phrase**, whether it emits UI or only runs
  an effect: `ProfileHeaderLayout`, `BackHandler`, not `ShowProfileHeader`,
  `HandleBackPress`.
- [CC-5] **A design-system component has no app or brand prefix** (`DropdownMenu`, not
  `AcmeDropdownMenu`); its package already scopes it.

## Recomposition

- [CC-6] **Per-frame animated state is read in a lambda modifier, not the composable body**:
  `Modifier.offset { … }`, `graphicsLayer { … }`, `layout { … }`, or
  `drawBehind { … }` instead of `Modifier.padding(bottom = animatedDp)`. A one-time
  state change recomposing once is not a concern.
- [CC-7] **A lambda or function reference is not wrapped in `remember`.** Strong skipping
  already memoizes lambdas keyed by their captures.

## Previews

- [CC-8] **A file includes a preview** unless it is hard to write or adds little value.
- [CC-9] **A preview is `private` and named `<ComposableName>Preview`**, or
  `<ComposableName><Variant>Preview`.
