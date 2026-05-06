#!/usr/bin/env bash
# Assert Dockerfile.digital-twin exists and builds
set -euo pipefail

BICAMERAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="$BICAMERAL_ROOT/docker"

[[ -f "$DOCKER_DIR/Dockerfile.digital-twin" ]] || { echo "FAIL: docker/Dockerfile.digital-twin not found"; exit 1; }

for stage in apt nvm node claude "claude-plugins" hindsight qwen gemini; do
  if ! grep -qi "$stage" "$DOCKER_DIR/Dockerfile.digital-twin"; then
    echo "FAIL: Dockerfile.digital-twin missing stage: $stage"
    exit 1
  fi
done

grep -q "FROM ubuntu:24.04" "$DOCKER_DIR/Dockerfile.digital-twin" || { echo "FAIL: base image must be ubuntu:24.04"; exit 1; }
grep -q "dotfiles" "$DOCKER_DIR/Dockerfile.digital-twin" || { echo "FAIL: Dockerfile.digital-twin must seed ~/dotfiles"; exit 1; }

if [[ "${SKIP_DOCKER_BUILD:-0}" != "1" ]]; then
  if ! command -v docker &>/dev/null; then
    echo "SKIP: docker not available"
    exit 0
  fi
  docker build -f "$DOCKER_DIR/Dockerfile.digital-twin" "$DOCKER_DIR" \
    --target base --quiet > /dev/null \
    && echo "PASS: Dockerfile.digital-twin builds (base stage)" \
    || { echo "FAIL: docker build failed"; exit 1; }
else
  echo "PASS: Dockerfile.digital-twin structure valid (build skipped)"
fi
