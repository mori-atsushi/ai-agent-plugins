#!/usr/bin/env bash
# Saves the review diff to a file so reviewer agents can read it by path instead
# of receiving the full diff inline. Shared by every skill that reviews a diff;
# it is not owned by any one of them, so it lives outside their directories.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# Output stays in the OS temp directory (not the reviewed repo) so these files
# never show up as untracked in the reviewed repo's git status, unless
# REVIEW_DIFF_DIR overrides it, keyed by repo path so concurrent worktrees do not
# overwrite each other's diff.
OUT_DIR="${REVIEW_DIFF_DIR:-${TMPDIR:-/tmp}/review-perspectives}"
mkdir -p "$OUT_DIR"
KEY=$(cksum <<<"$ROOT" | cut -d' ' -f1)
DIFF_FILE="${OUT_DIR%/}/review-diff-$KEY.diff"
FILES_FILE="${OUT_DIR%/}/review-files-$KEY.txt"
MODE="${1:-uncommitted}"
UNTRACKED=$(git ls-files --others --exclude-standard)

case "$MODE" in
  branch)
    if REMOTE_HEAD=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
      BRANCH="${REMOTE_HEAD#origin/}"
    else
      BRANCH="main"
      echo "Warning: could not resolve origin/HEAD; assuming $BRANCH" >&2
    fi
    BASE="$BRANCH"
    if git fetch origin "$BRANCH" 2>/dev/null; then
      BASE="origin/$BRANCH"
    else
      echo "Warning: could not fetch origin/$BRANCH; using local $BRANCH (diff may include stale commits)" >&2
    fi
    MERGE_BASE=$(git merge-base "$BASE" HEAD)
    HEADER="mode: branch, base: $BASE (merge-base..working tree, incl. uncommitted + untracked)"
    FILES=$(git diff "$MERGE_BASE" --name-only)
    LOG=$(git log --oneline "$BASE"..HEAD)
    DIFF_TEXT=$(git diff -U30 "$MERGE_BASE")
    ;;
  uncommitted)
    HEADER="mode: uncommitted (working tree vs. HEAD, incl. untracked files)"
    FILES=$(git diff HEAD --name-only)
    LOG=$(git log --oneline -5)
    DIFF_TEXT=$(git diff -U30 HEAD)
    ;;
  *)
    echo "Unknown mode: $MODE (expected no arg or 'branch')" >&2
    exit 1
    ;;
esac

if [ -n "$UNTRACKED" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    FILES="$FILES"$'\n'"$f"
    DIFF_TEXT="$DIFF_TEXT"$'\n'"$(git diff --no-index -U30 -- /dev/null "$f" || true)"
  done <<< "$UNTRACKED"
fi

if [ -z "$DIFF_TEXT" ]; then
  echo "MODE=$MODE"
  echo "EMPTY=true"
  exit 0
fi

{
  echo "# Review diff — $HEADER"
  echo
  echo "## Changed files"
  echo "$FILES"
  echo
  echo "## Commits"
  echo "$LOG"
  echo
  echo "## Diff (git diff -U30)"
  echo
  echo "$DIFF_TEXT"
} > "$DIFF_FILE"
chmod 600 "$DIFF_FILE"

echo "$FILES" > "$FILES_FILE"
chmod 600 "$FILES_FILE"

echo "MODE=$MODE"
echo "DIFF=$DIFF_FILE"
echo "FILES=$FILES_FILE"
