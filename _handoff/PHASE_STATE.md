---
title: Phase State
created: 2026-08-19
meta_status: active
purpose: >
  Optional. Tracks multi-session project phases. Small vaults do not need this;
  leave it empty and use NEXT_ACTIONS.md plus PENDING_WORK.md.
update_trigger: Mark a phase done when its exit condition is met.
---

# Phase State

| Phase | Status | Exit condition |
|---|---|---|
| Setup | in progress | setup.sh run, hooks installed, first session done |

Delete this file if you do not run phased work. Nothing breaks.
