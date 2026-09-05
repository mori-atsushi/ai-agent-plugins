---
description: Comment readability conventions checked by the readability perspective
perspectives:
  - readability
---

# Readability Checklist: Comments

Project rules win. This checklist covers what they do not say.

## General

- **A comment explains something the code itself cannot express.** Remove a comment
  that only restates the code, such as `// increment counter` above `counter++`.
- **A comment is added only once the code itself cannot be made clearer.** Improving
  the code comes first; the comment covers what remains.
- **A comment is as short as possible, in plain English a non-native speaker can
  follow.** Every line and every word is a liability; cut what does not add
  information.
- **A comment describes current behavior, not past history.** Put the reasoning
  behind a past decision in the commit message, not the code.

## Documentation comments

- **A documentation comment is optional.** Skip it when the code already makes the
  intent clear; write one when a fuller explanation helps.
- **A documentation comment that exists has a summary.** Documenting only a property
  or a return value, with no summary, is not enough.
- **A function whose purpose is an action, and that also returns a value, documents
  that return value.** The action alone does not make the return obvious.
- **A function returning `null`, or a nullable property, documents what `null`
  means** when that meaning is not obvious from the name or type.
- **A documentation comment does not mention its callers.** Naming a related type is
  fine; caller lists go stale.

## Inline comments

- **A workaround or a line whose behavior is not obvious has an inline comment.**
- **A non-obvious argument constraint has an inline comment.** For example, that a
  value must already be sorted, non-negative, or non-empty.
