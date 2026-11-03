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

## Log

After the first round's triage, log every finding the reviewers returned, one JSON
object per line on stdin. Log before dedupe, so a finding two reviewers raise is two
lines.

```bash
bash "$DEV_RULES_ROOT/scripts/log-findings.sh" --skill <skill> --perspective <name>... <rules.sh paths> <<'EOF'
{"perspective": "design", "severity": "medium", "triage": "accepted", "rules": ["KD-3"]}
EOF
```

- `--perspective`: each perspective that ran, findings or not.
- `<rules.sh paths>`: what the reviewers passed to `rules.sh` — `--files-list <FILES>`,
  the selected paths without any `:line` suffix, or nothing for a plan.
- `severity`: `critical`, `high`, `medium`, or `low`, as triaged.
- `triage`: `accepted` (valid and in scope, fixed or not), `rejected` (ignored, judged
  wrong, or dropped by a skill's validity gate), or `out-of-scope` (including a skill's
  scope gate).
- `rules`: the rule IDs, and `.agents/rules/` paths, in the finding's grounds. Leave
  out spec and perspective paths; `[]` when none remain.

On exit 1, fix the lines it names and resend every finding. On any other failure,
continue and say in the report that the findings were not logged.
