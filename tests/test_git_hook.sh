#!/usr/bin/env bash
# on_issue.sh triggers debate and writes record
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBATES_DIR="$(mktemp -d)"
trap 'rm -rf "$DEBATES_DIR"' EXIT

echo "[test_git_hook] Simulating new issue event..."

SLUG="hook-test-$$"
DEBATES_DIR="$DEBATES_DIR" \
  bash "$BICAMERAL_ROOT/scripts/on_issue.sh" \
  "https://github.com/example/repo/issues/99" \
  "Should we use tabs or spaces for indentation?" \
  "$SLUG"

RECORD=$(ls -t "$DEBATES_DIR"/*.md 2>/dev/null | head -1)
[[ -n "$RECORD" ]] || { echo "FAIL: no debate record found after on_issue.sh"; exit 1; }
grep -q "issue_slug:" "$RECORD" || { echo "FAIL: issue_slug missing from record"; exit 1; }

echo "PASS: git hook trigger produces debate record"
