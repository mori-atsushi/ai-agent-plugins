---
name: review-code
description: Review code from five perspectives, or a directory's structure from the design perspective. Report only by default. Pass `--fix` to fix and verify. Pass `branch` for a branch review, or file paths/ranges or directories for direct review. Otherwise review uncommitted changes. Use for code review, polishing, or "レビューして修正".
---

# Review Code

First resolve `DEV_RULES_ROOT`, this plugin's installation directory. Use
the source path for this `codex/skills/review-code/SKILL.md` and its plugin-root
ancestor. Pass the resolved absolute path to every reviewer.

Review code from five perspectives. Pick the scope from the arguments; `--fix`
combines with any of them:

1. `branch` — review the full branch diff.
2. One or more file selectors — review those files or inclusive ranges directly.
3. One or more directory selectors — review each directory's structure from its map,
   with the design perspective alone. Each file's own content is left to a file review.
4. None — review uncommitted changes only.

A selector is a repo-relative path. A file selector can end in `:line` or
`:start-end`, for example `app/Main.kt`, `app/Main.kt:42`, or `app/Main.kt:42-78`; a
directory selector cannot. Validate every path. When the arguments mix scopes —
`branch` with a selector, or file selectors with directory selectors — stop and say
so, without reviewing.

Without `--fix`, review once and report. Do not edit, build, test, or re-review. With
`--fix`, fix valid in-scope findings. Re-review until clean or after three rounds.

## 1. Prepare the review

Resolve the material:

```bash
bash "$DEV_RULES_ROOT/scripts/save-diff.sh" [branch]
```

- For branch or uncommitted scope, run the script. Pass `branch` only for branch
  scope. Record `MODE`, `DIFF`, and `FILES`. Stop if `EMPTY=true`. Do not read or
  paste the diff in the parent context.
- For direct file scope, **do not run the diff script**. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path. Do not widen the selection.
- For directory scope, do not run the diff script or widen the selection. Run
  `python3 "$DEV_RULES_ROOT/scripts/package-map.py" <dir>...` and record `MAP` and
  `FILES`. Do not read the map in the parent context.
- Infer a one-sentence objective. Infer requirements from the conversation and specs,
  then add items from issues, design docs, and plans, each tagged `(plan)`. Omit
  unavailable blocks.

## 2. Run the first review in parallel

Read `<plugin root>/codex/references/initial-reviewer.md` and apply it to every
initial reviewer. Spawn five read-only subagents at once; for directory scope, spawn
`review-design` alone. Wait for every result. Do
not verify before the first review. Give each subagent one perspective and this common
instruction:

```text
`DEV_RULES_ROOT` is <plugin root>. Read
<plugin root>/references/review-contract.md and follow it. Your perspective is
<perspective file>; the material is <DIFF path, direct MATERIAL selectors, or the MAP
path>. Other
reviewers cover the other perspectives, so stay strictly inside yours.

Changed-files list (pass it to rules.sh per the contract; omit this block for
direct MATERIAL selectors):
<FILES path>

For direct MATERIAL selectors or a MAP, read them as the contract's step 3 says. Do
not obtain a diff.

Objective:
<objective>

Specifications:
<specifications>
```

Omit the objective and specifications blocks for the rows marked No below.

| Label | Perspective file | Include objective and requirements |
| --- | --- | --- |
| `review-simplify` | `<plugin root>/perspectives/simplify.md` | No |
| `review-readability` | `<plugin root>/perspectives/readability.md` | No |
| `review-spec` | `<plugin root>/perspectives/spec.md` | Yes |
| `review-design` | `<plugin root>/perspectives/design.md` | Yes |
| `review-test` | `<plugin root>/perspectives/test.md` | Yes |

**With `--fix`**: keep the returned agent handles — they are needed for follow-up
re-reviews. Without `--fix`, the handles are not needed.

## 3. Triage

Create the record first (item 1 of **Record the findings**, below), before any triage.

Apply these rules to what the reviewers return:

- **Ignore** a finding that misreads the material, speculates about code outside it, or
  targets an existing instruction the change does not touch.
- **Out of scope** (any severity) — the finding names code outside the review target
  (`$DEV_RULES_ROOT/references/review-contract.md` step 3), or its fix would change
  the design of code outside it: report, do not fix. A fix to the target may still
  make the mechanical edits it forces elsewhere: edits that keep behavior and need
  no new decision, such as the imports and call sites a move or rename breaks.
