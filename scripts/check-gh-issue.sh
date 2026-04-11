#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-gh-issue.sh <commit-msg-file>}"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# Skip if all staged changes are markdown files
NON_MD="$(git diff --cached --name-only | grep -v '\.md$' || true)"
if [[ -z "$NON_MD" ]]; then
  exit 0
fi

ISSUE_NUMBER="$(echo "$STRIPPED_MSG" | head -1 | grep -oE '\[[0-9]+\]' | tr -d '[]' || true)"
if [[ -z "$ISSUE_NUMBER" ]]; then
  echo "error: issue number not found in commit message [$STRIPPED_MSG]"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "error: 'gh' not found — required for check" >&2
  exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
  echo "error: not authenticated with gh — required for check" >&2
  exit 1
fi

ISSUE_TITLE="$(gh issue view "$ISSUE_NUMBER" --json title -q .title 2>/dev/null || true)"
if [[ -z "$ISSUE_TITLE" ]]; then
  echo "error: GitHub issue #$ISSUE_NUMBER not found"
  echo "  create the issue before committing, or check you are in the correct repo"
  exit 1
fi

# Cache the title for other hooks in this git operation
echo "$ISSUE_TITLE" > "/tmp/gh-issue-${ISSUE_NUMBER}-title"
