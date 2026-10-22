---
description: Language-agnostic identifier spelling, control flow, function extraction, file structure, and declaration order
perspectives:
  - readability
paths:
  - "**/*.{kt,kts,java,swift,ts,tsx,js,jsx,py,go,rs,rb,dart,c,cc,cpp,h,m,mm,cs,scala}"
---

# General Code Rules

## Naming

- **An identifier is spelled out, not abbreviated.** `requestTimeout`, not `rt`;
  `repository`, not `repo`. A single letter is fine only in a small local scope.
- **A type names its concept without filler** such as `Manager`, `Handler`,
  `Helper`, `Util`, or `Data` when the rest of the name already is the concept.
- **A word with a programming meaning (`run`, `job`, `task`) is used only in that
  meaning.**

## Control flow

- **An early return is a guard clause or an edge case off the happy path.** Equally
  weighted branches use one conditional (`if (cond) X else Y`).
- **Control flow stays shallow, and a function keeps flow, concrete work, I/O, and
  type conversion in cohesive units.** Extract deeply nested logic or an independent
  step into a private function — only when it gets a clear name.
- **An expression gets a named value only when inlining hides intent**, such as a
  multi-line condition or a chain of null checks. Short, self-explanatory
  expressions stay inline.

## Files and members

- **A file holds one top-level class**, small value types and enums included, unless
  a more specific rule (such as [compose-convention.md](compose-convention.md))
  groups declarations. A
  helper used only by one parent may nest inside it, without the parent's prefix
  (under `OrderSummary`, `LineItem`, not `OrderLineItem`).
- **Class members follow this order:** properties, initialization, functions, nested
  types, then companion or static members.
- **A file stays readable in size.** Split a production file over 500 lines; 1000
  lines is the hard limit for production and test files.

## Declaration order

Within each list, the earlier criterion wins:

- **Properties and constructor parameters:** dependency (depended-on first), then
  importance (identifiers and core state before derived or auxiliary values), then
  relatedness.
- **Cases of a restricted type or enum:** importance or call order (initial before
  terminal, success before error), then relatedness.
- **Functions:** call order — a caller sits above the functions it calls.