- **🔴 / 🟠 / 🟡 in scope**: fix.
- **⚪ Low in scope**: fix when valid and simple; otherwise report.
- **Dedupe** across reviewers before reporting.
- **Code findings are fixed in the code, not covered with a comment.** Rename,
  restructure, simplify, or add a test first. Add a comment when background the code
  cannot show still needs one, and check it against
  `$DEV_RULES_ROOT/rules/comments.md` first.

`--fix` gates only the applying. Without it, triage still runs: it decides what gets
**reported** rather than **fixed**, so out-of-scope and unfixed findings are still listed in full, and
the report says what it *would* fix. Make no edits.

This skill adds two rules:

- Apply a suggested spec update in this change when it intentionally supersedes the
  recorded behavior; leave it out only when the correct new wording is unclear.
- Judge a finding that contradicts the issue, design doc, task list, or plan file the
  change was built from on its merits, never only by "the plan says otherwise". When
  the finding is sounder, treat it as in scope and, with `--fix`, also update any plan
  file in the repository; report the departure for the PR. When the plan is sounder,
  keep it and report why the finding is wrong. A user message in this conversation is
  not a plan: report a conflict with it, do not override it.

### Record the findings

Do this on every review, including one with no findings: the record counts which rules
were applied. The header of `scripts/review-record.sh` defines a finding's fields.

1. Before the first triage, create the record once. Keep the printed `RECORD=` path for
   every later round:

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill review-code --perspective <name>... <rules.sh paths>
   ```

   - `--perspective`: each perspective that ran (all five, or design alone for directory scope), findings or not.
   - `<rules.sh paths>`: what the reviewers passed to `rules.sh` — `--files-list <FILES>` (from the diff or the map), or the selected paths without any `:line` suffix.

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

3. Write the report's findings yourself: every round's, with the numbers `add` gave and
   the text, severity, and grounds you recorded. Group them under `🔴 Critical`, `🟠 High`,
   `🟡 Medium`, and `⚪ Low`, omitting empty groups, one line each:
   `- #<number> [<location>] <issue> — _grounds: <grounds>_`, with ` (out of scope)`
   appended for `out-of-scope`, or ` (fixed)` for one `--fix` fixed. End with
   `Ignored: #<number>, ...` when any were ignored. With nothing to show, write
   `No issues found.`

If recording fails any other way, such as no `jq` (exit 2), write the findings the same
way without numbers, and say they were not recorded.

### Then route

**Without `--fix`**: go straight to the report, no matter what this step found.

**With `--fix`**: if no fixable finding remains, go to the report. Otherwise
continue to step 4.

## 4. Fix and re-verify — only with `--fix`

Move or rename a file with `git mv`. After fixes, verify only affected modules. Skip
verification only for changes that cannot affect a build or test. Examples are docs,
comments, whitespace, formatting, and string-resource text. For branch or
uncommitted scope, rerun the diff script with the same `MODE`. For direct file
scope, keep the selectors; for directory scope, rerun `package-map.py`. Do not run
the diff script. When a fix moved or renamed a selected file or directory, its new
path replaces the old selector.

Resume `review-readability` (`review-design` for directory scope) and each agent that
found an issue in the prior round. Send the updated diff path, original selectors, or
new map path with a short fix summary. Ask the
agent to re-read and re-review. Wait for results. Return to step 3. Reuse existing
subagent threads. Do not spawn replacements.

Stop after three total review iterations, even if issues remain.

On Claude Code, use this plugin's `review-perspective` agent for every reviewer. On
Codex, spawn a read-only subagent directly. In either harness, wait for the full first
round before triage and reuse the same reviewer threads for re-review.

## 5. Report

**With `--fix`**:

```markdown
## Review Complete

### Iterations: <N>

### Findings
<findings, as in Record the findings, item 3>
Record: <the RECORD= path, or "not recorded — reason">

### Test / Build
- ✅ <selectors> passed
  # or ❌ <module>: <summary>
  # or ⏭️ skipped — <reason>
```

**Without `--fix`**:

```markdown
## Review Report

### Findings by severity
<findings, as in Record the findings, item 3>
Record: <the RECORD= path, or "not recorded — reason">
```
