---
name: drain
description: >
  Route Tasks and Quick scraps from today's (or a specified) daily note
  to _handoff/DRAIN_REVIEW.md for review, then commit approved items to
  TASKS.md / SCRAPS.md. Use when accumulating captures that need routing.
allowed-tools:
  - Bash
  - Read
---

# /drain

Extract unrouted Tasks and Quick scraps from a daily note into a staged
review doc. After the user marks items, commit routes them to their
destinations.

## Usage

```
/drain                       Extract from today's daily note
/drain 2026-07-01            Extract from a specific date
/drain --commit              Route all approved/declined items in DRAIN_REVIEW.md
/drain --status              Show pending marker count
```

## Steps

### Extract (/drain or /drain <date>)

1. Resolve the target date:
   - No arg -> today's date via `date +%Y-%m-%d`
   - Date arg -> use as-is

2. Run extract:
   ```bash
   python3 .claudian/scripts/drain.py 20_personal/daily/<date>.md
   ```

3. Report the output line from drain.py verbatim. If it refused (pending
   markers), surface the refusal and the pending count. Do not override.

### Commit (/drain --commit)

1. Run:
   ```bash
   python3 .claudian/scripts/drain.py --commit
   ```

2. Report: approved count, declined count, pending count.

3. If approved > 0, note that TASKS.md and/or SCRAPS.md were updated and
   offer to show the new entries.

### Status (/drain --status)

1. Run:
   ```bash
   python3 .claudian/scripts/drain.py --status
   ```

2. Report the count line verbatim.

## Rules

- NEVER edit DRAIN_REVIEW.md manually on the user's behalf. The user
  edits the marker tokens (MANUAL_REVIEW -> MANUAL_REVIEW_APPROVED or
  MANUAL_REVIEW_DECLINED) in their own editor.
- NEVER call --commit without being explicitly asked. Extract and commit
  are separate user-triggered steps.
- If drain.py refuses to extract (pending markers exist), tell the user
  the count and say to run `/drain --commit` first.
- If the daily note does not exist, surface the path and suggest running
  `/daily-note` first to create it.
