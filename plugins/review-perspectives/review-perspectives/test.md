# Perspective: Test

Review whether tests are proportionate to the behavior and use the appropriate form.

## Perspective-specific steps

Read **all** collected reference files before reviewing. They are required context,
not the change. When a reference conflicts with this checklist, the reference wins.
Anything it does not mention still stands.

Apply this perspective even without changed test files. Decide whether production code
needs a test. Leave naming and formatting to readability. Use the applicable checklist
for language-specific test rules.

## How to review

With a diff, compare tests with production changes. With direct files or ranges,
assess the selected code and tests. Read related context only when needed. Find the
added logic. Check that coverage is proportionate.

## Required test state

### Coverage

- Non-trivial core logic has proportionate tests for its function, branches, and edge
  cases. This includes domain calculations, state changes, parsing, empty input,
  boundaries, and errors. Trivial code, UI wiring, and screenshot-covered output need
  no separate tests.
- When a refactor changes behavior, its assertions change to cover the updated
  behavior. A separate refactor commit does not alter this requirement.

### Proportion

- A test does not duplicate rendering output (positions, dimensions, pixel
  coordinates) that a golden screenshot test already covers.
- Each test adds coverage beyond a trivial happy path or an existing near-duplicate.
- A test specifies intended durable behavior rather than a temporary implementation.
- A class exists for production behavior, not solely to test a one-line clear guard.

### Test form

- A test exercises behavior through a public seam. If none exists, use a separate
  class rather than calling a private function directly.
- A test uses a hand-written Fake when it is sufficient; a mocking library has a
  specific need.
- Test-only constructors, factories, and helpers live in test source.
- A test sits beside the tests for the same function or scenario rather than merely
  at the end of the file.
