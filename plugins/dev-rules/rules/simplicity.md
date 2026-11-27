---
description: Reusing existing utilities, removing unused code, and redundant checks
perspectives:
  - simplify
paths:
  - "**/*.{kt,kts,java,swift,ts,tsx,js,jsx,py,go,rs,rb,dart,c,cc,cpp,h,m,mm,cs,scala}"
---

# Simplicity Rules

- [SM-1] **Code uses an existing standard-library, framework, imported-library, or named
  project utility when one already expresses the operation** (`chunked`, `groupBy`,
  `fold`, `mapNotNull`).
- [SM-2] **Unreachable and unused functions, properties, parameters, imports, and branches
  are removed.** Remove an uncalled capability rather than renaming it.
- [SM-4] **A null check or cast adds information the type system cannot already prove.**
