---
title: "Project To-Do: Claudian Starter"
created: 2026-08-18
meta_status: active
purpose: >
  Single running to-do list for the Claudian Starter. This is a personal project
  and a tool, not a product. Keep it plain. Add items at the bottom of a section;
  check them off in place.
update_trigger: Add a line when new work appears; check it off when done.
---

# Project To-Do: Claudian Starter

Framing: this is a **project and a tool**, not a product. No roadmap, no
release, no marketing. It exists so one person (and a few testers) can run an
Obsidian vault with an AI helper and not lose data. Every item below serves that.

## Done (this build)

- [x] Genericized `CLAUDE.md` (rules, no personal content)
- [x] Curated `.claudian/scripts/` (43 reusable scripts, scrubbed)
- [x] All 5 skills ported and scrubbed
- [x] Empty vault taxonomy with per-folder README
- [x] `_handoff/` and `99_system/` doc templates
- [x] `.claude/settings.json` hook wiring (rm-guard + handoff regen)
- [x] Git `pre-commit` guard + `install.sh`
- [x] `setup.sh` + `SETUP.md` (placeholder replacement)
- [x] PII scrub audit (0 leaks)

## Now: documentation (this request)

- [x] Consolidated to-do list (this file)
- [x] Wiki-style starter guide (`wiki/` folder, interlinked notes)
- [x] Rewrite root `README.md` as the wiki front door
- [x] Simplified rules in ASD-STE100 (Simplified Technical English): `wiki/The Rules (Simple English)`
- [x] Plain-language pages for non-technical readers + `wiki/Glossary`
- [x] Explain git integration and why backup matters: `wiki/Git Backup`
- [x] Explain the sensitivity split, the pre-commit trigger, and the security-fires protocol: `wiki/Sensitivity and Security`
- [x] Wikilinks reference page: `wiki/Wikilinks`
- [x] Required Obsidian + community plugins: `wiki/Plugins`
- [x] Port the formal structure/frontmatter spec: `99_system/DOC_STANDARD.md` (+ `wiki/Frontmatter and Structure`)
- [x] Windows + run-from-flash-drive prerequisites: `wiki/Windows and Flash Drive`

## Done (third pass: 2026-08-19)

- [x] Fixed the three runtime gaps: shipped 6 missing state stubs
      (SESSION_HANDOFF_CURRENT, NEXT_ACTIONS, PHASE_STATE, VAULT_STATE,
      PROCESSING_CHECKPOINT, PUSH_INCONGRUENCE) AND hardened every numeric test in
      gen_session_boot.sh to default to 0. The integer error is gone.
- [x] Shipped `.claudian/config/vocab.yaml` as a small prototype (5 areas, 6
      types, 5 statuses) and generated `_handoff/TAG_SCHEMA.md` from it. Verified
      the generator runs and its output is dash-free and emoji-free.
- [x] Added a Load-on-demand section to CLAUDE.md listing all 15 ported docs,
      TOKEN_DISCIPLINE first.
- [x] CLAUDE.md: added the H1 heading, restored rule IDs (R-MAP-GUARD,
      R-WIKILINK-NOEXT, R-NO-EMOJI, R-NO-EM-DASH), added the cloud-only default
      note to the model boundary policy, and added R-ASD-STE100.
- [x] R-ASD-STE100: Simplified Technical English is now a hard rule in CLAUDE.md
      and is appended to every agent prompt (vault-classifier, vo-system-prompt)
      and to AGENTS.md.
- [x] Wrote `99_system/VAULT_ARCHITECTURE.md`: names every tracking file, its
      writer, its reader, and a "where do I write this?" table. This is the answer
      to "what are all of these files".
- [x] Implemented the safety policy: `_handoff/SAFETY_POLICY.md` with 9 hard
      deletion rules plus an explicit cron-commit section (what the hourly
      snapshot does, the one-repo rule, agents never push, gitignore before you
      enable it).
- [x] `_handoff/USER_CONTEXT.md` written WITH the Operational Failure Modes
      section (7 entries, append-only).
- [x] Imported the working formats: GOTCHAS (`### GN:` append-only with a
      template) and SECURITY_FIRES (with a STOP RULE at the top so the doc carries
      its own escalation).
- [x] Fixed the confusing SETUP.md hooks section: split into Layer 1 (already
      wired, nothing to run) and Layer 2 (two commands to type), labelled the code
      block as commands, and added a confirmation step.
