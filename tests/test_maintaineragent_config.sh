#!/usr/bin/env bash
# Verify maintaineragent agent.yaml parses + required fields present
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$BICAMERAL_ROOT/agents/maintaineragent/agent.yaml"

echo "[test_maintaineragent_config] Checking $CONFIG..."

[[ -f "$CONFIG" ]] || { echo "FAIL: $CONFIG not found"; exit 1; }
[[ -f "$BICAMERAL_ROOT/agents/maintaineragent/SOUL.md" ]] || { echo "FAIL: SOUL.md missing"; exit 1; }
[[ -f "$BICAMERAL_ROOT/agents/maintaineragent/RULES.md" ]] || { echo "FAIL: RULES.md missing"; exit 1; }

for field in name model sub_agents confidence; do
  grep -q "^${field}:" "$CONFIG" || { echo "FAIL: missing field '$field' in $CONFIG"; exit 1; }
done

grep -q "0.75" "$CONFIG" || { echo "FAIL: confidence threshold 0.75 not configured"; exit 1; }

echo "PASS: maintaineragent config valid"
