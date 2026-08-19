---
title: HANDOFF Template
created: 2026-05-31
meta_status: active
purpose: Copy this when scaffolding a new domain. Replace ALL_CAPS placeholders.
max_tokens: 500
update_trigger: Template structure change or new required HANDOFF section
---

# HANDOFF: DOMAIN_NAME

> Read after `VAULT_STATE.md`. Loads in <500 tokens. Single source of truth for this domain's state.

## Purpose

1-2 lines. What does this folder hard-filter for? What's NOT in here that someone might mistakenly look for?

Example: *"30_career/ contains resume entries, job applications, employment documents, and career planning. Does NOT contain school coursework (see 40_technical/school/) or general productivity notes (see 50_thinking/)."*

## Stats

- **File count:** N (as of YYYY-MM-DD)
- **Last meaningful update:** YYYY-MM-DD: short description
- **Indexed by MOC:** [[_MOCs/MOC_NAME]]
- **Vector index status:** healthy / stale / excluded

## Active topics

3-5 bullets. What's actively in flux? Lets a model know what NOT to disturb without checking.

- topic A: in progress
- topic B: blocked on X
- topic C: recently reorganized, leave alone

## Open decisions queued

Things that need a human call, not auto-resolution.

- [ ] decision 1
- [ ] decision 2

## Recent operations (last 5)

Most recent first. Lets a model verify it isn't undoing yesterday's work.

| Date | Operation | Reversible |
|---|---|---|
| YYYY-MM-DD | what happened | yes/no |

## Pointers

- **Related folders:** `XX_other/` (why)
- **Parent MOC:** [[_MOCs/...]]
- **Quarantine / exclusion:** files here NOT to surface in general queries

## How to extend

When you finish work in this domain:
1. Update "Stats" file count
2. Add one row to "Recent operations"
3. Update "Active topics" if anything resolved or new emerged
4. Keep total under 500 tokens: trim oldest operations log first
