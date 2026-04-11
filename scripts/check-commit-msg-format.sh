#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-commit-msg-format.sh <commit-msg-file>}"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# doc-only shortcut: skip format validation
if echo "$STRIPPED_MSG" | head -1 | grep -qE '^doc: .+'; then
  exit 0
fi

# Format: <type>(<scope>): ([<issue>]) <description>
# Scope and issue ID are optional.
TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
COMMIT_FORMAT_RE="^($TYPES)(\([^)]+\))?: (\[[0-9]+\] )?.+"

if ! echo "$STRIPPED_MSG" | head -1 | grep -qE "$COMMIT_FORMAT_RE"; then
  echo "error: commit message does not follow the required format"
  echo "  expected: <type>(<scope>): ([<issue>]) <description>"
  echo "  types: $TYPES"
  echo "  example: feat(auth): [42] add login endpoint"
  echo "  got: $(echo "$STRIPPED_MSG" | head -1)"
  exit 1
fi
