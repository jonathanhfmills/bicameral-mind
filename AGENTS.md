# bicameral-mind

Debate engine submodule. Provides LogicAgent + debate orchestration. Host repos provide their own agent (e.g. nullclaw).

## Structure

| Path | Purpose |
|------|---------|
| `agents/logicagent/` | Logic-first debater (Qwen 3.5, Hindsight memory) |
| `scripts/run_debate.py` | Debate orchestrator (Python, hindsight_litellm + qwen_agent) |
| `scripts/run_debate.sh` | Debate orchestrator (Bash, dry-run capable) |
| `scripts/ralph_loop.sh` | Confidence-gated implementation loop |
| `scripts/escalate.sh` | Escalate to Claude Code via `claude --print` |
| `scripts/create_training_pr.sh` | Training signal PR (merge=positive, close=negative) |
| `scripts/on_issue.sh` | Issue event handler → triggers debate |
| `docker/docker-compose.yml` | openclaw, digital-twin, hindsight-mcp, lucid-mcp, desktop |
| `docker/Dockerfile.digital-twin` | Ubuntu 24.04, full dev stack, automated pipeline |
| `tests/` | Engine test suite |

## HOST_DIR convention

All engine scripts accept `HOST_DIR` env var pointing to the host repo root. Defaults to parent directory (`..`). Always pass `HOST_DIR="$(CURDIR)"` from host repo Makefile delegation targets.

## For AI Agents

- Scripts are idempotent under DRY_RUN=true
- Tests use temp dirs — no side effects on host repo
- LogicAgent replaces Hermes; env vars `HERMES_LLAMA_URL`/`HERMES_MODEL` are accepted as fallbacks
