# Perspective: Harness

Review changes to rules, skills, agent prompts, references, hooks, and always-on
files. Ask one question: **Does this instruction earn its place? Will a future
session follow it?**

## Scope

The project reference files list the harness files in scope.

A tool's rule directory may contain symlinks to shared rules. Review the target,
not the symlink.

Ignore every non-harness file in the diff; the other perspectives own those.

## Perspective-specific steps

Do not review only the diff. Do not read the whole harness. Review the effective
instructions that a future session receives. Stop when you cover the change's reach.
A file is out of scope unless it changed, the change references it, or it loads with
the change.

Read, in this order, stopping when the change's reach is covered:

1. **Read each changed file in full.** Do not read only its hunks. New lines may
   repeat or contradict unseen content.
2. **What the change reaches**, by kind:
   - Changed **rule** → read sibling rules whose `paths` frontmatter can match the
     same file. Include any always-on file that co-loads with it.
   - Changed **skill** → read the `description:` lines of skills with nearby triggers.
     Read its harness-neutral mirror and any agent or reference it uses.
   - Changed **reference / perspective / agent** → the skills that consume it.
3. **Read both directions of the reference graph.** Grep for the file path and name.
   Follow links into and out of the changed file. For a deletion, find instructions
   that relied on it. Check whether the content must move instead of disappear.
4. **Read always-on files only when needed.** Read them when the change touches them
   or moves content into or out of them. Use the diff for line counts.

## Subtraction first

Do this before anything else, and report it even when you find no other issue.

For every net-added instruction, name the cheapest option that does not grow the
harness. An instruction can be a rule file, skill, section, bullet, or constraint.

- **Replace** an existing instruction (which file and section)
- **Merge** into an existing one instead of standing alone
- **Delete** something the addition makes redundant
- **Move it out of the harness** — use a test, lint rule, script, or hook when it can
  enforce the rule without an instruction
- **None** — allowed, but the reason is mandatory

Then count net added lines in the listed always-on files. Every session pays for this
growth. **Net growth without a replacement is 🟠 High.** State what to cut.

## Required instruction state

**Placement and necessity**

1. **Narrowest effective home.** Place an instruction in the narrowest home that
   works: path rule < skill < on-demand reference < always-on file. A module-only
   rule belongs in that module's rule.
2. **One source for each instruction.** Other files cite it rather than copying it.
3. **Progressive disclosure.** Workflow-only detail sits behind a skill or in
   `references/`, not an always-on file.
4. **Complexity budget.** Each new exception, branch, priority, or "see also" jump
   returns more value than its instruction cost.

**Wording that has to survive contact with a real session**

5. **Scope correctness.** State when the rule applies and when it does not. A one-off
   workaround remains a one-off rather than becoming a general rule.
6. **Actionability.** State an observable action or checkable condition; "carefully"
   and "as appropriate" alone are insufficient.
7. **Readable instructions.** Write plain English that people and AI, including a
   non-native speaker, can understand. Keep sentences short and state the required
   action or conclusion first.
8. **Source of truth.** Link to code, configuration, or a spec instead of copying
   values that can silently go stale.
9. **Safety.** Permissions, destructive commands, hidden errors, and skipped
   verification stay no broader than the motivating case.

**Fit with everything else**

10. **Conflict and precedence.** Parent, child, and co-loading instructions state
    which one wins when more than one applies.
11. **Skill routing.** A `description:` says what the skill does and when to use it
    without taking a nearby skill's triggers.
12. **Portability.** A harness-neutral instruction does not require one tool's
    mechanism; tool-specific mechanics live in that tool's directory.

## What NOT to flag

- An existing instruction the change does not touch, unless the change conflicts
  with it
- Missing coverage of a case that has never come up — the harness records what
  actually went wrong, not everything that could
- A harness-neutral mirror's wording differing from its tool-specific counterpart —
  only the shared *behavior* has to match

## Reviewing a doc in place

A caller may use this perspective with no diff. Then the document is the material.
Read every instruction as newly proposed. Apply the rules above with these changes:

- **Subtraction first** asks what the file can drop or merge. Omit `### Always-on
  budget` because nothing moved.
- All existing instructions are in scope. Neighbouring content is context only.
- Use the document's direct consumers for step 2. Use one inbound-reference grep for
  step 3. Do not follow references transitively.

## Output — extra required sections

Before the findings list, always output:

```
### Subtraction alternatives
- <added instruction> → <replace / merge / delete / move out / none + reason>
- (or "No net additions — deletions and rewrites only")

### Always-on budget
- <each always-on file touched> <+N/-M>
  → net <±N> lines
```

List at most the **8 highest-severity** findings. Say how many you dropped. Long
finding lists get skimmed.
