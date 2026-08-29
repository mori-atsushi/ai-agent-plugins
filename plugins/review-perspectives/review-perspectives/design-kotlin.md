---
description: Kotlin model-design conventions checked by the design perspective
perspectives:
  - design
paths:
  - "**/*.{kt,kts}"
---

# Design Checklist: Kotlin Models

Project rules win. This checklist covers what they do not say.

- **Mutually exclusive states have one typed representation.** Use a sealed class,
  interface, or enum property when only one alternative can be present. Independently
  nullable properties may remain separate.
- **A `data class` is a value object.** Use a regular class for mutable state,
  callbacks, or behavior beyond equality and copying.
- **The type hierarchy matches the allowed variants.** Use a sealed hierarchy for
  restricted variants; use a plain class, sealed class, or enum only when its variant
  model fits the expected extension points.
- **Sealed subtype nesting makes the hierarchy easy to read.** Nest small local
  subtypes; keep a large subtype top-level when nesting obscures it; use a consistent
  arrangement unless size gives a clear reason to differ.
