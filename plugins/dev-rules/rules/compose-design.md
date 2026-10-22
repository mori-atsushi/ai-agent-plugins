---
description: Jetpack Compose API shape — what a composable receives, where logic, position, and size live, slots, and interaction semantics
perspectives:
  - design
paths:
  - "**/*.kt"
---

# Jetpack Compose Design Rules

Applies to `@Composable` code only; a path glob cannot narrow further than Kotlin.

## Parameters

- **A composable receives only what it reads.** When it branches on a combination of
  unrelated fields or reads a fraction of an upstream model, define a small type for
  its needs (a sealed type for the branches, a narrower data class for the fields)
  and have the caller convert. Passing the upstream model is fine when it uses most of
  it.
- **A UI composable receives `State`, not a `Flow`.** Collect the `Flow` before the UI
  boundary. `remember*State` factories and `LaunchedEffect`/`DisposableEffect` may
  take a `Flow`.

## Logic, position, and size

- **A decision beyond a one-line guard moves out of a UI composable** into a plain
  function or a state class the composable only reads.
- **A composable is positioned by its caller.** Positioning modifiers (`align`,
  `offset`, …) are built at the call site and passed in through `modifier`. When an
  offset depends on data only the composable's layer understands, expose that
  computation as a plain function the caller invokes. Do not declare a composable as
  a `BoxScope`/`ColumnScope`/`RowScope` extension just to reach a scope-only
  modifier.
- **A composable's own size stays internal only when it is fixed and
  call-site-independent** (a fixed icon size). A size that depends on the call site
  is supplied by the caller.
- **A sibling positioned from a composable's size or offset is a slot of that
  composable**, and both are placed in one `Layout` (as `BottomSheetScaffold` places
  its snackbar). Do not hand the size or offset back out through a callback, a state
  holder, or `onGloballyPositioned`. Reading its own size for its own layout, drawing,
  or gestures is fine.

## Semantics

- **An interaction modifier (`clickable`, `toggleable`, …) always has an action.**
  When the interaction is conditionally absent, make the callback nullable and apply
  the modifier only when it is non-null.
