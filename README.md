# Personal Plugins

Personal marketplace for plugins that work with both Codex and Claude Code.

## Plugins

- `review-perspectives` — review code, implementation plans, and agent harness changes

## Install from GitHub

Codex:

```bash
codex plugin marketplace add mori-atsushi/ai-agent-plugins
codex plugin add review-perspectives@personal
```

Claude Code:

```bash
claude plugin marketplace add mori-atsushi/ai-agent-plugins
claude plugin install review-perspectives@atsushi-plugins
```

Start a new session after installing. Claude Code invokes its skills as
`/review-perspectives:review-code`, `/review-perspectives:review-plan`, and
`/review-perspectives:review-harness`.

## Develop from a checkout

For local development, replace the GitHub source above with the absolute path to this
checkout. Codex uses `codex plugin marketplace add <path>`; Claude Code uses
`claude plugin marketplace add <path>`.
