---
title: Documentation Standard
created: 2026-08-18
meta_status: active
purpose: >
  Format and structure standard for all docs in scoped folders. Defines required
  frontmatter, naming conventions, meta_status values, format contracts, and
  folder placement. This is the answer to "where are the formalized structures?".
update_trigger: >
  Add a new meta_status value; change a format contract; modify a naming
  convention; add a new scoped folder.
authority: >
  Rank 3. Role: FORMAT/STRUCTURE standard. CLAUDE.md = operator rules.
  SYSTEM_DOC_MAP = index. This doc = format spec. Do not duplicate their scope.
---

# Documentation Standard

> Role: FORMAT and STRUCTURE standard for system docs. Not operator rules
> (CLAUDE.md), not the doc index (SYSTEM_DOC_MAP.md).

## 1. Required frontmatter

Every file in a scoped folder (`_handoff/`, `99_system/`) MUST include:

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | Human-readable name |
| `created` | YYYY-MM-DD | yes | Creation date |
| `meta_status` | enum (section 3) | yes | Lifecycle state |
| `purpose` | string | yes | <=2 sentences: what this file is |
| `update_trigger` | string | yes | What event causes the next update |
| `authority` | string | recommended | Rank + conflict-resolution note |

Enforcement: every new scoped-folder doc must also get a `SYSTEM_DOC_MAP.md` row
before commit (see CLAUDE.md "System-doc creation rule").

## 2. Naming conventions

| Doc type | Format | Example |
|---|---|---|
| System docs (standing) | `UPPER_SNAKE_CASE.md` | `SYSTEM_DOC_MAP.md` |
| System docs (dated archive) | `NAME_archived_YYYYMMDD.md` | `SPEC_archived_20260818.md` |
| Scripts | `lower_snake_case.sh` / `.py` | `gen_session_boot.sh` |
| Wiki pages | `Title Case.md` | `Getting Started.md` |

## 3. meta_status values

| Value | Meaning |
|---|---|
| `active` | Live, maintained. Default for standing docs. |
| `generated` | Auto-generated. Do not hand-edit. |
| `standing-rule` | A permanent rule. Equal in force to CLAUDE.md. |
| `pending-user-action` | Needs user action before close. Surfaces at boot. |
| `active-vip` | High-priority carry-forward. Surfaces at boot. |
| `active-fire` | Active blocking issue. Surfaces at boot. |
| `permanent` | Append-only, never delete (e.g. GOTCHAS.md). |
| `archived` | No longer active; moved to an archive folder. |
| `superseded` | Replaced by a newer doc; link the successor. |

## 4. Format contracts

Some docs are parsed by scripts. Those docs MUST keep an exact format at the
parse points, or the boot counts break.

| Doc | Contract |
|---|---|
| `OPEN_DECISIONS.md` | Entries between `<!-- BEGIN_PENDING -->` and `<!-- END_PENDING -->`. Each is `### OD-N: Title` then a `Status: PENDING` line. |
| `IMPORTED_HANDOFFS.md` | Entries between `<!-- BEGIN_PENDING_REVIEW -->` and `<!-- END_PENDING_REVIEW -->`. |
| `SECURITY_FIRES.md` | Open rows contain the plain word `OPEN` in the status cell. |
| `MIGRATION_LOG.txt` | Date-header lines start with `YYYY-MM-DD:` (colon delimiter). |
| `GOTCHAS.md` | Entry headers are `### GN: Title` (colon delimiter). |

Delimiter policy: all machine-parsed delimiters are plain ASCII (colon, pipe, the
word OPEN). No em-dashes or emojis anywhere, in prose or in format contracts. The
parser regexes and the data templates use the same colon/word delimiters, so they
stay consistent. This satisfies the CLAUDE.md ban with no exceptions.

Rule: never rename or reformat a parse point without updating the consuming
script in the same commit.

## 5. Folder placement

| Folder | Contents |
|---|---|
| `_handoff/` | Session continuity docs |
| `99_system/` | Standing system docs |
| `_handoff/vip_next_session/` | High-priority carry-forwards; frontmatter-gated |

Cross-folder rule: `_handoff/` = session lifecycle. `99_system/` = standing
architecture. A doc belongs in one, not both.

## 6. Authority ranks

Lower number wins on conflict.

| Rank | Meaning |
|---|---|
| 1 | Live-generated (SESSION_BOOT.md) |
| 2 | Session-persistent, gated (OPEN_DECISIONS.md) |
| 3 | Active operator/reference (CLAUDE.md, this doc) |
| 4 | Registries and generated maps |
| 6-7 | Superseded or archived |

## 7. Archive policy

When a doc becomes inactive:

1. Set `meta_status: archived`.
2. Move it to the matching archive folder.
3. Update `SYSTEM_DOC_MAP.md`: remove from the active section; keep the row.
4. Add a `MIGRATION_LOG.txt` line.

Never archive, trash, or delete a live-mapped doc without explicit per-file
sign-off.

## 8. Symlinks

This starter ships real files, not symlinks. Nothing here is a link.

If you later share one script between this vault and another project, use the
symlink standard: exactly one canonical file, and every other location is a
symlink to it. Never a copy, because copies drift silently.

Rules if you adopt it:

1. Edit the canonical file only. Never edit through a link.
2. Never `cp` a script to share it. Link it.
3. Record each link in a new `99_system/SYMLINK_REGISTRY.md`. Create that file
   only when the first symlink exists, not before.

Warning for Windows and removable drives: exFAT and FAT cannot store symlinks,
and Windows needs a special permission to create them. If your vault lives on a
USB drive, do not use symlinks at all. See `wiki/Windows and Flash Drive`.
