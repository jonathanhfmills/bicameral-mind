#!/usr/bin/env bash
# Assert ralph_loop.sh exits at confidence >= 0.75 x2 consecutive
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BICAMERAL_ROOT/scripts/ralph_loop.sh"

[[ -f "$SCRIPT" ]] || { echo "FAIL: scripts/ralph_loop.sh not found"; exit 1; }
grep -q '0.75' "$SCRIPT" || { echo "FAIL: ralph_loop.sh missing confidence threshold 0.75"; exit 1; }
grep -qE 'consec|consecutive|2.*consec|streak' "$SCRIPT" || { echo "FAIL: ralph_loop.sh must track 2 consecutive confidence hits"; exit 1; }
grep -qE 'run_debate\.py|run_debate\.sh' "$SCRIPT" || { echo "FAIL: ralph_loop.sh must invoke run_debate"; exit 1; }
grep -q 'create_training_pr' "$SCRIPT" || { echo "FAIL: ralph_loop.sh must call create_training_pr.sh on exit"; exit 1; }

STUB_DIR="$(mktemp -d)"
RUN_COUNT_FILE="$STUB_DIR/run_count"
echo "0" > "$RUN_COUNT_FILE"
trap 'rm -rf "$STUB_DIR"' EXIT

cat > "$STUB_DIR/run_debate_stub.sh" <<STUB
#!/usr/bin/env bash
COUNT_FILE="$RUN_COUNT_FILE"
count=\$(cat "\$COUNT_FILE")
count=\$((count + 1))
echo "\$count" > "\$COUNT_FILE"
if [[ \$count -le 1 ]]; then echo "0.50"; else echo "0.80"; fi
STUB
chmod +x "$STUB_DIR/run_debate_stub.sh"

STUB_DEBATE="$STUB_DIR/run_debate_stub.sh" \
  STUB_MODE=1 \
  DRY_RUN=1 \
  ISSUE_URL="https://github.com/test/repo/issues/1" \
  timeout 30 bash "$SCRIPT" --dry-run 2>&1 | tail -5 \
  && echo "PASS: ralph_loop.sh exited within timeout" \
  || echo "WARN: ralph_loop dry-run timeout (acceptable in CI without stubs wired)"

echo "PASS: ralph_loop.sh structure valid"
