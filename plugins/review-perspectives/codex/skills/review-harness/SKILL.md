---
name: review-harness
description: Review harness material for necessity, scope, conflicts, redundancy, actionability, and safety. Report only by default. Pass `--fix` to apply fixes. Pass `branch` for a branch review or file paths/ranges for direct review. Otherwise review uncommitted changes. Use for harness, skill, or rule review.
---

# Review Harness

First resolve `REVIEW_PERSPECTIVES_ROOT`, this plugin's installation directory. Use
the source path for this `codex/skills/review-harness/SKILL.md` and its plugin-root
ancestor. Pass the resolved absolute path to the reviewer.

Review rules, skills, agent prompts, references, hooks, and always-on files through
`$REVIEW_PERSPECTIVES_ROOT/review-perspectives/harness.md`. `branch`, file selectors,
and `--fix` are
independent. Resolve scope in this order:

1. `branch` — review the full branch diff.
2. One or more file selectors — review those files or inclusive ranges directly.
3. Neither — review uncommitted changes only.

`branch` wins over file selectors. State that the selectors were ignored. A selector
is a repo-relative path. It can end in `:line` or `:start-end`, for example
`SKILL.md:42-78`. Validate every path. `--fix` enables fixes. Without it, triage still
runs. Report what you would fix, but do not edit.

A change already reviewed against `harness.md` in place still needs this pass. The
earlier review did not see this edit or its effects.

## 1. Prepare the review

Resolve the material:

```bash
bash "$REVIEW_PERSPECTIVES_ROOT/scripts/save-diff.sh" [branch]
```

- For branch or uncommitted scope, run the script. Pass `branch` only for branch
  scope. Record `MODE`, `DIFF`, and `FILES`. Stop if `EMPTY=true`. Do not read or
  paste the diff in the parent context.
- For direct file scope, **do not run the diff script**. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path.
- Infer a one-sentence objective from the conversation.

## 2. Run the review

Spawn one read-only subagent. Wait for its result.

```text
`REVIEW_PERSPECTIVES_ROOT` is <plugin root>. Read
<plugin root>/references/review-contract.md and follow it. Your perspective is
<plugin root>/review-perspectives/harness.md; the material is <DIFF path, or direct
MATERIAL selectors>. That perspective requires two sections (Subtraction alternatives,
Always-on budget) before the findings list — emit them.

Changed-files list (pass it to review-refs.sh per the contract; omit this block for
direct MATERIAL selectors):
<FILES path>

For direct MATERIAL selectors, read the named files and ranges directly. Do not
obtain a diff.

Objective:
<one-sentence objective>
```

## 3. Triage

Apply **Triage** and **`--fix`** from
`$REVIEW_PERSPECTIVES_ROOT/references/review-triage.md`. One rule
is specific to this skill:

- **Subtraction alternatives** — when the agent names a concrete replacement, merge,
  or deletion, take it. Adding on top of what it named needs a stated reason. A
  subtraction that deletes untouched content is **reported, not applied**. It is a
  proposal about another instruction.

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

### Fixed
- <finding → fix>
(with --fix; say "None" if nothing was fixable)

### Would fix
- <finding → fix it would apply>
(without --fix, in place of "Fixed")

### Not fixed / reported only
- <finding> (reason: out-of-scope subtraction / Low not simple / etc.)
```
