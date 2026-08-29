---
name: review-plan
description: Review an implementation plan before coding. Report only by default. Pass `--fix` to apply fixes when the plan is in files. Accept multiple plan paths or ranges. Use for "プランをレビュー", "計画をレビュー", or "plan review".
---

# Review Plan

First resolve `REVIEW_PERSPECTIVES_ROOT`, this plugin's installation directory. Use
the source path for this `codex/skills/review-plan/SKILL.md` and its plugin-root
ancestor. Pass the resolved absolute path to every reviewer.

Review an implementation plan before coding. Find design and correctness issues while
they are cheap to fix. `--fix` is independent of the plan argument. This skill has no
uncommitted or branch mode.

## 1. Locate and extract context

Use this source order:

1. One or more file selectors — read the selected files.
2. Inline arguments that are not selectors — use them as plan content.
3. No file selector or inline plan — extract the latest plan block from the
   conversation.

A selector is a repo-relative path. It can end in `:line` or `:start-end`. For
example: `plans/feature.md`, `plans/feature.md:42`, or
`plans/feature.md:42-78`. Validate every path. Each range is the primary plan
material. Multiple selectors form one plan. Do not run the diff script.

Ask for a plan if none is identifiable.

**Record the source.** Step 4 needs it. Only file selectors provide files to edit.

Extract a one-sentence objective. Extract concrete requirements and design decisions.

## 2. Run focused reviews in parallel

Spawn two read-only subagents at once. Wait for both. Give each the plan, objective,
and requirements. For file selectors, give the selectors instead of copying content.
Tell agents to read them directly. Keep handles only until both results return.

| Label | Perspective file |
| --- | --- |
| `review-design` | `<plugin root>/review-perspectives/design.md` |
| `review-spec` | `<plugin root>/review-perspectives/spec.md` |

Use this prompt, substituting the perspective file path:

```text
`REVIEW_PERSPECTIVES_ROOT` is <plugin root>. Read
<plugin root>/references/review-contract.md and follow it. Your perspective is
<perspective file>; the material is the implementation plan below, so the proposed
design is the change — flag issues with the plan, not with existing code.

For direct file selectors, read the named files and ranges directly; do not obtain a
diff. Omit the inline Plan block in that case and provide the selectors as `Material`.

Objective:
<objective>

Specifications:
<specifications>

Plan:
<full plan text>
```

## 3. Triage

Apply **Triage** and **`--fix`** from
`$REVIEW_PERSPECTIVES_ROOT/references/review-triage.md`. Use two
plan-specific gates:

- **Validity** — drop a finding that the plan or concrete code cannot support. Drop
  speculative findings.
- **Scope** — review the approach in the plan. This **replaces** the out-of-scope row
  in `review-triage.md`. Drop pre-existing issues in unchanged code below High when
  the plan does not mention them.

Sort survivors by severity, adjusting it when warranted.

On Claude Code, use this plugin's `review-perspective` agent for both reviews. On
Codex, spawn two read-only subagents directly and wait for both.

## 4. Fix — only with `--fix`

**Plan came from file selectors**: apply the step 3 findings to selected files.
Re-read the material. Report the result, not the intent. Do not run the diff script.

**Plan came from inline text or the conversation**: there is no file to edit. Do not
rewrite the plan in chat. Report only. State that `--fix` had no target.

## 5. Report

```markdown
## Plan Review Report

### Summary
<1–3 sentence overview of the plan and overall quality>

### Findings
<Findings, highest severity first; each gives severity, description, and why it
matters. If none, say exactly "No issues found.">

### Fixes applied
<Only with --fix. List what changed in the selected plan files, or "None — --fix had
no target (plan was inline text / conversation, not files)." Omit this section
entirely without --fix.>
```
