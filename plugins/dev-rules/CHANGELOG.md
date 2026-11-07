# Changelog

All notable changes to `dev-rules` (formerly `review-perspectives`) are documented in
this file.

## [2.2.9] - 2026-11-07

### Changed

- The harness perspective's progressive-disclosure rule also covers the reverse case: a
  procedure that only some runs of a skill need, such as handling a rare failure, goes in
  a reference file that the skill links from one line naming the condition.

## [2.2.8] - 2026-11-07

### Fixed

- `review-record.sh new` stops when a path argument does not exist, and says to give
  each perspective its own `--perspective`. `--perspective design spec` had recorded
  `spec` as a path without a word. The review skills write the usage as
  `--perspective <name> [--perspective <name>]...`.
- `review-record.sh add` says to cite rule IDs when a finding cites the path of a
  rule file that has them, in place of "is not one that ... applied". A plugin rule
  file cited by path, such as `rules/general.md`, was accepted as an existing file;
  it now gets the same message.

## [2.2.7] - 2026-11-07

### Changed

- The directory map leaves out private top-level declarations and their members:
  they say nothing about how a directory divides or depends. The preamble says a
  file may hold more declarations than it lists.

## [2.2.6] - 2026-11-07

### Changed

- The directory map's preamble spells out what a reference count of 0 and of 1 or
  more mean, and what to do with each, in place of "Only 0 is a signal". It also says
  a declaration with no count is private to its file.
- The harness perspective's readable-instructions item flags a sentence whose subject
  the reader cannot tell, such as "signal" or "this" with no noun saying what it
  refers to.

## [2.2.5] - 2026-11-07

### Changed

- The directory map's preamble says a reference count of 1 or more is not evidence a
  name could be private: only 0 is a signal. A design reviewer had proposed narrowing
  names that other files use.

## [2.2.4] - 2026-11-07

### Changed

- The directory map is written by `scripts/package-map.py` (Python 3.9 or later,
  standard library only) in place of the shell script, and counts references in one
  pass over the repository: about 18 seconds became under 2 on a 41-file directory.
  Ties in the import lists are ordered by name.
- Constructor properties written on the class's own line are listed as members.
- The tests are pytest tests under `tests/`, run with `uv run pytest`.

## [2.2.3] - 2026-11-07

### Changed

- The directory map lists each top-level class's exposed members — its functions and
  properties that are not private, protected, or overrides — with how many other files
  mention each one, so a member nothing outside its file uses shows.

### Added

- `tests/dev-rules/package-map.test.sh` checks the map and its Kotlin extractor.

## [2.2.2] - 2026-11-07

### Changed

- `review-code` reviews a directory through a map from the new
  `scripts/package-map.sh`, with the design perspective alone, instead of having five
  reviewers read every file body: on a large directory they read only part of it and
  did not say so. The map lists each file's top-level declarations, how many other
  files mention each one, child directories, and the packages the directory imports
  from and is imported by. A file's own content is left to a file review.
- Languages are added as extractors in `scripts/package-map/`; Kotlin is the first.

## [2.2.1] - 2026-11-07

### Changed

- A finding about a selected directory's structure names that directory as its
  `location`.
- `review-code --fix` reports, rather than fixes, a finding whose fix would change the
  design of code outside the review target; it still makes the mechanical edits a fix
  forces elsewhere, such as imports and call sites.

## [2.2.0] - 2026-11-07

### Added

- `review-code` takes directory selectors: the files directly in each directory are the
  review target, and `design` also reviews how the directory divides into files and
  child directories. With `--fix`, moves use `git mv`, and a moved or renamed selection
  is followed at its new path.
- `review-contract` step 3 defines each material's review target and reference code;
  findings about reference code are reported as out of scope.

### Changed

- `review-code` stops when the arguments mix scopes (`branch` with a selector, or files
  with directories); `review-harness` stops on `branch` with files or on a directory,
  instead of letting `branch` win.

## [2.1.7] - 2026-11-07

### Added

- `kotlin-design` Packages [KD-16]–[KD-19]: a package holds one concern, split by domain
  before technical layer; a parent package holds the abstract procedure and its children
  the implementation details, which do not depend on the parent; siblings share one
  level of abstraction; a package holds about 5–20 files.

