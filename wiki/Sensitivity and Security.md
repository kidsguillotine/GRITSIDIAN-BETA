---
title: Sensitivity and Security
created: 2026-08-18
meta_status: active
purpose: >
  Explain the sensitivity split, what triggers the pre-commit safety check and
  what it does, and the security-fires protocol.
update_trigger: Update when the sensitive-pattern set, the hook checks, or the fires protocol change.
---

# Sensitivity and Security

This page has three parts: the split, the safety check before a save, and the
fires protocol.

## 1. The sensitivity split

Not all files are equal. The system sorts them into three buckets.

**Bucket A: normal notes.** Ideas, projects, tasks, reference. These go into the
git backup. See [[Git Backup]].

**Bucket B: private files.** Money, tax, health, contacts, passwords in a file,
ID scans. These must never enter the git backup. The system moves them to a
**sensitive store**, a folder that sits outside git. The `.gitignore` file also
blocks their folders.

**Bucket C: secrets.** API keys, tokens, passwords in text. These belong only in
a `.env` file. A `.env` file is a small settings file that git ignores. Secrets
never go in a note.

The rule: the helper **routes** a private file. It never deletes it. See
[[The Rules (Simple English)]].

### What counts as private (the pattern set)

A file is private if its name contains any of these words:

`CRM, password, passwd, recovery, backup, ancestry, finance, paystub,
Offer_Letter, Employment_Agreement, Direct_Deposit, I-9, FormI9, W-2, W-4, SSN,
credentials`. Any `.csv` in a finance folder counts too.

Note: a date on the end of a name (for example `taxes_2026-04.md`) can hide the
word from a simple check. So a full-path scan is used, not just the file name.

## 2. The safety check before a save (pre-commit)

### What triggers it

The check is a **pre-commit hook**. A hook is a small script that git runs on its
own. This one runs every time you make a commit, after you install it with
`.claudian/hooks/install.sh`. You do not call it by hand. It looks only at the
files you staged for that commit.

### What it does

The check runs three tests. If any test fails, the commit stops and the hook
prints how to fix it.

1. **Private filename test.** It blocks the commit if a staged file name matches
   the pattern set above. A short whitelist skips known-safe names (for example
   navigation files). Fix: move the file to the sensitive store, or unstage it
   with `git restore --staged <path>`.

2. **Secret content test.** It scans the staged text for key shapes: OpenAI keys
   (`sk-...`), Google keys (`AIza...`), Amazon keys (`AKIA...`), private-key
   headers, Slack tokens, and UUID-shaped tokens next to the words "token",
   "secret", or "api_key". It does not print the match, to avoid a second leak.
   Fix: remove the secret, put it in `.env`, and re-stage.

3. **Wikilink test.** It blocks a new `[[note.md]]` link in note text, because
   the `.md` end breaks the link. Examples inside backticks are allowed. See
   [[Wikilinks]]. Fix: write `[[note]]` with no `.md`, or run
   `check_links.py --fix`.

There is also a separate guard, `rm-guard.sh`, that stops the AI from deleting a
`.md`, `.txt`, or `.csv` file. It runs before the delete, not at commit time.

### Bypass

You can skip the hook with `git commit --no-verify`. Do this only when you are
sure. The AI must never skip the hook without your clear "yes".

## 3. The security-fires protocol

A **security fire** is an open security problem that must be handled first, before
any other work.

1. When a fire is found, it is written to
   `_handoff/vip_next_session/SECURITY_FIRES.md`.
2. At the start of each session, the boot digest shows a line:
   `Security fires: N`.
3. If N is zero, work continues as normal.
4. If N is above zero, the agent reads `SECURITY_FIRES.md` first. It does the
   listed action before anything else.
5. When the problem is fixed, the entry is marked RESOLVED with a date.

This makes a leak impossible to ignore. The count sits at the top of every
session until the fire is closed.

## Related

- [[Git Backup]]: what the backup holds and how private files stay out of it.
- [[The Rules (Simple English)]]: the never-delete and route rules.
- `.gitignore` in the top folder: the folders git ignores.
