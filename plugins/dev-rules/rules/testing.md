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

- **Non-trivial core logic has tests for its function, branches, and edge cases:**
  domain calculations, state changes, parsing, empty input,
  boundaries, and errors.
- **A component's own branches are tested in its own test.** A caller's test covers
  only what the caller adds.
- **No test for:** the happy path of a trivial one-liner; a near-duplicate of another
  test; temporary behavior that will be replaced rather than extended; a data holder
  with no behavior; UI wiring; rendering output a golden screenshot test already
  covers (positions, dimensions, pixel coordinates); a class that only delegates a
  call; a class extracted only to test a one-line, self-evident guard.

## Test doubles

- **A test uses real implementations by default.** Substitute a dependency only for
  an external system, an expensive operation, logic another module owns, or a
  dependency too complex to construct.
- **A substitute is a hand-written fake, not a mocking library.** Define the
  dependency as an interface and implement it for the test (`FakeRepository` for
  `RepositoryImpl`).

## Form

- **Arrange, Act, and Assert are identifiable in each test.** A shared helper may
  extract work within one step, never across steps.
- **A test exercises behavior through a public seam**; it does not call a private
  function.
- **Test-only constructors, factories, and helpers live in test sources**, not
  production code.
- **Related tests sit together**: a new test goes beside the tests for the same
  function or scenario, not merely at the end of the file.

## Refactors

Existing tests prove behavior is unchanged only while their assertions stay untouched.

- **A behavior-preserving restructuring lands green against unchanged assertions
  first;** re-aim the tests in a separate commit. Adapting a test only so it
  compiles (a moved type, a renamed function) is fine.
- **A refactor that changes behavior changes its assertions** to cover the new
  behavior.