- [x] Fixed the SETUP.md verify grep so it no longer false-positives on
      documentation tokens.
- [x] Debolded the OD `Status: PENDING` marker and widened both parsers to accept
      either form. Verified a pending entry still counts.
- [x] Corrected the Windows guide: Git Bash is sufficient, WSL2 is needed ONLY for
      a local model.
- [x] Added PROJECT_TODO to the session boot digest (open count plus the first
      five items), and rewrote the boot trailer to point at the real doc set.
- [x] Folded the ponytail YAGNI ladder into DESIGN_BY_LIMITATION rather than
      shipping a second philosophy doc.
- [x] Added the symlink standard as a section in DOC_STANDARD, with the Windows
      and exFAT warning. No registry file until a symlink actually exists.
- [x] Added `99_system/skill-specs/README.md` documenting the three-location skill
      drift and the two options for fixing it.
- [x] New placeholder folders with guidance: `attachments/`, `_templates/`,
      `_handoff/unreviewed/`, `_handoff/imported/`, `_handoff/archive/`,
      `99_system/archive/`, `00_inbox/scraps/`.
- [x] Seeded `_MOCs/README.md` (machine-managed warning) and `crm/README.md` plus
      `_templates/person.md`.
- [x] Added `AGENTS.md` (entry point for non-Claude agents) and
      `OBSIDIAN_HOTKEYS.md` at the vault root.
- [x] Fixed a Windows and macOS portability bug: removed the empty
      `00_inbox/SCRAPS`, which collided by case with `00_inbox/scraps`.
- [x] Fixed generated-file contamination: gen_session_boot.sh now refuses to read
      git history unless the vault IS its own repository. Previously an export
      folder inside another vault reported the outer project's state as fact.
- [x] Registered all 15 new docs in SYSTEM_DOC_MAP. Orphan check is clean.

## Done (fourth pass: gotcha hardening 2026-08-19)

Read all 56 source-vault gotchas, classified each as universal or
machine-specific, and verified whether a defense actually exists in code.

- [x] Ported 25 generalized gotchas into `_handoff/GOTCHAS.md`, grouped by failure
      class, each with a Defense line marked MECHANICAL or DOCUMENTARY so a reader
      knows which ones hold when nobody is watching.
- [x] Verified four script-level defenses are really present, not just described:
      the `link_safe_move.py` destination whitelist and `#` rejection, the
      `task_surface.py` quoted-tag regex, the pre-commit awk fence reset, and the
      `check_links.py` broken-link modes.
- [x] Live-tested the G03 (tag-as-path) guard: it blocks
      `20_personal/#area/health/note.md` and `20_health/note.md`, and allows
      `crm/jane-smith.md`. This is the guard for the incident that moved 661 files.
- [x] FIXED A REAL BUG: `VALID_TOP_LEVEL` did not match the shipped folders, so
      moves into `attachments/`, `crm/`, `_templates/`, and `wiki/` would have been
      blocked. Reconciled the whitelist and `FOLDER_SCHEMA.md` in one change.
- [x] FIXED A SECURITY GAP: `.gitignore` only excluded one Obsidian file, leaving
      plugin `data.json` (plaintext API keys, G11) and
      `.claudian/claudian-settings.json` (the env-var injection field, G12)
      committable. Rewrote `.gitignore` with a cited reason per block and verified
      every security pattern with `git check-ignore`.
- [x] Added a Verification discipline section to CLAUDE.md installing the eleven
      universal rules that previously had no home: negative results need a working
      tool, patch applied is not patch effective, presence is not correctness, a
      count must state its unit, a cached index is a memory-sourced claim, check
      ground truth before repeating a blocked claim, rank your sources, never read
      machine cache, extend rather than fork a governed structure, a uniform
      approval is not a review, and a rule that needs a preload is not installed.
- [x] Confirmed the boot digest surfaces all 25 gotchas by title at session start.

Machine-specific gotchas deliberately NOT ported (they describe one machine, not a
class of failure): Flatpak sandbox PATH, `newgrp`, git-filter-repo interpreter
mismatch, ChromaDB API version, docker compose healthcheck and restart behavior,
n8n host networking, NFS root squash, Ollama model quirks (think mode, context
window, timeouts), MCP token handling, cross-platform `node_modules`, and the
vault-agent `.env` discovery path. They stay in the source vault.

## Next: verify and harden

