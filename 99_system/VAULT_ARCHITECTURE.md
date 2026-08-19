---
title: Vault Architecture
created: 2026-08-19
meta_status: active
purpose: >
  Explains every tracking file in the system, what writes it, what reads it, and
  which single file you should write to for a given kind of information. Read this
  when you are unsure where something belongs.
update_trigger: >
  Update when a tracking file is added, removed, or changes owner.
authority: >
  Rank 3. Canonical map of the tracking layer. FOLDER_SCHEMA covers content
  folders; this doc covers the state and decision files.
---

# Vault Architecture

The system has many small files on purpose. Each one answers a different question
and has exactly one writer. This page is the map.

## The one rule that makes it coherent

Every file below is either GENERATED or HUMAN. Never both.

- GENERATED: a script owns it. Do not hand-edit. Your edit will be erased.
- HUMAN: a person or an agent writes prose into it. No script rewrites it.

When you want to change what a GENERATED file says, change its source, not the
file.

## The three questions

Every tracking file answers one of three questions.

1. What is true right now? (state)
2. What must happen next? (work)
3. What did we decide, and what went wrong? (record)

## Group 1: state (all GENERATED, all machine-owned)

| File | Answers | Written by |
|---|---|---|
| `_handoff/SESSION_BOOT.md` | What do I read first this session? | `gen_session_boot.sh` |
| `_handoff/BOOT_DELTA.md` | What changed since the last boot? | `gen_session_boot.sh` |
| `_handoff/SESSION_HANDOFF_CURRENT.md` | The longer version of the same. | `generate_handoff.sh` |
| `_handoff/VAULT_STATE.md` | What were the last file operations? | `state_hook.py` |
| `_handoff/PROCESSING_CHECKPOINT.md` | Where did an interrupted batch stop? | `state_hook.py` |
| `_handoff/TAG_SCHEMA.md` | What tags exist? | `generate_tag_schema.py` |
| `_MOCs/*` | Index notes by topic. | `rebuild_mocs.py` |

SESSION_BOOT and SESSION_HANDOFF_CURRENT overlap by design. BOOT is the short
digest for the start of a session. HANDOFF is the long form written at the end.
If you only read one, read BOOT.

## Group 2: work (all HUMAN)

Three files, three different time horizons. This is the part people get wrong.

| File | Horizon | Write here when |
|---|---|---|
| `PROJECT_TODO.md` (vault root) | The project itself | The task is about building or fixing this system. |
| `_handoff/NEXT_ACTIONS.md` | This session and the next | You know exactly what to do and nobody needs to approve it. |
| `_handoff/PENDING_WORK.md` | Weeks or longer | The task is real but deferred. It would clutter NEXT_ACTIONS. |
| `_handoff/PHASE_STATE.md` | Optional, multi-session | You run phased projects with exit conditions. |

Rules of thumb:

- If it needs a decision from the user first, it is not work yet. Put it in
  OPEN_DECISIONS.md.
- If you cannot tell whether it goes in NEXT_ACTIONS or PENDING_WORK, use
  NEXT_ACTIONS and let session close move it down.
- PHASE_STATE is optional. Delete it if you do not run phased work.

### Can these be collapsed?

Yes, and you should if the split feels like overhead. For a small vault, two
files are enough: `PROJECT_TODO.md` for building the system and
`_handoff/NEXT_ACTIONS.md` for everything else. Delete PHASE_STATE and fold
PENDING_WORK into a "Later" heading inside NEXT_ACTIONS.

Keep all four only when the volume actually justifies it. Adding a tracker is
cheap; reading four trackers every session is not. See
`99_system/DESIGN_BY_LIMITATION.md`.

## Group 3: record (all HUMAN, most append-only)

| File | Answers | Rule |
|---|---|---|
| `_handoff/OPEN_DECISIONS.md` | What is waiting on the user? | Gated. Nothing acts until approved. |
| `_handoff/IMPORTED_HANDOFFS.md` | What did another agent tell us? | Nothing applies until approved. |
| `_handoff/MIGRATION_LOG.txt` | What moved, and where did it go? | Append-only. One line per operation. |
| `_handoff/GOTCHAS.md` | What tool surprised us? | Append-only. Never delete an entry. |
| `_handoff/vip_next_session/SECURITY_FIRES.md` | What is leaking? | Outranks all other work when OPEN. |
| `_handoff/SAFETY_POLICY.md` | What are we never allowed to do? | Standing rule. |
| `_handoff/USER_CONTEXT.md` | Who and what machine is this? | Failure-modes section is append-only. |
| `_handoff/PUSH_INCONGRUENCE.md` | Did the backup fail? | Append-only. Empty is healthy. |

## Group 4: the priority folder

`_handoff/vip_next_session/` holds anything that must not be lost between
sessions. Each file declares its own urgency in frontmatter:

- `active-fire`: blocking. Read the whole file.
- `active-vip`: high priority. Read the whole file.
- `pending-user-action`: waiting on the human. Read the whole file.
- anything else: read the frontmatter only.

This is how a long-running problem survives a truncated conversation.

## Group 5: the rules layer

| File | Role |
|---|---|
| `CLAUDE.md` | The constitution. What the agent may and may not do. |
| `AGENTS.md` | A pointer for non-Claude agents. |
| `99_system/DOC_STANDARD.md` | Format and frontmatter spec. |
| `99_system/FOLDER_SCHEMA.md` | Content folder taxonomy. |
| `99_system/VAULT_ARCHITECTURE.md` | This file. The tracking layer. |
| `99_system/SYSTEM_DOC_MAP.md` | The index. Every scoped doc registers here. |
| `wiki/*` | The human guide, in plain English. |

## Where do I write this? (quick answer)

| I have... | Write it here |
|---|---|
| a task for building this system | `PROJECT_TODO.md` |
| a task for right now | `_handoff/NEXT_ACTIONS.md` |
| a task for someday | `_handoff/PENDING_WORK.md` |
| a question for the user | `_handoff/OPEN_DECISIONS.md` |
| a tool that broke | `_handoff/GOTCHAS.md` |
| a leaked secret | `SECURITY_FIRES.md`, and stop working |
| a file I moved | `_handoff/MIGRATION_LOG.txt` |
| a fact about this machine | `_handoff/USER_CONTEXT.md` |
| a new tag | `.claudian/config/vocab.yaml`, then regenerate |
| a note | a numbered content folder. See FOLDER_SCHEMA. |
