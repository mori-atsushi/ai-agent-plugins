# Dev Rules

`dev-rules` holds general coding rules and the review workflows that apply them:

- `rules/` — general rules (Kotlin, Compose, Android, tests, design, comments, …),
  the single source for both writing and reviewing code
- `rules` skill — lists the rules that apply to given files, as path and summary
- `review-code` — five concurrent perspectives for a code change
- `review-plan` — design and specification checks before implementation
- `review-harness` — checks agent instructions, skills, rules, and hooks

The implementations are separate where their hosts differ:

- `codex/skills/` — Codex instructions and metadata
- `claude/skills/` — Claude Code instructions and its `review-perspective` agent

The rules, perspectives, scripts, review contract, and triage rules live at the plugin
root and are shared.

## Rules

Each file in `rules/` declares in its frontmatter what it covers:

```markdown
---
description: Kotlin idioms — named arguments, val, function form, null checks, @property docs, and file and nested-class layout
perspectives:
  - readability
paths:
  - "**/*.{kt,kts}"
---
```

- `description` — the one-line summary a reader uses to decide whether to open it
- `paths` — the files it covers; omit for every file
- `perspectives` — the one reviewer that applies it: `simplify`, `readability`, `spec`,
  `design`, `test`, `harness`

`scripts/rules.sh [<path>...] [--perspective <name>]` lists the matching rules as
`<path>\t<description>`, never their bodies. Three callers share it:

| Caller | When |
| --- | --- |
| `rules` skill (`dev-rules` on Claude Code's `PATH`) | Before implementing, to find which rules to read |
| Claude Code `PostToolUse` hook | After a file is read or written, names the rules covering it once per session |
| Review perspectives | Each reviewer collects the rules for its perspective |

Codex has no hook, so a project using Codex points its agent at the `rules` skill
from its `AGENTS.md`.

Each rule file names exactly one perspective, so no two reviewers judge the same rule.
A language or framework splits its rules into `<name>-convention` (readability) and
`<name>-design` (design) files.

Each rule starts with an ID, such as `[KD-3]`: a prefix unique to its file and a
number. Reviewers cite the ID, so rule usage can be counted. An ID never changes or
gets reused: rewording or moving a rule keeps its ID, a new rule takes the file's next
number, and a deleted rule's number stays unused.

`perspectives/` holds only what a reviewer needs beyond the rules: each perspective's
scope, steps, and what not to flag.

## Rule usage

`review-code` and `review-plan` keep each review's findings, with the rules each
perspective applied, in one JSON record written by `scripts/review-record.sh`, and
print the report's findings from it. Records live in
`~/.local/state/dev-rules/reviews/` (`$XDG_STATE_HOME` or `$DEV_RULES_REVIEWS` moves
them) and need `jq`. A finding cites a project rule by its path, plus its ID when it
has one.

`scripts/rule-stats.sh` counts, per rule, the reviews that applied it, the findings
that cite it, and how they were triaged. Judge only rules applied in many reviews. A
rule seldom cited is either followed or never triggers: search reviewed code for what
it forbids to tell which. A rule whose findings are mostly ignored is unclear or too
strict: read those findings in the records, then reword or remove it.

## Add project rules

Keep a project's own rules in its repository's `.agents/rules/`, not in this plugin.
They use the same frontmatter as `rules/` and reach every caller above: the skill, the
hook, and the reviewers named in `perspectives`. `rules.sh` reads no other project
directory, so a project needs no `.claude/rules/` copy or symlink.

`rules.sh` prints this plugin's rules first and the project's second, so a project
rule wins where the two conflict. Design project rules not to conflict: add only
project-specific behavior, architecture, or conventions, and do not copy or restate a
general rule. A project rule may narrow a general one (for example, forbidding what
the general rule only discourages).

Rule and perspective files do not need a `reviewed:` marker. The plugin deliberately
does not use review-date markers.
