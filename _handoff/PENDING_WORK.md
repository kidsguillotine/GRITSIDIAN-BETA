---
title: Pending Work
created: 2026-08-19
meta_status: active
purpose: >
  Deferred items only. This file is kept because generate_handoff.sh and
  gen_vo_memory.sh parse it. For day-to-day work use NEXT_ACTIONS.md instead: one
  queue is easier to keep honest than three.
update_trigger: Add an item you are deliberately not doing yet. Remove it when done.
---

# Pending Work

Read `_handoff/NEXT_ACTIONS.md` first. That is the live queue.

This file holds only work you have deliberately deferred: real, but not now. If an
item needs a decision from the user before it can start, it belongs in
`_handoff/OPEN_DECISIONS.md` instead.

## IMMEDIATE

(none)

## Later

(none)

## Why this file still exists

`generate_handoff.sh` extracts the IMMEDIATE block, and the section headers are a
format contract. If you want a single work queue, keep this file with empty
sections and write everything in NEXT_ACTIONS. Do not delete it: five scripts
reference it. See `99_system/VAULT_ARCHITECTURE.md`.
