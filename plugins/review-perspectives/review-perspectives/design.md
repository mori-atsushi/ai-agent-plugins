# Perspective: Design

Review decisions that shape or connect code. Check architecture, responsibility, state
ownership, data and API models, and reuse placement.

This perspective owns questions beyond one implementation. Check callers, types,
modules, state ownership, and domain meaning. `readability` owns local clarity, file
structure, and language or framework idioms.

Use the objective and specifications to understand the intended outcome. Do not treat
an implementation plan as the required solution. Review the code from a fresh,
independent viewpoint. Recommend a better design when the implementation reveals one.
The response to a finding must evaluate it on its merits, not dismiss it because the
code follows the plan.

## What to look for

### Project rules

Collected reference files define project-specific rules. They win when they conflict
with this perspective.

### Architecture
- **Business logic and UI concerns live in their respective layers.** Keep
  computation, rules, and state out of UI or view-model code, and keep UI concerns
  out of domain models.
- **Dependencies preserve architectural boundaries.** Check changed imports and build
  configuration against dependency references. In particular, domain modules do not
  import UI modules, API modules do not import their implementation modules, and
  public signatures do not expose implementation-only dependencies.
- **Build-variant code lives in its variant source set.** Keep debug code out of main
  source, and expose debug UI through `CompositionLocal` rather than composable
  parameters when project placement rules require it.
- **Module concepts form an acyclic dependency graph.** A concept in module A must
  not depend on module B when a concept in B also depends on A.
- **Each class owns its module's responsibility.** Put layout math, for example, in
  its layout owner rather than a UI component, and business-rule validation outside a
  repository.
- **Use cases depend on domain abstractions, not infrastructure details.** Repositories
  provide resolved data rather than leaking resource IDs, file paths, or framework
  contexts.
- **Expected failures are converted where they occur.** When a data operation has a
  meaningful recoverable failure, its data-layer owner catches only the expected
  exception type and exposes the outcome through its API. Use `null` or `false` only
  when that value has a clear, documented meaning; use a sealed type or enum when
  callers need to distinguish outcomes. UI and use cases do not catch lower-layer
  exceptions to invent fallback values. Avoid `catch (e: Throwable)`,
  `catch (e: Exception)`, `runCatching`, and unfiltered `Flow.catch` that turn
  unrelated exceptions into expected outcomes; a `Flow.catch` handler must identify
  the expected upstream failure and rethrow others. If no useful recovery exists,
  propagate the failure.

### Naming

Apply this section to every changed name. It includes types, functions, files,
workflows, scripts, directories, and labels.

- Follow a domain glossary when the collected references define one.
- **A name matches its current scope.** For example, a function that changes one field
  is not named `updateRecord`; narrowing, splitting, or moving code keeps its names
  current by renaming or changing the responsibility split.
- **A serialized name is explicit and stable.** A new enum case has `@SerialName`, and
  a new sealed subtype has an explicit discriminator, so a Kotlin rename cannot break
  stored data.

### Parallel-structure symmetry

Conceptually parallel code uses corresponding names, nesting, and files. This includes
sealed siblings and analogous modules, classes, and functions. A real difference,
such as size or extra state, must justify a different structure.

### Reusable domain logic extraction

Domain logic lives in a testable domain class or function rather than UI components,
view-models, reducers, or other view code. Cross-module logic has one shared domain
owner.

- **A boundary exposes values or controlled mutation.** Do not pass a mutable
  collection, observable state, writer, string builder, or collector for another side
  to write; return a value or a read-only view with named mutations.
- **Shared logic has a shared owner when it is one responsibility.** Extract behavior
  that should change together, especially when it has its own steps or conditions.
  Two or three similar call sites may keep a few repeated lines when each owns the
  behavior or may evolve independently; a caller count alone does not justify extraction.
- **An extracted helper represents one shared concern with a named responsibility.**
  Similar-looking code with different concerns stays separate so it can diverge
  safely. Keep caller-specific behavior at the caller, even when that leaves a small
  repetition. Inline a configurable wrapper that merely groups caller-specific steps,
  such as exception handling, logging, and fallback values. Similar `try`/`catch`
  structures do not justify a shared abstraction. Do not introduce generics or
  callbacks solely to unify such processing; retain them when they express a
  distinct operation or necessary type polymorphism.

- **Shared behavior lives with its owning type when it has one.** A helper for one
  domain object is often a member or extension on that type, so consumers do not
  duplicate its calculation.
- **Place logic by reuse.** Put shared queries and predicates in the shared layer.
  Keep one-off logic near its user. Project rules override this split.
- **Move duplicated calculations verbatim.** Keep their types. Re-deriving an
  integer from a float can change rounding.
- **Name the concept, not only the function.** Shared calculations may need a domain
  type so call sites show intent.

  ```kotlin
  // The shared concept: two records that satisfy some matching relationship.
  data class MatchedPair(val source: Item, val target: Item)
  fun Container.findMatchedPairs(...): List<MatchedPair>
  ```

### Call site reads as intent, not mechanism

A caller such as a use case or reducer shows *what* it does, not *how*. Put deep
navigation, raw model casts, and hand-built nested `copy` calls behind a named
operation on the owning type.

```kotlin
// Bad — the caller spells out the mechanism
val group = root.items[itemIndex] as? Group ?: return root
val slot = group.slots.getOrNull(0) ?: return root
val index = slot.findIndex(key) ?: return root
val entry = slot.entries[index] as? Entry ?: return root
// ... mutate, then rebuild Slot / Group / Root by hand

// Good — the caller reads as intent
group.slots.foldIndexed(root) { slotIndex, current, _ ->
    current.replaceEntryWithPlaceholder(key, slotIndex)
}
```

### Responsibilities and cohesion

Single responsibility and functional cohesion apply at every level. A class or function
contains work belonging to one purpose and splits independent responsibilities.

**At the class level**
- Each class has one clear responsibility; parsing and persistence, or UI state and
  business logic, are separate concerns.

**At the function level**
- A function keeps flow, concrete work, I/O, and type conversion in cohesive units;
  extract an independent responsibility into a private function.
- Extract only when the new responsibility has a clear name. Do not extract only to
  shorten a function. That is a simplify concern.
