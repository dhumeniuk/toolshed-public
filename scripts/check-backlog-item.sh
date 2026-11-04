#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="${1:?usage: check-backlog-item.sh <commit-msg-file>}"
STRIPPED_MSG="$(grep -v '^#' "$COMMIT_MSG_FILE" || true)"

# Skip if all staged changes are markdown files
NON_MD="$(git diff --cached --name-only | grep -v '\.md$' || true)"
if [[ -z "$NON_MD" ]]; then
  exit 0
fi

TRACKED_ID="$(echo "$STRIPPED_MSG" | head -1 | grep -oE '\[[A-Za-z0-9-]+\]' | tr -d '[]' || true)"
if [[ -z "$TRACKED_ID" ]]; then
  echo "error: no tracked-item reference found in commit message [$STRIPPED_MSG]"
  echo "  expected a bracketed backlog item id, e.g. [HA-1]"
  echo "  create the backlog item with the Personal Assistant MCP tool (create_page_item) before committing"
  exit 1
fi

# Backlog item ids come from the Personal Assistant's per-project counter
# (PageItemCounter keyed on (pageType, key) — see nextBacklogDisplayId),
# e.g. HA-1 (home-assistant), PS-2 (pair-split), PA-3 (personal-assistant).
# There is no scriptable way for a git hook to look these up (they live
# behind an MCP tool, not a CLI/API a script can call), so we only check
# the id has the expected <PREFIX>-<number> shape.
if [[ ! "$TRACKED_ID" =~ ^[A-Za-z]+-[0-9]+$ ]]; then
  echo "error: invalid tracked-item reference [$TRACKED_ID]"
  echo "  expected a backlog item id, e.g. [HA-1]"
  echo "  create/list backlog items with the Personal Assistant MCP tool (create_page_item / list_page_items)"
  exit 1
fi
