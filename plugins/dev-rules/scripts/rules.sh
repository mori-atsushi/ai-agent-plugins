#!/usr/bin/env bash
# Lists the rule files that apply, one per line as "<path>\t<description>", so the
# caller can judge relevance before opening one. Only paths and summaries are
# printed, never rule bodies.
#
# Usage: rules.sh [--perspective <name>] [--files-list <file>] [<path>...]
#
#   <path>... / --files-list  keep only rules whose `paths` match one of these files
#                             (absolute or repo-relative); with neither, every rule
#   --perspective <name>      keep only rules that list <name> under `perspectives`
#
# Roots, in print order — this plugin's general rules first, so where a project rule
# contradicts one, the later project rule wins:
#   <plugin>/rules/     general rules
#   .agents/rules/      the project's own rules
#
# A file opts in through its own YAML frontmatter — there is no registry to keep in
# sync:
#   description: <text>            one-line summary printed alongside the path
#   paths: [<glob>, ...]           which files it covers; absent = every file
# Lists are block style (`key:` then `  - value`) or one-line flow style; scalars are
# single-line.
#   perspectives: [<name>, ...]    which reviewers apply it

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERSPECTIVE=""
CHANGED=()

while [ $# -gt 0 ]; do
  case "$1" in
    --perspective) PERSPECTIVE="${2:?--perspective needs a name}"; shift 2 ;;
    --files-list)
      if [ -n "${2:-}" ] && [ "$2" != "-" ] && [ -s "$2" ]; then
        while IFS= read -r f; do
          [ -n "$f" ] && CHANGED+=("$f")
        done < "$2"
      fi
      shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) CHANGED+=("$1"); shift ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# Globs are repo-relative, so an absolute path inside the repo is made relative.
for i in ${CHANGED[@]+"${!CHANGED[@]}"}; do
  CHANGED[$i]="${CHANGED[$i]#"$ROOT"/}"
done

ROOTS=("$PLUGIN_ROOT/rules" .agents/rules)

shopt -s extglob nullglob

trim_value() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
  v="${v%\"}"; v="${v#\"}"
  v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}

collect() {
  case "$key" in
    perspectives) perspectives+=("$1") ;;
    paths) globs+=("$1") ;;
    description) desc="$1" ;;
  esac
}

# Translates a glob into a bash extended pattern: `{a,b}` -> `@(a|b)`, and `**/` ->
# `@(*/|)` so a leading `**/` also matches a file at the repo root.
to_pattern() {
  local p="$1" inner
  while [[ $p =~ \{([^{}]*)\} ]]; do
    inner="${BASH_REMATCH[1]}"
    p="${p/\{$inner\}/@(${inner//,/|})}"
  done
  p="${p//\*\*\//@(*\/|)}"
  p="${p//\*\*/*}"
  printf '%s' "$p"
}

# Splits a flow-style list body on the commas outside `{…}`, so a brace glob such as
# `**/*.{kt,kts}` stays one item.
split_flow() {
  local rest="$1" item="" depth=0 c i
  for ((i = 0; i < ${#rest}; i++)); do
    c="${rest:i:1}"
    case "$c" in
      '{') depth=$((depth + 1)) ;;
      '}') depth=$((depth - 1)) ;;
      ',') if [ "$depth" -eq 0 ]; then collect "$(trim_value "$item")"; item=""; continue; fi ;;
    esac
    item+="$c"
  done
  [ -n "$(trim_value "$item")" ] && collect "$(trim_value "$item")"
  return 0
}

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  for file in "$root"/*.md; do
    [ -f "$file" ] || continue
    [ "$(head -n 1 "$file")" = "---" ] || continue

    perspectives=()
    globs=()
    desc=""
    key=""
    while IFS= read -r line; do
      [ "$line" = "---" ] && break
      if [[ $line =~ ^([A-Za-z_-]+):[[:space:]]*(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"
        # Flow style on one line: `paths: ["a", "b"]`.
        if [[ $rest == \[*\] ]]; then
          rest="${rest#[}"; rest="${rest%]}"
          split_flow "$rest"
        elif [ -n "$rest" ]; then
          # Single-line scalar, e.g. `description: some text`.
          collect "$(trim_value "$rest")"
        fi
      elif [[ $line =~ ^[[:space:]]+-[[:space:]]+(.*)$ ]]; then
        collect "$(trim_value "${BASH_REMATCH[1]}")"
      fi
    done < <(tail -n +2 "$file")

    if [ -n "$PERSPECTIVE" ]; then
      match=""
      for p in ${perspectives[@]+"${perspectives[@]}"}; do
        [ "$p" = "$PERSPECTIVE" ] && match=yes
      done
      [ -n "$match" ] || continue
    fi

    # No globs, or no file to match against (a plan review has none): always listed.
    if [ ${#globs[@]} -eq 0 ] || [ ${#CHANGED[@]} -eq 0 ]; then
      printf '%s\t%s\n' "${file#"$ROOT"/}" "$desc"
      continue
    fi

    for glob in "${globs[@]}"; do
      pattern="$(to_pattern "$glob")"
      for changed in "${CHANGED[@]}"; do
        # shellcheck disable=SC2053
        if [[ $changed == $pattern ]]; then
          printf '%s\t%s\n' "${file#"$ROOT"/}" "$desc"
          break 2
        fi
      done
    done
  done
done
