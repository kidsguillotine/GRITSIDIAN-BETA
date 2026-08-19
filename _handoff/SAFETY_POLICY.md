---
title: Deletion and Backup Safety Policy
created: 2026-08-19
meta_status: standing-rule
purpose: >
  The permanent safety rules for deleting files and for keeping backups. This
  policy is why the system exists. It does not get archived or overwritten by
  session state. CLAUDE.md points here before any delete, sweep, or bulk move.
update_trigger: >
  Append a rule when a new loss or near-loss happens. Never remove a rule.
authority: >
  Standing rule. Equal in force to the CLAUDE.md hard prohibitions. If this file
  and any other doc disagree, this file wins on deletion and backup questions.
---

# Deletion and Backup Safety Policy

This policy exists because file loss is permanent and note loss is silent. Read
it before you delete anything.

## Part 1: the nine hard rules

1. `rm` is BANNED for content files (`.md`, `.txt`, `.csv`).
   Move the file instead: `mv <file> <vault>/.trash/<unique-name>`. The Obsidian
   trash folder is reversible. Only these may use `rm`: `.tmp`, `.lock`, `.swp`,
   byte-identical duplicates confirmed by `md5sum`, and empty files (`wc -c` is 0).

2. No file longer than 30 lines may be deleted without a full read.
   Reading the first 5 lines is for routing. It is not evidence for a delete.

3. Extract before delete. When a file mixes value with noise:
   write the valuable part to a new note, add a source line
   (`## Source: <original-path>, extracted <date>`), log it in
   `_handoff/MIGRATION_LOG.txt`, then move the original to `.trash/`.

4. When in doubt, archive. ARCHIVE is the default for an unclear file, not
   DELETE. Disk space is cheap. Lost personal data is not.

5. An agent NEVER deletes a personal data file. If the name matches a sensitive
   pattern, route it to the review folder or the sensitive store and stop. See
   `wiki/Sensitivity and Security`.

6. A file that looks like junk may hold original thinking. Exported notes with
   odd names and hash suffixes default to ARCHIVE.

7. Before deleting a large dump file, sample it at five offsets
   (`sed -n '100p;500p;1000p;5000p;9000p' file`). Confirm it is uniform machine
   output and not a mixed document.

8. A file judged only by its name gets ARCHIVE, never DELETE. A filename is not
   sufficient evidence of low value.

9. Never start a structural sweep without a git commit first. Run
   `bash .claudian/scripts/pre-sweep.sh` to take the checkpoint.

## Part 2: the backup policy, and what the cron does

The backup is the other half of safety. Rule 1 makes a delete reversible for a
few days. Git makes every change reversible forever.

### What runs automatically

`.claudian/scripts/hourly_snapshot.sh` is meant to run on a schedule (a cron job
or a systemd timer). Each run does exactly three things, on the vault repo only:

1. `git add -A` (stage everything that changed)
2. `git commit --allow-empty` with a timestamp message
3. `git push` to your remote

If the push fails, the script appends a line to
`_handoff/PUSH_INCONGRUENCE.md`. A non-empty log means your backup is not
reaching the remote. Fix that before you close a session.

### The cron rules

- The cron commits EVERYTHING that is not ignored. This is deliberate: a backup
  with gaps is not a backup. It also means `.gitignore` is the only thing
  standing between a private file and your remote. Get `.gitignore` right first,
  then enable the cron. Verify with `git status --short` before the first run.
- The cron touches ONE repository: this vault. It must never run `git add`,
  `git commit`, or `git push` in any other repo.
- The cron is the only thing that pushes. An agent must never `git push` during
  a session. One owner for the backup means no surprise history.
- An agent may commit (for example at session close). Only the schedule pushes.
- Use a PRIVATE remote. The vault holds personal notes.
- An empty commit each hour is normal and intended. It proves the timer is alive.

### Before you enable the cron

1. `git init`, then add a private remote.
2. Install the hooks: `.claudian/hooks/install.sh`. The pre-commit hook is the
   guard that blocks sensitive filenames and secrets. See
   `wiki/Sensitivity and Security`.
3. Confirm `.gitignore` covers your sensitive store, `.env`, and any private
   folder.
4. Run one manual `bash .claudian/scripts/hourly_snapshot.sh` and read the
   output before scheduling it.

### Restore

To see history: `git log --oneline`. To recover one file:
`git checkout <commit> -- <path>`. To inspect an old state without changing
anything: `git show <commit>:<path>`.
