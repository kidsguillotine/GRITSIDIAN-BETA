---
title: Agent Entry Point
created: 2026-08-19
meta_status: active
purpose: >
  Pointer file for any AI agent that opens this vault. Names the constitution and
  the boot sequence so a non-Claude agent does not have to guess.
update_trigger: Update if the constitution filename or the boot order changes.
---

# Agent Entry Point

If you are an AI agent working in this vault, read these in this order.

1. `CLAUDE.md`: the constitution. It governs everything you may and may not do.
   Every rule in it applies to you regardless of which model or product you are.
2. `_handoff/SESSION_BOOT.md`: the current state digest.
3. `_handoff/BOOT_DELTA.md`: what changed since the last session.
4. `_handoff/vip_next_session/`: read the frontmatter of each file. Open the body
   only for `active-fire`, `active-vip`, or `pending-user-action`.

Then stop and wait for the user.

## Non-negotiable, before you touch anything

- Never `rm` a `.md`, `.txt`, or `.csv` file. Move it to `.trash/` instead.
- Never write an emoji or an em dash. Plain ASCII text only.
- Write in ASD-STE100 (Simplified Technical English). Short sentences, one idea
  each, active voice.
- Ask before any action that changes state. General agreement is not consent for
  each sub-decision.
- If `SECURITY_FIRES.md` has a row marked OPEN, handle it before anything else.

Full detail: `CLAUDE.md`. Structure map: `99_system/VAULT_ARCHITECTURE.md`.
