---
id: SEAT_SPEC_integrity_layer_20260624
created: 2026-06-24
purpose: >
  Define a single referential-integrity layer for the system-doc + script +
  symlink graph. Closes the silent-failure-on-broken-reference class observed
  across G40/G41 and the 99_system consolidation map damage. Simplifies by
  collapsing duplicated state to single sources of truth and consolidating
  scattered checks into one fail-loud validator.
status: "PROPOSED: requires Claudian verification of script internals + user sign-off per item"
update_trigger: >
  A check is implemented (mark [BUILT]); a new silent-break failure mode is
  discovered (add a check row); a registry's generated-vs-judgment split changes.
authority: "spec only: does not override CLAUDE.md, OPEN_DECISIONS, or live Claudian measurement"
epistemic_note: >
  Doc-reference graph is [VERIFIED-against-uploaded-docs]. Script call-graph
  (read/write sets, count-computation sites, parser regexes) is [INFERENCE from
  transcripts + registries]: every such claim is tagged inline and must be
  confirmed by Claudian before implementation.
---

# Integrity Layer Spec

## 1. Problem

Every failure the system has hit is one disease: a reference that breaks or
drifts and fails *silently* instead of *loudly*. Four layers, same mechanism.

| Layer | Silent break | Caught today by |
|---|---|---|
| Doc | SYSTEM_DOC_MAP entry points at a trashed/moved file | nothing (orphan check is one-way) |
| Script | symlink target moved; `try/except ImportError` no-ops | only `curl :8766/health` `*_found` flags |
| Parser | append-only log line in wrong format, parser skips it | nothing (G40: colon vs em-dash) |
| Count | same metric computed by two scripts with different predicates | nothing until counts visibly disagree (G41) |

The forward orphan check (file -> is it in the map?) exists. Its mirror
(map entry -> does the file exist?) does not. Same gap repeats at every layer.

## 2. Principle (the redundancy correction)

- Redundant **state** is the cause of every bug above. One fact, one home.
- Redundant **checks** are the cure: validate the same graph at two times
  (hourly + session-close) so drift surfaces within an hour, not a session.
- Every reference is validated. Every validation fails LOUD: blocks commit or
  raises a VIP item; never a swallowed no-op.

## 3. Simplification: split each registry's columns

The four meta-docs (SYSTEM_DOC_MAP, SCRIPT_REGISTRY, SYMLINK_REGISTRY,
AUTOMATION_ROUTING) stay as separate human-facing views: they serve different
readers. But each has two kinds of column, and they must be handled differently:

| Column kind | Examples | Maintenance |
|---|---|---|
| Filesystem-knowable | file exists, path, symlink target resolves, script roster | machine-validated against disk: never the source of truth, only checked |
| Human judgment | authority rank, read-by, why-it-matters, update_trigger | hand-authored, the actual source of truth |

Stop hand-maintaining ref counts and roster lists. Either generate them or drop
them. A hand-kept "Refs: 45" that drifts to reality's 41 is a fourth drift source.

## 4. The reference graph

### 4a. Automation call graph  [INFERENCE: Claudian confirm read/write sets]

```
cron(hourly) -> hourly_snapshot.sh -> { gen_session_boot.sh, gen_vo_memory.sh } -> git commit+push (vault only)
session close -> session_close.sh -> { generate_handoff.sh --archive,
                                       reconcile_session.py (step 2b),
                                       state_hook.py, orphan check,
                                       P2/P3 checks, erosion audit } -> git commit

generate_handoff.sh  reads:  PHASE_STATE, NEXT_ACTIONS, PENDING_WORK,
                              OPEN_DECISIONS, IMPORTED_HANDOFFS, GOTCHAS, MIGRATION_LOG
                     writes: SESSION_HANDOFF_CURRENT.md, handoff_history/, erosion_audit/
                     calls:  gen_session_boot.sh
gen_session_boot.sh  reads:  OPEN_DECISIONS (OD/IH counts), MIGRATION_LOG (last-3, em-dash),
                              GOTCHAS (count), resume point
                     writes: SESSION_BOOT.md
gen_vo_memory.sh     reads:  folder schema, model routing, phase status, GOTCHAS
                     writes: obsilo-memory/knowledge.md, obsilo-memory/projects.md
```

