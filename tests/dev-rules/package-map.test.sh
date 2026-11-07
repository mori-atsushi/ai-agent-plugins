#!/usr/bin/env bash
# Tests for plugins/dev-rules/scripts/package-map.sh and its Kotlin extractor.
# Builds a throwaway git repository, maps its directories, and checks the map.
# Run: bash tests/dev-rules/package-map.test.sh   (exit 0 when every check passes)

set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/plugins/dev-rules/scripts/package-map.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export REVIEW_DIFF_DIR="$WORK/out"
failures=0

check() { # check <description> <map file> <exact line expected>
  if grep -qxF -- "$3" "$2"; then
    echo "ok   - $1"
  else
    echo "FAIL - $1: no line '$3'"
    failures=$((failures + 1))
  fi
}

refute() { # refute <description> <map file> <fixed text that must not appear>
  if grep -qF -- "$3" "$2"; then
    echo "FAIL - $1: found '$3'"
    failures=$((failures + 1))
  else
    echo "ok   - $1"
  fi
}

run_map() { # run_map <dir>... ; sets MAP and FILES
  local out
  out=$(bash "$SCRIPT" "$@")
  MAP=$(sed -n 's/^MAP=//p' <<<"$out")
  FILES=$(sed -n 's/^FILES=//p' <<<"$out")
}

cd "$WORK"
git init -q repo
cd repo
mkdir -p a/p b/q only/sub

cat >a/p/Box.kt <<'KT'
package a.p

import b.q.Thing
import c.d.topFn
import e.f.*

class Box(
    val width: Int,
    private val secret: Int,
) {
    fun area(): Int = width
    internal val label: String get() = ""
    private fun hidden() = 1
    protected fun guarded() = 2
    override fun toString() = ""
    companion object {
        fun make() = Box(1, 2)
    }
}

private class P {
    fun notExposed() = 1
}

fun interface Callback {
    fun call()
}

internal fun <T> Box.unusedExtensionXyz(value: T) = value

internal val usedEverywhereXyz = 1
KT

cat >a/p/notes.txt <<'TXT'
not Kotlin
TXT

cat >b/q/Thing.kt <<'KT'
package b.q

import a.p.Box

class Thing {
    val box = Box(1, 2)
    val n = usedEverywhereXyz
}
KT

touch only/sub/Leaf.kt
git add -A

echo "# Top-level declarations"
run_map a/p
check "class with its line count" "$MAP" "- a/p/Box.kt (31 lines)"
check "class referenced from another file" "$MAP" "  - class Box — 1"
check "fun interface keeps its kind and name" "$MAP" "  - fun interface Callback — 0"
check "single-letter private class, no count" "$MAP" "  - private class P"
check "generic extension fun named by its own name" "$MAP" "  - internal fun unusedExtensionXyz — 0"
check "property used elsewhere" "$MAP" "  - internal val usedEverywhereXyz — 1"

echo "# Exposed members"
check "constructor property" "$MAP" "    - val width — 0"
check "member function" "$MAP" "    - fun area — 0"
check "internal member property" "$MAP" "    - internal val label — 0"
refute "private constructor property left out" "$MAP" "secret"
refute "private member left out" "$MAP" "hidden"
refute "protected member left out" "$MAP" "guarded"
refute "override left out" "$MAP" "toString"
refute "companion object member left out" "$MAP" "make"
refute "private class's members left out" "$MAP" "notExposed"

echo "# Packages"
check "package line" "$MAP" "Package: a.p"
check "imports a class's package" "$MAP" "- b.q (1)"
check "imports a top-level function's package" "$MAP" "- c.d (1)"
check "imports a star import's package" "$MAP" "- e.f (1)"
check "a package on both sides is a cycle" "$MAP" "## Both ways (a dependency cycle)"
sed -n '/^## Both ways/,$p' "$MAP" >"$WORK/cycle"
check "cycle names the other package" "$WORK/cycle" "- b.q"

echo "# Files without an extractor"
check "unsupported extension named" "$MAP" "No extractor for: .txt — read those files to judge them."
check "unsupported file still listed" "$MAP" "- a/p/notes.txt (1 lines)"

echo "# FILES list"
check "FILES lists the Kotlin file" "$FILES" "a/p/Box.kt"
check "FILES lists the other file" "$FILES" "a/p/notes.txt"

echo "# A directory with only a child directory"
run_map only
check "no files" "$MAP" "## Files (0)"
check "child directory listed" "$MAP" "- only/sub/ (1 files)"

echo "# Concurrent maps do not share a path"
run_map a/p
first=$MAP
run_map a/p
if [[ "$first" != "$MAP" ]]; then echo "ok   - each run writes its own map"; else
  echo "FAIL - two runs wrote the same map path"; failures=$((failures + 1)); fi

echo
if ((failures > 0)); then
  echo "$failures check(s) failed"
  exit 1
fi
echo "All checks passed"
