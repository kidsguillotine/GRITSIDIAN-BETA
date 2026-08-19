---
title: Script Registry
created: 2026-08-19
meta_status: active
purpose: >
  Roster of every script shipped in .claudian/scripts. The validator (check C4)
  diffs this table against the folder, so an entry with no file, or a file with no
  entry, is reported as drift.
update_trigger: >
  Add a row when you add a script; remove the row when you remove one. Keep this
  table and the folder in agreement or C4 fails.
authority: Rank 4 registry. The folder on disk is ground truth; this is its index.
---

# Script Registry

Scripts live in `.claudian/scripts/`. 42 shipped.

Regenerate this table after adding or removing a script, then re-run
`bash .claudian/scripts/validate_system.sh` and confirm C4 passes.

## .claudian/scripts/

| Script | Purpose |
|---|---|
| `agent_memory.py` | see file header |
| `agent_runner.py` | see file header |
| `api_catalog_build.py` | api_catalog_build.py: deterministic public-apis catalog -> vault reference note. |
| `apply_classify_tags.py` | area/* and #type/* tags into the frontmatter of each "tagged" file. |
| `check_links.py` | see file header |
| `classify.py` | see file header |
| `constants.sh` | Shared literals for vault shell scripts |
| `dedup_pipeline.py` | see file header |
| `drain.py` | see file header |
| `gen_last_modified.sh` | Generate LAST_MODIFIED_INDEX.md from git log |
| `gen_session_boot.sh` | Generate _handoff/SESSION_BOOT.md |
| `gen_vo_memory.sh` | Regenerate knowledge.md and projects.md from templates + canonical include markers |
| `generate_handoff.sh` | Generate SESSION_HANDOFF_CURRENT.md from live system state |
| `generate_tag_schema.py` | see file header |
| `hourly_snapshot.sh` | hourly commit + push for the VAULT repo only. |
| `inference.py` | see file header |
| `inject_frontmatter.py` | see file header |
| `interaction_log.py` | see file header |
| `inventory_tree.sh` | Output file/folder trees for key locations |
| `link_safe_move.py` | see file header |
| `merge_files.py` | see file header |
| `op_idempotency.py` | see file header |
| `op_log.py` | see file header |
| `parse_file.sh` | standard content spot-check for any file |
| `pre-sweep.sh` | see file header |
| `rebuild_mocs.py` | see file header |
| `reconcile_session.py` | see file header |
| `rm-guard.sh` | PreToolUse hook blocking rm on vault content files |
| `session_close.sh` | Comprehensive session close audit + handoff generation |
| `state_hook.py` | see file header |
| `task_extract.py` | see file header |
| `task_promote.py` | see file header |
| `task_surface.py` | see file header |
| `time_context.py` | see file header |
| `token_report.py` | see file header |
| `validate_frontmatter.py` | see file header |
| `validate_system.sh` | Referential integrity validator (C1 + C2 + C3 + C4 + C6 + OD-residue) |
| `vault_agent.py` | see file header |
| `vault_decision_check.sh` | pre-decision verification for any file pair |
| `vault_setup.sh` | idempotent vault setup |
| `vault_tree.sh` | Print vault folder structure 6 levels deep |
| `vip_index_scan.sh` | Frontmatter-index scan for session start |