Bug locus: gen_session_boot.sh AND generate_handoff.sh each compute the IH count
independently. That is the duplicated-computation disease (G41). Same risk exists
for OD count, security-fire count, GOTCHAS count, phase status.

### 4b. Doc-reference graph  [VERIFIED against SYSTEM_DOC_MAP]

- First-reads chain: CLAUDE.md -> SESSION_BOOT -> OPEN_DECISIONS -> IMPORTED_HANDOFFS -> GOTCHAS
- Authority precedence: SESSION_HANDOFF_CURRENT > PHASE_STATE/NEXT_ACTIONS > MASTER_PLAN_v2 > CLAUDE.md > VAULT_OPERATOR_FULL > others
- Highest blast radius (edit-with-care): MIGRATION_LOG, GOTCHAS, PHASE_STATE, MASTER_PLAN_v2, SESSION_HANDOFF_CURRENT, SAFETY_POLICY

### 4c. Script/symlink graph  [VERIFIED against SYMLINK_REGISTRY]

- One canonical file per script in your-scripts/scripts/; all other locations are
  symlinks, never copies. (your-scripts-paid DEAD/PAUSED 2026-06-26: not canonical.)
- Container risk: agent_runner.py imports siblings via symlink; missing docker
  mount -> ImportError swallowed -> interaction_log/time_context/op_log/idempotency
  silently disabled. Only `:8766/health` `*_found:true` confirms resolution.

## 5. Check set: one validator, fails loud

All run inside a single `validate_system.sh`, invoked by BOTH hourly_snapshot.sh
(cheap drift alarm) and session_close.sh (commit gate). Any non-OK line blocks
session close or raises a VIP item.

