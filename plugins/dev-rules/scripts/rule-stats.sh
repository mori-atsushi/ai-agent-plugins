#!/usr/bin/env bash
# Counts, per rule, how often reviews applied it and how their findings that cite it
# were triaged, from the records review-record.sh writes. A rule cited rarely though
# often applied, or mostly ignored, is a candidate for rewording or removal.
#
# Usage: rule-stats.sh [<records dir>]   (default: where review-record.sh writes)
#
# Prints TSV: rule, applied (reviews that applied it), cited (findings citing it), and
# those findings by triage: fix, report, out-of-scope, ignore. Every current plugin
# rule is listed, cited or not, plus any other rule the records name, such as a
# removed one. A project rule is prefixed with its project's directory name.

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "rule-stats: jq not found" >&2; exit 2; }

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-${DEV_RULES_REVIEWS:-${XDG_STATE_HOME:-$HOME/.local/state}/dev-rules/reviews}}"
[ -d "$DIR" ] || { echo "rule-stats: no records in $DIR" >&2; exit 1; }

# Same ID pattern as rule_keys in review-record.sh.
IDS="$(sed -n 's/^- \[\([A-Z][A-Z0-9]*-[0-9][0-9]*\)\].*/\1/p' "$PLUGIN_ROOT"/rules/*.md |
  jq -R . | jq -sc .)"

find "$DIR" -maxdepth 1 -name '*.json' -exec cat {} + | jq -rs --argjson ids "$IDS" '
  # A project rule key (`.agents/rules/…`) is only unique within its project.
  def qualify($project): if startswith(".agents/") then "\($project | split("/") | last):\(.)" else . end;
  map(.project as $p | {
    applied: [.applicable[][] | qualify($p)] | unique,
    findings: [.findings[] | .rules = [.rules[] | qualify($p)]]
  }) as $reviews
  | [$reviews[].findings[]] as $findings
  | ($ids + [$reviews[].applied[]] + [$findings[].rules[]] | unique
     | sort_by(split("-") | [.[0], (.[1] // "" | tonumber? // 0)])) as $keys
  | ["rule", "applied", "cited", "fix", "report", "out-of-scope", "ignore"],
    ($keys[] as $k
      | ($findings | map(select(.rules | index($k)))) as $cited
      | [$k, ($reviews | map(select(.applied | index($k))) | length), ($cited | length)]
        + (["fix", "report", "out-of-scope", "ignore"]
           | map(. as $t | $cited | map(select(.triage == $t)) | length)))
  | @tsv'
