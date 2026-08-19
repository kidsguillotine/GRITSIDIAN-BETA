---
title: Format Contract Inventory
created: 2026-06-26
meta_status: active
purpose: >
  Enumerate every file a script parses/counts, the expected format it assumes,
  and whether that contract is enforced. Feeds H3 (format linter build).
  Any consume-point lacking a lint check that gates a count or session-start
  read is a latent G40/G41.
update_trigger: >
  Add a row when a new script parses a vault doc, or when a doc format changes.
  Mark "Linted" -> yes when H3 covers the pattern.
authority: Rank 3 reference. Source of truth for H3 build scope.
basis: IH-9 T3 (2026-06-26)
---

# Format Contract Inventory

> Scope: scripts that parse vault docs to produce counts, booleans, or session-start content.
> Priority: HIGH = gates a count/read at session boot. MEDIUM = structural parse. LOW = advisory.

---

## OPEN_DECISIONS.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| PENDING block scope | gen_session_boot.sh, generate_handoff.sh, validate_system.sh | `<!-- BEGIN_PENDING -->` ... `<!-- END_PENDING -->` on their own lines (exact match) | HIGH | [FAIL] No |
| OD count (heading-based) | generate_handoff.sh `pending_decision_count()` | `^### OD-N: ` inside PENDING block | HIGH | [FAIL] No: **diverges from gen_session_boot.sh** |
| OD count (status-based) | gen_session_boot.sh | `**Status:** PENDING` (trailing whitespace stripped) inside PENDING block | HIGH | WARNING: Partial: OD-residue in validate_system.sh catches stranded resolved ODs but not format drift |
| OD heading + title | gen_session_boot.sh | `### OD-([0-9]+): (.*)` (regex) | MEDIUM | [FAIL] No |

**Known divergence:** `generate_handoff.sh` counts `### OD-` headings (can overcount resolved-but-unarchived ODs); `gen_session_boot.sh` counts status fields (correct). OD-residue check in validate_system.sh is a downstream patch, not a root fix. H3 should enforce that both scripts agree, or pick one method.

---

## IMPORTED_HANDOFFS.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| PENDING REVIEW block scope | gen_session_boot.sh, generate_handoff.sh | `<!-- BEGIN_PENDING_REVIEW -->` ... `<!-- END_PENDING_REVIEW -->` (exact) | HIGH | [FAIL] No |
| IH count (status-based) | gen_session_boot.sh, generate_handoff.sh | `**Status:** PENDING REVIEW` (exact, including trailing newline behavior) | HIGH | [FAIL] No |

---

## SECURITY_FIRES.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Open fire count | gen_session_boot.sh | `^\|.*OPEN` (ERE: table row starting with pipe, containing OPEN) | HIGH | [FAIL] No |

**Risk:** if the WARNING: emoji changes to a text marker, or the table row format loses the leading `|`, SEC_COUNT silently drops to 0. Same class as G42 (ERE flag required; already applied in C5 fix).

---

## MIGRATION_LOG.txt

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Date-header entries | gen_session_boot.sh, c6_check() | `^YYYY-MM-DD: description` (em-dash U+2014) | HIGH | [x] C6 in validate_system.sh (post-cutoff 2026-06-25) |

---

## PUSH_INCONGRUENCE.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Active failure lines | gen_session_boot.sh | `^- [0-9]{4}-.*push failed` | MEDIUM | [FAIL] No (script-written; low drift risk: writer and reader are both in hourly_snapshot.sh chain) |

---

## SYSTEM_DOC_MAP.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Section headers (folder context) | c1_check(), c2_check() | `^## ` or `^### <folder/>...` (path token: `[._a-zA-Z0-9][a-zA-Z0-9_./-]*/`) | MEDIUM | [FAIL] No: a malformed section header silently resets folder context to "" and skips that section's entries |
| Table data rows | c1_check(), c4_check() | `^\|[[:space:]]*([^|]+)[[:space:]]*\|.*\|.*` (pipe-delimited, 2+ columns) | MEDIUM | [FAIL] No |

**Risk:** The 36->4 scoping episode (IH-7) was caused by the section-header parser not reaching certain sections. A malformed header (e.g. added space before `###`) silently drops entries from C1 scope.

---

## SYMLINK_REGISTRY.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Active Symlinks section boundary | c3_check() | `^## Active Symlinks` (exact, case-sensitive) | MEDIUM | [FAIL] No: rename or extra space breaks section entry |
| Symlink table rows | c3_check() | `^\|[[:space:]]*([^|]+)[[:space:]]*\|.*\|.*` | MEDIUM | [x] Functional (symlink resolution tested) |

---

## SCRIPT_REGISTRY.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| your-scripts/scripts/ section boundary | c4_check() | `^## your-scripts/scripts/` (exact) | MEDIUM | [FAIL] No: rename breaks scope |
| Script table rows | c4_check() | `\|[[:space:]]*\`<name>.py\`[[:space:]]*\|` (backtick-wrapped) | MEDIUM | [x] Functional (file roster tested) |

---

## GOTCHAS.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Entry count | gen_session_boot.sh (display only) | `^#{2,3} G[0-9]+` | LOW | [FAIL] No (display only: not a session gate) |

---

## vip_next_session/*.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| meta_status field | gen_session_boot.sh | YAML `meta_status: <value>` in first frontmatter block; values: `active-vip`, `active-fire`, `pending-user-action` (others silently skipped) | MEDIUM | [FAIL] No: a typo silently drops a VIP file from boot display |

---

## SESSION_HANDOFF_CURRENT.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Active flags ([FIRE] lines) | gen_session_boot.sh | Lines containing `[FIRE]`, excluding `^##`, `^> `, `^---` | LOW | [FAIL] No (generated file: low drift risk) |

---

## PENDING_WORK.md

| Consume-point | Script | Expected format | Priority | Linted? |
|---|---|---|---|---|
| Security block | generate_handoff.sh | `[!] IMMEDIATE: SECURITY` heading -> next `## ` heading | MEDIUM | [FAIL] No |

---

## Summary: unprotected HIGH-priority contracts

These gate session-start counts and have no lint coverage:

1. `OPEN_DECISIONS.md`: `BEGIN_PENDING` / `END_PENDING` block markers
2. `OPEN_DECISIONS.md`: divergent counting methods between generate_handoff.sh (heading) and gen_session_boot.sh (status)
3. `IMPORTED_HANDOFFS.md`: `BEGIN_PENDING_REVIEW` / `END_PENDING_REVIEW` block markers
4. `SECURITY_FIRES.md`: `OPEN` table row format

H3 build order: these four first, then MEDIUM-priority section-header contracts.
