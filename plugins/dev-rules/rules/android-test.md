---
description: Android test environment, and which Compose UI behavior gets a UI test
perspectives:
  - test
paths:
  - "**/*.kt"
---

# Android Test Rules

Applies to Android code only; a path glob cannot narrow further than Kotlin.

- **An Android test runs on Robolectric.** Reserve an instrumentation test for
  behavior only a device or emulator can show.

## Compose UI tests

Applies to tests of `@Composable` code.

- **Compose UI tests are kept to a few critical interaction flows** that only the UI
  as a whole can show.
- **A decision beyond a one-line guard is unit-tested, not UI-tested**: a branch over
  several inputs or a state transition is pinned by a unit test of the code that
  makes it, and a UI test pinning such a decision is replaced by that unit test.
- **No UI test for what a composable only renders or forwards:** rendering, a
  wired-up callback, static text, a prop branch that only toggles what is shown, or
  the framework's own behavior (layout, lazy lists, semantics, a click reaching its
  handler).
