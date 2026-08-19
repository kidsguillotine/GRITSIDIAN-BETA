---
title: Open Decisions
created: 2026-08-18
meta_status: active
purpose: Pending decisions awaiting user confirmation (Explicit Confirmation Gate).
update_trigger: Append inside the PENDING block; move to Resolved when confirmed.
---

# Open Decisions

FORMAT CONTRACT: the boot scripts count entries between the two markers below.
Each pending entry is a `### OD-N: Title` header (colon delimiter) followed by a
`Status: PENDING` line. Keep the colon and the marker comments exactly. See
`99_system/DOC_STANDARD.md` section 4.

<!-- BEGIN_PENDING -->
<!-- END_PENDING -->

## Resolved

(none)

## Template for a new entry (place inside the PENDING markers)

```
### OD-1: Short title of the decision
- ts: <ISO-8601 UTC>
- context: why this decision exists
- options: A / B / C
- recommendation: one option
Status: PENDING
```
