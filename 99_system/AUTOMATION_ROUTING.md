---
title: "Automation Routing: \"What Runs Where\""
created: 2026-06-24
meta_status: active
purpose: >
  Project-level rule for which automation loop belongs on which substrate.
  Prevents per-loop re-derivation of substrate placement (Sisyphus instance -
  IH-3 O-7). Resolves OD-29.
update_trigger: >
  Add a row to any table when a new substrate is introduced or an existing
  placement decision is revisited. Update placement rules if a substrate's
  capability changes (e.g. agent_runner.py gains a new endpoint).
authority: >
  Rank 2. Authoritative for new automation placement decisions. Existing
  placements were decided case-by-case; this document canonicalizes the
  pattern they form and governs all future additions.
---

# Automation Routing: What Runs Where

## The four substrates

| Substrate | What it is | Port/Access |
|---|---|---|
| **VO MCP** | Vault Operator MCP server (Obsidian plugin) | 27182 (localhost HTTP/MCP) |
| **Claudian** | Claude Code agent (this session, conversational) | Session scope only: no background process |
| **n8n** | Workflow engine (Docker) | 5678 |
| **agent_runner.py** | Python sidecar HTTP server (Docker) | 8766 |

---

## Placement rules

### VO MCP: use when

- The operation requires Obsidian plugin state (open files, active note, plugin settings)
- The operation calls a VO-registered tool (`tools/list`, frontmatter update, wikilink resolution, note read/write via the VO API)
- The caller is Claudian or n8n and needs a vault read/write without running Python

### Claudian: use when

- The task requires multi-file judgment, architectural reasoning, or a cross-session decision
- The task produces infrastructure artifacts (scripts, CLAUDE.md edits, system docs, OD entries)
- The task is a session-close step (handoff regen, reconcile, state_hook, git commit)
- The operation requires explicit user confirmation (Confirmation Gate)

**Not for:** bulk vault content ops. Those go to agent_runner.py.

### n8n: use when

- The trigger is time-based (cron, interval) or event-based (file watch, webhook)
- The operation is a multi-step pipeline that chains HTTP calls to other substrates
- The automation must run unattended without a Claudian session open
- Examples: inbox watcher, nightly git commit, ICS export, scheduled classify run

### agent_runner.py: use when

- The operation is Python-heavy and runs a local model via Ollama
- The task is: classify, dedup, link_safe_move, chroma_reconcile, or any bulk content op
- The caller is n8n (proxied) or Claudian providing a command for async execution
- The operation should NOT require a Claudian session to be open

---

## Placement quick-reference

| Operation | Substrate |
|---|---|
| Read/write a vault note via API | VO MCP |
| Update note frontmatter | VO MCP |
| Classify a new inbox file | agent_runner.py (via n8n or direct HTTP) |
| Dedup two candidate files | agent_runner.py |
| link_safe_move (rename/move with link rewrite) | agent_runner.py |
| ChromaDB reconcile | agent_runner.py |
| Rebuild MOC index | agent_runner.py (triggered by n8n) |
| Nightly maintenance workflow (git commit, ICS export, scheduled classify batch) | n8n |
| Hourly vault snapshot + push | cron -> hourly_snapshot.sh (vault-only infra script) |
| Session-close handoff regen | Claudian |
| session_close reconcile (reconcile_session.py) | Claudian |
| state_hook update | Claudian (per operation) |
| Architectural decision + OD entry | Claudian |
| Scheduled classify batch | n8n -> agent_runner.py |
| Inbox watcher trigger | n8n |
| ICS calendar export | n8n |
| A-1 gate test run | Claudian (user-invoked, one-off) |

---

## When in doubt

1. Does it touch vault content (classify, dedup, frontmatter writes, moves)? -> **agent_runner.py**
2. Does it require Obsidian plugin state or VO-registered tools? -> **VO MCP**
3. Is it time-driven or event-driven and runs without a session? -> **n8n**
4. Does it require judgment, cross-session context, or user confirmation? -> **Claudian**

If multiple rules match, use the one closest to the data. Content ops stay in agent_runner.py even if they're triggered from n8n or invoked by Claudian providing a command.

---

## What does NOT belong on each substrate

| Substrate | NOT for |
|---|---|
| VO MCP | Python-heavy processing, Ollama calls, git ops |
| Claudian | Bulk content ops, time-triggered automation, unattended runs |
| n8n | Judgment calls, session-scope decisions, git push to origin |
| agent_runner.py | Architectural decisions, user-confirmation gates, session-close handoffs |

---

*Source: IH-3 O-7 (2026-06-21), OD-29 resolved 2026-06-24.*
