# Perspective: Readability

Review local code clarity against the collected rules: identifier spelling, comments,
control flow and private-function extraction, file structure, and language or framework idioms.

This perspective owns clarity and consistency within a function, class, or file.
`design` owns cross-code questions. That includes responsibility, model shape, API
boundaries, whether a name is accurate, and sharing code. `test` owns test-specific conventions.

## Perspective-specific steps

Read **all** collected rule files. They are context, not the change.

## What NOT to flag

- Matters no rule file covers
- Formatting issues the project's auto-formatter fixes on its own
- A single rule pattern that is clearer as written. Rules are defaults, not absolute;
  skip a literal rule that would make code worse.
