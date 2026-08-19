---
title: Phase State
created: 2026-08-19
meta_status: active
purpose: >
  Optional multi-session phase tracking. Kept because validate_system.sh check C11
  and gen_vo_memory.sh read it. A small vault does not need it: leave the table
  empty and use NEXT_ACTIONS.md.
update_trigger: Mark a phase complete when its exit condition is met.
---

# Phase State

Optional. Leave this empty unless you run work in named phases with exit
conditions.

| Phase | Status | Exit condition |
|---|---|---|
| Setup | in progress | setup.sh run, hooks installed, first session done |

## Why this file still exists

Check C11 in `validate_system.sh` compares rows here against
`IMPORTED_HANDOFFS.md` to catch work marked complete in one place and unfinished
in the other. Deleting the file makes C11 skip instead of pass, which is a silent
gap rather than a clean result. Keep it, empty is fine.
