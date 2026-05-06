.PHONY: help debate ralph escalate training-pr observer maintainer digital-twin agent-start hindsight test ollama

SHELL := /bin/bash

# Host repo root: passed explicitly as HOST_DIR, or auto-detected via git superproject
HOST_DIR ?= $(shell git -C "$(CURDIR)" rev-parse --show-superproject-working-tree 2>/dev/null || echo "$(CURDIR)/..")

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Debate Engine"
	@echo "  debate         Run feelings↔logic debate: make debate TOPIC=\"...\""
	@echo "  ralph          Ralph loop: exit at confidence >=0.75x2: make ralph ISSUE_URL=..."
	@echo "  escalate       Escalate issue to Claude Code: make escalate ISSUE_URL=..."
	@echo "  training-pr    Create training signal PR"
	@echo "  maintainer     Start Universal Observer (openclaw) container"
	@echo "  observer       Alias for maintainer"
	@echo "  digital-twin   Build digital twin container"
	@echo "  agent-start    Start OpenSandbox desktop sandbox"
	@echo "  hindsight      Install hindsight-client + hindsight-litellm memory providers"
	@echo "  test           Run all engine tests"
	@echo "  ollama         Setup guide for Ollama models (qwen2.5:7b + gemma2:9b)"

debate:
	@HOST_DIR="$(HOST_DIR)" python3 "$(CURDIR)/scripts/run_debate.py"

ralph:
	@HOST_DIR="$(HOST_DIR)" ISSUE_URL="$(ISSUE_URL)" bash "$(CURDIR)/scripts/ralph_loop.sh"

escalate:
	@ISSUE_URL="$(ISSUE_URL)" bash "$(CURDIR)/scripts/escalate.sh"

training-pr:
	@HOST_DIR="$(HOST_DIR)" bash "$(CURDIR)/scripts/create_training_pr.sh"

maintainer observer:
	HOST_DIR="$(HOST_DIR)" docker compose -f "$(CURDIR)/docker/docker-compose.yml" up openclaw

digital-twin:
	docker build -f "$(CURDIR)/docker/Dockerfile.digital-twin" "$(CURDIR)/docker" -t digital-twin:latest

agent-start:
	HOST_DIR="$(HOST_DIR)" docker compose -f "$(CURDIR)/docker/docker-compose.yml" up desktop

hindsight:
	@if ! command -v uv &>/dev/null; then \
		curl -fsSL https://astral.sh/uv/install.sh | bash; \
	fi
	uv pip install --system "hindsight-client>=0.4.22"
	@if command -v hindsight &>/dev/null; then \
		hindsight mcp setup 2>/dev/null || true; \
	fi

test:
	@chmod +x tests/*.sh
	@for t in tests/test_*.sh; do bash "$$t" || exit 1; done
	@echo "All engine tests passed"

ollama:
	@echo "Ollama setup: install from https://ollama.ai then:"
	@echo "  ollama pull qwen2.5:7b"
	@echo "  ollama pull gemma2:9b"
