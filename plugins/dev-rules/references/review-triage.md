# Review Triage

What the review workflow skills do with the findings a
reviewer returns, on either harness. Triage rows that belong to one skill — spec
updates, subtraction alternatives, a plan's scope gate — stay in that skill.

Kept out of `references/review-contract.md` on purpose: a reviewer reads that
file, and `Read` returns all of it, so none of this may sit inside it.

## Triage

- **Ignore** a finding that misreads the material, speculates about code outside it, or
  targets an existing instruction the change does not touch.
- **Out of scope** (any severity) — the finding names code outside the material,
  not a file or hunk in it: report, do not fix.
- **🔴 / 🟠 / 🟡 in scope**: fix.
- **⚪ Low in scope**: fix when valid and simple; otherwise report.
- **Dedupe** across reviewers before reporting.
- **Code findings are fixed in the code, not covered with a comment.** Rename,
  restructure, simplify, or add a test first. Add a comment when background the code
  cannot show still needs one, and check it against
  `$DEV_RULES_ROOT/rules/comments.md` first.

## `--fix`

`--fix` gates only the *applying*. Without it, triage still runs — it decides what gets
**reported** rather than **fixed**, so out-of-scope and unfixed findings are still
listed in full, and the report says what it *would* fix. Make no edits.

## Record

The review's findings live in one record file. The report's findings are printed from
it, and rule usage is counted from it.

1. Before the first triage, create the record once. Keep the printed `RECORD=` path for
   every later round:

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill <skill> --perspective <name>... <rules.sh paths>
   ```

   - `--perspective`: each perspective that ran, findings or not.
   - `<rules.sh paths>`: what the reviewers passed to `rules.sh` — `--files-list <FILES>`,
     the selected paths without any `:line` suffix, or nothing for a plan.

2. After each round's triage and dedupe, add that round's findings, one JSON object per
   line, as the header of `review-record.sh` defines them. A later round adds only
   findings not already recorded.

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" add "$RECORD" <<'EOF'
   {"perspectives": ["design"], "severity": "medium", "location": "app/Main.kt:42", "issue": "<the finding and its fix>", "grounds": ["KD-3"], "triage": "fix"}
   EOF
   ```

   - `perspectives`: the reviewers that raised it; several when dedupe merged them.
   - `location`: `file:line`, or the plan section.
   - `issue`: the finding and its fix; for a plan, also why it matters.
   - `triage`: `fix` (fixed, or would be without `--fix`), `report` (valid and in scope,
     not fixed), `out-of-scope` (the **Out of scope** row), or `ignore` (including a finding a
     skill's gate drops).

   On exit 1, fix the lines it names and resend the whole round.

3. Print the findings for the report with
   `bash "$DEV_RULES_ROOT/scripts/review-record.sh" report "$RECORD"`, grouped by
   severity, or with `report --by-outcome` as Fixed and Remaining. Use its output
   unchanged.

If the script fails any other way, write the findings into the report yourself in the
same shape — by severity, or Fixed and Remaining — and say they were not recorded.
