---
name: review-harness
description: "Review harness material for necessity, scope, conflicts, redundancy, actionability, and safety. Report only by default. Pass \"--fix\" to apply fixes. Accept branch or file paths/ranges; otherwise review uncommitted changes. Triggers: \"harnessをレビュー\", \"skillの変更をレビュー\", \"review my harness changes\"."
argument-hint: "[branch | <file[:line[-end]]>...] [--fix]"
allowed-tools: Agent, Read, Edit, Write, Bash(dev-rules-root), Bash($CLAUDE_PLUGIN_ROOT/scripts/save-diff.sh*), Bash($CLAUDE_PLUGIN_ROOT/scripts/review-record.sh*), Bash(git diff *), Bash(git log *)
---

# Review Harness Skill

Set `DEV_RULES_ROOT` by running `dev-rules-root` before preparing
the review. Pass the resulting absolute path to the reviewer.

Review rules, skills, agent prompts, references, hooks, and always-on files through
`$DEV_RULES_ROOT/perspectives/harness.md`. `branch`, file selectors,
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
  `bash "$DEV_RULES_ROOT/scripts/save-diff.sh" branch` or
  `bash "$DEV_RULES_ROOT/scripts/save-diff.sh"`. The latter reviews
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
  subagent_type: "dev-rules:review-perspective",
  prompt: """
    DEV_RULES_ROOT: <resolved plugin root>
    Perspective reference file (Read this first, it is your rubric):
      <plugin root>/perspectives/harness.md
    Changed-files list (pass it to rules.sh per the contract; omit for direct
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

Create the record first (item 1 of **Record the findings**, below), before any triage.

Apply these rules to what the reviewers return:

- **Ignore** a finding that misreads the material, speculates about code outside it, or
  targets an existing instruction the change does not touch.
- **Out of scope** (any severity) — the finding names code outside the material, not a
  file or hunk in it: report, do not fix.
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
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill review-harness --perspective <name>... <rules.sh paths>
   ```

   - `--perspective`: each perspective that ran (harness), findings or not.
   - `<rules.sh paths>`: what the reviewers passed to `rules.sh` — `--files-list <FILES>` or the selected paths without any `:line` suffix.

2. After each round's triage and dedupe, add that round's findings, one per line. A
   later round adds only findings not already recorded. With none, skip `add`.

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
- Record: <the RECORD= path, or "not recorded — reason">

### Fixed
- <finding → fix, as in Record the findings, item 3>
(with --fix; omit or say "None" if nothing was fixable)

### Would fix
- <finding → fix it would apply>
(without --fix, in place of "Fixed")

### Not fixed / reported only
- <finding> (reason: out-of-scope subtraction / Low not simple / etc.)
```
