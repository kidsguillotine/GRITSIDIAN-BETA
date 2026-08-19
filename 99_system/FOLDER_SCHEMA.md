---
title: "Folder Schema: canonical top-level vault layout"
created: 2026-08-18
meta_status: active
purpose: >
  Single source of truth for the vault's top-level folder structure. Enumerates
  every legitimate top-level folder, its purpose, and whether it is a valid move
  destination for automated pipelines. Downstream reference:
  .claudian/scripts/link_safe_move.py VALID_TOP_LEVEL frozenset must match the
  "valid move destination" set.
update_trigger: >
  When a top-level folder is added, renamed, or removed on disk. Update this file
  FIRST, then update VALID_TOP_LEVEL in link_safe_move.py to match, then commit.
authority: >
  Rank 3: canonical for folder schema. Only the disk itself supersedes this doc.
---

# Folder Schema

> Canonical layout of the vault's top-level folders. Land any structural change
> here first, then propagate to the guard (`link_safe_move.py:VALID_TOP_LEVEL`)
> and the routing map (`vault_agent.py:TAG_TO_FOLDER`).

## Content folders (valid move destinations)

| Folder | Purpose |
|---|---|
| `00_inbox/` | Raw capture and abstain-destination for unrouted files. Default target for unmapped classify tags. |
| `10_active/` | Currently-active work: routines, TODOs, current-project state. |
| `20_personal/` | Personal life domain: health, family, home, personal records. Route sensitive subfolders (e.g. `finance/`) to gitignore. |
| `30_career/` | Career, resumes, work history, professional records. |
| `40_technical/` | Technical notes: code, learning, systems. |
| `50_notes/` | General notes and ideas, non-domain-specific. |
| `60_creative/` | Creative work: writing, music, art. |
| `70_manual_review/` | Files flagged by the pipeline that need a human decision. Content here means the automation abstained. |
| `80_archive/` | Historical/superseded content, kept for reference. Do not auto-route here. |
| `crm/` | Person notes (contacts). Optional; remove if unused. |
| `attachments/` | Images, PDFs, and other media embedded in notes. Set this as Obsidian's attachment folder. |
| `_templates/` | Note templates for the Obsidian Templates and Templater plugins. |
| `wiki/` | The human-facing guide for this system. |
| `99_system/` | System documentation, this file included. |
| `_MOCs/` | Maps of Content: index notes. Bulk-managed by `rebuild_mocs.py`. Do not hand-edit. |
| `_handoff/` | Session handoff, decision logs, incident records. |
| `.trash/` | Local trash for reversible deletions. Never a classify destination. Matches Obsidian's built-in `.trash/`. |

## Non-content folders (never valid move destinations)

Plugin state, config, and script directories. Automated pipelines must not route
files here.

| Folder | Purpose |
|---|---|
| `.git/` | Git internal state |
| `.claude/` | Claude Code (Claudian) skills and settings |
| `.claudian/` | Claudian scripts, hooks, config |
| `.obsidian/` | Obsidian plugin state |

## Reconciliation rule

Whenever this doc changes at the folder level, update in the same change:

1. `.claudian/scripts/link_safe_move.py`: `VALID_TOP_LEVEL` must match the
   content-folders set (plus `.trash/`).
2. `.claudian/scripts/vault_agent.py`: `TAG_TO_FOLDER` targets must all appear
   in the content-folders table above.

If a folder is renamed or removed on disk without updating this doc, the guard
starts blocking moves to the new path and the tag resolver may point at a
nonexistent target. Both fail closed rather than corrupting.
