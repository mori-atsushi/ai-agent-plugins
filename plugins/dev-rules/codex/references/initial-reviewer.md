# Initial Reviewer Launch

Apply this policy to every initial Codex review subagent. It does not apply when a
review workflow resumes an existing reviewer for re-review.

- Start the reviewer with `fork_turns="none"`. The invoking skill's prompt supplies
  the complete review context.
- Always pass `model="gpt-6.1-sol"` when spawning, regardless of the active parent
  model.
