# Perspective: Design

Review decisions that shape or connect code against the collected rules:
architecture, responsibility, state ownership, data and API models, name accuracy, and
whether and where to share code.

This perspective owns questions beyond one implementation. Check callers, types,
modules, state ownership, and domain meaning. `readability` owns local clarity, file
structure, and language or framework idioms.

Use the objective and specifications to understand the intended outcome. Do not treat
an implementation plan as the required solution. Review the code from a fresh,
independent viewpoint. Recommend a better design when the implementation reveals one.

## A finding against a recorded decision

A decision is recorded when the issue, design doc, task list, or plan the change was
built from states the choice. Such a decision is still not the required solution, but a
finding that asks for something else names the decision in `issue` and gives the
concrete reason the alternative is better: a defect the decision causes, or a cost it
adds that the alternative removes. Without such a reason, do not raise the finding.

## What NOT to flag

- An alternative that is only different or optional: the finding names no defect, no
  cost, and no rule the current design breaks

## When the material is a directory map

With a directory map, review only how the directory divides: whether it holds one
concern, how its child directories are cut, how the files directly in it are grouped,
which packages it depends on and which depend on it, a file holding several top-level
declarations, and a declaration or exposed member that no other file mentions. Leave
each file's own content to a file review.