| # | Check | Direction | Closes | Claudian must supply |
|---|---|---|---|---|
| C1 | every SYSTEM_DOC_MAP file entry exists on disk -> `DANGLING:` | map -> fs | trashed-but-mapped (this session) | n/a: pure fs walk | **[BUILT 2026-06-25]** |
| C2 | every scoped .md is in SYSTEM_DOC_MAP -> `UNMAPPED:` | fs -> map | new doc with no map entry | already exists, keep | **[BUILT 2026-06-25: OD-34 option B; scope: _handoff/+99_system/ vs SYSTEM_DOC_MAP; .claudian/scripts/ vs SYMLINK_REGISTRY; non-blocking]** |
| C3 | every SYMLINK_REGISTRY symlink resolves to an existing canonical -> `BROKEN_LINK:` | registry -> fs | silent ImportError degrade | n/a: `readlink -f` + `test -e` | **[BUILT 2026-06-25]** |
| C4 | SCRIPT_REGISTRY roster == your-scripts/scripts/ .py files (two-way diff) -> `MISSING_SCRIPT:` / `UNMAPPED_SCRIPT:` | registry <-> fs | undocumented or missing scripts | n/a: set diff | **[BUILT 2026-06-25]** |
| C5 | security-fire count read from SECURITY_FIRES.md OPEN table rows (not PENDING_WORK.md checkboxes) | single source | 2-vs-3 SESSION_BOOT miscount (live bug fixed 2026-06-25) | confirmed other counts (OD/IH) already consistent | **[BUILT 2026-06-25: targeted fix; full shared-function extraction deferred]** |
| C6 | append-only log lines match the parser's canonical format -> `FORMAT_VIOLATION:` | writer <-> parser | em-dash/colon invisibility (G40) | the exact MIGRATION_LOG parse regex gen_session_boot uses | **[BUILT 2026-06-25: OD-35 option A; pattern confirmed from gen_session_boot.sh:65; non-blocking; first run: 485 historical violations (pre-em-dash era, expected)]** |
| C7 | a lower-authority doc never hand-copies a fact owned by a higher-authority doc; it derives or is validated against it | authority chain | divergence at source | list of facts duplicated across the authority chain | **[DEFERRED: OD-36 option B; semantic check requires curated fact manifest; no live C7-class failure; re-open on first observed drift event]** |
| C8 | FORMAT_CONTRACT block markers present in OPEN_DECISIONS + IMPORTED_HANDOFFS -> `WARN C8:` | doc -> parser | missing `BEGIN_PENDING` / `END_PENDING` / `BEGIN_PENDING_REVIEW` / `END_PENDING_REVIEW` markers that break gen_session_boot.sh PENDING count | n/a: grep for 4 fixed strings | **[BUILT 2026-06-25: post-spec addition; retroactively recorded here 2026-07-01]** |
| C9 | shell scripts scanned for G42 BRE `^\|` trap -> `WARN C9:` | script -> pattern | grep BRE pipe-anchor (`'^\|`) silently matches every line instead of filtering table rows | n/a: grep -rnF in .claudian/scripts/*.sh | **[BUILT 2026-06-26: post-spec addition; retroactively recorded here 2026-07-01]** |
| C10 | broken wikilink count via check_links.py -> `WARN C10:` (soft threshold ≥95% OK) | fs -> wikilinks | G44 wikilink rot undetected until manual audit | n/a: check_links.py --audit --json | **[BUILT 2026-06-25; crisis RESOLVED 2026-07-01 at 95.1%; retroactively recorded here 2026-07-01]** |
| C11 | PHASE_STATE.md COMPLETE rows vs IMPORTED_HANDOFFS.md IH status -> `IH_STALE:` | PHASE_STATE -> IMPORTED_HANDOFFS | IH-9 sat IN PROGRESS 5 days after H1-H5 COMPLETE (2026-07-01): no mechanism caught it | IMPORTED_HANDOFFS `**Status:**` field format per IH entry; PHASE_STATE IH row extraction regex | **[PROPOSED 2026-07-01: non-blocking; see §9]** |
| C12 | pipeline script `_SKIP_DIRS` non-dot folder names vs vault filesystem -> `SKIP_DIR_MISSING:` | script config -> fs | `05_pre-inbox` in 3 scripts, folder never existed; reference was copy-paste drift (caught by hand 2026-07-01) | grep `_SKIP_DIRS` from schedule_surface.py, task_surface.py, frontmatter_to_ics.py; Python set-literal parse | **[PROPOSED 2026-07-01: non-blocking; see §9]** |
| C13 | SUPERSESSION_INDEX.md AUDIT PENDING sections -> `SUPERSESSION_AUDIT_PENDING:` | doc -> action state | your-stack/docs/decision_log.md audit twice-deferred 2026-06-26 -> 2026-07-01; no mechanism surfaces age | grep `AUDIT PENDING` in SUPERSESSION_INDEX.md; extract nearest `##` header | **[PROPOSED 2026-07-01: non-blocking; see §9]** |

C1+C2+C3+C4 = full referential integrity across doc and script layers (forward,
reverse, symlink, roster). C5+C6 remove two duplicated-state root causes. C7
deferred (semantic; no live failure). C8+C9+C10 added post-spec: format-contract
integrity, BRE trap lint, wikilink count. C11+C12+C13 proposed: track/disk
divergence class: the hand-found drift pattern recurring across three sessions.

## 6. Implementation prerequisites (Claudian, before any build)

1. `grep -rn` count-computation across .claudian/scripts/ and your-scripts/scripts/
  : enumerate every site that computes OD/IH/security-fire/GOTCHAS counts (C5).
2. The exact MIGRATION_LOG line-parse regex in gen_session_boot.sh (C6).
3. Confirm the read/write sets in 4a: correct any inferred edge.
4. `find 99_system -type f | sort` post-consolidation (still outstanding from the
   prior request) so C1 has ground truth to validate against.
5. Confirm whether validate_system.sh should hard-block close on a violation or
   only write a VIP item (recommend: hard-block on DANGLING/BROKEN_LINK/ROSTER_DRIFT;
   VIP-item on UNMAPPED/FORMAT_VIOLATION).

## 7. Sequencing

1. C1 + C3 first: they catch the damage already on disk (dangling map entries
   from this session's deletes; any broken symlink). Cheapest, highest immediate value.
2. C4 + C2: roster + orphan reconcile.
3. C5: single count function. Touches generators; do after C1/C3 prove the
   validator harness works.
4. C6 + C7: format lint + authority-derivation. Lowest urgency, highest design care.

## 8. Gate

This is a spec. Each check is a separate enumerable decision; general approval is
not consent on all seven. Builds touch generators and commit gates (system-script
scope) -> Explicit Confirmation Gate + OPEN_DECISIONS entry per check before
Claudian writes. Validator runs read-only; no .trash interaction; no content moves.

---

## 9. Proposed checks (C11-C13): scoped 2026-07-01

All three are the same failure class: a tracking doc disagrees with ground truth,
and no mechanism catches it except a human deciding to look. The instances below
are the spec: they define what "divergence" means for each check.

### C11: IH completion state

**Pattern:** tracking doc says IN PROGRESS; build record says COMPLETE.
**Instance:** IH-9 IN PROGRESS in IMPORTED_HANDOFFS.md for 5 days after PHASE_STATE
recorded all required stages COMPLETE (caught by hand 2026-07-01).
**Direction:** PHASE_STATE.md (authority rank 2) -> IMPORTED_HANDOFFS.md
**Output line:** `IH_STALE: IH-N: PHASE_STATE=COMPLETE IMPORTED_HANDOFFS=<actual status>`
**Blocking:** Non-blocking: VIP item, never increments ERRORS

Implementation inputs (confirm before build):
- PHASE_STATE IH row format: `| System: IH-N <title> | [x] COMPLETE <date>: ... |`
  (filter rows: `IH-` substring in col 1; COMPLETE substring in col 2)
- IMPORTED_HANDOFFS IH entry status: `**Status:** <value>`: find nearest `## IH-N`
  heading, then scan for `**Status:**` within that block
- Scope: only IH rows that PHASE_STATE tracks: untracked IHs not checked
- Known gap: PHASE_STATE IH rows use "System: IH-N" prefix; strip to extract N

### C12: Pipeline script SKIP_DIRS vs vault filesystem

**Pattern:** script config references a vault folder that doesn't exist on disk.
**Instance:** `05_pre-inbox` in `_SKIP_DIRS` of schedule_surface.py, task_surface.py,
frontmatter_to_ics.py: folder never existed; reference was copy-paste drift
(caught by hand 2026-07-01; removed same session).
**Direction:** script `_SKIP_DIRS` set literals -> vault filesystem
**Output line:** `SKIP_DIR_MISSING: <folder>: referenced in <script> _SKIP_DIRS, not found in vault`
**Blocking:** Non-blocking: VIP item, never increments ERRORS

Implementation inputs (confirm before build):
- Target scripts (canonical paths):
  `~/Projects/gridsidian/scripts/schedule_surface.py`: `_SKIP_DIRS = {...}` multi-line set literal
  `~/Projects/gridsidian/scripts/task_surface.py`: same pattern
  `~/Projects/gridsidian/scripts/frontmatter_to_ics.py`: inline in docstring + skip list variable
- Parse strategy: awk/grep for lines between `_SKIP_DIRS` assignment and closing `}`; extract
  quoted strings; filter dot-prefixed (`.trash`, `.git`, `.obsidian` etc.): those are
  infrastructure, OK if absent
- Underscore-prefixed dirs (`_parsing`) are vault-local paths: check existence
- Check: `test -d "$VAULT/<folder>"` for each non-dot entry

### C13: SUPERSESSION_INDEX AUDIT PENDING surface

**Pattern:** a SUPERSESSION_INDEX section is marked AUDIT PENDING and ages without
a mechanism to surface it at close.
**Instance:** `your-stack/docs/decision_log.md` section has been AUDIT PENDING
since OD-41 (2026-06-26); deferred twice without any session-close flag (2026-07-01).
**Direction:** SUPERSESSION_INDEX.md content (text scan)
**Output line:** `SUPERSESSION_AUDIT_PENDING: <section header>: AUDIT PENDING in SUPERSESSION_INDEX.md`
**Blocking:** Non-blocking: VIP item, never increments ERRORS

Implementation inputs (confirm before build):
- Single grep: `grep -n "AUDIT PENDING" "$VAULT/99_system/SUPERSESSION_INDEX.md"`
- For each hit, walk backward to find the nearest `##` header: that's the section name
- Emit one output line per section with AUDIT PENDING text
- Extends automatically: any future AUDIT PENDING blocks in new sections surface without
  code change
