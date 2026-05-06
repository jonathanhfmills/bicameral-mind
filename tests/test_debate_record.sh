#!/usr/bin/env bash
# Assert Debate Record format is correct
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBATES_DIR="$(mktemp -d)"
trap 'rm -rf "$DEBATES_DIR"' EXIT

echo "[test_debate_record] Creating test debate record..."

DEBATE_ISSUE_SLUG="test-issue-001" \
DEBATE_TOPIC="test: feelings vs logic on tab indentation" \
DEBATES_DIR="$DEBATES_DIR" \
  bash "$BICAMERAL_ROOT/scripts/run_debate.sh" --dry-run

RECORD=$(ls -t "$DEBATES_DIR"/*.md 2>/dev/null | head -1)

if [[ -z "$RECORD" ]]; then
  echo "FAIL: no debate record written to $DEBATES_DIR"
  exit 1
fi

echo "[test_debate_record] Found: $RECORD"

for field in date issue_slug agents confidence turns; do
  if ! grep -q "^${field}:" "$RECORD"; then
    echo "FAIL: missing frontmatter field '$field' in $RECORD"
    exit 1
  fi
done

CONFIDENCE=$(grep "^confidence:" "$RECORD" | awk '{print $2}')
if ! echo "$CONFIDENCE" | grep -qE '^0(\.[0-9]+)?$|^1(\.0+)?$'; then
  echo "FAIL: confidence '$CONFIDENCE' is not a 0-1 float"
  exit 1
fi

if ! grep -q "^## Turn" "$RECORD"; then
  echo "FAIL: no turn blocks found in $RECORD"
  exit 1
fi

echo "PASS: debate record format valid"
