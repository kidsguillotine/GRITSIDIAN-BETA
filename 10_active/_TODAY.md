---
title: "TODAY: daily surface"
created: 2026-06-23
meta_status: active
purpose: >
  Single landing-page surface for daily vault use. Pulls recent captures,
  active items, pending decisions, and inbox state into one view via
  Dataview queries. Edit the queries to tune what surfaces; never edit
  the results (Dataview owns the result blocks).
update_trigger: >
  Adjust queries when the surfacing pattern drifts (e.g. a new tag, a
  folder reshuffle, query returning too much/too little).

tags:
  - "#area/technical"
  - "#type/task"
---

# TODAY

This note needs the Dataview plugin. Without it you see the query text instead
of results. See `wiki/Plugins`.

> Single morning/evening surface. All blocks are live Dataview queries.
> They update when you reload the note. Click any result row to open it.

## Recently captured (last 24h)

```dataview
TABLE WITHOUT ID
  file.link AS "Note",
  file.folder AS "Folder",
  dateformat(file.mtime, "HH:mm") AS "When"
FROM "00_inbox" OR "10_active" OR "20_personal" OR "30_career" OR "40_technical" OR "50_notes" OR "60_creative"
WHERE file.mtime >= date(today) - dur(1 day)
SORT file.mtime DESC
LIMIT 15
```

## Inbox state

```dataview
TABLE WITHOUT ID
  file.folder AS "Inbox folder",
  length(rows) AS "File count"
FROM "00_inbox"
WHERE !contains(file.path, ".trash")
GROUP BY file.folder
SORT length(rows) DESC
```

## Active items (frontmatter status)

```dataview
LIST
FROM "10_active" OR "30_career" OR "40_technical"
WHERE meta_status = "active" OR status = "active" OR contains(file.tags, "#status/active")
SORT file.mtime DESC
LIMIT 20
```

## Stale active (active but untouched >7 days)

```dataview
TABLE WITHOUT ID
  file.link AS "Note",
  dateformat(file.mtime, "yyyy-MM-dd") AS "Last touched"
FROM "10_active" OR "30_career" OR "40_technical"
WHERE (meta_status = "active" OR status = "active") AND file.mtime < date(today) - dur(7 days)
SORT file.mtime ASC
LIMIT 10
```

## Pending decisions (link)

See [[_handoff/OPEN_DECISIONS]]. The PENDING block lists every decision that
awaits your call. An item there blocks automation and memory commits.

## Open fires (link)

See [[_handoff/vip_next_session/SECURITY_FIRES]]. A row marked OPEN outranks
all other work. Surfaced here so it stays visible.

---

## Tuning notes

- A query returns too much: tighten `LIMIT` or add a filter
- A query returns too little: check that your notes carry the expected
  frontmatter (`meta_status: active`) or tag (`#status/active`)
- You added a folder: update the `FROM` clauses
- Query syntax: see Dataview docs or `[[99_system/CAPTURE_QUICKREF]]`
