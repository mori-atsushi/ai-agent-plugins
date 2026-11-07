---
name: review-code
description: "Review code from five perspectives, or a directory's structure from the design perspective; report-only by default. Pass \"--fix\" to fix and verify. Pass \"branch\" for a branch review, or file paths/ranges or directories for direct review; otherwise review uncommitted changes. Triggers: \"polish\", \"ポリッシュ\", \"レビューして修正\", \"review this diff\"."
argument-hint: "[branch | <file[:line[-end]]>... | <dir>...] [--fix]"
allowed-tools: Agent, SendMessage, Read, Edit, Write, Bash(dev-rules-root), Bash($CLAUDE_PLUGIN_ROOT/scripts/save-diff.sh*), Bash(python3 $CLAUDE_PLUGIN_ROOT/scripts/package-map.py*), Bash($CLAUDE_PLUGIN_ROOT/scripts/review-record.sh*), Bash(git diff *), Bash(git log *), Bash(git mv *)
---

# Review Code Skill

Set `DEV_RULES_ROOT` by running `dev-rules-root` before preparing the
review. Pass the resulting absolute path to every reviewer.

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

## Step 0: Setup

Resolve the material:

- **Branch or uncommitted scope**: run
  `bash "$DEV_RULES_ROOT/scripts/save-diff.sh" branch` or
  `bash "$DEV_RULES_ROOT/scripts/save-diff.sh"`. The latter reviews
  uncommitted changes only.
- **Direct file scope**: do **not** run the diff script. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path. Do not widen the selection.
- **Directory scope**: do not run the diff script or widen the selection. Run
  `python3 "$DEV_RULES_ROOT/scripts/package-map.py" <dir>...` and capture `MAP=` and
  `FILES=`. Hand the reviewer both paths. Do not read the map here.

For diff scope, capture `DIFF=`, `FILES=`, and `MODE=` from stdout. Stop if
`EMPTY=true`. Hand reviewers the `DIFF` path. Do not read or paste the diff here.

From the **conversation history**, extract:
- **Objective**: one sentence describing the goal
- **Specifications**: bullet list of requirements from specs, then items from issues,
  design docs, or plans, each tagged `(plan)` (omit if none)

## Step 1: Launch review agents — ITERATION START

Spawn all five review agents in one message; for directory scope, spawn
`review-design` alone. Do not verify before the first review.

Spawn the plugin's `review-perspective` agent for each row. Do not set `model:`:
the agent's own frontmatter owns it.

```
Agent(
  description: "Review <name from table>",
  subagent_type: "dev-rules:review-perspective",
  prompt: """
    DEV_RULES_ROOT: <resolved plugin root>
    Perspective reference file (Read this first, it is your rubric):
      <perspective file path from table>
    Changed-files list (pass it to rules.sh per the contract; omit for direct
    MATERIAL selectors):
      <FILES path from Step 0>
    Material to review:
      <DIFF path from Step 0, direct MATERIAL selectors, or the MAP path>
    For direct MATERIAL selectors or a MAP, read them as the contract's step 3 says.
    Do not obtain a diff.
    <only for rows marked ✓ — include the two blocks below, omit them otherwise:>
    Objective:
      <one-sentence objective from Step 0>
    Specifications:
      <bullet list from Step 0, or omit block if none>
  """
)
```

| # | Label | Perspective file path | Obj + Spec? |
|---|-------|-----------------------|-------------|
| 1 | `review-simplify`   | `<plugin root>/perspectives/simplify.md`   | — |
| 2 | `review-readability` | `<plugin root>/perspectives/readability.md` | — |
| 3 | `review-spec`       | `<plugin root>/perspectives/spec.md`       | ✓ |
| 4 | `review-design`     | `<plugin root>/perspectives/design.md`     | ✓ |
| 5 | `review-test`       | `<plugin root>/perspectives/test.md`       | ✓ |

**With `--fix`: record each agent's `agentId`** from the tool return value — Step 3 resumes
agents via `SendMessage(to: agentId)`. Without `--fix`, the handles are not needed.

## Step 2: Triage

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

- **Spec update suggested**: fix — apply the spec edit in this PR when the change
  intentionally supersedes the recorded behavior; leave it out only when the correct
  new wording is unclear
- **Contradicts the plan** (an issue, design doc, task list, or plan file the change
  was built from): judge the finding on its merits, never only by "the plan says
  otherwise". Sounder finding → treat it as in scope and, with `--fix`, also update
  any plan file in the repository; report the departure for the PR. Sounder plan →
  keep it and report why the finding is wrong. A user message in this conversation
  is not a plan: report a conflict with it, do not override it.

### Record the findings

Do this on every review, including one with no findings: the record counts which rules
were applied. The header of `scripts/review-record.sh` defines a finding's fields.

1. Before the first triage, create the record once. Keep the printed `RECORD=` path for
   every later round:

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill review-code --perspective <name> [--perspective <name>]... <rules.sh paths>
   ```

   - `--perspective`: one per perspective that ran (all five, or design alone for directory scope), findings or not.
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

**Without `--fix`**: go straight to Step 4 (report) — no matter what Step 2 found.

**With `--fix`**: if no in-scope Critical/High/Medium findings (and any earlier fixes
already verified) → Step 4 (report). Otherwise → Step 3.

## Step 3: Fix + Re-verify — only with `--fix`, MANDATORY if Step 2 has fixable findings

Fix in-scope Critical, High, and Medium findings; move or rename a file with
`git mv`. Fix build or test failures. Apply valid, simple Low fixes too.

**Verify only what you changed.** Use modules that your fixes touched. Skip only when
the fixes cannot break a build or test. Examples are docs, comments, whitespace,
formatting, and string-resource text. When in doubt, run verification.

For branch or uncommitted scope, rerun the Step 0 script with the same mode. For
direct file scope, keep the selectors; for directory scope, rerun `package-map.py`.
Do not run the diff script. When a fix moved or renamed a selected file or directory,
its new path replaces the old selector. Then:
- Resume `review-readability` **always** (`review-design` for directory scope), plus any agent that had findings in the previous round
- Run the narrowed verification (unless skipped per above)

```
SendMessage(to: "<agentId>", message: "Material updated after fixes (<DIFF path, MATERIAL selectors, or MAP path>) — re-read and re-review. Fixes: <summary>", summary: "Updated material — please re-review")
```

Go to Step 2 with new findings. Stop after 3 total iterations.

## Step 4: Report

**With `--fix`**:

```
## Review Complete

### Iterations: <N>

### Findings
<findings, as in Record the findings, item 3>
Record: <the RECORD= path, or "not recorded — reason">

### Test / Build
- ✅ <selectors> passed  (or ❌ <module>: <summary>, or ⏭️ skipped — <reason, e.g. docs-only fixes / no fixes made>)
```

**Without `--fix`**:

```
## Review Report

### Findings by severity
<findings, as in Record the findings, item 3>
Record: <the RECORD= path, or "not recorded — reason">
```
