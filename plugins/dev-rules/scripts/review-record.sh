#!/usr/bin/env bash
# Keeps one review's findings in a JSON file, the source of rule-stats.sh's counts. Files
# live in $DEV_RULES_REVIEWS, default ${XDG_STATE_HOME:-~/.local/state}/dev-rules/reviews.
#
# Usage:
#   review-record.sh new --skill <name> --perspective <name> [--perspective <name>]... [--files-list <file>] [<path>...]
#       Creates a record holding the rules each perspective applies (rules.sh for the
#       given files) and prints RECORD=<path>.
#   review-record.sh add <record> < findings.jsonl
#       Validates one round of triaged findings, one JSON object per line, and appends
#       them as the next round, numbered in input order after the earlier rounds. Prints
#       only the numbers given. Any invalid line rejects the whole round (exit 1).
#
# A finding:
#   {"perspectives": ["design"], "severity": "medium", "location": "app/Main.kt:42",
#    "issue": "...", "grounds": ["KD-3", "docs/spec.md"], "triage": "in-scope"}
#   perspectives  the perspectives that raised it; several after dedupe
#   severity      critical | high | medium | low
#   location      file:line, the plan section, or a selected directory
#   triage        in-scope | out-of-scope | ignore
#   grounds       what the finding cites: rules those perspectives applied (an ID, or the
#                 path of a rule file without IDs), or other existing files
#
# Without jq, nothing is recorded (exit 2).

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "review-record: jq not found; nothing recorded" >&2
  exit 2
fi

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${DEV_RULES_REVIEWS:-${XDG_STATE_HOME:-$HOME/.local/state}/dev-rules/reviews}"
ID_PATTERN='^[A-Z][A-Z0-9]*-[0-9][0-9]*$'

# Prints the name a finding cites each rule in a rule file by: its ID, or the file's
# path when the file has no IDs. rule-stats.sh matches IDs with the same pattern.
rule_keys() {
  if has_rule_ids "$1"; then
    sed -n 's/^- \[\([A-Z][A-Z0-9]*-[0-9][0-9]*\)\].*/\1/p' "$1"
  else
    printf '%s\n' "${1#"$ROOT"/}"
  fi
}

# Whether the rule file lists rules under IDs, so a finding cites them by ID.
has_rule_ids() {
  grep -q '^- \[[A-Z][A-Z0-9]*-[0-9][0-9]*\]' "$1"
}

