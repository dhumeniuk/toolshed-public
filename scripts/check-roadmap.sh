#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-roadmap.sh <commit-msg-file>}"
REPO_ROOT="$(git rev-parse --show-toplevel)"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# doc-only shortcut: skip roadmap validation
if echo "$STRIPPED_MSG" | head -1 | grep -qE '^doc: .+'; then
  exit 0
fi

FIRST_LINE="$(echo "$STRIPPED_MSG" | head -1)"
ISSUE_NUMBER="$(echo "$FIRST_LINE" | grep -oE '\[[0-9]+\]' | tr -d '[]' || true)"

ROADMAP="$REPO_ROOT/ROADMAP.md"
if [[ ! -f "$ROADMAP" ]]; then exit 0; fi

if [[ -n "$ISSUE_NUMBER" ]]; then
  if grep -qE "\|\s*$ISSUE_NUMBER\s*\|" "$ROADMAP"; then
    echo "error: issue #$ISSUE_NUMBER is still in ROADMAP.md"
    echo "  remove it from ROADMAP.md before committing"
    exit 1
  fi
else
  DESC="$(echo "$FIRST_LINE" | sed 's/^[a-z]*: \[[0-9]*\] //')"
  if grep -qF "| $DESC |" "$ROADMAP"; then
    echo "error: '$DESC' is still in ROADMAP.md"
    echo "  remove it from ROADMAP.md before committing"
    exit 1
  fi
fi
