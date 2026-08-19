---
title: "VIP Actions: Next Session"
created: 2026-08-18
meta_status: active
purpose: >
  Transient priority bucket. Items here MUST be read by the next session before
  other work. Files are tagged in frontmatter with active-vip / active-fire /
  pending-user-action to control expand-or-index at boot.
update_trigger: At session close, drop items that must not be lost. At session
  start, mark IN PROGRESS / DONE / DEFERRED and move resolved items out.
authority: Rank 2 (authoritative-transient). Supersedes the general queue until processed.
---

# VIP: Next Session

(empty on a fresh vault)
