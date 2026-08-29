#!/usr/bin/env bash
# Prints the reference files a reviewer for <perspective> must read, one path per
# line: the perspective's own checklists plus the reviewing project's additional
# rules. Run by the reviewer itself — no skill selects or forwards them.
#
# A file opts in through its own YAML frontmatter — there is no registry to keep in
# sync:
#   perspectives: [<name>, ...]   which reviewers it belongs to (required to be found)
#   paths: [<glob>, ...]          which changed files make it relevant; absent = always
#
# Only review files are searched. `docs/rules/` is deliberately out: a rule tells an
# author what to write, a perspective tells a reviewer what to flag, and the two want
# different wording and granularity even where they cover the same ground.

set -euo pipefail

PLUGIN_ROOT="${1:?usage: review-refs.sh <plugin-root> <perspective> [changed-files-list]}"
PERSPECTIVE="${2:?usage: review-refs.sh <plugin-root> <perspective> [changed-files-list]}"
FILES_LIST="${3:-}"

cd "$(git rev-parse --show-toplevel)"

# Every root is scanned the same way. The perspective checklists come first so a
# reviewer reads the general rule before the project's take on it.
ROOTS=("$PLUGIN_ROOT/review-perspectives" .agents/review-perspectives)

CHANGED=()
if [ -n "$FILES_LIST" ] && [ "$FILES_LIST" != "-" ] && [ -s "$FILES_LIST" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && CHANGED+=("$f")
  done < "$FILES_LIST"
fi

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

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  for file in "$root"/*.md; do
    [ -f "$file" ] || continue
    [ "$(head -n 1 "$file")" = "---" ] || continue

    perspectives=()
    globs=()
    key=""
    while IFS= read -r line; do
      [ "$line" = "---" ] && break
      if [[ $line =~ ^([A-Za-z_-]+):[[:space:]]*(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"
        # Flow style on one line: `paths: ["a", "b"]`.
        if [[ $rest == \[*\] ]]; then
          rest="${rest#[}"; rest="${rest%]}"
          IFS=',' read -ra items <<< "$rest"
          for value in ${items[@]+"${items[@]}"}; do
            collect "$(trim_value "$value")"
          done
        fi
      elif [[ $line =~ ^[[:space:]]+-[[:space:]]+(.*)$ ]]; then
        collect "$(trim_value "${BASH_REMATCH[1]}")"
      fi
    done < <(tail -n +2 "$file")

    match=""
    for p in ${perspectives[@]+"${perspectives[@]}"}; do
      [ "$p" = "$PERSPECTIVE" ] && match=yes
    done
    [ -n "$match" ] || continue

    # No globs, or no changed-file list (a plan review has none): always relevant.
    if [ ${#globs[@]} -eq 0 ] || [ ${#CHANGED[@]} -eq 0 ]; then
      echo "$file"
      continue
    fi

    for glob in "${globs[@]}"; do
      pattern="$(to_pattern "$glob")"
      for changed in "${CHANGED[@]}"; do
        # shellcheck disable=SC2053
        if [[ $changed == $pattern ]]; then
          echo "$file"
          break 2
        fi
      done
    done
  done
done
