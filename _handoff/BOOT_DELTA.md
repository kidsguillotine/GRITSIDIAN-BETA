---
title: Boot Delta
generated: 2026-08-19T02:56
meta_status: active
purpose: Changes in OPEN_DECISIONS/IMPORTED_HANDOFFS/GOTCHAS since prior boot. Read instead of full files when < 24h stale.
update_trigger: Written by gen_session_boot.sh on every boot run.
---

# Boot Delta  (generated 2026-08-19T02:56)

Changes since 2026-08-19T02:44

### GOTCHAS (entry index)
Added:
```
### G01: delete is not reversible, and the trash tools may not exist (2026-08-19)
### G02: a cached index is a memory-sourced claim (2026-08-19)
### G03: an agent can invent folders from tag names (2026-08-19)
### G04: a wikilink with a .md extension breaks navigation (2026-08-19)
### G05: a hand edit to a generated file is erased (2026-08-19)
### G06: a format change makes entries invisible to the parser (2026-08-19)
### G07: count the status field, not the heading (2026-08-19)
### G08: `grep -c` counts lines, not files (2026-08-19)
### G09: in a basic regular expression, `\|` means "or" (2026-08-19)
### G10: awk state leaks across files in one diff (2026-08-19)
### G11: plugin settings files hold plaintext API keys (2026-08-19)
### G12: an API key in a plugin setting can silently override your subscription (2026-08-19)
### G13: credentials hide in casually named files (2026-08-19)
### G14: a rule buried as style guidance does not fire (2026-08-19)
### G15: "patch applied" is not "patch effective" (2026-08-19)
### G16: "command not found" is not "the thing does not exist" (2026-08-19)
### G17: an agent will report a generated file as updated without running the generator (2026-08-19)
### G18: check the ground truth before repeating a "blocked" claim (2026-08-19)
### G19: bulk approval inverts the review gate (2026-08-19)
### G20: check the governed vocabulary before inventing a new structure (2026-08-19)
### G21: treat AI-generated documentation as marketing, not ground truth (2026-08-19)
### G22: six recurring agent behavior failures (2026-08-19)
### G23: exported filenames can contain invisible characters (2026-08-19)
### G24: machine cache files will exhaust an agent's context (2026-08-19)
### G25: a generated digest can report another project's history (2026-08-19)
```
Removed:
```
### G01: short title of the failure (2026-08-19)
```

