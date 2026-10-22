---
name: rules
description: "List the coding rules that apply to given files — this plugin's general rules plus the project's own — as path and one-line summary, without their bodies. Use before implementing a change to find which rules to read. Triggers: \"ルールを確認\", \"どのルールが適用される\", \"which rules apply\"."
argument-hint: "[<path>...] [--perspective <name>]"
allowed-tools: Bash(dev-rules *), Bash(dev-rules)
---

# Rules

Run `dev-rules <arguments>` and return its output unchanged. Each line is
`<path>\t<description>`.

- `<path>...` — files to be read or changed, existing or not; omit for every rule.
- `--perspective <name>` — only rules a reviewer of that perspective applies
  (`readability`, `design`, `simplify`, `test`, `spec`, `harness`).

Do not read the listed rules here. The caller opens the ones whose description fits
its task. The plugin's rules print first and the project's (`.agents/rules/`) after
them. Where two disagree, the project rule wins; among plugin rules, the more specific
one wins.
