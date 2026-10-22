#!/usr/bin/env bash
# Claude Code PostToolUse hook: after a file is read or written, names the rules that
# cover it — this plugin's general rules and the project's `.agents/rules/`. Each rule
# is named once per session; bodies are never injected.
# Any failure stays silent — a missing rule list must not block the tool call.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
FILE="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")"
SESSION="$(jq -r '.session_id // empty' <<<"$INPUT")"
CWD="$(jq -r '.cwd // empty' <<<"$INPUT")"
[ -n "$FILE" ] && [ -n "$SESSION" ] || exit 0
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null

RULES="$("$(dirname "$0")/rules.sh" "$FILE" 2>/dev/null)" || exit 0
[ -n "$RULES" ] || exit 0

STATE_DIR="${TMPDIR:-/tmp}/dev-rules"
mkdir -p "$STATE_DIR" || exit 0
SEEN="$STATE_DIR/hook-$SESSION.seen"
touch "$SEEN"

NEW="$(grep -vxF -f "$SEEN" <<<"$RULES" || true)"
[ -n "$NEW" ] || exit 0
printf '%s\n' "$NEW" >> "$SEEN"

CONTEXT="Rules that cover $FILE (dev-rules plugin rules first, then the project's). Before writing code there, read each one relevant to the task. Where a project rule differs from a plugin rule, the project rule wins.
$NEW"

jq -n --arg context "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $context}}'
