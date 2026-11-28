---
description: Android threading, locally persisted data, and keeping the Activity out of longer-lived objects
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
- [AN-3] **An object that outlives the Activity never receives the Activity or anything tied
  to it**: the Activity, the Activity's `Context`, `Window`, or `View`s, its `Lifecycle` or
  `LifecycleOwner`, or a lambda that captures one. Longer-lived means a ViewModel, a
  singleton, an application-wide module or scope, and the coroutines and `Channel`s inside
  them. Not even briefly, and not as an argument: `viewModel.purchase(activity)` and
  `singleton.onEditorClosed(activity)` both break this. The Application `Context` is allowed.
  Run the work that needs an Activity (In-App Review, a Billing launch) in code that lives no
  longer than the Activity: an object the Activity creates and holds, `lifecycleScope` with
  `repeatOnLifecycle`, or a composition effect reading `LocalActivity`. The longer-lived
  object exposes that there is work to do (a `StateFlow`) and takes back the result as a
  plain value, such as an enum.
