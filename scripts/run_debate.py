#!/usr/bin/env python3
"""3-turn debate: Nullclaw (hindsight_litellm/Gemma4) vs LogicAgent (qwen_agent/Qwen3.5)."""
import os
import sys
import json
import datetime
import subprocess
from pathlib import Path

BICAMERAL_ROOT = Path(__file__).parent.parent
HOST_DIR = Path(os.environ.get("HOST_DIR", str(BICAMERAL_ROOT)))
DEBATES_DIR = Path(os.environ.get("DEBATES_DIR", str(HOST_DIR / "debates")))
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() in ("true", "1")

ISSUE_URL = os.environ.get("ISSUE_URL", "")
TOPIC = os.environ.get("DEBATE_TOPIC", os.environ.get("TOPIC", ISSUE_URL or "unnamed debate"))
ISSUE_SLUG = os.environ.get(
    "DEBATE_ISSUE_SLUG",
    "".join(c if c.isalnum() or c == "-" else "-" for c in TOPIC.lower().replace(" ", "-"))[:40],
)
DATE = datetime.date.today().isoformat()
RECORD = DEBATES_DIR / f"{DATE}-{ISSUE_SLUG}.md"

NULLCLAW_LLAMA_URL = os.environ.get("NULLCLAW_LLAMA_URL", "http://localhost:8080/v1")
LOGICAGENT_LLAMA_URL = os.environ.get(
    "LOGICAGENT_LLAMA_URL",
    os.environ.get("HERMES_LLAMA_URL", "http://localhost:8081/v1"),
)
HINDSIGHT_URL = os.environ.get("HINDSIGHT_MCP_URL", "http://localhost:8888")
LUCID_URL = os.environ.get("LUCID_MCP_URL", "http://localhost:9000")


def seed_context(topic: str) -> str:
    """Query Lucid (episodic) + Hindsight (semantic) for pre-debate seed."""
    lucid_ctx = ""
    hindsight_ctx = ""
    try:
        import urllib.request
        req = urllib.request.Request(
            f"{LUCID_URL}/recall",
            data=json.dumps({"query": topic}).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=5) as r:
            lucid_ctx = json.loads(r.read()).get("context", "")
    except Exception:
        pass
    try:
        import urllib.request
        req = urllib.request.Request(
            f"{HINDSIGHT_URL}/reflect",
            data=json.dumps({"query": topic, "bank_id": "shared"}).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=5) as r:
            hindsight_ctx = json.loads(r.read()).get("patterns", "")
    except Exception:
        pass
    parts = [p for p in [lucid_ctx, hindsight_ctx] if p]
    return "\n\n".join(parts) if parts else ""


def run_nullclaw(prompt: str, seed: str = "") -> str:
    """Nullclaw turn: hindsight_litellm → Gemma 4 (feelings-first)."""
    if DRY_RUN or not NULLCLAW_LLAMA_URL:
        return f"[stub] nullclaw responds to: {prompt[:80]}"
    try:
        import hindsight_litellm
        hindsight_litellm.configure(hindsight_api_url=HINDSIGHT_URL)
        hindsight_litellm.set_defaults(
            bank_id="nullclaw",
            use_reflect=True,
            reflect_context="feelings-first agent surfacing patterns/anti-patterns",
        )
        messages = []
        if seed:
            messages.append({"role": "system", "content": seed})
        messages.append({"role": "user", "content": prompt})
        resp = hindsight_litellm.completion(
            model="openai/gemma4",
            messages=messages,
            hindsight_query=prompt,
            api_base=NULLCLAW_LLAMA_URL,
            api_key="local",
        )
        return resp.choices[0].message.content
    except Exception as e:
        return f"[nullclaw error: {e}]"


def run_logicagent(prompt: str, seed: str = "") -> str:
    """LogicAgent turn: qwen_agent.Assistant → Qwen 3.5 (logic-first)."""
    if DRY_RUN or not LOGICAGENT_LLAMA_URL:
        return f"[stub] logicagent responds to: {prompt[:80]}"
    try:
        from qwen_agent.agents import Assistant
        agent = Assistant(
            llm={
                "model": "qwen3.5",
                "model_server": LOGICAGENT_LLAMA_URL,
                "api_key": "local",
                "generate_cfg": {"enable_thinking": True},
            },
            function_list=["mcp::hindsight", "mcp::filesystem", "mcp::fetch"],
            system_message=seed or "",
        )
        messages = [{"role": "user", "content": prompt}]
        result = []
        for resp in agent.run(messages):
            result.extend(resp)
        last = next((m["content"] for m in reversed(result) if m.get("role") == "assistant"), "")
        return last or "[logicagent: no response]"
    except Exception as e:
        return f"[logicagent error: {e}]"


def main() -> None:
    DEBATES_DIR.mkdir(parents=True, exist_ok=True)

    seed = seed_context(TOPIC)

    turn1 = run_nullclaw(TOPIC, seed=seed)
    turn2 = run_logicagent(turn1, seed=seed)
    turn3 = run_nullclaw(turn2)

    confidence = float(os.environ.get("DEBATE_CONFIDENCE", "0.50"))

    RECORD.write_text(
        f"""---
date: {DATE}
issue_slug: {ISSUE_SLUG}
agents: [nullclaw, logicagent]
turns: 3
confidence: {confidence:.2f}
topic: "{TOPIC}"
issue_url: "{ISSUE_URL}"
---

# Debate: {TOPIC}

## Turn 1 — Nullclaw (feelings-first)

{turn1}

## Turn 2 — LogicAgent (logic-first)

{turn2}

## Turn 3 — Nullclaw (synthesis)

{turn3}

## Verdict

confidence: {confidence:.2f}
escalation: {"true — confidence >= 0.75" if confidence >= 0.75 else "false — awaiting further debate or manual decision"}
"""
    )
    print(f"[run_debate] Record written: {RECORD}")


if __name__ == "__main__":
    main()
