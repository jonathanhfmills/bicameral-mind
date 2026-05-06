#!/usr/bin/env bash
# Ralph loop: local agents attempt implementation; exit at confidence >= 0.75 x2 consecutive.
# PR always created at exit — merge=positive signal, close=negative signal.
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$BICAMERAL_ROOT/scripts"
HOST_DIR="${HOST_DIR:-$BICAMERAL_ROOT}"
ISSUE_URL="${ISSUE_URL:-${1:-}}"
DRY_RUN="${DRY_RUN:-false}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-10}"
CONFIDENCE_THRESHOLD="0.75"

RUN_DEBATE="${STUB_DEBATE:-$SCRIPTS_DIR/run_debate.py}"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

if [[ -z "$ISSUE_URL" && "$DRY_RUN" != "true" ]]; then
  echo "[ralph] ERROR: ISSUE_URL required"
  exit 1
fi

consecutive=0
attempt=0
last_confidence="0.00"
confidence_scores=()

echo "[ralph] Starting loop. Issue: ${ISSUE_URL:-stub} threshold=${CONFIDENCE_THRESHOLD}x2"

DISCORD_THREAD_ID=""
if [[ -n "${DISCORD_BOT_TOKEN:-}" && -n "${DISCORD_FORUM_CHANNEL_ID:-}" ]]; then
  THREAD_TITLE=$(echo "${ISSUE_URL:-${DEBATE_TOPIC:-unnamed}}" | sed 's|https\?://[^/]*/||')
  THREAD_RESP=$(curl -sf -X POST \
    "https://discord.com/api/v10/channels/${DISCORD_FORUM_CHANNEL_ID}/threads" \
    -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$(echo "$THREAD_TITLE" | cut -c1-100)\",\"message\":{\"content\":\"👀 ${THREAD_TITLE}\"}}" \
    2>/dev/null || echo "")
  DISCORD_THREAD_ID=$(echo "$THREAD_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")
  [[ -n "$DISCORD_THREAD_ID" ]] && echo "[ralph] Forum thread created: $DISCORD_THREAD_ID"
fi
export DISCORD_THREAD_ID DISCORD_BOT_TOKEN DISCORD_MENTION_USER_ID

while [[ $attempt -lt $MAX_ATTEMPTS ]]; do
  attempt=$((attempt + 1))
  echo "[ralph] Attempt $attempt/$MAX_ATTEMPTS"

  if [[ "$DRY_RUN" != "true" ]] && [[ "${STUB_MODE:-0}" != "1" ]]; then
    git -C "$HOST_DIR" stash --quiet 2>/dev/null || true
  fi

  if [[ "$DRY_RUN" == "true" ]] || [[ "${STUB_MODE:-0}" == "1" ]]; then
    if [[ -n "${STUB_DEBATE:-}" ]]; then
      confidence=$(bash "$STUB_DEBATE" 2>/dev/null || echo "0.50")
    else
      confidence="0.50"
    fi
  else
    DISCORD_THREAD_ID="$DISCORD_THREAD_ID" HOST_DIR="$HOST_DIR" ISSUE_URL="$ISSUE_URL" python3 "$RUN_DEBATE" 2>/dev/null || true
    RECORD=$(ls -t "$HOST_DIR/debates/"*.md 2>/dev/null | head -1)
    confidence=$(grep "^confidence:" "$RECORD" 2>/dev/null | head -1 | awk '{print $2}' || echo "0.50")
  fi

  echo "[ralph] Attempt $attempt confidence: $confidence"
  confidence_scores+=("$confidence")

  if (( $(echo "$confidence >= $CONFIDENCE_THRESHOLD" | bc -l) )); then
    consecutive=$((consecutive + 1))
    echo "[ralph] Consecutive hits: $consecutive/2"
  else
    consecutive=0
  fi

  last_confidence="$confidence"

  if [[ $consecutive -ge 2 ]]; then
    echo "[ralph] Exit condition met: confidence >= $CONFIDENCE_THRESHOLD x2 consecutive"
    break
  fi
done

CONFIDENCE_SCORES="${confidence_scores[*]}" \
  HOST_DIR="$HOST_DIR" \
  ISSUE_URL="$ISSUE_URL" \
  DRY_RUN="$DRY_RUN" \
  bash "$SCRIPTS_DIR/create_training_pr.sh" || true

echo "[ralph] Done. Final confidence: $last_confidence after $attempt attempt(s)"

if [[ -n "${DISCORD_BOT_TOKEN:-}" && -n "${DISCORD_THREAD_ID:-}" ]]; then
  if [[ $consecutive -ge 2 ]]; then
    MSG="✅ <@${DISCORD_MENTION_USER_ID:-}> Ready. Merge to approve or close to pass."
  else
    MSG="⚠️ <@${DISCORD_MENTION_USER_ID:-}> Couldn't reach a confident answer. Needs your input."
  fi
  curl -sf -X POST "https://discord.com/api/v10/channels/${DISCORD_THREAD_ID}/messages" \
    -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"${MSG}\"}" > /dev/null \
    && echo "[ralph] Discord thread final post sent" || echo "[ralph] Discord thread post failed (non-fatal)"
fi
