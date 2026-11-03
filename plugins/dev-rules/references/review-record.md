# Review record

Each review's findings go into one record file, from which rule usage is counted. The
header of `scripts/review-record.sh` defines a finding's fields.

1. Before the first triage, create the record once. Keep the printed `RECORD=` path for
   every later round:

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill <skill> --perspective <name>... <rules.sh paths>
   ```

   - `--perspective`: each perspective that ran, findings or not.
   - `<rules.sh paths>`: what the reviewers passed to `rules.sh` — `--files-list <FILES>`,
     the selected paths without any `:line` suffix, or nothing for a plan.

2. After each round's triage and dedupe, add that round's findings, one per line. A
   later round adds only findings not already recorded.

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" add "$RECORD" <<'EOF'
   {"perspectives": ["design"], "severity": "medium", "location": "app/Main.kt:42", "issue": "<the finding and its fix>", "grounds": ["KD-3"], "triage": "in-scope"}
   EOF
   ```

   - `issue`: the finding and its fix; for a plan, also why it matters.
   - `grounds`: as the reviewer cited them.
   - `triage`: `out-of-scope` for the **Out of scope** row of `review-triage.md`;
     `ignore` for a finding triage or a skill's gate drops.

   On exit 1, fix the lines it names and resend the whole round. On success it prints
   the numbers it gave, in input order.

3. Write the report's findings yourself: every round's, with the numbers `add` gave and
   the text, severity, and grounds you recorded. Group them under `🔴 Critical`, `🟠 High`,
   `🟡 Medium`, and `⚪ Low`, omitting empty groups, one line each:
   `- #<number> [<location>] <issue> — _grounds: <grounds>_`, with ` (out of scope)`
   appended for `out-of-scope`, or ` (fixed)` for one `--fix` fixed. End with
   `Ignored: #<number>, ...` when any were ignored. With nothing to show, write
   `No issues found.`

If recording fails any other way, such as no `jq` (exit 2), write the findings the same
way without numbers, and say they were not recorded.
