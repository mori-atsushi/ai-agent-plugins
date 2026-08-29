# Review Perspectives

`review-perspectives` provides three review workflows:

- `review-code` — five concurrent perspectives for a code change
- `review-plan` — design and specification checks before implementation
- `review-harness` — checks agent instructions, skills, rules, and hooks

The implementations are separate where their hosts differ:

- `codex/skills/` — Codex instructions and metadata
- `claude/skills/` — Claude Code instructions and its `review-perspective` agent

The shared scripts, review contract, triage rules, and general checklists live at the
plugin root.

## Add project-specific perspectives

Keep a project's extra rules in its repository, not in this plugin:

```text
<project>/.agents/review-perspectives/
```

For example, a project can add `design-domain.md` there to review architecture specific
to its core domain without changing the general design perspective for every project.

Each file declares the perspective it augments and, optionally, the changed paths for
which it applies:

```markdown
---
description: Editor architecture checks
perspectives:
  - design
paths:
  - "library/editor/**/*.kt"
---

# Editor design checks

- A notation-editing state change bypasses the editor command boundary.
```

Use one or more of these `perspectives` values:

- `simplify`
- `readability`
- `spec`
- `design`
- `test`
- `harness`

Omit `paths` when the project rule always applies. With a diff, a `paths` glob limits
the rule to matching changed files. Plan reviews have no changed-file list, so every
rule for their perspective applies.

The plugin reads its general checklist first and the project directory second. A
project rule therefore overrides the general checklist if they conflict. Do not copy a
general checklist into the project directory; add only project-specific behavior,
architecture, or conventions.

Project perspective files do not need a `reviewed:` marker. The plugin deliberately
does not use review-date markers.
