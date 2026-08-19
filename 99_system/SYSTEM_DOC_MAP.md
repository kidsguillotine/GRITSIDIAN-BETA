---
title: System Doc Map
created: 2026-08-18
meta_status: active
purpose: >
  Registry of every doc in a scoped folder (_handoff/, 99_system/). Every new
  scoped-folder doc MUST be registered here before commit (see CLAUDE.md
  "System-doc creation rule").
update_trigger: Add a row when a scoped-folder doc is created; remove on archive.
---

# System Doc Map

| Doc | Purpose | Authority |
|---|---|---|
| `CLAUDE.md` | Operating constitution | 1 |
| `99_system/FOLDER_SCHEMA.md` | Canonical top-level folder layout | 3 |
| `99_system/DOC_STANDARD.md` | Format/structure + frontmatter spec | 3 |
| `99_system/SYSTEM_DOC_MAP.md` | This registry | 4 |
| `99_system/API_CATALOG.md` | Local API catalog for /api-lookup | 6 |
| `99_system/TOKEN_DISCIPLINE.md` | Deterministic-script-over-per-item standing rule | 3 |
| `99_system/DESIGN_BY_LIMITATION.md` | Design philosophy | 5 |
| `99_system/SCRIPT_REGISTRY.md` | Registry of pipeline scripts | 4 |
| `99_system/CAPTURE_QUICKREF.md` | Capture-pipeline quick reference | 5 |
| `_handoff/SESSION_BOOT.md` | Session-start digest (generated) | 2 |
| `_handoff/BOOT_DELTA.md` | Delta since prior boot (generated) | 2 |
| `_handoff/OPEN_DECISIONS.md` | Pending decisions (confirmation gate) | 2 |
| `_handoff/IMPORTED_HANDOFFS.md` | External-agent imports pending review | 2 |
| `_handoff/PENDING_WORK.md` | Active work queue | 3 |
| `_handoff/GOTCHAS.md` | Environment traps (append-only) | 3 |
| `_handoff/TAG_SCHEMA.md` | Governed tag vocabulary | 3 |
| `_handoff/MIGRATION_LOG.txt` | Audit trail of structural ops | 2 |
| `_handoff/vip_next_session/README.md` | Transient next-session priority bucket | 2 |
| `_handoff/vip_next_session/SECURITY_FIRES.md` | Open security incidents | 2 |
| `99_system/VAULT_ARCHITECTURE.md` | What every tracking file is for | 3 |
| `99_system/AGENTS_AND_TOOLS.md` | Agents, skills, tool choice, inherited rules | 4 |
| `99_system/SCRIPT_SPECS.md` | Reading validator output; running rebuild_mocs | 4 |
| `99_system/SYMLINK_REGISTRY.md` | Symlink index (none active) | 4 |
| `99_system/SUPERSESSION_INDEX.md` | Dead decisions, do not re-apply | 3 |
| `99_system/SCRIPT_REGISTRY.md` | Roster of shipped scripts, checked by C4 | 4 |
| `99_system/skill-specs/README.md` | Skill vs spec folder policy | 5 |
| `_handoff/SAFETY_POLICY.md` | Deletion and backup safety, cron rules | 1 |
| `_handoff/USER_CONTEXT.md` | Machine facts + operational failure modes | 3 |
| `_handoff/SESSION_HANDOFF_CURRENT.md` | Long-form session handoff (generated) | 2 |
| `_handoff/NEXT_ACTIONS.md` | Short-horizon work queue | 3 |
| `_handoff/PHASE_STATE.md` | Optional phase tracking | 5 |
| `_handoff/VAULT_STATE.md` | Last vault operations (generated) | 2 |
| `_handoff/PROCESSING_CHECKPOINT.md` | Interrupted batch resume point (generated) | 2 |
| `_handoff/PUSH_INCONGRUENCE.md` | Failed backup pushes (append-only) | 2 |
| `_handoff/unreviewed/README.md` | Triage queue policy | 5 |
| `_handoff/imported/README.md` | External import policy | 5 |
| `AGENTS.md` | Entry point for non-Claude agents | 3 |
| `OBSIDIAN_HOTKEYS.md` | Keyboard reference for the human | 6 |
| `PROJECT_TODO.md` | Building this system | 3 |

Authority rank: lower number = higher authority. 1 = constitution, 2 = live
operational state, 3 = canonical reference, 4+ = registries and generated docs.
