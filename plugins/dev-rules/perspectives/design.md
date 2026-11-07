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

With a directory map, review only how the directory divides: whether it holds one
concern, how its child directories are cut, how the files directly in it are grouped,
which packages it depends on and which depend on it, a file holding several top-level
declarations, and a declaration that no other file mentions. Leave each file's own
content to a file review.
