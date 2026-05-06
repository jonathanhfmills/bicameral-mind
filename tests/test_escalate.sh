#!/usr/bin/env bash
# Assert escalate.sh invokes claude --print with ISSUE_URL
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BICAMERAL_ROOT/scripts/escalate.sh"

[[ -f "$SCRIPT" ]] || { echo "FAIL: scripts/escalate.sh not found"; exit 1; }
grep -q 'claude --print' "$SCRIPT" || { echo "FAIL: escalate.sh must invoke 'claude --print'"; exit 1; }
grep -q 'ISSUE_URL' "$SCRIPT" || { echo "FAIL: escalate.sh must use ISSUE_URL"; exit 1; }
if grep -q '\-\-plan\|plan\.md\|plan_file' "$SCRIPT"; then
  echo "FAIL: escalate.sh must not pass a plan file"
  exit 1
fi

ISSUE_URL="https://github.com/test/repo/issues/1"
STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT
cat > "$STUB_DIR/claude" <<'STUB'
#!/usr/bin/env bash
echo "STUB_CLAUDE_CALLED: $@"
STUB
chmod +x "$STUB_DIR/claude"

OUTPUT=$(PATH="$STUB_DIR:$PATH" ISSUE_URL="$ISSUE_URL" bash "$SCRIPT" 2>&1)

echo "$OUTPUT" | grep -q "STUB_CLAUDE_CALLED" || { echo "FAIL: escalate.sh did not invoke claude"; exit 1; }
echo "$OUTPUT" | grep -q "$ISSUE_URL" || { echo "FAIL: escalate.sh did not pass ISSUE_URL to claude"; exit 1; }

echo "PASS: escalate.sh invokes claude --print with ISSUE_URL"
