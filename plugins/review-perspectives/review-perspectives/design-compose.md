---
description: Jetpack Compose state and component-boundary conventions checked by the design perspective
perspectives:
  - design
paths:
  - "**/*.kt"
---

# Design Checklist: Jetpack Compose

Skip this file when the change has no `@Composable`. Its `paths` can narrow only to
Kotlin, not Compose.

Project rules win. This checklist covers what they do not say.

- **A composable receives a model shaped for what it reads.** Use a sealed type when
  the branch selects a state, or a smaller data class when it needs selected fields.
  Passing an upstream model is appropriate when the composable genuinely uses most
  of it.
- **A UI composable receives `State`, not a `Flow`.** Collect a `Flow` before the UI
  boundary. `remember*State`, `LaunchedEffect`, and `DisposableEffect` may receive a
  `Flow`.
- **A shared design-system component uses an unprefixed generic name.** The package
  already supplies app and brand scope: prefer `DropdownMenu` to `AcmeDropdownMenu`.
- **A composable is positioned by its caller, never by itself.** Positioning
  modifiers (`align`, `offset`, and the like) are built at the call site and
  passed in through `modifier: Modifier = Modifier`. When an offset depends on
  data only the composable's layer understands, expose that computation as a
  plain function the caller invokes — don't apply it internally. This also
  rules out declaring a composable as a `BoxScope`/`ColumnScope`/`RowScope`
  extension just to reach a scope-only modifier (`align`, `weight`) — the
  caller already holds that receiver and can build the modifier itself.
- **A composable's own size (`width`/`height`) stays internal only when it is fixed
  and call-site-independent** (e.g. a fixed icon size). Once a size depends on
  where the composable is used — layout data specific to that call site — the
  caller computes and supplies it too, the same way it supplies position.
- **A UI composable keeps business logic out of its body** (see design.md's
  business-logic/UI split). For a composable, that means hoisting decisions and
  computations to the host (the caller) or extracting them into a state class the
  composable merely reads, rather than deriving or deciding them inline.
