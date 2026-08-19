---
title: Security Fires
created: 2026-08-19
meta_status: active
purpose: >
  Open security incidents. A fire is anything that exposes a credential or
  private data. The session-start digest counts the open rows here.
update_trigger: >
  Add a row when a fire is found. Change OPEN to CLOSED with a date when fixed.
authority: >
  Rank 1 gate. An open fire outranks all other work, including the user's
  current request, until it is contained.
---

# Security Fires

## STOP RULE (read this first)

If any row below says OPEN, halt other work now. Do the Action for that row
before you continue with anything else, including a direct user request. Tell the
user in one sentence that a fire is open and what you are doing about it. Only
after the row reads CLOSED do you return to normal work.

If every row reads CLOSED, do nothing here and continue.

The session digest shows `Security fires: N`. That count comes from this table.

## Status table

FORMAT CONTRACT: the boot script counts rows whose status cell holds the plain
word `OPEN`. Keep the status cell as exactly `OPEN` or `CLOSED`. See
`99_system/DOC_STANDARD.md` section 4.

| Fire | Status | Action |
|---|---|---|
| Fire 0: example row, delete this | CLOSED | none |

## Details

Add one block per open fire: what leaked, where it went, and the first action.

## What counts as a fire

- A credential committed to git (API key, token, password, private key).
- A private file pushed to a remote.
- A secret pasted into a note or a chat log.
- A public remote on a repository that holds personal notes.

## How to handle one

1. Add the row with status OPEN and stop other work.
2. Revoke the credential at its source first. Rotation beats cleanup: a key that
   is already revoked cannot be used, even if the old copy still exists.
3. Remove the value from the working tree and put it in `.env`.
4. Only then decide whether rewriting git history is worth it.
5. Add a `_handoff/GOTCHAS.md` entry so the same leak does not recur.
6. Set the row to CLOSED with the date.
