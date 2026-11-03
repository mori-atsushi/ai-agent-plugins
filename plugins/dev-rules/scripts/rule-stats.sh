#!/usr/bin/env bash
# Counts, per rule, how often reviews applied it and how their findings that cite it
# were triaged, from the log log-findings.sh writes. A rule cited rarely though often
# applied, or mostly rejected, is a candidate for rewording or removal.
#
# Usage: rule-stats.sh [<log>]   (default: the log log-findings.sh writes)
#
# Prints TSV: rule, applied (reviews that applied it), cited (findings citing it),
# accepted, rejected, out-of-scope. Every current plugin rule is listed, cited or not,
# plus any other rule the log names, such as a removed one or a project rule's path.

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "rule-stats: jq not found" >&2; exit 2; }

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${1:-${DEV_RULES_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/dev-rules/findings.jsonl}}"
[ -f "$LOG" ] || { echo "rule-stats: no log at $LOG" >&2; exit 1; }

# Same ID pattern as rule_keys in log-findings.sh.
IDS="$(sed -n 's/^- \[\([A-Z][A-Z0-9]*-[0-9][0-9]*\)\].*/\1/p' "$PLUGIN_ROOT"/rules/*.md |
  jq -R . | jq -sc .)"

jq -rs --argjson ids "$IDS" '
  map(select(.type == "run")) as $runs
  | map(select(.type == "finding")) as $findings
  | ($ids + [$runs[].applicable[][]] + [$findings[].rules[]] | unique | sort_by(split("-") | [.[0], (.[1] // "" | tonumber? // 0)])) as $keys
  | ["rule", "applied", "cited", "accepted", "rejected", "out-of-scope"],
    ($keys[] as $k
      | ($findings | map(select(.rules | index($k)))) as $cited
      | [$k,
         ($runs | map(select([.applicable[][]] | index($k))) | length),
         ($cited | length),
         ($cited | map(select(.triage == "accepted")) | length),
         ($cited | map(select(.triage == "rejected")) | length),
         ($cited | map(select(.triage == "out-of-scope")) | length)])
  | @tsv' "$LOG"
