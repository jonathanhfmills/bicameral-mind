#!/usr/bin/env bash
# Assert run_debate.py uses gemini/qwen CLIs (not curl) and references logicagent
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BICAMERAL_ROOT/scripts/run_debate.py"

[[ -f "$SCRIPT" ]] || { echo "FAIL: scripts/run_debate.py not found"; exit 1; }

if grep -q 'curl.*debate/turn' "$SCRIPT"; then
  echo "FAIL: run_debate.py still uses curl for agent invocation"
  exit 1
fi

grep -q 'hindsight_litellm' "$SCRIPT" || { echo "FAIL: run_debate.py must use hindsight_litellm for Nullclaw"; exit 1; }
grep -q 'qwen_agent' "$SCRIPT" || { echo "FAIL: run_debate.py must use qwen_agent for LogicAgent"; exit 1; }
grep -q 'lucid' "$SCRIPT" || { echo "FAIL: run_debate.py must query Lucid for pre-debate seed"; exit 1; }
grep -q 'ISSUE_URL\|issue_url' "$SCRIPT" || { echo "FAIL: run_debate.py must accept ISSUE_URL"; exit 1; }
grep -q 'logicagent\|run_logicagent' "$SCRIPT" || { echo "FAIL: run_debate.py must reference logicagent (not hermes)"; exit 1; }

echo "PASS: run_debate.py uses CLI wrappers and references logicagent"
