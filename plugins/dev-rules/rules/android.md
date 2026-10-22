---
description: Android threading and persisted DataStore values
perspectives:
  - design
paths:
  - "**/*.kt"
---

# Android Rules

Applies to Android code only; a path glob cannot narrow further than Kotlin.

- **A blocking regular function declares its worker-thread requirement** with
  `@WorkerThread`, or is `suspend` and switches to its own dispatcher.
- **A DataStore value is the only copy.** Read its `Flow` and write through a
  `suspend` call. Do not add a mirror `MutableStateFlow`, optimistic update, or
  pending-write flag; read-only views derived from the `Flow` are fine. Bridge the
  write delay only for a flicker that was observed and measured.
