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
- **Non-trivial shared logic has a shared owner.** Extract logic with its own steps or
  conditions, or a third caller; a few shared lines with only two callers may remain
  local.
- **An extracted helper represents one shared concern.** Similar-looking code with
  different concerns stays separate so it can diverge safely.

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

Single responsibility and high cohesion apply at every level. A class or function
contains related concerns and splits independent responsibilities.

**At the class level**
- Each class has one clear responsibility; parsing and persistence, or UI state and
  business logic, are separate concerns.

**At the function level**
- A function keeps flow, concrete work, I/O, and type conversion in cohesive units;
  extract an independent responsibility into a private function.
- Extract only when the new responsibility has a clear name. Do not extract only to
  shorten a function. That is a simplify concern.
