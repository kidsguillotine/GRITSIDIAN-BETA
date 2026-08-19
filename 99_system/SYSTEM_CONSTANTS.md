---
title: System Constants
created: 2026-06-26
meta_status: active
purpose: >
  Single-source canonical for all literal values hardcoded in more than one
  script or doc. Scripts source constants.sh; this doc is the human-readable
  reference. C9 linter (H3b) will warn on hardcoded literals found here.
update_trigger: >
  Add a row when a literal appears in more than one file and may drift.
  Mark "sourced?" -> yes when the corresponding script sources constants.sh.
authority: "Rank 3 reference. Basis: IH-9 H2 (2026-06-26)"
---

# System Constants

> Scripts source `.claudian/scripts/constants.sh` for bash.
> Python scripts: import from a `constants.py` (not yet built: open item).
> This doc is the human-readable reference. Do not hardcode values listed
> here in scripts: source or import them.

---

## Service ports

| Constant | Value | Service | Sourced? |
|---|---|---|---|
| `PORT_OBSIDIAN_HTTPS` | `27124` | Obsidian REST API (HTTPS, canonical) | [FAIL] |
| `PORT_OBSIDIAN_HTTP` | `27123` | Obsidian REST API (HTTP, legacy) | [FAIL] |
| `PORT_VO_MCP` | `27182` | Vault Operator MCP built-in server | [FAIL] |
| `PORT_OLLAMA` | `11434` | Ollama inference server | [FAIL] |
| `PORT_AGENT_RUNNER` | `8766` | agent_runner.py HTTP sidecar | [FAIL] |
| `PORT_CHROMADB` | `8000` | ChromaDB vector store | [FAIL] |
| `PORT_CALENDAR` | `8090` | nginx calendar-server (your-scripts.ics) | [FAIL] |
| `PORT_N8N` | `5678` | n8n workflow engine | [FAIL] |

---

## Active Stack Services

<!-- VO_MEMORY_INCLUDE_BEGIN: stack-services -->

| Service | Port | Notes |
|---------|------|-------|
| Ollama | :11434 | `systemctl --user start ollama` or `ollama serve` |
| ChromaDB | :8000 | Docker: `pas-chromadb`; health: `/api/v2/heartbeat` |
| n8n | :5678 | Docker: `pas-n8n`; `network_mode: host` required |
| agent-runner | :8766 | Docker: `pas-agent-runner`; Python sidecar for n8n->vault_agent bridge |
| VO MCP (built-in, Obsidian) | :27182 | VO's own built-in server: NOT an external service |
| Obsidian REST API | :27124 HTTPS / :27123 HTTP | HTTPS canonical; use https://localhost:27124 with SSL verification disabled |

**Stack startup:**
```bash
cd ~/Projects/your-stack && sudo docker compose up -d
systemctl --user start ollama
```
**Service recovery:** `curl -s localhost:8000/api/v2/heartbeat && curl -s localhost:5678/healthz && curl -s localhost:11434/`

<!-- VO_MEMORY_INCLUDE_END: stack-services -->

---

## Formatting literals

| Constant | Value | Used in | Sourced? |
|---|---|---|---|
| `EM_DASH` | U+2014 `-` | MIGRATION_LOG grep (C6), date-headers | [x] gen_session_boot.sh |
| `MIGRATION_DATE_PATTERN` | `^[0-9]{4}-[0-9]{2}-[0-9]{2}: ` | gen_session_boot.sh, generate_handoff.sh C6 | [FAIL] |

---

## Paths

| Constant | Value | Notes | Sourced? |
|---|---|---|---|
| `VAULT` | `__VAULT_ROOT__` | Set via env or hardcoded default in each script | [FAIL] |
| `GRITSIDIAN_SCRIPTS` | `__SCRIPTS_ROOT__/scripts` | Canonical script location | [FAIL] |
| `AGENT_MEMORY_DB` | `~/.local/share/agent_memory/memory.db` | XDG-style, outside vault tree | [FAIL] |

---

## Thresholds

| Constant | Value | Enforced by | Sourced? |
|---|---|---|---|
| `DEDUP_THRESHOLD` | `0.99` | CLAUDE.md hard prohibition, merge_files.py | [FAIL] |
| `C6_CUTOFF_DATE` | `2026-06-25` | validate_system.sh c6_check() | [FAIL] |

---

## Block markers (format contracts)

| Constant | Value | Used in | Sourced? |
|---|---|---|---|
| `OD_BEGIN` | `<!-- BEGIN_PENDING -->` | OPEN_DECISIONS.md, gen_session_boot.sh, generate_handoff.sh, validate_system.sh C8 | [FAIL] |
| `OD_END` | `<!-- END_PENDING -->` | (same) | [FAIL] |
| `IH_BEGIN` | `<!-- BEGIN_PENDING_REVIEW -->` | IMPORTED_HANDOFFS.md, gen_session_boot.sh, generate_handoff.sh, validate_system.sh C8 | [FAIL] |
| `IH_END` | `<!-- END_PENDING_REVIEW -->` | (same) | [FAIL] |

---

## Secret-scan patterns (canonical)

Single source of truth for high-confidence secret detection. Three implementations MUST stay identical to this list: `.git/hooks/pre-commit` (`SECRET_PATTERNS`, bash ERE), `.claudian/scripts/intake_gate.py` (`check_secrets`), `.claudian/scripts/intake_gate.js` (`checkSecrets`). Diverging any copy re-creates the 2026-07-23 gap where intake_gate PASSed a `token: <uuid>` leak the hook would block.

`<uuid>` = `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`.

| Pattern (ERE) | Catches |
|---|---|
| `\bsk-[A-Za-z0-9_-]{20,}` | OpenAI/Anthropic `sk-` key (word-anchored since 2026-07-05 to skip `disk-state`/`flask-based`) |
| `\bAKIA[0-9A-Z]{16}` | AWS access key |
| `\bAIza[0-9A-Za-z_-]{30,}` | Google API key |
| `-----BEGIN [A-Z ]*PRIVATE KEY-----` | PEM private key block |
| `\bxox[baprs]-[A-Za-z0-9-]{10,}` | Slack token |
| `[Tt][Oo][Kk][Ee][Nn][^a-zA-Z0-9]{1,8}<uuid>` | labeled `token: <uuid>` (G13 / SECURITY_FIRES Fire 2 leak shape) |
| `[Ss][Ee][Cc][Rr][Ee][Tt][^a-zA-Z0-9]{1,8}<uuid>` | labeled `secret: <uuid>` |
| `[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][^a-zA-Z0-9]{1,8}<uuid>` | labeled `api_key: <uuid>` |

Sourced? [FAIL]: documented-canonical; the three copies are hand-synced, not loaded from a shared file. A future `constants` refactor could generate all three from this table.

---

## Sourcing status summary

Scripts that currently source `constants.sh`: none (as of 2026-06-26).

Priority refactor order (highest drift risk first):
1. gen_session_boot.sh + generate_handoff.sh: share MIGRATION_DATE_PATTERN, OD_BEGIN/END, IH_BEGIN/END
2. validate_system.sh: C6 hardcodes the em-dash pattern; C8 will use block markers
3. generate_handoff.sh: ports hardcoded in service-check table

> Open item: `constants.py` for Python scripts (classify.py, vault_agent.py, etc.): defer until a concrete cross-script drift event occurs.
