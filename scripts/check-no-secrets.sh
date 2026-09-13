#!/usr/bin/env bash
set -euo pipefail

SECRET_PATTERNS=(
  'sk_live_[0-9a-zA-Z]+'
  'sk_test_[0-9a-zA-Z]+'
  'AKIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_-]{35}'
  'ghp_[0-9a-zA-Z]{36}'
  'xoxb-[0-9]+-[0-9a-zA-Z]+'
  'access_token\s*=\s*["\x27][^"]+["\x27]'
  'private_key\s*=\s*["\x27][^"]+["\x27]'
  'client_secret\s*=\s*["\x27][^"]+["\x27]'
)

if [ "${CI:-}" = "true" ]; then
  ENV_FILES=$(git ls-files | grep -E '^\.env(\.|$)' | grep -v '\.example$' || true)
  if [ -n "$ENV_FILES" ]; then
    echo "❌ .env file(s) found tracked in repo: $ENV_FILES"
    exit 1
  fi
  FILES=$(git ls-files | grep -vE '^\.env(\.|$)' || git ls-files | grep '\.example$' || true)
  FOUND=0
  for pattern in "${SECRET_PATTERNS[@]}"; do
    MATCHES=$(echo "$FILES" | xargs grep -lE "$pattern" 2>/dev/null || true)
    if [ -n "$MATCHES" ]; then
      echo "❌ Possible secret detected (pattern: $pattern) in: $MATCHES"
      FOUND=1
    fi
  done
else
  STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
  if [ -z "$STAGED_FILES" ]; then exit 0; fi
  for file in $STAGED_FILES; do
    if echo "$file" | grep -qE '^\.env(\.|$)' && ! echo "$file" | grep -q '\.example$'; then
      echo "❌ Blocked: attempting to commit $file"
      exit 1
    fi
  done
  FOUND=0
  for pattern in "${SECRET_PATTERNS[@]}"; do
    MATCHES=$(git diff --cached -U0 | grep '^+' | grep -vE '^\+\+\+' | grep -oE "$pattern" || true)
    if [ -n "$MATCHES" ]; then
      echo "❌ Possible secret detected matching pattern: $pattern"
      FOUND=1
    fi
  done
fi

if [ "${FOUND:-0}" -eq 1 ]; then
  echo "   Review your staged changes and remove any secrets before committing."
  exit 1
fi
exit 0
