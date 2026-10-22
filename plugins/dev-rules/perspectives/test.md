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

With a diff, compare tests with production changes. With direct files or ranges,
assess the selected code and tests. Read related context only when needed. Find the
added logic. Check that coverage is proportionate.
