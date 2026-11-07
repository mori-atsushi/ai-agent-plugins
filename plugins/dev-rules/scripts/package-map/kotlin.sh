#!/usr/bin/env bash
# extensions: kt kts
# Kotlin extractor for package-map.sh. Reads the .kt files named as arguments and
# prints, tab-separated, one line per fact:
#   package <path> <package name>
#   decl    <path> <kind> <name>     a top-level declaration; kind keeps its modifiers
#   import  <path> <package>         the package an import names
set -euo pipefail

awk '
  FNR == 1 { path = FILENAME }
  /^package[ \t]/ {
    name = $2; sub(/;$/, "", name)
    print "package\t" path "\t" name
    next
  }
  /^import[ \t]/ {
    target = $2; sub(/;$/, "", target)
    n = split(target, part, ".")
    pkg = ""
    for (i = 1; i < n; i++) {
      if (part[i] ~ /^[A-Z]/) break
      pkg = (pkg == "" ? part[i] : pkg "." part[i])
    }
    print "import\t" path "\t" pkg
    next
  }
  /^[a-z@]/ {
    line = $0
    gsub(/@[A-Za-z.]+(\([^)]*\))?[ \t]*/, "", line)
    if (match(line, /(^|[ \t])(class|interface|object|fun|val|var|typealias)[ \t]/) == 0) next
    kind = substr(line, 1, RSTART + RLENGTH - 2)
    sub(/^[ \t]+/, "", kind)
    rest = substr(line, RSTART + RLENGTH)
    if (kind ~ /fun$/ && rest ~ /^interface[ \t]/) { kind = kind " interface"; sub(/^interface[ \t]+/, "", rest) }
    sub(/^<[^>]*>[ \t]*/, "", rest)
    if (match(rest, /^[A-Za-z_][A-Za-z0-9_.]*(<[^>]*>)?(\?)?\.?[A-Za-z_][A-Za-z0-9_]*/) == 0) next
    name = substr(rest, 1, RLENGTH)
    gsub(/<[^>]*>/, "", name)
    sub(/^.*\./, "", name)
    print "decl\t" path "\t" kind "\t" name
  }
' "$@"
