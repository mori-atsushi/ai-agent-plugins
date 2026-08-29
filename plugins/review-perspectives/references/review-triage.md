# Review Triage

What the review workflow skills do with the findings a
reviewer returns, on either harness. Triage rows that belong to one skill — spec
updates, subtraction alternatives, a plan's scope gate — stay in that skill.

Kept out of `references/review-contract.md` on purpose: a reviewer reads that
file, and `Read` returns all of it, so none of this may sit inside it.

## Triage

- **Ignore** a finding that misreads the material, speculates about code outside it, or
  targets an existing instruction the change does not touch.
- **Out of scope** (any severity): report, do not fix.
- **🔴 / 🟠 / 🟡 in scope**: fix.
- **⚪ Low in scope**: fix when valid and simple; otherwise report.
- **Dedupe** across reviewers before reporting.

## `--fix`

`--fix` gates only the *applying*. Without it, triage still runs — it decides what gets
**reported** rather than **fixed**, so out-of-scope and unfixed findings are still
listed in full, and the report says what it *would* fix. Make no edits.
