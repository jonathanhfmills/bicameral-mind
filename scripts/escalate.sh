#!/usr/bin/env bash
# Escalate a GitHub issue to Claude Code for implementation.
# ISSUE_URL is the sole context — no plan file passed.
set -euo pipefail

ISSUE_URL="${ISSUE_URL:-${1:-}}"

if [[ -z "$ISSUE_URL" ]]; then
  echo "[escalate] ERROR: ISSUE_URL required (env var or first arg)"
  exit 1
fi

# Validate GitHub URL to prevent prompt injection
if ! echo "$ISSUE_URL" | grep -qE '^https://github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+/issues/[0-9]+$'; then
  echo "[escalate] ERROR: ISSUE_URL must be a GitHub issue URL (https://github.com/owner/repo/issues/N)"
  exit 1
fi

echo "[escalate] Escalating to Claude Code: $ISSUE_URL"
claude --print "Implement the GitHub issue at $ISSUE_URL"