# Whether the file at this path, relative to the project or absolute, is a rule file:
# one in the project's .agents/rules/ or the plugin's rules/.
is_rule_file() {
  case "$1" in
    .agents/rules/*.md | "$PLUGIN_ROOT"/rules/*.md) return 0 ;;
    *) return 1 ;;
  esac
}

# Prints the path a ground names, in the project or else the plugin; nothing when
# neither has it.
resolve_ground() {
  if [ -e "$1" ]; then
    echo "$1"
  elif [ -e "$PLUGIN_ROOT/$1" ]; then
    echo "$PLUGIN_ROOT/$1"
  fi
}

# Passes problems through, replacing each "FILE <perspectives>\t<path>" — a cited path
# that is not an applied rule — with a problem when the path exists in neither the project
# nor the plugin, or is a rule file those perspectives did not apply.
check_files() {
  local line perspectives ground file
  while IFS= read -r line; do
    case "$line" in
      "FILE "*)
        perspectives="${line#FILE }"
        perspectives="${perspectives%%$'\t'*}"
        ground="${line#*$'\t'}"
        file="$(resolve_ground "$ground")"
        if [ -z "$file" ]; then
          echo "grounds \"$ground\" is neither a rule nor an existing file"
        elif is_rule_file "$file" && has_rule_ids "$file"; then
          echo "grounds \"$ground\" is a rule file with IDs; cite the ID of a rule in it that $perspectives applied, not its path"
        elif is_rule_file "$file"; then
          echo "rule \"$ground\" is not one that $perspectives applied"
        fi ;;
      ?*) echo "$line" ;;
    esac
  done
}

cmd_new() {
  local skill="" perspectives=() rules_args=() paths=() p applicable keys
  while [ $# -gt 0 ]; do
    case "$1" in
      --skill) skill="${2:?--skill needs a name}"; shift 2 ;;
      --perspective) perspectives+=("${2:?--perspective needs a name}"); shift 2 ;;
      --files-list) rules_args+=(--files-list "${2:?--files-list needs a file}"); shift 2 ;;
      -*) echo "Unknown option: $1" >&2; exit 1 ;;
      *) rules_args+=("$1"); paths+=("$1"); shift ;;
    esac
  done
  [ -n "$skill" ] || { echo "review-record: --skill is required" >&2; exit 1; }
  [ ${#perspectives[@]} -gt 0 ] || { echo "review-record: --perspective is required" >&2; exit 1; }

  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$ROOT"
  for p in ${paths[@]+"${paths[@]}"}; do
    [ -e "$p" ] || {
      echo "review-record: no file or directory \"$p\"; give each perspective its own --perspective" >&2
      exit 1
    }
  done

  applicable="{}"
  for p in "${perspectives[@]}"; do
    keys="$("$PLUGIN_ROOT/scripts/rules.sh" --perspective "$p" ${rules_args[@]+"${rules_args[@]}"} |
      cut -f1 | while IFS= read -r f; do rule_keys "$f"; done | jq -R . | jq -sc 'unique')"
    applicable="$(jq -c --arg p "$p" --argjson k "$keys" '. + {($p): $k}' <<<"$applicable")"
  done

  mkdir -p "$DIR"
  local record
  record="$DIR/$(date -u +%Y%m%dT%H%M%SZ)-$(basename "$ROOT")-$skill-$$.json"
  jq -n --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg project "$ROOT" \
    --arg skill "$skill" --arg version "$(jq -r .version "$PLUGIN_ROOT/.claude-plugin/plugin.json")" \
    --argjson applicable "$applicable" \
    '{date: $date, project: $project, skill: $skill, version: $version,
      applicable: $applicable, rounds: 0, findings: []}' > "$record"
  echo "RECORD=$record"
}

cmd_add() {
  local record="${1:?add needs a record path}"
  [ -f "$record" ] || { echo "review-record: no record at $record" >&2; exit 1; }
  local applicable errors="" valid="" n=0 line problems
  applicable="$(jq -c .applicable "$record")"
  ROOT="$(jq -r .project "$record")"
  cd "$ROOT"

  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    [ -n "${line//[[:space:]]/}" ] || continue
    if ! jq -e . >/dev/null 2>&1 <<<"$line"; then
      problems="not valid JSON"
    else
      problems="$(jq -r --argjson applicable "$applicable" --arg id_pattern "$ID_PATTERN" '
        def strings_array: type == "array" and length > 0 and all(type == "string");
        if type != "object" then "not a JSON object" else
          (keys - ["perspectives", "severity", "location", "issue", "grounds", "triage"]
            | map("unknown key \(.)") | .[]),
          (["perspectives", "severity", "location", "issue", "grounds", "triage"] - keys
            | map("missing key \(.)") | .[]),
          (select(has("perspectives")) | .perspectives
            | if strings_array | not then "perspectives is not a non-empty array of names"
              else .[] | select($applicable[.] == null)
                | "perspective \(tojson) did not run (\($applicable | keys | join(", ")))" end),
          (select(has("severity") and (.severity | IN("critical", "high", "medium", "low") | not))
            | "severity \(.severity | tojson) is not critical, high, medium, or low"),
          (select(has("triage") and (.triage | IN("in-scope", "out-of-scope", "ignore") | not))
            | "triage \(.triage | tojson) is not in-scope, out-of-scope, or ignore"),
          (select(has("location") and (.location | type != "string" or length == 0))
            | "location is not a non-empty string"),
          (select(has("issue") and (.issue | type != "string" or length == 0))
            | "issue is not a non-empty string"),
          (select(has("grounds")) | (.perspectives // []) as $ps | .grounds
            | if strings_array | not then "grounds is not a non-empty array of strings"
              else .[] | . as $g
                | select([$ps[] | select(type == "string") | $applicable[.] // [] | index($g)] | any | not)
                | if startswith("/")
                  then "grounds \(tojson) is absolute; use a path relative to the project or plugin root"
                  elif test($id_pattern)
                  then "rule \(tojson) is not one that \($ps | join(", ")) applied"
                  else "FILE \($ps | join(", "))\t\(.)" end end)
        end' <<<"$line")"
      problems="$(check_files <<<"$problems")"
    fi
    if [ -n "$problems" ]; then
      errors+="$(sed "s/^/line $n: /" <<<"$problems")"$'\n'
    else
      valid+="$line"$'\n'
    fi
  done

  if [ -n "$errors" ]; then
    printf 'review-record: nothing recorded; fix these and resend the whole round:\n%s' "$errors" >&2
    exit 1
  fi

  local tmp="$record.tmp"
  if ! printf '%s' "$valid" | jq -s --slurpfile record "$record" '
    $record[0] as $r
    | ($r.rounds + 1) as $round
    | $r + {rounds: $round, findings: ($r.findings + (to_entries | map(.value as $f | $f + {
        id: (($r.findings | length) + .key + 1),
        round: $round
      })))}' > "$tmp"; then
    rm -f "$tmp"
    exit 1
  fi
  mv "$tmp" "$record"
  jq -r '.rounds as $round | [.findings[] | select(.round == $round) | .id]
    | if length == 0 then "Recorded no findings (round \($round))"
      elif length == 1 then "Recorded 1 finding as #\(first) (round \($round))"
      else "Recorded \(length) findings as #\(first)–#\(last) (round \($round))" end' "$record"
}

case "${1:-}" in
  new) shift; cmd_new "$@" ;;
  add) shift; cmd_add "$@" ;;
  *) echo "Usage: review-record.sh new|add ..." >&2; exit 1 ;;
esac
