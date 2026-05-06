#!/usr/bin/env bash
# Bicameral debate orchestrator — runs nullclaw↔logicagent debate and writes Debate Record
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST_DIR="${HOST_DIR:-$BICAMERAL_ROOT}"
DEBATES_DIR="${DEBATES_DIR:-$HOST_DIR/debates}"
DRY_RUN="${DRY_RUN:-false}"
TOPIC="${DEBATE_TOPIC:-${TOPIC:-unnamed debate}}"
ISSUE_SLUG="${DEBATE_ISSUE_SLUG:-$(echo "$TOPIC" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-40)}"
DATE="$(date +%Y-%m-%d)"
RECORD="$DEBATES_DIR/${DATE}-${ISSUE_SLUG}.md"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

mkdir -p "$DEBATES_DIR"

run_turn() {
  local agent="$1" prompt="$2"
  if [[ "$DRY_RUN" == "true" ]] || [[ -z "${NULLCLAW_LLAMA_URL:-}" ]]; then
    echo "[stub] $agent responds to: $prompt"
    return
  fi
  curl -sf "${OPENCLAW_API_URL:-http://localhost:8090}/debate/turn" \
    -H "Content-Type: application/json" \
    -d "{\"agent\":\"$agent\",\"prompt\":$(printf '%s' "$prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}"
}

TURN1=$(run_turn nullclaw "$TOPIC")
TURN2=$(run_turn logicagent "$TURN1")
TURN3=$(run_turn nullclaw "$TURN2")

CONFIDENCE="${DEBATE_CONFIDENCE:-0.50}"
if [[ "$DRY_RUN" != "true" ]] && [[ -n "${OPENCLAW_API_URL:-}" ]]; then
  CONFIDENCE=$(curl -sf "$OPENCLAW_API_URL/debate/confidence" \
    -H "Content-Type: application/json" \
    -d "{\"turns\":[$(printf '%s' "$TURN1 $TURN2 $TURN3" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))]}')" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["score"])' 2>/dev/null || echo "0.50")
fi

cat > "$RECORD" <<EOF
---
date: $DATE
issue_slug: $ISSUE_SLUG
agents: [nullclaw, logicagent]
turns: 3
confidence: $CONFIDENCE
topic: "$TOPIC"
---

# Debate: $TOPIC

## Turn 1 — Nullclaw (feelings-first)

$TURN1

## Turn 2 — LogicAgent (logic-first)

$TURN2

## Turn 3 — Nullclaw (synthesis)

$TURN3

## Verdict

confidence: $CONFIDENCE
$(if (( $(echo "$CONFIDENCE >= 0.75" | bc -l) )); then echo "escalation: true — issue URL sent to OMC for Claude Code implementation"; else echo "escalation: false — awaiting further debate or manual decision"; fi)
EOF

echo "[run_debate] Record written: $RECORD"

if (( $(echo "$CONFIDENCE >= 0.75" | bc -l) )) && [[ -n "${OPENCLAW_GATEWAY_URL:-}" ]]; then
  curl -sf "$OPENCLAW_GATEWAY_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENCLAW_TOKEN:-}" \
    -d "{\"instruction\":\"Implement resolution for issue: $TOPIC\",\"debate_record\":\"$RECORD\"}" \
    && echo "[run_debate] Escalated to OMC" || echo "[run_debate] Escalation failed (non-fatal)"
fi
