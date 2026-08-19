---
title: Wikilinks
created: 2026-08-18
meta_status: active
purpose: Explain how notes link to each other and the one hard rule about the .md end.
update_trigger: Update when the wikilink rule or the link checker changes.
---

# Wikilinks

A **wikilink** is how one note points to another. You write two square brackets
around the note name.

## How to write a link

- `[[Getting Started]]` links to the note named "Getting Started".
- `[[folder/note]]` links to a note in a folder.
- `[[note|shown text]]` links to "note" but shows "shown text".

Click the link in Obsidian to open the other note. This is what makes a set of
notes into a web, like a small private wikipedia.

## The one hard rule: no `.md` end

Never put `.md` at the end of a wikilink.

- Correct: `[[note]]`
- Wrong: `[[note.md]]`

Obsidian looks up the link by the note's short name. `note.md` is not a short
name, so the link fails. If an AI helper repeats the mistake, it can grow worse,
like `[[note.md.md]]`. The pre-commit check blocks this. See
[[Sensitivity and Security]].

## Images are different

An image embed keeps its end. Write `![[picture.png]]` to show a picture. The `!`
at the front and the file end are correct here. An image is media, not a
wikilink.

## The link checker

The script `check_links.py` finds broken links.

- Count broken links: `python3 .claudian/scripts/check_links.py --count-broken`.
- Fix `.md`-end links: `python3 .claudian/scripts/check_links.py --fix`.

On a fresh vault the count is zero. Keep it near zero as you add notes.

## Maps of Content

The `_MOCs` folder holds index notes. Each index note links to many notes on one
topic. The script `rebuild_mocs.py` keeps them current. Do not edit them by hand.

## Related

- [[Sensitivity and Security]]: the pre-commit check that blocks bad links.
- [[Frontmatter and Structure]]: the data block at the top of a note.


<!-- vault-operator:incoming-links -->

> [!relation-in]- 15 Notes link here
> | Note |
> | --- |
> | [[Frontmatter and Structure]] |
> | [[Glossary]] |
> | [[Home]] |
> | [[SCRIPT_REGISTRY]] |
> | [[SCRIPT_REGISTRY]] |
> | [[Sensitivity and Security]] |
> | [[SESSION_HANDOFF_20260604_v0]] |
> | [[SESSION_HANDOFF_20260604_v1]] |
> | [[SESSION_HANDOFF_20260604_v2]] |
> | [[SESSION_HANDOFF_20260604_v3]] |
> | [[SESSION_HANDOFF_20260605_v0]] |
> | [[SESSION_HANDOFF_20260605_v1]] |
> | [[SESSION_HANDOFF_20260605_v2]] |
> | [[SESSION_HANDOFF_20260605_v3]] |
> | [[The Rules (Simple English)]] |
<!-- /vault-operator:incoming-links sha="8933bb3" -->
