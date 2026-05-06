#!/usr/bin/env bash
# Verify scripts default to Ollama endpoint (not raw llama.cpp ports)
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "[test_ollama_endpoint] Checking Ollama endpoint references..."

SCRIPT="$BICAMERAL_ROOT/scripts/run_debate.py"
[[ -f "$SCRIPT" ]] || { echo "FAIL: scripts/run_debate.py not found"; exit 1; }

# Must reference Ollama URL (not hardcoded llama.cpp ports as primary default)
grep -q "11434" "$SCRIPT" || { echo "FAIL: run_debate.py must reference Ollama port 11434"; exit 1; }
grep -q "OLLAMA_BASE_URL" "$SCRIPT" || { echo "FAIL: run_debate.py must support OLLAMA_BASE_URL env var"; exit 1; }

# LogicAgent config must reference Ollama
LA_CONFIG="$BICAMERAL_ROOT/agents/logicagent/agent.yaml"
grep -q "11434\|OLLAMA_BASE_URL" "$LA_CONFIG" || { echo "FAIL: logicagent/agent.yaml must reference Ollama endpoint"; exit 1; }

echo "PASS: Ollama endpoint correctly configured"
