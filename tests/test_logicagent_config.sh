#!/usr/bin/env bash
# Verify logicagent agent.yaml parses + required fields present
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$BICAMERAL_ROOT/agents/logicagent/agent.yaml"

echo "[test_logicagent_config] Checking $CONFIG..."

[[ -f "$CONFIG" ]] || { echo "FAIL: $CONFIG not found"; exit 1; }
[[ -f "$BICAMERAL_ROOT/agents/logicagent/SOUL.md" ]] || { echo "FAIL: SOUL.md missing"; exit 1; }
[[ -f "$BICAMERAL_ROOT/agents/logicagent/RULES.md" ]] || { echo "FAIL: RULES.md missing"; exit 1; }

for field in name model memory; do
  grep -q "^${field}:" "$CONFIG" || { echo "FAIL: missing field '$field' in $CONFIG"; exit 1; }
done

grep -q "hindsight" "$CONFIG" || { echo "FAIL: hindsight memory provider not configured"; exit 1; }
grep -q "local_embedded" "$CONFIG" || { echo "FAIL: local_embedded mode not set"; exit 1; }
grep -q "bank_id_template" "$CONFIG" || { echo "FAIL: bank_id_template not set"; exit 1; }

echo "PASS: logicagent config valid"
