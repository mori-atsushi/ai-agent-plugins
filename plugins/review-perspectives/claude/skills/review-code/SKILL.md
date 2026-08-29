---
name: review-code
description: "Review code from five perspectives; report-only by default. Pass \"--fix\" to fix and verify. Pass \"branch\" for a branch review or file paths/ranges for direct review; otherwise review uncommitted changes. Triggers: \"polish\", \"ポリッシュ\", \"レビューして修正\", \"review this diff\"."
argument-hint: "[branch | <file[:line[-end]]>...] [--fix]"
allowed-tools: Agent, SendMessage, Read, Edit, Write, Bash(review-perspectives-root), Bash($CLAUDE_PLUGIN_ROOT/scripts/save-diff.sh*), Bash(git diff *), Bash(git log *)
---

# Review Code Skill

Set `REVIEW_PERSPECTIVES_ROOT` by running `review-perspectives-root` before preparing the
review. Pass the resulting absolute path to every reviewer.

Review code from five perspectives. `branch`, file selectors, and `--fix` are
independent. Resolve scope in this order:

1. `branch` — review the full branch diff.
2. One or more file selectors — review those files or inclusive ranges directly.
3. Neither — review uncommitted changes only.

`branch` wins over file selectors. State that the selectors were ignored. A selector
is a repo-relative path. It can end in `:line` or `:start-end`. For example:
`app/Main.kt`, `app/Main.kt:42`, or `app/Main.kt:42-78`. Validate every path.

Without `--fix`, review once and report. Do not edit, build, test, or re-review. With
`--fix`, fix valid in-scope findings. Re-review until clean or after three rounds.

## Step 0: Setup

Resolve the material:

- **Branch or uncommitted scope**: run
  `bash "$REVIEW_PERSPECTIVES_ROOT/scripts/save-diff.sh" branch` or
  `bash "$REVIEW_PERSPECTIVES_ROOT/scripts/save-diff.sh"`. The latter reviews
  uncommitted changes only.
- **Direct file scope**: do **not** run the diff script. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path. Do not widen the selection.

For diff scope, capture `DIFF=`, `FILES=`, and `MODE=` from stdout. Stop if
`EMPTY=true`. Hand reviewers the `DIFF` path. Do not read or paste the diff here.

From the **conversation history**, extract:
- **Objective**: one sentence describing the goal
- **Specifications**: bullet list of requirements from specs/design docs/plans (omit if none)

## Step 1: Launch review agents — ITERATION START

Spawn all five review agents in one message. Do not verify before the first review.

Spawn the plugin's `review-perspective` agent for each row. Do not set `model:`:
the agent's own frontmatter owns it.

```
Agent(
  description: "Review <name from table>",
  subagent_type: "review-perspectives:review-perspective",
  prompt: """
    REVIEW_PERSPECTIVES_ROOT: <resolved plugin root>
    Perspective reference file (Read this first, it is your rubric):
      <perspective file path from table>
    Changed-files list (pass it to review-refs.sh per the contract; omit for direct
    MATERIAL selectors):
      <FILES path from Step 0>
    Material to review:
      <DIFF path from Step 0, or direct MATERIAL selectors>
    For direct MATERIAL selectors, read the named files and ranges directly. Do not
    obtain a diff.
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
| 1 | `review-simplify`   | `<plugin root>/review-perspectives/simplify.md`   | — |
| 2 | `review-readability` | `<plugin root>/review-perspectives/readability.md` | — |
| 3 | `review-spec`       | `<plugin root>/review-perspectives/spec.md`       | ✓ |
| 4 | `review-design`     | `<plugin root>/review-perspectives/design.md`     | ✓ |
| 5 | `review-test`       | `<plugin root>/review-perspectives/test.md`       | ✓ |

**With `--fix`: record each agent's `agentId`** from the tool return value — Step 3 resumes
agents via `SendMessage(to: agentId)`. Without `--fix`, the handles are not needed.

## Step 2: Triage

Apply **Triage** and **`--fix`** from
`$REVIEW_PERSPECTIVES_ROOT/references/review-triage.md`. One rule
is specific to this skill:

- **Spec update suggested**: fix — apply the spec edit in this PR when the change
  intentionally supersedes the recorded behavior; leave it out only when the correct
  new wording is unclear
- **Design finding**: evaluate it on its merits. Do not reject it only because the
  implementation follows a plan. Plans guide the work; they are not the required
  solution.

**Without `--fix`**: go straight to Step 4 (report) — no matter what Step 2 found.

**With `--fix`**: if no in-scope Critical/High/Medium findings (and any earlier fixes
already verified) → Step 4 (report). Otherwise → Step 3.

## Step 3: Fix + Re-verify — only with `--fix`, MANDATORY if Step 2 has fixable findings

Fix in-scope Critical, High, and Medium findings. Fix build or test failures. Apply
valid, simple Low fixes too.

**Verify only what you changed.** Use modules that your fixes touched. Skip only when
the fixes cannot break a build or test. Examples are docs, comments, whitespace,
formatting, and string-resource text. When in doubt, run verification.

For branch or uncommitted scope, rerun the Step 0 script with the same mode. For
direct file scope, keep the selectors. Do not run the diff script. Then:
- Resume `review-readability` **always**, plus any agent that had findings in the previous round
- Run the narrowed verification (unless skipped per above)

```
SendMessage(to: "<agentId>", message: "Material updated after fixes (<DIFF path or MATERIAL selectors>) — re-read and re-review. Fixes: <summary>", summary: "Updated material — please re-review")
```

Go to Step 2 with new findings. Stop after 3 total iterations.

## Step 4: Report

**With `--fix`**:

```
## Review Complete

### Iterations: <N>

### Fixed
- [file:line] <fix> (was: <finding>)

### Test / Build
- ✅ <selectors> passed  (or ❌ <module>: <summary>, or ⏭️ skipped — <reason, e.g. docs-only fixes / no fixes made>)

### Remaining
- ⚪/🟠 [file:line] — <finding> (reason: out-of-scope / Low not fixed)
```

**Without `--fix`**:

```
## Review Report

### Findings by severity
🔴 Critical
- [file:line] <finding> (in-scope / out-of-scope)

🟠 High
- ...

🟡 Medium
- ...

⚪ Low
- ...

(Omit a severity group with no findings. If none at all, say "No issues found.")
```
