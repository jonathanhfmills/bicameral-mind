.PHONY: help debate ralph escalate training-pr observer maintainer digital-twin agent-start hindsight test ollama llama-install llama-download llama-serve

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
	@echo "  llama-install  Build llama.cpp with CUDA from source"
	@echo "  llama-download Download Qwen3.5-4B UD-Q4_K_XL GGUF"
	@echo "  llama-serve    Start llama-server on port 8080 with CUDA and KV cache quantization"

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

MODELS_DIR ?= $(HOME)/models
LLAMA_CPP_DIR ?= $(HOME)/llama.cpp

llama-install: ## Build llama.cpp (rotorquant fork) with CUDA from source
	git clone --branch feature/planarquant-kv-cache https://github.com/johndpope/llama-cpp-turboquant.git $(LLAMA_CPP_DIR) 2>/dev/null \
		|| (git -C $(LLAMA_CPP_DIR) fetch origin && git -C $(LLAMA_CPP_DIR) checkout feature/planarquant-kv-cache && git -C $(LLAMA_CPP_DIR) pull)
	cmake -B $(LLAMA_CPP_DIR)/build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release $(LLAMA_CPP_DIR)
	cmake --build $(LLAMA_CPP_DIR)/build --config Release -j$$(nproc)

llama-download: ## Download Qwen3.5-4B UD-Q4_K_XL GGUF
	mkdir -p $(MODELS_DIR)
	hf download unsloth/Qwen3.5-4B-GGUF \
		Qwen3.5-4B-UD-Q4_K_XL.gguf \
		--local-dir $(MODELS_DIR)

llama-serve: ## Start llama-server on port 8080 with CUDA and rotorquant KV cache
	$(LLAMA_CPP_DIR)/build/bin/llama-server \
		-m $(MODELS_DIR)/Qwen3.5-4B-UD-Q4_K_XL.gguf \
		-ngl 99 \
		--port 8080 \
		--host 0.0.0.0 \
		-c 8192 \
		--cache-type-k iso3 \
		--cache-type-v iso3
