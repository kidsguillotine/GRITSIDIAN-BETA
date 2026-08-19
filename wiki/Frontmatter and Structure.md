---
title: Frontmatter and Structure
created: 2026-08-18
meta_status: active
purpose: Plain explanation of the data block at the top of a note and the folder layout, with a link to the formal spec.
update_trigger: Update when the frontmatter fields or folder layout change.
---

# Frontmatter and Structure

## Is there a formal spec? Yes.

The formal rules live in `99_system/DOC_STANDARD.md`. It lists the required
fields, the naming rules, and the format contracts. The folder layout lives in
`99_system/FOLDER_SCHEMA.md`. Both are referenced from `CLAUDE.md` and listed in
`99_system/SYSTEM_DOC_MAP.md`. This page is the plain-English summary.

## What frontmatter is

**Frontmatter** is a small block of data at the top of a note. It sits between
two lines of three dashes. It holds facts about the note, not the note's content.

```
---
title: My Note
created: 2026-08-18
meta_status: active
---
```

Obsidian shows this as "Properties". In Word terms, it is like the document
properties panel, but you can read it as plain text.

## The required fields (for system notes)

System notes in `_handoff/` and `99_system/` must have these fields:

- `title`: the note's name in plain words.
- `created`: the date you made it.
- `meta_status`: the note's state. `active` means live and in use.
- `purpose`: one or two sentences on what the note is for.
- `update_trigger`: the event that means "update this note".

Normal notes (ideas, tasks) do not need all of this. Only system notes do.

## Why meta_status matters

The AI reads `meta_status` before it trusts a note. `active` means the note is
true now. `superseded` or `archived` means the note is old history. The AI does
not act on old notes. This stops the AI from repeating a dead decision.

## The folder layout

The top folders sort notes by life area:

- `00_inbox`: new, unsorted notes.
- `10_active`: current work.
- `20_personal`, `30_career`, `40_technical`, `50_notes`, `60_creative`: by topic.
- `70_manual_review`: the AI put it here because it was not sure.
- `80_archive`: old, kept for reference.
- `99_system`: the system's own docs.
- `_MOCs`: index notes. See [[Wikilinks]].
- `_handoff`: session notes and logs.

Full detail: `99_system/FOLDER_SCHEMA.md`.

## Related

- [[Wikilinks]]: how notes link.
- [[The Rules (Simple English)]]: how the AI uses meta_status.
- `99_system/DOC_STANDARD.md`: the formal spec.
