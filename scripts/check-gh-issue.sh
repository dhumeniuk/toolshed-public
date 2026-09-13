#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-gh-issue.sh <commit-msg-file>}"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# Skip if all staged changes are markdown files
NON_MD="$(git diff --cached --name-only | grep -v '\.md$' || true)"
if [[ -z "$NON_MD" ]]; then
  exit 0
fi

TRACKED_ID="$(echo "$STRIPPED_MSG" | head -1 | grep -oE '\[[A-Za-z0-9-]+\]' | tr -d '[]' || true)"
if [[ -z "$TRACKED_ID" ]]; then
  echo "error: no tracked-item reference found in commit message [$STRIPPED_MSG]"
  echo "  expected a bracketed reference, e.g. [42] (GitHub issue) or [<backlog-item-id>]"
  echo "  create the issue or backlog item before committing"
  exit 1
fi

# Numeric references are treated as GitHub issue numbers and verified to
# exist, same as before — this also feeds the title cache that
# check-release-notes.sh depends on for repos still using GitHub issues.
if [[ "$TRACKED_ID" =~ ^[0-9]+$ ]]; then
  if ! command -v gh &>/dev/null; then
    echo "error: 'gh' not found — required to verify GitHub issue #$TRACKED_ID" >&2
    exit 1
  fi

  if ! gh auth status &>/dev/null 2>&1; then
    echo "error: not authenticated with gh — required to verify GitHub issue #$TRACKED_ID" >&2
    exit 1
  fi

  ISSUE_TITLE="$(gh issue view "$TRACKED_ID" --json title -q .title 2>/dev/null || true)"
  if [[ -z "$ISSUE_TITLE" ]]; then
    echo "error: GitHub issue #$TRACKED_ID not found"
    echo "  create the issue before committing, or check you are in the correct repo"
    exit 1
  fi

  # Cache the title for other hooks in this git operation
  echo "$ISSUE_TITLE" > "/tmp/gh-issue-${TRACKED_ID}-title"
fi

# Non-numeric references (e.g. a Personal Assistant backlog item id) are
# accepted as-is — there is no scriptable way for a git hook to look those
# up (they live behind an MCP tool, not a CLI/API a script can call), so we
# only check that a reference is present in the commit message.
