---
title: The Rules (Simple English)
created: 2026-08-18
meta_status: active
purpose: >
  A short, plain version of the CLAUDE.md rules. Written in ASD-STE100
  (Simplified Technical English), a controlled writing style with short
  sentences and one idea per sentence. The full rules stay in CLAUDE.md.
update_trigger: Update when a rule in CLAUDE.md changes.
---

# The Rules (Simple English)

This page says the rules in short sentences. ASD-STE100 means Simplified
Technical English. It is a writing style. It uses short sentences. It puts one
idea in each sentence. The full rules are in `CLAUDE.md`. If the two pages
disagree, `CLAUDE.md` is correct.

## How the helper behaves

1. The helper acts when you ask. It does not act on its own.
2. The helper does one job for each instruction.
3. The helper asks one question when it is not sure. It does not guess.
4. The helper tells you a problem in one sentence. Then it waits.
5. The helper does not use memory as fact. It checks the files first.

## Before the helper changes anything important

1. The helper asks you first. This is the confirmation step.
2. The helper shows the choices. It gives a suggestion.
3. The word "ok" for one task is not "ok" for all tasks.
4. The helper waits for your answer. Then it acts.

## How the helper protects files

1. The helper never deletes a note file. It moves the file to the `.trash`
   folder. You can get the file back.
2. The helper never deletes a private file. It moves the file to a safe place.
   See [[Sensitivity and Security]].
3. The helper reads a long file fully before it removes the file.
4. The helper saves a backup before a large change. See [[Git Backup]].
5. The helper keeps a log of each move.

## How the helper writes

1. The helper does not use emojis.
2. The helper does not use long dashes.
3. The helper writes plain text.
4. The helper does not add extra features that you did not ask for.

## How the helper handles many files

1. For five files or fewer, the helper works file by file.
2. For more than five files, the helper makes a plan first.
3. The plan is a "dry run". A dry run shows the change but does not do it.
4. You read the dry run. Then the helper does the change in one step.

## Links and notes

1. The helper writes links without the `.md` end. See [[Wikilinks]].
2. The helper reads linked notes to find related facts.
3. The helper keeps index notes up to date. These live in the `_MOCs` folder.

## Where the full rules live

- `CLAUDE.md`: the complete rules.
- [[Frontmatter and Structure]]: the data block and folder layout.
- [[Glossary]]: the meaning of each technical word.
