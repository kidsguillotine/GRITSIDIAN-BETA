---
title: Tag Schema
generated: 2026-08-19
meta_status: generated
generation_note: "DO NOT EDIT. Generated from .claudian/config/vocab.yaml by generate_tag_schema.py. Edit vocab.yaml instead."
---

# Tag Schema

> Generated 2026-08-19 from `.claudian/config/vocab.yaml`. Do not hand-edit this file.

---

## `#area/*`: Domain Assignment (closed)

| Tag | Primary Anchors |
|---|---|
| `#area/personal` | home, family, health, appointment, personal |
| `#area/career` | resume, job, interview, employer, career, work |
| `#area/technical` | code, script, server, api, config, bug, ... (+1) |
| `#area/creative` | writing, music, art, draft, lyrics, creative |
| `#area/admin` | invoice, receipt, insurance, license, renewal, admin |
| `#area/general` | general, misc, log, daily |

---

## `#type/*`: Note Kind (closed)

| Tag | Use for |
|---|---|
| `#type/note` |  |
| `#type/task` | Things to do. Has a checkbox or action item. |
| `#type/reference` | Something you look up, not process. Recipes, specs, cheat sheets. |
| `#type/journal` |  |
| `#type/project` | Multi-step effort with a goal and timeline. |
| `#type/capture` |  |

---

## `#status/*`: Lifecycle State (closed)

| Tag | Meaning |
|---|---|
| `#status/unsorted` | Newly injected. Pending classification. |
| `#status/active` |  |
| `#status/waiting` | Blocked on something external. |
| `#status/done` |  |
| `#status/archived` | Done or superseded. Not deleted. |

---

## `#priority/*`: Urgency (closed)

| Tag | Use for |
|---|---|
| `#priority/urgent` | Blocks everything else. |
| `#priority/high` | Important, do soon. |
| `#priority/medium` | Default level. |
| `#priority/low` | Nice to have. |

---


---

## `#topic/*`: Content Topics (extensible)

Human-approved via SA-1 vocabulary gate. New topics require cluster discovery approval.

| Tag | Description |
|---|---|
| `#topic/setup` | Installing or configuring this vault and its tools. |
| `#topic/backup` | Git snapshots, remotes, and recovery. |

Add new topics: edit `vocab.yaml` -> `topics:` -> re-run `generate_tag_schema.py`.

---

## Tag Aliases

| Alias | Canonical |
|---|---|
| `#area/work` | `#area/career` |
| `#area/tech` | `#area/technical` |

---

## Straggler / Legacy Tags

Bare tags (pre-namespace) still accepted by `validate_frontmatter.py` for backward compatibility.
Do not use in new notes. Migrate to namespaced form on next touch.

```
daily  finance  hardware  tech-setup  music  car  comp  maintenance
errand  project  yearly  what  why  high_priority_to-do  routine
urgent  waiting  health  digital  today  now
```
