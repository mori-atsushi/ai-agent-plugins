---
name: review-harness
description: Review harness material for necessity, scope, conflicts, redundancy, actionability, and safety. Report only by default. Pass `--fix` to apply fixes. Pass `branch` for a branch review or file paths/ranges for direct review. Otherwise review uncommitted changes. Use for harness, skill, or rule review.
---

# Review Harness

First resolve `DEV_RULES_ROOT`, this plugin's installation directory. Use
the source path for this `codex/skills/review-harness/SKILL.md` and its plugin-root
ancestor. Pass the resolved absolute path to the reviewer.

Review rules, skills, agent prompts, references, hooks, and always-on files through
`$DEV_RULES_ROOT/perspectives/harness.md`. `branch`, file selectors,
and `--fix` are
independent. Resolve scope in this order:

1. `branch` — review the full branch diff.
2. One or more file selectors — review those files or inclusive ranges directly.
3. Neither — review uncommitted changes only.

When `branch` comes with file selectors, or a selector names a directory, stop and say
so, without reviewing. A selector is a repo-relative file path. It can end in `:line`
or `:start-end`, for example `SKILL.md:42-78`. Validate every path. `--fix` enables
fixes. Without it, triage still runs. Report what you would fix, but do not edit.

A change already reviewed against `harness.md` in place still needs this pass. The
earlier review did not see this edit or its effects.

## 1. Prepare the review

Resolve the material:

```bash
bash "$DEV_RULES_ROOT/scripts/save-diff.sh" [branch]
```

- For branch or uncommitted scope, run the script. Pass `branch` only for branch
  scope. Record `MODE`, `DIFF`, and `FILES`. Stop if `EMPTY=true`. Do not read or
  paste the diff in the parent context.
- For direct file scope, **do not run the diff script**. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path.
- Infer a one-sentence objective from the conversation.

## 2. Run the review

Read `<plugin root>/codex/references/initial-reviewer.md` and apply it to the initial
reviewer. Spawn one read-only subagent. Wait for its result.

```text
`DEV_RULES_ROOT` is <plugin root>. Read
<plugin root>/references/review-contract.md and follow it. Your perspective is
<plugin root>/perspectives/harness.md; the material is <DIFF path, or direct
MATERIAL selectors>. That perspective requires two sections (Subtraction alternatives,
Always-on budget) before the findings list — emit them.

Changed-files list (pass it to rules.sh per the contract; omit this block for
direct MATERIAL selectors):
<FILES path>

For direct MATERIAL selectors, read them as the contract's step 3 says. Do not
obtain a diff.

Objective:
<one-sentence objective>
```

## 3. Triage

Create the record first (item 1 of **Record the findings**, below), before any triage.

Apply these rules to what the reviewers return:

- **Ignore** a finding that misreads the material, speculates about code outside it, or
  targets an existing instruction the change does not touch.
- **Out of scope** (any severity) — the finding names code outside the review target
  (`$DEV_RULES_ROOT/references/review-contract.md` step 3): report, do not fix.
- **🔴 / 🟠 / 🟡 in scope**: fix.
- **⚪ Low in scope**: fix when valid and simple; otherwise report.
- **Dedupe** across reviewers before reporting.

`--fix` gates only the applying. Without it, triage still runs: it decides what gets
**reported** rather than **fixed**, so out-of-scope and unfixed findings are still listed in full, and
the report says what it *would* fix. Make no edits.

This skill adds one rule:

- **Subtraction alternatives** — when the agent names a concrete replacement, merge,
  or deletion, take it. Adding on top of what it named needs a stated reason. A
  subtraction that deletes untouched content is **reported, not applied**. It is a
  proposal about another instruction.

### Record the findings

Do this on every review, including one with no findings: the record counts which rules
were applied. The header of `scripts/review-record.sh` defines a finding's fields.

1. Before the first triage, create the record once. Keep the printed `RECORD=` path for
   every later round:

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill review-harness --perspective <name> [--perspective <name>]... <rules.sh paths>
   ```

   - `--perspective`: one per perspective that ran (harness), findings or not.
   - `<rules.sh paths>`: what the reviewers passed to `rules.sh` — `--files-list <FILES>` or the selected paths without any `:line` suffix.

2. After each round's triage and dedupe, add that round's findings, one per line.
   Start from the JSON lines in the reviewers' `jsonl` blocks: merge duplicates into
   one line listing every `perspectives`, change `severity` where you triaged it
   differently, and set `triage`. Repair a malformed reviewer line; do not drop its
   finding. A later round adds only findings not already recorded. With none, skip `add`.

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" add "$RECORD" <<'EOF'
   {"perspectives": ["design"], "severity": "medium", "location": "app/Main.kt:42", "issue": "<the finding and its fix>", "grounds": ["KD-3"], "triage": "in-scope"}
   EOF
   ```

   - `issue`: the finding and its fix; for a plan, also why it matters.
   - `grounds`: as the reviewer cited them.
   - `triage`: `out-of-scope` for the **Out of scope** bullet above;
     `ignore` for a finding the **Ignore** bullet or a skill's gate drops.

   On exit 1, fix the lines it names and resend the whole round. On success it prints
   the numbers it gave, in input order.

3. Write the findings yourself in the report's **Fixed** / **Would fix** / **Not fixed**
   lists: every round's, one line each:
   `- #<number> <severity> [<location>] <finding → fix> — _grounds: <grounds>_`, with the
   numbers `add` gave and the text, severity, and grounds you recorded. End with
   `Ignored: #<number>, ...` when any were ignored. With nothing to show, write
   `No issues found.`

If recording fails any other way, such as no `jq` (exit 2), write the findings the same
way without numbers, and say they were not recorded.

## 4. Apply — only with `--fix`

Apply the fixes selected in step 3 (Critical/High/Medium, valid/simple Low, and
taken subtraction alternatives). Do not re-spawn the agent — one review pass;
carry anything unresolved into the report.

Without `--fix`, make no edits — step 3's triage already decided what *would* be
fixed; the report states it.

On Claude Code, use this plugin's `review-perspective` agent. On Codex, spawn one
read-only subagent directly.

## 5. Report

```markdown
## Harness Review

### Review
- Objective: <one sentence>
- Subtraction: <what was replaced/merged/deleted instead of added, or "net addition — reason">
- Always-on net: <±N lines>
- Record: <the RECORD= path, or "not recorded — reason">

### Fixed
- <finding → fix, as in Record the findings, item 3>
(with --fix; say "None" if nothing was fixable)

### Would fix
- <finding → fix it would apply>
(without --fix, in place of "Fixed")

### Not fixed / reported only
- <finding> (reason: out-of-scope subtraction / Low not simple / etc.)
```
