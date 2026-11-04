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
# Extract backlog item id like [HA-1] -> HA-1
TRACKED_ID="$(echo "$FIRST_LINE" | grep -oE '\[[A-Za-z]+-[0-9]+\]' | tr -d '[]' || echo "")"

# No backlog item id in commit — nothing to check
if [[ -z "$TRACKED_ID" ]]; then
  exit 0
fi

RELEASE_NOTES="$REPO_ROOT/RELEASE_NOTES.md"
if [[ ! -f "$RELEASE_NOTES" ]]; then
  echo "error: RELEASE_NOTES.md not found in repo root"
  exit 1
fi

# There is no scriptable way to fetch a backlog item's title (it lives
# behind an MCP tool, not a CLI/API a script can call), so we only check
# that an entry for this id was added to RELEASE_NOTES.md.
if ! grep -qE -- "^- $TRACKED_ID: .+" "$RELEASE_NOTES"; then
  echo "error: release note entry not found in RELEASE_NOTES.md"
  echo "  expected: '- $TRACKED_ID: <summary>'"
  echo "  look up the item's title with the Personal Assistant MCP tool (list_page_items) if needed"
  exit 1
fi
