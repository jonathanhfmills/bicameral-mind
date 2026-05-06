#!/usr/bin/env bash
# Escalate a GitHub issue to Claude Code for implementation.
# ISSUE_URL is the sole context — no plan file passed.
set -euo pipefail

ISSUE_URL="${ISSUE_URL:-${1:-}}"

if [[ -z "$ISSUE_URL" ]]; then
  echo "[escalate] ERROR: ISSUE_URL required (env var or first arg)"
  exit 1
fi

echo "[escalate] Escalating to Claude Code: $ISSUE_URL"
claude --print "Implement the GitHub issue at $ISSUE_URL"
