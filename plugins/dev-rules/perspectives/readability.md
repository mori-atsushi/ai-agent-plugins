# Perspective: Readability

Review local code clarity against the collected rules: identifier spelling, comments,
control flow and private-function extraction, file structure, and language or framework idioms.

This perspective owns clarity and consistency within a function, class, or file.
`design` owns cross-code questions. That includes responsibility, model shape, API
boundaries, whether a name is accurate, and sharing code. `test` owns test-specific conventions.

## Perspective-specific steps

Read **all** collected rule files. They are context, not the change.

## When the material is a plan

Review the identifiers, file names, and structure the plan proposes (variable,
function, class, and file names; their spelling and form) against the collected rules,
as if they were already written. Name the proposed identifier in `issue` and give the
corrected one. Skip what the plan leaves open; do not invent names for it.

## What NOT to flag

- Matters no rule file covers
- Formatting issues the project's auto-formatter fixes on its own
- A single rule pattern that is clearer as written. Rules are defaults, not absolute;
  skip a literal rule that would make code worse.
