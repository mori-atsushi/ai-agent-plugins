# Review Contract — for the reviewer

What a reviewer applying one perspective must do on either supported harness. The
calling skill supplies `REVIEW_PERSPECTIVES_ROOT`, the installed plugin root.

Read by the reviewer itself, so nothing addressed to the skill running the review
belongs here: that lives in `references/review-triage.md`, which a reviewer never
opens.

Given one perspective reference file and the material to review — a diff, direct
file selection, or implementation plan:

1. Read the perspective file and adopt it as your **rubric**. Its rules describe the
   required state; report only concrete deviations from that state. Stay strictly
   inside it — the other perspectives run as separate reviewers.
2. Collect your reference files: run
   `bash "$REVIEW_PERSPECTIVES_ROOT/scripts/review-refs.sh" "$REVIEW_PERSPECTIVES_ROOT" <perspective> <changed-files list>`,
   where `<perspective>` is the perspective filename's basename without `.md` and the
   changed-files list is the path the prompt names — omit that argument when it names
   none, as on a plan review. Each line printed is `<path>\t<description>`: this
   plugin's general checklists appear first, followed by the reviewing project's
   optional `.agents/review-perspectives/` overlays. Use the description to judge
   relevance before opening a file — skip one only when the description makes it
   clearly inapplicable to the material (e.g. a Compose-specific checklist and the
   diff touches no `@Composable`); read every other file the command lists. A
   perspective's own instruction to read all collected reference files (step 4)
   overrides this skip allowance. Their order settles nothing but disagreements —
   **where two contradict, the later one wins**. It printing nothing is normal; the
   rubric then stands on its own. If you cannot run it — no Bash tool, or the command
   fails — read the named plugin perspective and glob the project's
   `.agents/review-perspectives/*.md`, applying their `perspectives` / `paths`
   frontmatter yourself, and say in your report that
   you did. Never skip the step.
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
   intent.
7. Do not edit files. `review-refs.sh` is the only command you run.

Return each finding as:

- **\<severity\>** **[file:line]** The issue, and the fix or principle as the perspective directs.

Prefix every finding with exactly one suggested severity so the caller can triage — the
caller may adjust it:

- 🔴 **Critical** — bug, correctness failure, or architectural violation
- 🟠 **High** — significant design or spec problem worth resolving before merge
- 🟡 **Medium** — naming, responsibility, or structural improvement worth considering
- ⚪ **Low** — minor suggestion with little practical impact

Add any extra sections the perspective defines. If you find nothing, say exactly
"No issues found."
