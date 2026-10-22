---
name: rules
description: List the coding rules that apply to given files — this plugin's general rules plus the project's own — as path and one-line summary, without their bodies. Use before implementing a change to find which rules to read, or for "ルールを確認" / "which rules apply".
---

# Rules

Resolve this plugin's root from the source path of this
`codex/skills/rules/SKILL.md` (its plugin-root ancestor), then run:

```bash
bash "<plugin root>/scripts/rules.sh" [<path>...] [--perspective <name>]
```

Return its output unchanged. Each line is `<path>\t<description>`.

- `<path>...` — files to be read or changed, existing or not; omit for every rule.
- `--perspective <name>` — only rules a reviewer of that perspective applies
  (`readability`, `design`, `simplify`, `test`, `spec`, `harness`).

Do not read the listed rules here. The caller opens the ones whose description fits
its task. The plugin's rules print first and the project's (`.agents/rules/`) after
them. Where two disagree, the project rule wins; among plugin rules, the more specific
one wins.
