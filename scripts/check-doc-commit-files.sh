#!/usr/bin/env bash
set -euo pipefail

# Validates that "doc: <description>" commits only touch .md files
# No-op for non-doc commits.

COMMIT_MSG_FILE="${1:?usage: check-doc-commit-files.sh <commit-msg-file>}"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# Only applies to doc: commits
if ! echo "$STRIPPED_MSG" | head -1 | grep -qE '^doc: .+'; then
  exit 0
fi

CHANGED_FILES="$(git diff --cached --name-only)"
NON_DOC_FILES="$(echo "$CHANGED_FILES" | grep -v '\.md$' || true)"

if [[ -n "$NON_DOC_FILES" ]]; then
  echo "error: doc commits may only contain changes to .md files"
  echo "  unexpected files:"
  echo "$NON_DOC_FILES" | sed 's/^/    /'
  exit 1
fi
