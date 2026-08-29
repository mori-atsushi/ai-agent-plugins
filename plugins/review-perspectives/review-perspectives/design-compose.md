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
