---
title: User Context and System Profile
created: 2026-08-19
meta_status: active
purpose: >
  Facts about this specific install: the machine, the person's preferences, and
  the failure modes seen in this environment. The agent reads this to stop asking
  the same setup questions and to avoid known traps.
update_trigger: >
  Update when hardware changes, a preference changes, or a new operational
  failure mode is found. The failure-modes section is append-only.
---

# User Context and System Profile

Fill this in once. The agent reads it instead of guessing.

## Hardware

| Item | Value |
|---|---|
| Operating system | (fill in: Windows 11, Linux, macOS) |
| RAM | (fill in) |
| Disk free | (fill in) |
| GPU and VRAM | (fill in, or "none" if cloud-only) |

## How this vault runs

| Item | Value |
|---|---|
| Mode | cloud-only, or cloud plus local model |
| Shell | (Git Bash, WSL2, zsh, bash) |
| Python version | (`python3 --version`) |
| Vault on removable drive | yes or no. If yes see `wiki/Windows and Flash Drive` |

## Preferences

- Writing style: ASD-STE100 (Simplified Technical English). Short sentences. No
  emojis. No em dashes. See CLAUDE.md rule R-ASD-STE100.
- Confirmation: ask before any action that changes state. General agreement is
  not consent for each sub-decision.
- Detail level: (fill in: terse, or explain the reasoning)

## Active projects

List the two or three things you are actually working on. Keep it short so the
agent can prioritize.

1. (fill in)

## Operational Failure Modes (session level)

Append-only. These are traps seen in a real session, not theory. Add one when it
bites you. Environment traps that belong to a tool go in `_handoff/GOTCHAS.md`
instead; this section is for failures in how a session is run.

### 1. Stale directory listings

A file listing captured earlier in a session can be wrong by the time you act on
it. Re-check the path immediately before a move or a delete. Ghost folders that
were already removed still appear in old output.

### 2. Large machine-generated files exceed the context limit

Plugin index files and database dumps can be enormous. Never read one whole.
Sample it. Some file types should never be read at all; list them here as you
find them.

### 3. Filenames with invisible characters

Exported files sometimes contain invisible Unicode characters. They break exact
name matching and quiet a `grep`. Match on a substring, not the whole name.

### 4. Duplicate names from cloud sync

Sync services create copies named `file (2).md`. They are near-identical, not
identical. Never merge on the name alone. Compare content first.

### 5. Rate limits and long operations

A long batch can stop partway. Write the checkpoint before you start, not after.
See `_handoff/PROCESSING_CHECKPOINT.md`.

### 6. Chat history is not memory

A conversation gets truncated and compacted without warning. Any decision that
matters must be written to a file at the moment it is made. This is the single
most common cause of lost work.

### 7. A generated file can absorb the wrong state

A generator script that reads git will read whatever repository it finds. If your
vault sits inside another repository, the generated digest can pick up the outer
repository's history. Confirm the vault is its own repository.
