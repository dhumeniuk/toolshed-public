#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-release-notes.sh <commit-msg-file>}"
REPO_ROOT="$(git rev-parse --show-toplevel)"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# doc-only shortcut: skip release notes validation
if echo "$STRIPPED_MSG" | head -1 | grep -qE '^doc: .+'; then
  exit 0
fi

FIRST_LINE="$(echo "$STRIPPED_MSG" | head -1)"
# Extract issue number like [123] -> 123
ISSUE_ID="$(echo "$FIRST_LINE" | grep -oE '\[[0-9]+\]' | tr -d '[]' || echo "")"

# No issue ID in commit — nothing to check
if [[ -z "$ISSUE_ID" ]]; then
  exit 0
fi

RELEASE_NOTES="$REPO_ROOT/RELEASE_NOTES.md"
if [[ ! -f "$RELEASE_NOTES" ]]; then
  echo "error: RELEASE_NOTES.md not found in repo root"
  exit 1
fi

# Read issue title from cache written by check-gh-issue.sh, or fall back to gh
CACHE_FILE="/tmp/gh-issue-${ISSUE_ID}-title"
if [[ -f "$CACHE_FILE" ]]; then
  ISSUE_TITLE="$(cat "$CACHE_FILE")"
elif command -v gh &>/dev/null; then
  ISSUE_TITLE="$(gh issue view "$ISSUE_ID" --json title -q .title 2>/dev/null || echo "")"
else
  echo "error: gh CLI not found and no cache — cannot verify release notes"
  exit 1
fi

if [[ -z "$ISSUE_TITLE" ]]; then
  echo "error: could not fetch title for issue #$ISSUE_ID"
  exit 1
fi

# Check that "- <issue_id>: <issue_title>" exists in RELEASE_NOTES.md
if ! grep -qF -- "- $ISSUE_ID: $ISSUE_TITLE" "$RELEASE_NOTES"; then
  echo "error: release note entry not found in RELEASE_NOTES.md"
  echo "  expected: '- $ISSUE_ID: $ISSUE_TITLE'"
  exit 1
fi
