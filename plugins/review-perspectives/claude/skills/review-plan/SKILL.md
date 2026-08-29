---
name: review-plan
description: "Review an implementation plan before coding. Report only by default. Pass \"--fix\" to apply fixes when the plan is in files. Accept multiple plan paths or ranges. Triggers: \"プランをレビュー\", \"計画をレビュー\", \"plan review\"."
argument-hint: "[<plan text or file[:line[-end]]>...] [--fix]"
allowed-tools: Read, Edit, Agent, Bash(review-perspectives-root)
---

# Review Plan Skill

Set `REVIEW_PERSPECTIVES_ROOT` by running `review-perspectives-root` before launching
reviewers. Pass the resulting absolute path to both reviewers.

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

Both reviews use the plugin's `review-perspective` agent. They differ only by
perspective file. Spawn both in one message. For inline plans, paste the full text.
For file selectors, give the selectors. Tell the reviewer to read them directly. Do
not obtain a diff.

```
Agent(
  description: "Review <label from table>",
  subagent_type: "review-perspectives:review-perspective",
  prompt: """
    REVIEW_PERSPECTIVES_ROOT: <resolved plugin root>
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
| 1 | `review-design` | `<plugin root>/review-perspectives/design.md` |
| 2 | `review-spec`   | `<plugin root>/review-perspectives/spec.md` |

## Step 3: Triage findings

Apply **Triage** and **`--fix`** from
`$REVIEW_PERSPECTIVES_ROOT/references/review-triage.md`. Use two
plan-specific gates:

- **Validity** — drop a finding that the plan or concrete code cannot support. Drop
  speculative findings.
- **Scope** — review the approach in the plan. This **replaces** the out-of-scope row
  in `review-triage.md`. Drop pre-existing issues in unchanged code below High when
  the plan does not mention them.

## Step 4: Fix — only with `--fix`

**When the plan came from file selectors** (Step 0 case 1): apply the step 3 findings
to selected files. Re-read the material. Report the result, not the intent. Do not
run the diff script.

**When the plan came from inline text or the conversation** (Step 0 case 2 or 3):
there is no file to edit. Do not rewrite the plan in chat. Report only. State that
`--fix` had no target.

## Step 5: Compile the report

Sort surviving findings by each agent's suggested severity, adjusting if needed.

Output format:

```
## Plan Review Report

### Summary
<1–3 sentence overview of the plan and overall quality>

### Findings
<All findings sorted by severity — Critical first, Low last.
 Each finding: severity tag, description, why it matters.
 If there are no findings, say "No issues found.">

### Fixes applied
<Only with --fix. List what changed in the selected plan files, or "None — --fix had no target
(plan was inline text / conversation, not files)." Omit this section entirely without
--fix.>
```

Omit severity groups that have no findings.
