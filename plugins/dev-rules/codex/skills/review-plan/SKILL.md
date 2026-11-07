---
name: review-plan
description: Review an implementation plan before coding. Report only by default. Pass `--fix` to apply fixes when the plan is in files. Accept multiple plan paths or ranges. Use for "プランをレビュー", "計画をレビュー", or "plan review".
---

# Review Plan

First resolve `DEV_RULES_ROOT`, this plugin's installation directory. Use
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

Read `<plugin root>/codex/references/initial-reviewer.md` and apply it to every
initial reviewer. Spawn two read-only subagents at once. Wait for both. Give each the
plan, objective, and requirements. For file selectors, give the selectors instead of
copying content. Tell agents to read them directly. Keep handles only until both
results return.

| Label | Perspective file |
| --- | --- |
| `review-design` | `<plugin root>/perspectives/design.md` |
| `review-spec` | `<plugin root>/perspectives/spec.md` |

Use this prompt, substituting the perspective file path:

```text
`DEV_RULES_ROOT` is <plugin root>. Read
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

On Claude Code, use this plugin's `review-perspective` agent for both reviews. On
Codex, spawn two read-only subagents directly and wait for both.

## 3. Triage

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

   - `--perspective`: one per perspective that ran (design and spec), findings or not.
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
<findings, as in Record the findings, item 3>
Record: <the RECORD= path, or "not recorded — reason">

### Fixes applied
<Only with --fix. List what changed in the selected plan files, or "None — --fix had
no target (plan was inline text / conversation, not files)." Omit this section
entirely without --fix.>
```