- [ ] Dry-run `setup.sh` on a copy in a throwaway path; confirm 0 placeholders remain
- [ ] Test git hooks fire: try to stage a `.md` delete and a bare `[[X.md]]` link; confirm block
- [ ] Confirm `check_links.py --count-broken` returns 0 on the empty vault
- [ ] Confirm `gen_session_boot.sh` runs after `setup.sh` and produces a valid SESSION_BOOT
- [ ] Windows path: verify scripts that assume POSIX paths degrade or document the WSL/Git-Bash requirement
- [ ] Decide: keep `crm/` in the starter, or drop it as optional

## Done (second pass)

- [x] RESOLVED via option B (user: "never emojis, never em dash over everything"): rewrote every parser delimiter to plain ASCII (OD header `### OD-N: Title`, MIGRATION_LOG `YYYY-MM-DD:`, GOTCHAS `### GN:`, SECURITY_FIRES status cell plain word `OPEN`). Global sweep removed all em-dashes, emojis, typographic arrows, and box-drawing across the whole export (scripts, skills, docs). Verified: 0 em-dashes, 0 emojis, parsers still return 0/0/0, all Python compiles, all shells pass `bash -n`.
- [x] Integrated the reusable `99_system` framework docs (TOKEN_DISCIPLINE, DESIGN_BY_LIMITATION, MODEL_ROUTING, AUTOMATION_ROUTING, FORMAT_CONTRACT_INVENTORY, CLAUDE_TOOL_MANIFEST, SUBAGENT_SPECS, SCRIPT_REGISTRY, SYSTEM_CONSTANTS, INTEGRITY_LAYER_SPEC, REBUILD_MOCS_SPEC, DOMAIN_HANDOFF_TEMPLATE, CAPTURE_QUICKREF); registered all in SYSTEM_DOC_MAP.
- [x] Grabbed from DOT_CLAUDE_COPY: `vault-classifier` subagent definition and `vo-system-prompt.md`.

## Open questions (need a decision)

- [ ] G19 automation candidate: make the apply script warn when every status in a
      manifest is the same value, which means it was mass-flipped, not reviewed.
- [ ] G13 gap: no mechanical check catches an email next to a password-shaped
      string. Decide whether a content heuristic is worth the false positives.
- [ ] G15 has no automation anywhere. Decide whether a binding check (disk vs
      runtime vs behavior) is worth building, or stays a discipline.
- [ ] Collapse the older vault versions (the ones that lived in `plans`) into the
      single vault we use now. Inventory every prior copy, pick the canonical one,
      migrate anything unique, retire the rest. Prerequisite for one source of
      truth.
- [ ] Skill folder policy: pick Option A or Option B in
      `99_system/skill-specs/README.md`. Right now three locations exist in the
      source vault and only `.claude/skills/` runs.
- [ ] Work-tracker consolidation: keep four work files (PROJECT_TODO,
      NEXT_ACTIONS, PENDING_WORK, PHASE_STATE) or collapse to two? See the "Can
      these be collapsed?" section in `99_system/VAULT_ARCHITECTURE.md`. The
      recommendation there is two for a small vault.
- [ ] Ported `99_system` docs still carry history from the source vault (OD
      numbers, dated incidents, scripts not shipped here). Trim to the reusable
      core, or ship as reference?
- [ ] `SCRIPT_REGISTRY.md` and `SYSTEM_CONSTANTS.md` may list scripts and paths
      that the curated starter does not include. Reconcile against
      `.claudian/scripts/`.
- [ ] Should the volatile boot files stay tracked in git? The `.gitignore` has the
      two lines commented out, with the tradeoff explained.
- [ ] `crm/` now has a README and a person template. Keep it, or drop it as
      out-of-scope for a starter?
- [ ] Distribution: `_export/GRITSIDIAN-BETA` is its own git repo with a zip of
      this folder. Decide whether testers get the zip or clone the folder
      directly. A zip cannot receive fixes; a repo can.
- [ ] The vault-root `.gitignore` does not list `_export/`, so the hourly cron
      commits this starter into the private vault repo. Intended, or exclude it?

## Parked (tracked elsewhere, NOT part of this shareable starter)

These live in the private vault `_handoff/`, not here. Listed by name only so the
thread is not lost. Do not copy their detail into this folder.

- Vault-wide: broken-wikilink repair, push-failure log, session open-decisions.
- Hardware: SanDisk SSD recovery (active fire).

Reason kept separate: this folder is meant to be handed to testers. Personal
vault operations must not leak into it (see `wiki/Sensitivity and Security`).
