# Perspective: Simplify

Find code that can be simpler without losing clarity or correctness. Prefer structural
changes that reduce maintenance work. Do not chase micro-optimizations. Apply the
collected rules.

Stay within one scope: code that can be removed, or replaced by what already exists.
Whether and where to extract or share code, naming, and responsibility splits belong
to design.

## What NOT to flag

- Style differences that don't reduce complexity
- Minor naming suggestions
- Things that are verbose by convention (e.g., explicit type annotations on public
  API surfaces)
