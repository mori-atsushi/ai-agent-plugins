---
description: Architecture, layer boundaries, failure handling, naming scope, symmetry, call-site intent, cohesion, and when and where to share code
perspectives:
  - design
paths:
  - "**/*.{kt,kts,java,swift,ts,tsx,js,jsx,py,go,rs,rb,dart,c,cc,cpp,h,m,mm,cs,scala}"
---

# Design Rules

## Architecture

- **Business logic and UI concerns live in their own layers.** Computation, rules,
  and state stay out of UI and view-model code (layout math lives in its layout
  owner, not a UI component); UI concerns stay out of domain models; business-rule
  validation lives outside a repository.
- **Dependencies preserve architectural boundaries.** Domain modules do not import UI
  modules, API modules do not import their implementation modules, and public
  signatures do not expose implementation-only dependencies.
- **Module concepts form an acyclic graph.** A concept in module A does not depend on
  module B when a concept in B depends on A.
- **Build-variant code lives in its variant source set.** Debug-only code stays out
  of the main source set.
- **Use cases depend on domain abstractions, not infrastructure.** A repository
  returns resolved data, not resource IDs, file paths, or framework contexts.

## Boundaries

- **A boundary passes values or controlled mutation.** Do not pass a mutable
  collection, observable state, writer, string builder, or collector for the other
  side to write into. Return a value, or wrap the state in a class with named
  operations and a read-only view.
- **Mutually exclusive states have one typed representation**: a sealed hierarchy or
  enum, not several nullable fields of which at most one is set. Independently
  nullable properties may stay separate.

## Failures

- **Error handling covers a failure that can plausibly occur at that call site.** A
  trusted call gets no `try`/`catch` or fallback value "just in case"; an unexpected
  failure propagates.
- **An expected failure is converted where it occurs.** Its data-layer owner catches
  only the expected exception type and exposes the outcome through its API: `null`
  or `false` only when that value has a clear, documented meaning, otherwise a
  sealed type or enum. UI and use cases do not catch lower-layer exceptions to invent
  fallback values.
- **Broad handlers do not hide unrelated failures.** Avoid catching `Throwable` or
  `Exception`, and filter a stream's error handler to the expected upstream failure,
  rethrowing the rest. With no useful recovery, propagate.

## Naming

Spelling and form (abbreviations, filler words) are readability's; this section owns
whether a name is accurate.

- **A name says what its unit computes or does without surrounding context.** A
  shared subexpression's name stays accurate in every branch that uses it.
- **A function name describes the operation or its result, not only its input.**
- **A side-effect-free function is named for the value it returns** (`toSummary()`,
  `withBase(…)`), not with a verb that implies mutation (`change…`, `update…`).
- **A name follows the project's domain glossary** when one exists.
- **A name matches its current scope.** A function that changes one field is not
  `updateRecord`; narrowing, splitting, or moving code renames what it touches.

## Parallel structure

- **Conceptually parallel code uses corresponding names, nesting, and files.** This
  covers analogous modules, classes, and functions. Only a real
  difference, such as size or extra state, justifies a different structure.

## Call site reads as intent

- **A caller such as a use case or reducer shows what it does, not how.** Deep
  navigation, raw casts, and hand-built nested copies belong behind a named operation
  on the owning type.

  ```kotlin
  // Bad — the caller spells out the mechanism
  val group = root.items[itemIndex] as? Group ?: return root
  val slot = group.slots.getOrNull(0) ?: return root
  // ... mutate, then rebuild Slot / Group / Root by hand

  // Good — the caller reads as intent
  group.slots.foldIndexed(root) { slotIndex, current, _ ->
      current.replaceEntryWithPlaceholder(key, slotIndex)
  }
  ```

## Responsibilities and cohesion

- **A class has one clear responsibility.** Parsing and persistence are separate
  classes.

## Sharing and placement

- **Share behavior, not matching code.** Extract repeated computation or conditions
  when they are one responsibility that should change together. Two or three similar
  call sites stay separate when each owns its behavior or may evolve independently;
  a caller count or a few repeated lines alone do not justify extraction. Constants
  are the same: do not share one because the values coincide today. A named value
  (a size or dimension included) is reused or names a shared concept; a one-use
  value stays at its call site.
- **An extracted helper represents one named concern.** Keep caller-specific
  behavior at the caller, even at the cost of a small repetition. Do not introduce generics or callbacks solely to unify such
  processing.
- **Code shared by sibling files lives in neither of them**, but in its own file or a
  shared file named for the concept.
- **Shared behavior lives with its owning type.** A helper for one domain object is
  usually a member or extension on that type, so consumers do not recompute it.
- **Logic is placed by reuse.** Shared queries and predicates, cross-module logic
  included, have one owner in the shared layer; one-off logic stays private, next to
  its user. Promote it only once a second user
  actually exists.
- **A duplicated calculation moves verbatim.** Keep its types: re-deriving an integer
  from a float can change rounding.
- **A shared calculation names its concept,** with a domain type when that makes call
  sites show intent (`fun Container.findMatchedPairs(): List<MatchedPair>`).
