---
description: Android threading conventions checked by the design perspective
perspectives:
  - design
paths:
  - "**/*.kt"
---

# Design Checklist: Android

Skip this file when the change is not Android code. Its `paths` can narrow only to
Kotlin.

Project rules win. This checklist covers what they do not say.

- **A blocking regular function declares its worker-thread requirement.** Annotate an
  Android function that must run on a worker thread with `@WorkerThread`. A function
  may instead be `suspend` and establish its dispatcher.
