---
description: What deserves a test, test doubles, test form, and refactors under test
perspectives:
  - test
paths:
  - "**/*.{kt,kts,java,swift,ts,tsx,js,jsx,py,go,rs,rb,dart,c,cc,cpp,h,m,mm,cs,scala}"
---

# Testing Rules

## Coverage

Aim for necessary and sufficient coverage: every test earns its place against its
cost in maintenance, brittleness, and run time.

- [TS-1] **Non-trivial core logic has tests for its function, branches, and edge cases:**
  domain calculations, state changes, parsing, empty input,
  boundaries, and errors.
- [TS-2] **A component's own branches are tested in its own test.** A caller's test covers
  only what the caller adds.

A test that TS-3 or TS-13 to TS-17 rules out is deleted, or its assertion narrowed to
what is relied on, even when no other test covers the same code; TS-12 applies only
when one does.

- [TS-3] **No test for code not worth pinning:** the happy path of a trivial
  one-liner; a data holder with no behavior; UI wiring; a class that only delegates a
  call; a class extracted only to test a one-line, self-evident guard; temporary
  behavior that will be replaced rather than extended.
- [TS-12] **No test for what another test already pins:** a near-duplicate of another
  test; rendering output a golden screenshot test already covers (positions,
  dimensions, pixel coordinates).
- [TS-13] **No test whose expected values are copied from the code under test:** a
  `when` or lookup table restated entry by entry, a constant, or a default value, so
  the test fails only when the value is edited on purpose. Exception: a value that a
  spec fixes, or that something outside the code reads back (a saved file format, an
  analytics event name, a wire protocol), may be pinned.
- [TS-14] **No test of something other than the project's code:** the language, a
  library, or the framework (a data class's `equals` or `copy`, enum entries, standard
  library behavior), or a test double itself.
- [TS-15] **No test that cannot fail:** one with no assertion; one that only checks the
  code does not throw, when not throwing is not its specified behavior; one that only
  checks a result is not null; one that asserts the value a fake was set up to return.
- [TS-16] **An assertion pins only behavior a spec, caller, or user relies on,** not an
  incidental result of the current implementation: the order of a result no one
  depends on, which of equal candidates wins, an error message's exact wording that no
  spec fixes, an internal call's count or order that no caller observes, an
  intermediate value the result does not expose. Behavior no one can be named as
  relying on is incidental. Such an assertion holds back a later change to the
  implementation without protecting anyone.
- [TS-17] **No test for an input the code's callers cannot produce,** because a guard
  elsewhere already rules it out. The guard's own test stays; TS-17 covers the code
  behind the guard.

## Test doubles

- [TS-4] **A test uses real implementations by default.** Substitute a dependency only for
  an external system, an expensive operation, logic another module owns, or a
  dependency too complex to construct.
- [TS-5] **A substitute is a hand-written fake, not a mocking library.** Define the
  dependency as an interface and implement it for the test (`FakeRepository` for
  `RepositoryImpl`).

## Form

- [TS-6] **Arrange, Act, and Assert are identifiable in each test.** A shared helper may
  extract work within one step, never across steps.
- [TS-7] **A test exercises behavior through a public seam**; it does not call a private
  function.
- [TS-8] **Test-only constructors, factories, and helpers live in test sources**, not
  production code.
- [TS-9] **Related tests sit together**: a new test goes beside the tests for the same
  function or scenario, not merely at the end of the file.

## Refactors

Existing tests prove behavior is unchanged only while their assertions stay untouched.

- [TS-10] **A behavior-preserving restructuring lands green against unchanged assertions
  first;** re-aim the tests in a separate commit. Adapting a test only so it
  compiles (a moved type, a renamed function) is fine.
- [TS-11] **A refactor that changes behavior changes its assertions** to cover the new
  behavior.
