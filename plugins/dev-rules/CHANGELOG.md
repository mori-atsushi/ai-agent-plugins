# Changelog

All notable changes to `dev-rules` (formerly `review-perspectives`) are documented in
this file.

## [Unreleased]

## [2.0.0] - 2026-10-22

### Changed

- Renamed the plugin from `review-perspectives` to `dev-rules`. Skills are now
  `/dev-rules:review-code`, `/dev-rules:review-plan`, and `/dev-rules:review-harness`;
  the reviewer agent is `dev-rules:review-perspective`, the root command
  `dev-rules-root`, and the root variable `DEV_RULES_ROOT`.
- General rules moved into `rules/`, one source for writing and reviewing code. The
  per-language checklists (`readability-kotlin.md`, `design-compose.md`, …) and the
  checklists inside the readability, design, simplify, and test perspectives became
  `general`, `comments`, `design`, `simplicity`, `testing`, `kotlin-convention`,
  `kotlin-design`, `kotlin-test`, `compose-convention`, `compose-design`, `android`,
  and `android-test` rules, each owned by exactly one perspective. The perspective
  files in `perspectives/` (formerly `review-perspectives/`) keep only each
  reviewer's scope, steps, and exclusions.
- `scripts/review-refs.sh` became `scripts/rules.sh`, which takes paths as arguments.
- A project's own rules now live in `.agents/rules/`, used for both writing and
  reviewing. `.agents/review-perspectives/` and `.claude/rules/` are no longer read.
- Some rules became stricter in the move: an expression body is required where the
  function is a single expression, a production file over 500 lines is split, the
  `test<Target>_<Condition>` naming is no longer only a default, and mocking libraries
  are not used. Comment rules apply to every file, not only code.
- Among plugin rules, the more specific one wins (`compose-convention` over `general`).
- The simplify perspective no longer judges whether to share code (design does), and
  the test perspective owns test naming and assertion style.

### Added

- A `rules` skill that lists the rules covering given files as path and summary.
- A Claude Code `PostToolUse` hook naming the plugin rules that cover a file read or
  written, once per session.

## [1.2.4] - 2026-10-05

### Added

- Compose readability reviews now check one file per public or internal composable,
  file naming and declaration order, and previews at the bottom of the file unless
  they are difficult to write or offer little value.

### Changed

- Initial Codex review subagents now always use `gpt-6.1-sol`, regardless of the
  parent model.
- Test reviews now require clear Arrange, Act, and Assert boundaries, including
  shared helpers that stay within a single step.

## [1.2.3] - 2026-09-29

### Changed

- Readability reviews flag documentation comments that restate the code; a
  documentation comment carries only background the code cannot show, such as argument
  conditions, and is usually absent or one line.
- Triage fixes code findings in the code before adding a comment, and checks any added
  comment against the comment checklist.

## [1.2.2] - 2026-09-27

### Added

- Compose readability reviews now flag lambdas and function references wrapped in
  `remember`, which strong skipping already memoizes.

## [1.2.1] - 2026-09-26

### Changed

- Simplify and design reviews now favor functional cohesion over extracting a few
  similar lines, leaving caller-owned behavior with its callers.

### Added

- Design reviews now flag logically cohesive helper wrappers that only bundle caller-specific
  control flow, error handling, logging, and fallback values.
- Design reviews now reject generics introduced solely to unify processing between otherwise
  concrete operations.
- Kotlin design reviews now flag `suspend` functions without suspend work, and Android design
  reviews flag blocking regular functions lacking a worker-thread annotation.
- Test reviews now reject tests for classes that only delegate a function call to another
  component.
- Design reviews now require expected failures to be converted at their source and flag broad
  exception handling that hides unrelated failures.

## [1.2.0] - 2026-09-07

### Changed

- Codex review subagents now start with `fork_turns="none"`, preventing parent
  conversation history from influencing the initial review.
- Initial Codex review subagents now use `gpt-5.6-terra` at most, while preserving a
  lower-capability parent model.

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
