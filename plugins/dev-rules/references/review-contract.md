# Review Contract — for the reviewer

What a reviewer applying one perspective must do on either supported harness. The
calling skill supplies `DEV_RULES_ROOT`, the installed plugin root.

Read by the reviewer itself, so nothing addressed to the skill running the review
(triage, recording) belongs here; that lives in each skill.

Given one perspective reference file and the material to review — a diff, direct
file selection, or implementation plan:

1. Read the perspective file and adopt it as your **rubric**. It and the rule files
   collected in step 2 describe the required state; report only concrete deviations
   from that state. Stay strictly inside it — the other perspectives run as separate
   reviewers.
2. Collect your rule files: run
   `bash "$DEV_RULES_ROOT/scripts/rules.sh" --perspective <perspective> --files-list <changed-files list>`,
   where `<perspective>` is the perspective filename's basename without `.md` and the
   changed-files list is the path the prompt names. For a direct file selection, pass
   the selected paths (without any `:line` suffix) as arguments instead; on a plan
   review, pass neither. Each line printed is
   `<path>\t<description>`: this plugin's general rules appear first, then the
   reviewing project's rules (`.agents/rules/`). Use the description to judge relevance before
   opening a file — skip one only when the description makes it clearly inapplicable
   to the material (e.g. a Compose rule and the material touches no `@Composable`);
   read every other file the command lists. A perspective's own instruction to read
   all collected rule files (step 4) overrides this skip allowance. Their order
   settles nothing but disagreements — **where two contradict, a project rule beats a
   plugin rule, and among plugin rules the more specific one wins** (`compose-convention`
   over `general`).
   It printing nothing is normal; the perspective then stands on its own. If you
   cannot run it — no Bash tool, or the command fails — glob `$DEV_RULES_ROOT/rules/`
   and the project's `.agents/rules/`, applying their
   `perspectives` / `paths` frontmatter yourself, and say in your report that you did.
   Never skip the step.
3. Read the material.
   - A diff file already carries 30 lines of context around each change: use it as
     the primary source and do not re-read files whose changes are already clear
     from it. Fetch other files only when that context is genuinely insufficient.
   - For a direct file selection, read each named file. A `:line` or
     `:start-end` suffix limits the primary review material to that inclusive range;
     read surrounding or related code only when it is genuinely needed for context.
     Do not obtain a diff for direct file selections.
4. Follow any extra steps the perspective specifies — **even when that means reading
   files the diff does not touch.** The perspective's own steps win over step 3.
5. When the material is a plan rather than current code or a diff, treat the
   proposed design as the change: flag issues with the plan, not with existing code.
6. Use an objective or specifications block, when supplied, only to judge the change's
   intent. An item tagged `(plan)` shows the intended approach, not a requirement.
7. Do not edit files. `rules.sh` is the only command you run.

Return findings as one JSON object per line, in a single fenced `jsonl` block at the end
of your reply, so the caller records them as given. Any prose before the block is
optional; keep it to what the perspective asks for beyond findings.

```jsonl
{"perspectives": ["design"], "severity": "medium", "location": "app/Main.kt:42", "issue": "<the issue, and the fix or principle as the perspective directs>", "grounds": ["KD-3"]}
```

- `perspectives`: one item, your perspective's basename.
- `severity`: exactly one suggested severity, so the caller can triage; the caller may
  adjust it:
  - `critical` — bug, correctness failure, or architectural violation
  - `high` — significant design or spec problem worth resolving before merge
  - `medium` — naming, responsibility, or structural improvement worth considering
  - `low` — minor suggestion with little practical impact
- `location`: `file:line`, or the plan section.
- `grounds`: an array of what justifies the finding, so the caller can verify it: a
  rule's ID (`KD-3`), else its path; a spec's or perspective file's path.
- No `triage` key; the caller adds it.

A perspective's own format note (e.g. `spec.md`'s) adds content to `issue` or extra
sections outside the block; it does not change the block. Write every line as valid
JSON, since a malformed line makes the caller's record reject the round.

If you find nothing, say exactly "No issues found." after any sections the perspective
requires, and omit the block.
