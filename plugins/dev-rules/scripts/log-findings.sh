#!/usr/bin/env bash
# Validates one review's triaged findings and appends them, with the rules each
# perspective applied, to a JSON Lines log. Any invalid finding rejects the whole
# input (exit 1), so the log never holds a partial review. Without jq, nothing is
# logged (exit 2).
#
# Usage: log-findings.sh --skill <name> --perspective <name>... [--files-list <file>] [<path>...] < findings.jsonl
#
#   --skill <name>            the review skill, e.g. review-code
#   --perspective <name>      a perspective that ran; repeat for each, findings or not
#   <path>... / --files-list  the reviewed files, passed on to rules.sh
#
# Each input line is one finding:
#   {"perspective": "design", "severity": "medium", "triage": "accepted", "rules": ["KD-3"]}
#   severity  critical | high | medium | low
#   triage    accepted (valid, in scope, fixed or not) | rejected | out-of-scope
#   rules     the cited rules among those the perspective applied: IDs, or
#             `.agents/rules/` paths for rules without one
#
# The log is $DEV_RULES_LOG, or $XDG_STATE_HOME/dev-rules/findings.jsonl.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "log-findings: jq not found; findings not logged" >&2
  exit 2
fi

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL=""
PERSPECTIVES=()
RULES_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --skill) SKILL="${2:?--skill needs a name}"; shift 2 ;;
    --perspective) PERSPECTIVES+=("${2:?--perspective needs a name}"); shift 2 ;;
    --files-list) RULES_ARGS+=(--files-list "${2:?--files-list needs a file}"); shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) RULES_ARGS+=("$1"); shift ;;
  esac
done
[ -n "$SKILL" ] || { echo "log-findings: --skill is required" >&2; exit 1; }
[ ${#PERSPECTIVES[@]} -gt 0 ] || { echo "log-findings: --perspective is required" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# The rule a citation names: each ID in a rule file, or the file's path when it has none.
# rule-stats.sh matches IDs with the same pattern.
rule_keys() {
  local ids
  ids="$(sed -n 's/^- \[\([A-Z][A-Z0-9]*-[0-9][0-9]*\)\].*/\1/p' "$1")"
  if [ -n "$ids" ]; then printf '%s\n' "$ids"; else printf '%s\n' "${1#"$ROOT"/}"; fi
}

APPLICABLE="{}"
for p in "${PERSPECTIVES[@]}"; do
  keys="$("$PLUGIN_ROOT/scripts/rules.sh" --perspective "$p" ${RULES_ARGS[@]+"${RULES_ARGS[@]}"} |
    cut -f1 | while IFS= read -r f; do rule_keys "$f"; done | jq -R . | jq -sc .)"
  APPLICABLE="$(jq -c --arg p "$p" --argjson k "$keys" '. + {($p): $k}' <<<"$APPLICABLE")"
done

RUN="$(date -u +%Y%m%dT%H%M%SZ)-$$"
VERSION="$(jq -r .version "$PLUGIN_ROOT/.claude-plugin/plugin.json")"
OUT="$(jq -nc --arg run "$RUN" --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg project "$(basename "$ROOT")" --arg skill "$SKILL" --arg version "$VERSION" \
  --argjson applicable "$APPLICABLE" \
  '{type: "run", run: $run, date: $date, project: $project, skill: $skill,
    version: $version, applicable: $applicable}')"

PERSPECTIVES_JSON="$(printf '%s\n' "${PERSPECTIVES[@]}" | jq -R . | jq -sc .)"
ERRORS=""
n=0
while IFS= read -r line || [ -n "$line" ]; do
  n=$((n + 1))
  [ -n "${line//[[:space:]]/}" ] || continue
  if ! jq -e . >/dev/null 2>&1 <<<"$line"; then
    problems="not valid JSON"
  else
    problems="$(jq -r --argjson applicable "$APPLICABLE" --argjson perspectives "$PERSPECTIVES_JSON" '
      if type != "object" then "not a JSON object" else
        (keys - ["perspective", "severity", "triage", "rules"] | map("unknown key \(.)") | .[]),
        (["perspective", "severity", "triage", "rules"] - keys | map("missing key \(.)") | .[]),
        (select(has("perspective") and (.perspective as $p | $perspectives | index($p) | not))
          | "perspective \(.perspective | tojson) is not one of \($perspectives | join(", "))"),
        (select(has("severity") and (.severity | IN("critical", "high", "medium", "low") | not))
          | "severity \(.severity | tojson) is not critical, high, medium, or low"),
        (select(has("triage") and (.triage | IN("accepted", "rejected", "out-of-scope") | not))
          | "triage \(.triage | tojson) is not accepted, rejected, or out-of-scope"),
        (select(has("rules")) | .perspective as $p | .rules
          | if type != "array" then "rules is not an array"
            elif ($perspectives | index($p)) == null then empty
            else .[] | select(. as $r | $applicable[$p] | index($r) | not)
              | "rule \(tojson) is not a rule ID or .agents/rules path that \($p) applied" end)
      end' <<<"$line")"
  fi
  if [ -n "$problems" ]; then
    ERRORS+="$(sed "s/^/line $n: /" <<<"$problems")"$'\n'
  else
    OUT+=$'\n'"$(jq -c --arg run "$RUN" '{type: "finding", run: $run} + .' <<<"$line")"
  fi
done

if [ -n "$ERRORS" ]; then
  printf 'log-findings: nothing logged; fix these and resend every finding:\n%s' "$ERRORS" >&2
  exit 1
fi

LOG="${DEV_RULES_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/dev-rules/findings.jsonl}"
mkdir -p "$(dirname "$LOG")"
printf '%s\n' "$OUT" >> "$LOG"
echo "Logged $(($(wc -l <<<"$OUT") - 1)) findings to $LOG"
