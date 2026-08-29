---
name: review-code
description: Review code from five perspectives. Report only by default. Pass `--fix` to fix and verify. Pass `branch` for a branch review or file paths/ranges for direct review. Otherwise review uncommitted changes. Use for code review, polishing, or "レビューして修正".
---

# Review Code

First resolve `REVIEW_PERSPECTIVES_ROOT`, this plugin's installation directory. Use
the source path for this `codex/skills/review-code/SKILL.md` and its plugin-root
ancestor. Pass the resolved absolute path to every reviewer.

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

## 1. Prepare the review

Resolve the material:

```bash
bash "$REVIEW_PERSPECTIVES_ROOT/scripts/save-diff.sh" [branch]
```

- For branch or uncommitted scope, run the script. Pass `branch` only for branch
  scope. Record `MODE`, `DIFF`, and `FILES`. Stop if `EMPTY=true`. Do not read or
  paste the diff in the parent context.
- For direct file scope, **do not run the diff script**. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path. Do not widen the selection.
- Infer a one-sentence objective. Infer requirements from the conversation, specs,
  design docs, and plans. Omit unavailable blocks.

## 2. Run the first review in parallel

Spawn five read-only subagents at once. Wait for every result. Do not verify before
the first review. Give each subagent one perspective and this common instruction:

```text
`REVIEW_PERSPECTIVES_ROOT` is <plugin root>. Read
<plugin root>/references/review-contract.md and follow it. Your perspective is
<perspective file>; the material is <DIFF path, or direct MATERIAL selectors>. Other
reviewers cover the other perspectives, so stay strictly inside yours.

Changed-files list (pass it to review-refs.sh per the contract; omit this block for
direct MATERIAL selectors):
<FILES path>

For direct MATERIAL selectors, read the named files and ranges directly. Do not
obtain a diff.

Objective:
<objective>

Specifications:
<specifications>
```

Omit the objective and specifications blocks for the rows marked No below.

| Label | Perspective file | Include objective and requirements |
| --- | --- | --- |
| `review-simplify` | `<plugin root>/review-perspectives/simplify.md` | No |
| `review-readability` | `<plugin root>/review-perspectives/readability.md` | No |
| `review-spec` | `<plugin root>/review-perspectives/spec.md` | Yes |
| `review-design` | `<plugin root>/review-perspectives/design.md` | Yes |
| `review-test` | `<plugin root>/review-perspectives/test.md` | Yes |

**With `--fix`**: keep the returned agent handles — they are needed for follow-up
re-reviews. Without `--fix`, the handles are not needed.

## 3. Triage

Apply **Triage** and **`--fix`** from
`$REVIEW_PERSPECTIVES_ROOT/references/review-triage.md`. One rule
is specific to this skill:

- Apply a suggested spec update in this change when it intentionally supersedes the
  recorded behavior; leave it out only when the correct new wording is unclear.
- Evaluate every design finding on its merits. Do not reject it only because the
  implementation follows a plan. Plans guide the work; they are not the required
  solution.

**Without `--fix`**: go straight to the report, no matter what this step found.

**With `--fix`**: if no fixable finding remains, go to the report. Otherwise
continue to step 4.

## 4. Fix and re-verify — only with `--fix`

After fixes, verify only affected modules. Skip verification only for changes that
cannot affect a build or test. Examples are docs, comments, whitespace, formatting,
and string-resource text. For branch or uncommitted scope, rerun the diff script with
the same `MODE`. For direct file scope, keep the selectors. Do not run the script.

Resume `review-readability` and each agent that found an issue in the prior round.
Send the updated diff path or original selectors with a short fix summary. Ask the
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

### Fixed
- [file:line] <fix> (was: <finding>)

### Test / Build
- ✅ <selectors> passed
  # or ❌ <module>: <summary>
  # or ⏭️ skipped — <reason>

### Remaining
- ⚪/🟠 [file:line] — <finding> (reason: out-of-scope / Low not fixed)
```

If there are no fixed or remaining findings, say so explicitly in the relevant
section.

**Without `--fix`**:

```markdown
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
```

Omit a severity group with no findings. If there are none at all, say exactly
"No issues found."
