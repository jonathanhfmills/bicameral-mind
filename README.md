# bicameral-mind

Debate engine for living code repositories. Two hemispheres reach convergence before implementation proceeds.

- **Nullclaw** (feelings): host-repo agent, Gemma 4 via llama.cpp, Lucid memory
- **LogicAgent** (logic): engine-provided, Qwen 3.5 via llama.cpp, Hindsight memory
- **Convergence threshold**: ≥0.75 confidence × 2 consecutive runs → ralph loop exits

## Usage as submodule

```bash
git submodule add https://github.com/jonathanhfmills/bicameral-mind bicameral-mind
```

Delegate from host repo Makefile:

```makefile
debate:
    @HOST_DIR="$(CURDIR)" $(MAKE) -C bicameral-mind debate
```

## Standalone targets

```
make debate TOPIC="..."        Run a debate
make ralph  ISSUE_URL="..."    Ralph loop (exit at convergence)
make escalate ISSUE_URL="..."  Escalate to Claude Code
make training-pr               Create training signal PR
make maintainer                Start openclaw observer container
make test                      Run engine tests
```

## Agent ownership

Engine lives here. Agent personas (nullclaw, etc.) live in host repos. Training debates remain per-repository in `debates/`.
