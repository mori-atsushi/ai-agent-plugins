---
description: Kotlin test conventions checked by the test perspective
perspectives:
  - test
paths:
  - "**/*.{kt,kts}"
---

# Test Checklist: Kotlin

Skip this file when the change has no Kotlin test. Its paths can narrow only to
Kotlin. Project rules win. This checklist covers what they do not say.

## Proportionate test coverage

- Tests cover behavior rather than a data class that only holds properties.

## Test form

- Assertions use `kotlin.test` equivalents rather than `org.junit.Assert.*`.
- A data-class assertion compares the expected and actual values with
  `assertEquals(expected, actual)`, so new or overlooked fields cannot be missed.
- A `Flow` test uses Turbine (`runTest` + `flow.test { ... }`) rather than hand-rolled
  collection into a list.
- A test name states its target and condition, using
  `test[TargetFunctionName]_[Condition]` by default.
