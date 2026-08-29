---
description: Android test conventions checked by the test perspective
perspectives:
  - test
paths:
  - "**/*.kt"
---

# Test Checklist: Android

Skip this file when the change has no Android test or `@Composable`. Its paths can
narrow only to Kotlin. Project rules win. This checklist covers what they do not say.

## Proportionate test coverage

- Compose UI tests cover behavior beyond rendering, callback wiring, static text, or a
  prop branch. Those concerns are rendering rather than logic worth testing.

## Test form

- An Android test uses Robolectric when it provides the required fidelity; reserve an
  instrumentation test for behavior that needs a device or instrumented environment.
