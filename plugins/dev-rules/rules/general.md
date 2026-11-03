---
description: Language-agnostic identifier spelling, control flow, function extraction, file structure, and declaration order
perspectives:
  - readability
paths:
  - "**/*.{kt,kts,java,swift,ts,tsx,js,jsx,py,go,rs,rb,dart,c,cc,cpp,h,m,mm,cs,scala}"
---

# General Code Rules

## Naming

- [GN-1] **An identifier is spelled out, not abbreviated.** `requestTimeout`, not `rt`;
  `repository`, not `repo`. A single letter is fine only in a small local scope.
- [GN-2] **A type names its concept without filler** such as `Manager`, `Handler`,
  `Helper`, `Util`, or `Data` when the rest of the name already is the concept.
- [GN-3] **A concept the standard library or framework already names keeps that name**, not
  a synonym. Examples:
  - Kotlin: `xxxOrNull` for a null-returning variant, `toXxx()` for a conversion and
    `asXxx()` for a view.
  - Android: `popUpTo` as Navigation names it, not `popThrough`.
  - Swift: `makeXxx()` for a factory.
  - Python: `append` and `extend` for lists, not `add` and `add_all`.
- [GN-4] **A word with a programming meaning (`run`, `job`, `task`) is used only in that
  meaning.**

## Control flow

- [GN-5] **An early return is a guard clause or an edge case off the happy path.** Equally
  weighted branches use one conditional (`if (cond) X else Y`).
- [GN-6] **Control flow stays shallow, and a function keeps flow, concrete work, I/O, and
  type conversion in cohesive units.** Extract deeply nested logic or an independent
  step into a private function — only when it gets a clear name.
- [GN-7] **An expression gets a named value only when inlining hides intent**, such as a
  multi-line condition or a chain of null checks. Short, self-explanatory
  expressions stay inline.

## Files and members

- [GN-8] **A file holds one top-level class**, small value types and enums included, unless
  a more specific rule (such as [compose-convention.md](compose-convention.md))
  groups declarations. A
  helper used only by one parent may nest inside it, without the parent's prefix
  (under `OrderSummary`, `LineItem`, not `OrderLineItem`).
- [GN-9] **Class members follow this order:** properties, initialization, functions, nested
  types, then companion or static members.
- [GN-10] **A file stays readable in size.** Split a production file over 500 lines; 1000
  lines is the hard limit for production and test files.

## Declaration order

Within each list, the earlier criterion wins:

- [GN-11] **Properties and constructor parameters:** dependency (depended-on first), then
  importance (identifiers and core state before derived or auxiliary values), then
  relatedness.
- [GN-12] **Cases of a restricted type or enum:** importance or call order (initial before
  terminal, success before error), then relatedness.
- [GN-13] **Functions:** call order — a caller sits above the functions it calls.
