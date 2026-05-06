#!/usr/bin/env bash
# Git hook handler: triggers debate when a new GitHub issue is detected
set -euo pipefail

ISSUE_URL="${1:-}"
ISSUE_TITLE="${2:-}"
ISSUE_SLUG="${3:-$(echo "$ISSUE_TITLE" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-40)}"

if [[ -z "$ISSUE_TITLE" ]]; then
  echo "[on_issue] No issue title provided — skipping debate"
  exit 0
fi

echo "[on_issue] New issue: $ISSUE_TITLE ($ISSUE_URL)"

DEBATE_TOPIC="$ISSUE_TITLE" \
DEBATE_ISSUE_SLUG="$ISSUE_SLUG" \
  bash "$(dirname "$0")/run_debate.sh"
