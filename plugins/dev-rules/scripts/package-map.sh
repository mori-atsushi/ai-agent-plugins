#!/usr/bin/env bash
# Writes a structure map of each named directory, so a design reviewer can judge a
# whole package without reading every file body: the files directly in it with their
# line counts, top-level declarations and their exposed members, how often each is referenced
# from other files, its child directories, and the packages it imports from and is
# imported by. Prints MAP=<path>, and FILES=<path> listing the files mapped.
#
# Usage: package-map.sh <dir>...
#
# Language support is one extractor per language in package-map/<language>.sh, whose
# "# extensions:" header names the file extensions it reads. An extractor prints
# tab-separated lines for the files given as arguments:
#   package <path> <package name>
#   decl    <path> <kind> <name>
#   member  <path> <owner> <kind> <name>   (optional) an exposed member of decl <owner>
#   import  <path> <package>
# A file with no extractor is listed with its line count only, and the map says so.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACTORS="$SCRIPT_DIR/package-map"

OUT_DIR="${REVIEW_DIFF_DIR:-${TMPDIR:-/tmp}/dev-rules}"
mkdir -p "$OUT_DIR"
MAP_FILE=$(mktemp "${OUT_DIR%/}/package-map-XXXXXX")
FILES_FILE="$MAP_FILE.files"

(($# > 0)) || { echo "usage: package-map.sh <dir>..." >&2; exit 2; }

extractor_for() {
  local ext="$1" file
  for file in "$EXTRACTORS"/*.sh; do
    if grep -qE "^# extensions:.*[[:space:]]$ext([[:space:]]|$)" "$file"; then
      echo "$file"
      return
    fi
  done
}

map_directory() {
  local dir="${1%/}" facts own_packages unsupported="" ext extractor
  facts=$(mktemp)
  local -a files=()
  while IFS= read -r f; do files+=("$f"); done < <(find "$dir" -maxdepth 1 -type f ! -name '.*' | sort)
  printf '%s\n' ${files[@]+"${files[@]}"} | sed '/^$/d' >>"$FILES_FILE"

  for ext in $(printf '%s\n' ${files[@]+"${files[@]}"} | sed -n 's/.*\.\([^./]*\)$/\1/p' | sort -u); do
    extractor=$(extractor_for "$ext")
    if [[ -n "$extractor" ]]; then
      bash "$extractor" $(printf '%s\n' ${files[@]+"${files[@]}"} | grep "\.$ext\$") >>"$facts"
    else
      unsupported+=" .$ext"
    fi
  done
  own_packages=$(awk -F'\t' '$1 == "package" { print $3 }' "$facts" | sort -u)

  echo "# $dir"
  echo
  echo "Package: $(echo $own_packages)"
  [[ -n "$unsupported" ]] && echo "No extractor for:$unsupported — read those files to judge them."
  echo
  echo "## Files (${#files[@]})"
  echo
  echo "Each declaration is \`kind name\`, then the number of other files that mention its"
  echo "name (a word match, so a common name over-counts; 0 is the signal). Indented under a"
  echo "class or object are its exposed members (not private, protected, or override),"
  echo "counted the same way."
  echo
  local f lines
  for f in ${files[@]+"${files[@]}"}; do
    lines=$(wc -l <"$f" | tr -d ' ')
    echo "- $f ($lines lines)"
    awk -F'\t' -v p="$f" '$1 == "decl" && $2 == p { print $3 "\t" $4 }' "$facts" |
      while IFS=$'\t' read -r kind name; do
        if [[ " $kind " == *" private "* ]]; then
          echo "  - $kind $name"
        else
          refs=$({ git grep -l -w -F -e "$name" -- . ":!$f" || true; } | wc -l | tr -d ' ')
          echo "  - $kind $name — $refs"
        fi
        awk -F'\t' -v p="$f" -v o="$name" '$1 == "member" && $2 == p && $3 == o { print $4 "\t" $5 }' "$facts" |
          while IFS=$'\t' read -r mkind mname; do
            refs=$({ git grep -l -w -F -e "$mname" -- . ":!$f" || true; } | wc -l | tr -d ' ')
            echo "    - $mkind $mname — $refs"
          done
      done
  done

  echo
  echo "## Child directories"
  echo
  local child any=""
  while IFS= read -r child; do
    any=1
    echo "- $child/ ($(find "$child" -type f ! -name '.*' | wc -l | tr -d ' ') files)"
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | sort)
  [[ -n "$any" ]] || echo "None."

  [[ -n "$own_packages" ]] || { rm -f "$facts"; return; }

  local out in
  out=$(awk -F'\t' '$1 == "import" { print $2 "\t" $3 }' "$facts" | sort -u | cut -f2 |
    grep -vxF "$own_packages" | sort | uniq -c | sort -rn || true)

  # Importers: every tracked file the same extractors read, outside this directory.
  local all_facts
  all_facts=$(mktemp)
  for ext in $(printf '%s\n' ${files[@]+"${files[@]}"} | sed -n 's/.*\.\([^./]*\)$/\1/p' | sort -u); do
    extractor=$(extractor_for "$ext")
    [[ -n "$extractor" ]] || continue
    git ls-files -z "*.$ext" | xargs -0 bash "$extractor" >>"$all_facts" 2>/dev/null || true
  done
  in=$(awk -F'\t' -v own="$own_packages" -v dir="$dir/" '
    BEGIN { n = split(own, o, "\n"); for (i = 1; i <= n; i++) mine[o[i]] = 1 }
    $1 == "package" { pkg[$2] = $3 }
    $1 == "import" && ($3 in mine) && index($2, dir) != 1 { from[$2] = 1 }
    END { for (p in from) if (!(pkg[p] in mine)) print pkg[p] }
  ' "$all_facts" | sort | uniq -c | sort -rn || true)
  rm -f "$all_facts"

  echo
  echo "## Imports from other packages (files importing)"
  echo
  [[ -n "$out" ]] && echo "$out" | awk '{ print "- " $2 " (" $1 ")" }' || echo "None."
  echo
  echo "## Imported by other packages (files importing)"
  echo
  [[ -n "$in" ]] && echo "$in" | awk '{ print "- " $2 " (" $1 ")" }' || echo "None."
  echo
  echo "## Both ways (a dependency cycle)"
  echo
  local both
  both=$(comm -12 <(echo "$out" | awk '{ print $2 }' | sort -u) <(echo "$in" | awk '{ print $2 }' | sort -u))
  [[ -n "$both" ]] && echo "$both" | sed 's/^/- /' || echo "None."
  rm -f "$facts"
}

{
  for dir in "$@"; do
    map_directory "$dir"
    echo
  done
} >"$MAP_FILE"
echo "MAP=$MAP_FILE"
echo "FILES=$FILES_FILE"
