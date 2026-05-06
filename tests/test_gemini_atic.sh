#!/usr/bin/env bash
# Gemini ATIC (Agentic Tool Invocation Compatibility) check
# Verifies FeelingsAgent uses gemini CLI in a way compatible with local Ollama/Gemma inference
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "[test_gemini_atic] Checking Gemini ATIC compatibility..."

SCRIPT="$BICAMERAL_ROOT/scripts/run_debate.py"

# FeelingsAgent (nullclaw) must use hindsight_litellm (ATIC-compatible wrapper)
grep -q "hindsight_litellm" "$SCRIPT" || { echo "FAIL: FeelingsAgent must use hindsight_litellm for ATIC compatibility"; exit 1; }

# Must NOT use direct Google API calls (only local Ollama/llama.cpp inference allowed)
if grep -q "google\.generativeai\|GOOGLE_API_KEY" "$SCRIPT"; then
  echo "FAIL: FeelingsAgent must use local inference only (no Google API calls — TOS compliance)"
  exit 1
fi

# LogicAgent must use qwen_agent (ATIC-compatible)
grep -q "qwen_agent" "$SCRIPT" || { echo "FAIL: LogicAgent must use qwen_agent for ATIC compatibility"; exit 1; }

# MaintainerAgent orchestration present
grep -q "MaintainerAgent\|maintaineragent\|MAINTAINERAGENT" "$SCRIPT" || { echo "FAIL: run_debate.py must include MaintainerAgent orchestration"; exit 1; }

# ATIC dry-run: verify debate runs end-to-end without inference
DEBATES_DIR="$(mktemp -d)"
trap 'rm -rf "$DEBATES_DIR"' EXIT

DEBATE_TOPIC="gemini-atic-test" \
DEBATE_ISSUE_SLUG="atic-test-$$" \
DEBATES_DIR="$DEBATES_DIR" \
DRY_RUN=true \
  python3 "$SCRIPT"

RECORD=$(ls -t "$DEBATES_DIR"/*.md 2>/dev/null | head -1)
[[ -n "$RECORD" ]] || { echo "FAIL: no debate record written during ATIC dry-run"; exit 1; }

echo "PASS: Gemini ATIC compatibility verified"
