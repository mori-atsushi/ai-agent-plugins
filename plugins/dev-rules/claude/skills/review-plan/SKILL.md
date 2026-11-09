---
name: review-plan
description: "Review an implementation plan before coding. Report only by default. Pass \"--fix\" to apply fixes when the plan is in files. Accept multiple plan paths or ranges. Triggers: \"プランをレビュー\", \"計画をレビュー\", \"plan review\"."
argument-hint: "[<plan text or file[:line[-end]]>...] [--fix]"
allowed-tools: Read, Edit, Agent, Bash(dev-rules-root), Bash($CLAUDE_PLUGIN_ROOT/scripts/review-record.sh*)
---

# Review Plan Skill

Set `DEV_RULES_ROOT` by running `dev-rules-root` before launching
reviewers. Pass the resulting absolute path to all three reviewers.

Review an implementation plan before coding. Find design and correctness issues while
they are cheap to fix. `--fix` is independent of the plan argument. This skill has no
uncommitted or branch mode.

## Step 0: Locate the plan

Use this source order:

1. One or more file selectors — read the selected files.
2. Inline arguments that are not selectors — use them as plan content.
3. No file selector or inline plan — extract the latest plan block from the
   conversation.

A selector is a repo-relative path. It can end in `:line` or `:start-end`. For
example: `plans/feature.md:42-78`. Validate every path. Each range is the primary
plan material. Multiple selectors form one plan. Do not run the diff script.

If no plan is identifiable, ask the user to provide one.

**Record the source.** Step 4 needs it. Only file selectors provide files to edit.

## Step 1: Extract context from the plan

From the plan text, extract:

- **Objective**: one sentence describing the goal
- **Specifications**: bullet list of concrete requirements and design decisions
  stated in the plan (which classes/modules are involved, invariants, expected
  behavior, data flow)

## Step 2: Launch agents in parallel

The three reviews use the plugin's `review-perspective` agent. They differ only by
perspective file. Spawn all three in one message. For inline plans, paste the full text.
For file selectors, give the selectors. Tell the reviewer to read them directly. Do
not obtain a diff.

```
Agent(
  description: "Review <label from table>",
  subagent_type: "dev-rules:review-perspective",
  prompt: """
    DEV_RULES_ROOT: <resolved plugin root>
    Perspective reference file (Read this first, it is your rubric):
      <perspective file path from table>
    The material under review is the implementation plan below — treat the proposed
    design as the change and flag issues with the plan, not with existing code. You may
    Read any source files you need for context.
    For direct file selectors, omit the inline Plan block and provide:
    Material: <selectors>. Read the named files and ranges directly; do not obtain a
    diff.
    Objective:
      <one-sentence objective from Step 1>
    Specifications:
      <bullet list from Step 1>
    Plan:
      <full plan text>
  """
)
```

| # | `label` | Perspective file path |
|---|---------|-----------------------|
| 1 | `review-design` | `<plugin root>/perspectives/design.md` |
| 2 | `review-spec`   | `<plugin root>/perspectives/spec.md` |
| 3 | `review-readability` | `<plugin root>/perspectives/readability.md` |

## Step 3: Triage findings

Create the record first (item 1 of **Record the findings**, below), before any triage.

Apply these rules to what the reviewers return:

- **🔴 / 🟠 / 🟡**: fix.
- **⚪ Low**: fix when valid and simple; otherwise report.
- **Dedupe** across reviewers before reporting.

`--fix` gates only the applying. Without it, triage still runs: it decides what gets
**reported** rather than **fixed**, so unfixed findings are still listed in full, and
the report says what it *would* fix. Make no edits.

This skill adds two gates:

- **Validity** — drop a finding that the plan or concrete code cannot support. Drop
  speculative findings.
- **Scope** — review the approach in the plan. Drop pre-existing issues in unchanged
  code below High when the plan does not mention them.

### Record the findings

Do this on every review, including one with no findings: the record counts which rules
were applied. The header of `scripts/review-record.sh` defines a finding's fields.

1. Before the first triage, create the record once. Keep the printed `RECORD=` path for
   every later round:

   ```bash
   bash "$DEV_RULES_ROOT/scripts/review-record.sh" new --skill review-plan --perspective <name> [--perspective <name>]... <rules.sh paths>
   ```

   - `--perspective`: one per perspective that ran (design, spec, and readability), findings or not.
   - `<rules.sh paths>`: what the reviewers passed to `rules.sh` — nothing, for a plan.

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
   - `triage`: `ignore` for a finding the **Validity** or **Scope** gate drops;
     otherwise `in-scope`.

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

## Step 4: Fix — only with `--fix`

**When the plan came from file selectors** (Step 0 case 1): apply the step 3 findings
to selected files. Re-read the material. Report the result, not the intent. Do not
run the diff script.

**When the plan came from inline text or the conversation** (Step 0 case 2 or 3):
there is no file to edit. Do not rewrite the plan in chat. Report only. State that
`--fix` had no target.

## Step 5: Compile the report

Output format:

```
## Plan Review Report

### Summary
<1–3 sentence overview of the plan and overall quality>

### Findings
<findings, as in Record the findings, item 3>
Record: <the RECORD= path, or "not recorded — reason">

### Fixes applied
<Only with --fix. List what changed in the selected plan files, or "None — --fix had no target
(plan was inline text / conversation, not files)." Omit this section entirely without
--fix.>
```
