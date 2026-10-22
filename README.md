# Personal Plugins

Personal marketplace for plugins that work with both Codex and Claude Code.

## Plugins

- `dev-rules` — general coding rules, plus code, plan, and harness review workflows that apply them

## Use inside this repository

`.claude/settings.json` declares this repo's own marketplace and enables
`dev-rules` at the project scope, so Claude Code offers to trust and
load it the first time you open this checkout — no install command needed.
Approve the trust prompt, then start a new session.

## Install from GitHub

Codex:

```bash
codex plugin marketplace add mori-atsushi/ai-agent-plugins
codex plugin add dev-rules@personal
```

Claude Code:

```bash
claude plugin marketplace add mori-atsushi/ai-agent-plugins
claude plugin install dev-rules@atsushi-plugins
```

Start a new session after installing. Claude Code invokes its skills as
`/dev-rules:rules`, `/dev-rules:review-code`, `/dev-rules:review-plan`, and
`/dev-rules:review-harness`.

## Develop from a checkout

For local development, replace the GitHub source above with the absolute path to this
checkout. Codex uses `codex plugin marketplace add <path>`; Claude Code uses
`claude plugin marketplace add <path>`.