## [2.1.6] - 2026-11-07

### Added

- `design` [DS-26]: a name says what its value means or what its unit does, not where it
  is used (`hasEditAction`, not `onEditSheet`); event callbacks such as `onClick`, and a
  name visible only inside the context it names, are exempt.
- `kotlin-convention` [KC-12]: a `Boolean` property, parameter, or function reads as an
  assertion: a predicate prefix (`isEmpty`), a third-person verb (`handlesBack`), or a
  bare state adjective from a short closed list (`enabled`, `visible`, `closed`); not a
  bare noun, an imperative, or any other adjective without a prefix.
- `compose-convention` [CC-10]: a composable of our own takes its `Boolean` parameter
  names from the Material component it resembles (`enabled`, `checked`, `isError`), as a
  reference vocabulary distinct from GN-3's framework-imposed names.

## [2.1.5] - 2026-11-05

### Changed

- `review-record.sh add` rejects an absolute path in `grounds`, so the rule added in
  2.1.4 is enforced rather than only requested.

## [2.1.4] - 2026-11-05

### Changed

- Reviewers write a `grounds` path relative to the project or plugin root, so records
  match across machines (`references/review-contract.md`).

## [2.1.3] - 2026-11-05

### Changed

- Reviewers return their findings as JSON lines in a `jsonl` block
  (`references/review-contract.md`) instead of a Markdown list, so the review skills
  record them with `review-record.sh add` without rewriting each one. The skill adds
  `triage` and merges duplicates.

## [2.1.2] - 2026-11-05

### Changed

- `review-harness` records its findings like `review-code` and `review-plan`.
- The triage rules moved from `references/review-triage.md` into each review skill, so a
  session cannot skip them. A file every run of a skill must read is inlined when short
  (`perspectives/harness.md`, item 3). The "fix code findings in the code" bullet now
  applies to `review-code` only.
- `perspectives/harness.md` limits a `SKILL.md`: over 250 lines is Medium, over 400 is High.

## [2.1.1] - 2026-11-05

### Fixed

- `review-code` and `review-plan` skipped recording in most reviews because the record steps
  sat in `references/review-record.md`, which the skills only pointed to. The steps are now in
  each skill (Claude and Codex), the record is created before triage even when nothing is
  found, and the report shows the record path. Edit the four copies together.

## [2.1.0] - 2026-11-03

### Added

- Each rule starts with a stable ID, such as `[KD-3]`, and reviewers cite it in a finding's
  grounds.
- `review-code` and `review-plan` keep each review's findings in its own JSON record through
  `scripts/review-record.sh`, which validates each triage round (`in-scope`,
  `out-of-scope`, `ignore`) and numbers the findings the report lists.
- `scripts/rule-stats.sh` counts, per rule, how often reviews applied and cited it, and how the
  citing findings were triaged, with project rules grouped by project.

## [2.0.4] - 2026-11-03

### Changed

- `kotlin-design`: a one-shot result is a `suspend` function; `Flow` only for multiple values.
- `android`: the DataStore single-source-of-truth rule now covers Room and ViewModel state, and
  says to write on click and observe the `Flow`.

## [2.0.3] - 2026-11-03

### Changed

- `review-code` judges a finding that contradicts the issue, design doc, or plan on its merits
  instead of dropping it, and tags plan items `(plan)` for reviewers as intent, not requirements.
- Triage: out of scope now means a finding about code outside the reviewed material.

## [2.0.2] - 2026-11-02

### Changed

- `general`: a concept the standard library or framework already names keeps that name, not a
  synonym (for example `xxxOrNull` in Kotlin, `popUpTo` in Android Navigation).

## [2.0.1] - 2026-11-01

### Changed

- Each finding must cite the rule, spec, or perspective file that grounds it, as a trailing
  `— grounds: <path>`, so the caller can verify it.
- `kotlin-design`: a function-type parameter forwarded through two or more classes or layers is a
  named `interface` (or a class when tests do not substitute it), not a lambda.

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
