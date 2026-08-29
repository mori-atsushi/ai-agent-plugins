---
name: review-harness
description: "Review harness material for necessity, scope, conflicts, redundancy, actionability, and safety. Report only by default. Pass \"--fix\" to apply fixes. Accept branch or file paths/ranges; otherwise review uncommitted changes. Triggers: \"harnessをレビュー\", \"skillの変更をレビュー\", \"review my harness changes\"."
argument-hint: "[branch | <file[:line[-end]]>...] [--fix]"
allowed-tools: Agent, Read, Edit, Write, Bash(review-perspectives-root), Bash($CLAUDE_PLUGIN_ROOT/scripts/save-diff.sh*), Bash(git diff *), Bash(git log *)
---

# Review Harness Skill

Set `REVIEW_PERSPECTIVES_ROOT` by running `review-perspectives-root` before preparing
the review. Pass the resulting absolute path to the reviewer.

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

## Step 0: Setup

Resolve the material:

- **Branch or uncommitted scope**: run
  `bash "$REVIEW_PERSPECTIVES_ROOT/scripts/save-diff.sh" branch` or
  `bash "$REVIEW_PERSPECTIVES_ROOT/scripts/save-diff.sh"`. The latter reviews
  uncommitted changes only.
- **Direct file scope**: do **not** run the diff script. Keep the validated selectors
  as `MATERIAL`. There is no `FILES` path.

For diff scope, capture `DIFF=`, `FILES=`, and `MODE=` from stdout. Stop if
`EMPTY=true`. Hand the reviewer the `DIFF` path. Do not read or paste the diff here.

From the conversation history, extract a one-sentence **Objective**.

## Step 1: Launch the review agent

Spawn the plugin's `review-perspective` agent. Pass no `model:`: the agent's own
frontmatter sets it, and this perspective has no claim on a heavier one.

```
Agent(
  description: "Review harness change",
  subagent_type: "review-perspectives:review-perspective",
  prompt: """
    REVIEW_PERSPECTIVES_ROOT: <resolved plugin root>
    Perspective reference file (Read this first, it is your rubric):
      <plugin root>/review-perspectives/harness.md
    Changed-files list (pass it to review-refs.sh per the contract; omit for direct
    MATERIAL selectors):
      <FILES path from Step 0>
    Material to review:
      <DIFF path from Step 0, or direct MATERIAL selectors>
    For direct MATERIAL selectors, read the named files and ranges directly. Do not
    obtain a diff.
    Objective:
      <one-sentence objective from Step 0>
  """
)
```

## Step 2: Triage

Apply **Triage** and **`--fix`** from
`$REVIEW_PERSPECTIVES_ROOT/references/review-triage.md`. One rule
is specific to this skill:

- **Subtraction alternatives** — when the agent names a concrete replacement, merge,
  or deletion, take it. Adding on top of what it named needs a stated reason. A
  subtraction that deletes untouched content is **reported, not applied**. It is a
  proposal about another instruction.

## Step 3: Apply — only with `--fix`

Apply the fixes selected in Step 2 (Critical/High/Medium, valid/simple Low, and
taken subtraction alternatives). Do not re-spawn the agent — one review pass; carry
anything unresolved into the report.

Without `--fix`, make no edits — Step 2's triage already decided what *would* be
fixed; the report states it.

## Step 4: Report

```
## Harness Review

### Review
- Objective: <one sentence>
- Subtraction: <what was replaced/merged/deleted instead of added, or "net addition — reason">
- Always-on net: <±N lines>

### Fixed
- <finding → fix>
(with --fix; omit or say "None" if nothing was fixable)

### Would fix
- <finding → fix it would apply>
(without --fix, in place of "Fixed")

### Not fixed / reported only
- <finding> (reason: out-of-scope subtraction / Low not simple / etc.)
```
