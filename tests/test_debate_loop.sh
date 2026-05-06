#!/usr/bin/env bash
# Debate loop produces 3 turns in Debate Record (dry-run)
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBATES_DIR="$(mktemp -d)"
trap 'rm -rf "$DEBATES_DIR"' EXIT

echo "[test_debate_loop] Running dry-run debate loop..."

DEBATE_TOPIC="test: 3-turn loop validation" \
DEBATE_ISSUE_SLUG="loop-test-$$" \
DEBATES_DIR="$DEBATES_DIR" \
  bash "$BICAMERAL_ROOT/scripts/run_debate.sh" --dry-run

RECORD=$(ls -t "$DEBATES_DIR"/*.md 2>/dev/null | head -1)
[[ -n "$RECORD" ]] || { echo "FAIL: no record found"; exit 1; }

TURN_COUNT=$(grep -c "^## Turn" "$RECORD" || true)
[[ "$TURN_COUNT" -ge 3 ]] || { echo "FAIL: expected ≥3 turns, got $TURN_COUNT in $RECORD"; exit 1; }

grep -q "nullclaw" "$RECORD" || { echo "FAIL: nullclaw not in record"; exit 1; }
grep -q "logicagent" "$RECORD" || { echo "FAIL: logicagent not in record"; exit 1; }

echo "PASS: debate loop produces 3-turn record"
