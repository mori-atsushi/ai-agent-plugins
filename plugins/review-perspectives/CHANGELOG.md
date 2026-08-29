# Changelog

All notable changes to `review-perspectives` are documented in this file.

## [1.0.0] - 2026-08-29

### Added

- `review-code`, `review-plan`, and `review-harness` skills for both Claude Code and
  Codex, sharing scripts, the review contract, and triage rules from the plugin root.
- Five general review perspectives — `simplify`, `readability`, `spec`, `design`,
  `test` — plus Kotlin/Compose-specific variants.
- A `harness` perspective for reviewing agent instructions, skills, rules, and hooks.
- Project-specific perspective overlays via `<project>/.agents/review-perspectives/`.
