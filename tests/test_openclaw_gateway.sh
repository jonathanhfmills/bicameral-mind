#!/usr/bin/env bash
# OMC config exists + standalone Discord path configured
set -euo pipefail
BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OMC_CONFIG="$HOME/.claude/omc_config.openclaw.json"

echo "[test_openclaw_gateway] Checking openclaw gateway config..."

[[ -f "$OMC_CONFIG" ]] || { echo "FAIL: $OMC_CONFIG not found — run setup first"; exit 1; }

for key in enabled gateways hooks; do
  grep -q "\"$key\"" "$OMC_CONFIG" || { echo "FAIL: missing key '$key' in $OMC_CONFIG"; exit 1; }
done

grep -q "OPENCLAW_REPLY_CHANNEL=discord" "$BICAMERAL_ROOT/docker/docker-compose.yml" \
  || { echo "FAIL: discord reply channel not configured in docker-compose.yml"; exit 1; }

echo "PASS: openclaw gateway (OMC + standalone Discord) configured"
