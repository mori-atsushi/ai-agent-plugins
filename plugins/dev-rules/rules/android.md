---
description: Android threading and locally persisted data
perspectives:
  - design
paths:
  - "**/*.kt"
---

# Android Rules

Applies to Android code only; a path glob cannot narrow further than Kotlin.

- [AN-1] **A blocking regular function declares its worker-thread requirement** with
  `@WorkerThread`, or is `suspend` and switches to its own dispatcher.
- [AN-2] **Locally persisted data (DataStore, Room) is the single source of truth.** A click handler
  calls the `suspend` write; the UI observes the `Flow`. Do not hold a copy in a ViewModel, such
  as a mirror `MutableStateFlow`, optimistic update, or pending-write flag; read-only views
  derived from the `Flow` are fine. Bridge the write delay only for a flicker that was observed
  and measured.
