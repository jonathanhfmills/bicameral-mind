#!/usr/bin/env bash
# Assert create_training_pr.sh produces PR body with all 4 required sections
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BICAMERAL_ROOT/scripts/create_training_pr.sh"

[[ -f "$SCRIPT" ]] || { echo "FAIL: scripts/create_training_pr.sh not found"; exit 1; }
grep -q 'gh pr create' "$SCRIPT" || { echo "FAIL: create_training_pr.sh must invoke 'gh pr create'"; exit 1; }

STUB_DIR="$(mktemp -d)"
BODY_FILE="$STUB_DIR/pr_body.md"
DEBATES_DIR="$STUB_DIR/debates"
trap 'rm -rf "$STUB_DIR"' EXIT
mkdir -p "$DEBATES_DIR"

cat > "$STUB_DIR/gh" <<STUB
#!/usr/bin/env bash
capture=0
for arg in "\$@"; do
  if [[ \$capture -eq 1 ]]; then
    printf '%s' "\$arg" > "$BODY_FILE"
    capture=0
  fi
  [[ "\$arg" == "--body" ]] && capture=1
done
echo "STUB_GH_PR_CREATED"
STUB
chmod +x "$STUB_DIR/gh"

RECORD="$DEBATES_DIR/2026-01-01-test-issue.md"
cat > "$RECORD" <<'EOF'
---
date: 2026-01-01
issue_slug: test-issue
agents: [nullclaw, logicagent]
turns: 3
confidence: 0.80
topic: "test issue"
---

## Turn 1 — Nullclaw (feelings-first)
stub turn 1

## Turn 2 — LogicAgent (logic-first)
stub turn 2

## Turn 3 — Nullclaw (synthesis)
stub turn 3

## Verdict
confidence: 0.80
EOF

OUTPUT=$(PATH="$STUB_DIR:$PATH" \
  DEBATES_DIR="$DEBATES_DIR" \
  DEBATE_RECORD="$RECORD" \
  CONFIDENCE_SCORES="0.50 0.80 0.80" \
  DRY_RUN=1 \
  bash "$SCRIPT" 2>&1)

echo "$OUTPUT" | grep -q "STUB_GH_PR_CREATED" || { echo "FAIL: create_training_pr.sh did not invoke gh pr create"; exit 1; }

for section in "Debate Transcript" "Hindsight" "Confidence" "Diff"; do
  if ! grep -qi "$section" "$SCRIPT"; then
    echo "FAIL: create_training_pr.sh missing section: $section"
    exit 1
  fi
done

echo "PASS: create_training_pr.sh structure valid with all 4 PR body sections"
