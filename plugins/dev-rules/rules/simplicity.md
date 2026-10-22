---
description: Removing unused code, needless abstractions, and redundant checks
perspectives:
  - simplify
paths:
  - "**/*.{kt,kts,java,swift,ts,tsx,js,jsx,py,go,rs,rb,dart,c,cc,cpp,h,m,mm,cs,scala}"
---

# Simplicity Rules

- **Code uses an existing standard-library, framework, imported-library, or named
  project utility when one already expresses the operation** (`chunked`, `groupBy`,
  `fold`, `mapNotNull`).
- **Unreachable and unused functions, properties, parameters, imports, and branches
  are removed.**
- **Every abstraction provides a current benefit.** An interface or wrapper with one
  use needs a reason to exist; inline a wrapper that only bundles caller-specific
  steps such as exception handling, logging, and fallback values. Remove an uncalled
  capability rather than renaming it.
- **A null check or cast adds information the type system cannot already prove.**
