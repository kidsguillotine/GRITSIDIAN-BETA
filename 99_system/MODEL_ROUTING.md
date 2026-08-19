---
title: "Model Routing: Canonical"
created: 2026-07-01
meta_status: active
purpose: >
  Canonical model routing table for the your-scripts stack. Sourced by
  99_system/obsilo-memory/knowledge.md via gen_vo_memory.sh include-marker
  resolver (VO_MEMORY_RESOLVE mechanism, OD-47 option B). Edit this file
  to update memory: do not edit the generator.
update_trigger: >
  When a model is added to active rotation, moved to shelf, deprecated, or
  when routing rules change (e.g., which model handles tool-calling vs RAG).
authority: >
  Rank 3 canonical. Single source for the model routing table. Downstream:
  gen_vo_memory.sh embeds the marked section via VO_MEMORY_INCLUDE markers.
---

# Model Routing

<!-- VO_MEMORY_INCLUDE_BEGIN: model-routing -->

| Model | Role | Notes |
|-------|------|-------|
| qwen3:8b | Primary: all tool-calling/agentic work via vault_agent.py | `"think": False` top-level for /api/chat; inside `options` for /api/generate |
| qwen3:8b-hermes-ctx | qwen3:8b with 128K context (Modelfile variant): **current build: 64K (65536); rebuild to 131072 pending user action** | Use for Hermes Agent (requires 64K min); same think-mode rules apply |
| qwen3.5:9b | Higher-capacity qwen3 shelf model | Shelf: not in active rotation; candidate if qwen3:8b quality insufficient |
| hermes3:latest | RAG/retrieval ONLY | Declares tools capability but tool-calling reliability is insufficient: NEVER route agent loops to it |
| llama3.1 | classify.py fallback | Used when qwen3:8b unavailable |
| deepseek-r1:14b | Long-form reasoning only | NOT suitable for tool-calling (hits token budget in think phase) |
| deepseek-r1:32b | Long-form reasoning only | Same as 14b, higher capacity |
| granite4:latest | Shelf model | IBM Granite 4; not in active rotation |
| gemma4:latest | Shelf model | Google Gemma 4; not in active rotation |
| nomic-embed-text:latest | Embeddings only | ChromaDB semantic index; not a chat/agent model |

**vault_agent.py** v2.6.1 is the operative local-model agent loop. It is NOT a thin VO MCP wrapper (that refactor was SUPERSEDED: MASTER_PLAN_v2.md Decision 20).

<!-- VO_MEMORY_INCLUDE_END: model-routing -->

---

## Operation Routing Ladder (SPEC_D3, 2026-07-03)

Every RECURRING operation is specced at the lowest tier meeting its acceptance criteria. Escalation above spec tier requires a one-line logged reason. One-off work is exempt: the ladder governs recurrence.

| Tier | Executor | Cost | Use when |
|------|----------|------|----------|
| 0 | Deterministic script | Free | Acceptance criteria need no judgment |
| 1 | qwen3:8b local | Free | Classification/extraction; A-1 TOP-cleared |
| 2 | Claudian (API) | Metered | Multi-step orchestration, code, judgment |
| 3 | Seat (subscription) | Flat | Strategy, specs, cross-session synthesis |

Initial tier assignments:

| Operation | Tier | Basis |
|-----------|------|-------|
| drain classification | 1 | Already running at T1 |
| unreviewed triage (cluster_triage.py) | 0 | SPEC_D2 deterministic script |
| 402-task dedup/normalize pre-pass | 0/1 | Script pre-pass, human decides after |
| boot generation (gen_session_boot.sh) | 0 | Already running at T0 |
| session reconcile (reconcile_session.py) | 0 | Already running at T0 |
| handoff synthesis | 3 | Cross-session context; seat-flat |
| vault code changes | 2 | Orchestration judgment; metered |
