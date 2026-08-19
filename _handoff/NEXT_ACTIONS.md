---
title: Next Actions
created: 2026-08-19
meta_status: active
purpose: >
  The single live work queue. Newest or most urgent first. This is the file to read
  and write during a normal session.
update_trigger: Update when you finish an action or learn about a new one.
---

# Next Actions

The one queue. If you only maintain one work file, maintain this one.

## Now

- [ ] Finish setup: run `./setup.sh`, then `git init`, then
      `bash .claudian/hooks/install.sh`. See `SETUP.md`.
- [ ] Fill in `_handoff/USER_CONTEXT.md` so the agent stops guessing about your
      machine.
- [ ] Set the Obsidian attachment folder to `attachments` and the template folder
      to `_templates`. See `wiki/Plugins`.

## Later

(none)

## Where other work lives

| Kind of item | File |
|---|---|
| Building or fixing this system | `PROJECT_TODO.md` (vault root) |
| Deliberately deferred | `_handoff/PENDING_WORK.md` |
| Needs a decision from you first | `_handoff/OPEN_DECISIONS.md` |
| Named phases with exit conditions | `_handoff/PHASE_STATE.md` (optional) |

Full map: `99_system/VAULT_ARCHITECTURE.md`.
