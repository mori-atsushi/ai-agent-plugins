# Initial Reviewer Launch

Apply this policy to every initial Codex review subagent. It does not apply when a
review workflow resumes an existing reviewer for re-review.

- Start the reviewer with `fork_turns="none"`. The invoking skill's prompt supplies
  the complete review context.
- Cap the reviewer model at `gpt-5.6-terra`. If the active parent model is
  `gpt-6-astra` or `gpt-5.6-sol`, pass `model="gpt-5.6-terra"` when spawning. For
  every other parent model, omit `model` so the reviewer inherits that same parent
  model.
