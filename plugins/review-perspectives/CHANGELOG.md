# Changelog

All notable changes to `review-perspectives` are documented in this file.

## [1.1.0] - 2026-09-06

### Added

- A standalone readability checklist for comment conventions (general,
  documentation-comment, and inline-comment rules), loaded independently instead of
  living inside the general readability checklist.
- A Kotlin readability rule preferring `if` or a null-safe scope function over `when`
  for a null check.
- A Compose design rule keeping business logic out of UI composables by hoisting it
  to the host or a state class.
- A Compose readability rule naming `Unit`-returning composables (UI-emitting or
  side-effect-only, e.g. `BackHandler`) as noun phrases, not verbs.

### Changed

- `review-refs.sh` prints each reference file's description so a reviewer can judge
  relevance before opening it.
- Review scratch files (`review-diff`/`review-files`) are saved under the OS temp
  dir instead of the repo's `tmp/`, so they no longer show up as untracked files in
  the reviewed repo.

## [1.0.1] - 2026-08-30

### Added

- Kotlin/Compose design checks for dependency placement and composable
  positioning/sizing.

## [1.0.0] - 2026-08-29

### Added

- `review-code`, `review-plan`, and `review-harness` skills for both Claude Code and
  Codex, sharing scripts, the review contract, and triage rules from the plugin root.
- Five general review perspectives — `simplify`, `readability`, `spec`, `design`,
  `test` — plus Kotlin/Compose-specific variants.
- A `harness` perspective for reviewing agent instructions, skills, rules, and hooks.
- Project-specific perspective overlays via `<project>/.agents/review-perspectives/`.
