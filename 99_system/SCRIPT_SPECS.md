---
title: Script Specs
created: 2026-08-19
meta_status: active
purpose: >
  What the two non-obvious scripts do, when to run them, and what their checks
  mean. Replaces INTEGRITY_LAYER_SPEC.md and REBUILD_MOCS_SPEC.md, which together
  ran 464 lines of design history for scripts that already work.
update_trigger: >
  Update when a check is added to validate_system.sh or the MOC format changes.
authority: >
  Rank 4. The scripts are ground truth. This explains their output.
---

# Script Specs

Most scripts in `.claudian/scripts/` explain themselves in their header comment.
Two do not, because their output needs interpreting.

## validate_system.sh

Checks the vault's internal consistency. Run it before a session close, or any
time you suspect drift.

    bash .claudian/scripts/validate_system.sh

It prints one line per check. `OK` means the check ran and passed. `WARN` means it
could not run or found something non-blocking. `FAIL` means fix it before you
commit.

| Check | What it verifies |
|---|---|
| C1 | Every doc listed in SYSTEM_DOC_MAP actually exists (no dangling rows) |
| C2 | Every doc on disk appears in SYSTEM_DOC_MAP (no unmapped files) |
| C3 | Every symlink in SYMLINK_REGISTRY resolves |
| C4 | SCRIPT_REGISTRY matches `.claudian/scripts/` in both directions |
| C6 | MIGRATION_LOG date headers use the agreed format |
| C8 | Format-contract block markers are present and intact |
| C9 | No script uses the `grep '^\|'` trap (see gotcha G09) |
| C10 | Broken wikilink count |
| C11 | No import marked complete while its execution state says otherwise |
| C12 | Folders named in script skip-lists still exist |
| C13 | SUPERSESSION_INDEX has no unreviewed sections |

Read the count in each OK line. `OK C4: 0 entries checked` is not a pass, it is a
check that examined nothing. A validator that inspects zero files and reports OK
is the failure described in gotcha G16. If a count is unexpectedly zero, find out
why before you trust the green.

## rebuild_mocs.py

Regenerates the index notes in `_MOCs/` from the tags on your notes.

    python3 .claudian/scripts/rebuild_mocs.py

It scans notes for `#area/*` tags and writes one index note per area, listing
every note that carries the tag at its current path.

Why it is a script and not an agent job: the 2000-link navigation collapse in
gotcha G04 happened because an agent rewrote index links by following a prompt.
Regenerating from tags is mechanical, so it is a script. Do not delegate this to a
model.

Rules:

- The files in `_MOCs/` are generated. Do not hand-edit them.
- Run it after any batch that moves files, because a move invalidates every link
  that pointed at the old path.
- Wikilinks it writes carry no `.md` extension. See `wiki/Wikilinks`.
- On a fresh vault the folder stays empty, which is correct: there is nothing to
  index until notes carry tags.
