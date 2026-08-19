---
title: Git Backup
created: 2026-08-18
meta_status: active
purpose: Explain what git does here, why the backup matters, and how the automatic snapshot works.
update_trigger: Update when the snapshot cadence or push target changes.
---

# Git Backup

The git backup is the most important safety net in this system. Read this page.

## What git is, in one line

Git is a program that saves a full snapshot of your folder each time you tell it
to. Each snapshot is a **commit**. You can go back to any commit later.

A **remote** is a copy of those snapshots on another computer, usually a private
online repository. Sending your commits there is a **push**.

## Why the backup matters

The AI helper moves, renames, and merges files. Most of the time it is right.
Sometimes a change is wrong. The git backup is what makes every change safe to
undo.

- If a change is wrong, you go back to the last good commit.
- If your disk fails, your notes are on the remote.
- If you delete the wrong thing, the commit still holds the old copy.

Without the backup, one bad bulk operation could lose work. With the backup,
nothing is truly lost. This is why the rules require a commit **before** any
large sweep (see [[The Rules (Simple English)]]).

## How the automatic snapshot works

1. A schedule (for example, once an hour) runs `hourly_snapshot.sh`.
2. The script stages every change: `git add -A`.
3. The script makes a commit with a timestamp.
4. The script pushes the commit to the remote.
5. If the push fails, the script writes the failure to a log so you see it.

This runs on its own. You do not have to remember to save.

## The session snapshot

At the end of each AI session, a hook runs `generate_handoff.sh --quick`. This
refreshes the session notes so the next session knows where you stopped. The
rules say the AI must **not** push during a session. Only the schedule pushes.
This keeps one clear owner of the backup.

## What you must set up once

1. Install git.
2. Turn this folder into a git repository: `git init`.
3. Create a private remote (for example, a private GitHub repository).
4. Connect the remote: `git remote add origin <your-remote-url>`.
5. Install the safety hooks: `.claudian/hooks/install.sh`. See
   [[Sensitivity and Security]].
6. Set the schedule that runs `hourly_snapshot.sh`.

## Keep private files out of the backup

The backup must not contain passwords, tax files, or other private data. The
`.gitignore` file and the pre-commit safety check keep them out. See
[[Sensitivity and Security]].

## Related

- [[Sensitivity and Security]]: the check that runs before each commit.
- [[The Rules (Simple English)]]: the backup-before-sweep rule.
