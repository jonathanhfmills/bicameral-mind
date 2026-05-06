#!/usr/bin/env bash
# Debate Record confidence field; high score sets escalation=true
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBATES_DIR="$(mktemp -d)"
trap 'rm -rf "$DEBATES_DIR"' EXIT

echo "[test_escalation] Testing confidence scoring and escalation flag..."

DEBATE_TOPIC="escalation-high-confidence-test" \
DEBATE_ISSUE_SLUG="esc-high-$$" \
DEBATE_CONFIDENCE="0.90" \
DEBATES_DIR="$DEBATES_DIR" \
  bash "$BICAMERAL_ROOT/scripts/run_debate.sh" --dry-run

RECORD=$(ls -t "$DEBATES_DIR"/*.md 2>/dev/null | head -1)
[[ -n "$RECORD" ]] || { echo "FAIL: no record"; exit 1; }
grep -q "^confidence:" "$RECORD" || { echo "FAIL: confidence field missing"; exit 1; }
grep -q "escalation: true" "$RECORD" || { echo "FAIL: high confidence (0.90) should set escalation: true"; exit 1; }

DEBATE_TOPIC="escalation-low-confidence-test" \
DEBATE_ISSUE_SLUG="esc-low-$$" \
DEBATE_CONFIDENCE="0.40" \
DEBATES_DIR="$DEBATES_DIR" \
  bash "$BICAMERAL_ROOT/scripts/run_debate.sh" --dry-run

RECORD_LOW=$(ls -t "$DEBATES_DIR"/*.md 2>/dev/null | head -1)
grep -q "escalation: false" "$RECORD_LOW" || { echo "FAIL: low confidence (0.40) should set escalation: false"; exit 1; }

echo "PASS: confidence scoring and escalation flags correct"
