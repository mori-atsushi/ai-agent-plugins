---
description: Kotlin test naming, assertions, and Flow testing
perspectives:
  - test
paths:
  - "**/*Test.kt"
  - "**/src/test/**/*.kt"
  - "**/src/*Test/**/*.kt"
---

# Kotlin Test Rules

- [KT-1] **A test function is named `test<TargetFunction>_<Condition>`** —
  `testLoadUser_whenCacheIsValid`.
- [KT-2] **Assertions come from `kotlin.test`** (`assertEquals`, `assertTrue`), not
  `org.junit.Assert`.
- [KT-3] **A data-class result is compared whole** with `assertEquals(expected, actual)`,
  not field by field, so a new or overlooked field cannot slip through.
- [KT-4] **A `Flow` test uses Turbine** (`runTest` + `flow.test { ... }`), not hand-rolled
  collection into a list.
