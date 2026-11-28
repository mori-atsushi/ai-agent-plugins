# Perspective: Test

Review whether tests are proportionate to the behavior and use the appropriate form,
against the collected rules.

## Perspective-specific steps

Read **all** collected rule files before reviewing. They are required context, not
the change.

Apply this perspective even without changed test files. Decide whether production code
needs a test. Test naming and assertion style follow the test rules; leave other clarity of test
code to readability.

## How to review

With a diff, compare tests with production changes. With direct files, ranges, or a
directory's files, assess the selected code and its tests. Read related context only
when needed. Find the added logic. Check that coverage is proportionate.

## What a finding must show

- **A missing test**: name an input or state that reaches the untested branch through
  the code's real callers. Do not ask for a test of a state the callers cannot produce,
  or of a one-line, self-evident guard.
- **A duplicate test**: name the existing test that covers the same branch.
  Check that the test to remove covers nothing that test leaves out, such as how
  another level passes the behavior on. If it does, it is not a duplicate.
- **An unneeded test or assertion**: cite the test rule that rules it out; a TS-12
  finding follows the duplicate bullet above. For a pinned incidental behavior, name
  the implementation change it would block that keeps every spec, caller, and user
  expectation intact. For an input callers cannot produce, name the guard that rules
  it out.
