---
description: When to write a comment, and what documentation and inline comments contain
perspectives:
  - readability
---

# Comment Rules

## General

- **A comment explains what the code itself cannot express.** Remove one that only
  restates the code, such as `// increment counter` above `counter++`.
- **A comment comes only after the code cannot be made clearer.** Improve the code
  first; the comment covers what remains.
- **A comment is as short as possible, in plain English a non-native speaker can
  follow.** Cut every line and word that adds no information.
- **A comment describes current behavior, not history.** The reasoning behind a past
  decision belongs in the commit message.

## Documentation comments

- **A documentation comment carries only background the code cannot show:** argument
  conditions (already sorted, non-negative, non-empty), what the return value means,
  and preconditions the caller must meet. Usually that is no comment or one line. A
  comment that walks through branches, edge cases, or steps the body makes plain is
  too long; when the code is hard to follow, simplify the code instead.
- **A documentation comment that exists has a summary.** Documenting only a property
  or a return value is not enough.
- **A function whose purpose is an action, and that also returns a value, documents
  that value.**
- **A `null` return or nullable property documents what `null` means** when the name
  or type does not make it obvious.
- **A documentation comment describes its own type, not its callers.** Naming a
  related type is fine; a list of callers goes stale.

## Inline comments

- **A workaround, or a line whose behavior is not obvious, has an inline comment.**
