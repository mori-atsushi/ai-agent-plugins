# Perspective: Readability

Review local code clarity. Check the applicable general, Kotlin, and Jetpack Compose
conventions.

This perspective owns clarity and consistency within a function, class, or file.
`design` owns cross-code questions. That includes responsibility, model shape, API
boundaries, and reuse placement.

## Perspective-specific steps

Read **all** collected reference files. They are context, not the change. When two
references conflict, the later and more specific one wins. Anything it does not
mention still stands.

## What NOT to flag

- Matters no reference file covers
- Formatting issues the project's auto-formatter fixes on its own
- A single checklist pattern that is clearer as written. These checks are defaults,
  not absolute rules. Skip a literal rule that would make code worse.

## General conventions

### Naming

- **A name expresses its unit's purpose without surrounding context.**
- **An identifier is descriptive rather than abbreviated or cryptic.** `repo`, `cfg`,
  and a single letter outside a small local scope usually need a fuller name.
- **A non-transfer type names its concept without filler.** Avoid `Manager`,
  `Handler`, `Helper`, `Util`, or `Data` when the remaining name is the concept.
- **A function name describes the operation or result, not only its input.**

### Comments

- **A comment explains information the code cannot express.** Remove restatements
  such as `// increment counter` above `counter++`.
- **Workarounds, non-obvious side-effect return values, argument constraints, and
  `null` meanings have the comment they need.**
- **A comment documents its type or behavior, not a caller list.** Naming a related
  type is fine; caller lists go stale.
- **A comment describes current behavior, not a past implementation.** Version
  control keeps history.
- Do not flag a comment only because it is long or you would not write it. Flag only
  restatement or staleness risk.

### Control flow and error handling

- **Equal branches use the clearer conditional form.** Prefer `if (cond) X else Y`
  over `if (cond) { return X }; return Y` when it reads more clearly; retain guard
  clauses for edge cases.
- **Control flow remains shallow enough to read.** Extract a private function when it
  gives a clear responsibility without making the code less clear.
- **Error handling represents a plausible failure.** Trusted calls do not gain a
  `try`/`catch` or null fallback merely "just in case"; propagate instead.

### File and member structure

- **A file has one top-level class.** A small helper may nest in its only parent.
- **Class members follow state/properties, initialization, functions, nested types,
  then companion or static members.**
- **Production files stay within a readable size.** Consider splitting a changed file
  over 500 lines; 1000 lines is the hard limit for production and test files.
- **Properties and constructor parameters are ordered by dependency, importance, then
  relatedness.**
- **Restricted-type and enum cases are ordered by importance or call order, then
  relatedness.**
- **Functions follow call order, with callers above their callees.**
