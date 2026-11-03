---
description: When to write a comment, and what documentation and inline comments contain
perspectives:
  - readability
---

# Comment Rules

## General

- [CM-1] **A comment explains what the code itself cannot express.** Remove one that only
  restates the code, such as `// increment counter` above `counter++`.
- [CM-2] **A comment comes only after the code cannot be made clearer.** Improve the code
  first; the comment covers what remains.
- [CM-3] **A comment is as short as possible, in plain English a non-native speaker can
  follow.** Cut every line and word that adds no information.
- [CM-4] **A comment describes current behavior, not history.** The reasoning behind a past
  decision belongs in the commit message.

## Documentation comments

- [CM-5] **A documentation comment carries only background the code cannot show:** argument
  conditions (already sorted, non-negative, non-empty), what the return value means,
  and preconditions the caller must meet. Usually that is no comment or one line. A
  comment that walks through branches, edge cases, or steps the body makes plain is
  too long; when the code is hard to follow, simplify the code instead.
- [CM-6] **A documentation comment that exists has a summary.** Documenting only a property
  or a return value is not enough.
- [CM-7] **A function whose purpose is an action, and that also returns a value, documents
  that value.**
- [CM-8] **A `null` return or nullable property documents what `null` means** when the name
  or type does not make it obvious.
- [CM-9] **A documentation comment describes its own type, not its callers.** Naming a
  related type is fine; a list of callers goes stale.

## Inline comments

- [CM-10] **A workaround, or a line whose behavior is not obvious, has an inline comment.**
