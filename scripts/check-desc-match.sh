#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-desc-match.sh <commit-msg-file>}"
REPO_ROOT="$(git rev-parse --show-toplevel)"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# doc-only shortcut: skip description validation
if echo "$STRIPPED_MSG" | head -1 | grep -qE '^doc: .+'; then
  exit 0
fi

FIRST_LINE="$(echo "$STRIPPED_MSG" | head -1)"
ISSUE_NUMBER="$(echo "$FIRST_LINE" | grep -oE '\[[0-9]+\]' | tr -d '[]' || true)"
if [[ -z "$ISSUE_NUMBER" ]]; then exit 0; fi

RELEASE_NOTES="$REPO_ROOT/RELEASE_NOTES.md"
if [[ ! -f "$RELEASE_NOTES" ]]; then
  echo "error: RELEASE_NOTES.md not found in repo root"
  exit 1
fi

RELEASE_NOTES_ROWS="$(grep -E "\|\s*$ISSUE_NUMBER\s*\|" "$RELEASE_NOTES" || true)"
if [[ -z "$RELEASE_NOTES_ROWS" ]]; then exit 0; fi

# Strip the type and issue bracket from the commit message to get the description
COMMIT_DESC="$(echo "$FIRST_LINE" | sed 's/^[a-z]*: \[[0-9]*\] //')"

# Pass if any row for this issue matches the commit description
while IFS= read -r row; do
  ROW_DESC="$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')"
  if [[ "$COMMIT_DESC" == "$ROW_DESC" ]]; then exit 0; fi
done <<< "$RELEASE_NOTES_ROWS"

echo "error: commit description does not match any RELEASE_NOTES.md entry for issue #$ISSUE_NUMBER"
echo "  commit: $COMMIT_DESC"
exit 1
