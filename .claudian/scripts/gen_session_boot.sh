#!/usr/bin/env bash
# gen_session_boot.sh: Generate _handoff/SESSION_BOOT.md
# ========================================================
# Generates the single-file fast-load for session start.
# Replaces the 6-file canonical first-read with one ~50-line file.
# Target: ~200 tokens (vs ~40% of session budget for the 6-file protocol).
#
# Called by:
#   generate_handoff.sh : at session close (always fresh at boot)
#   hourly_snapshot.sh  : after commit (keeps file ≤1 hour stale)
#
# Standalone: bash .claudian/scripts/gen_session_boot.sh
#
# Output: _handoff/SESSION_BOOT.md (always overwritten)

set -uo pipefail

VAULT="${VAULT:-__VAULT_ROOT__}"
OUT="$VAULT/_handoff/SESSION_BOOT.md"
TS="$(date '+%Y-%m-%dT%H:%M')"

# -- Resume point --------------------------------------------------------------
# Last commit with "session close" in the message; fall back to latest commit.
# Only trust git when the vault is its own repository. If this folder sits inside
# a DIFFERENT repo (for example an export folder inside another vault), git would
# report the OUTER repo's history and the digest would state another project's
# state as fact. Fail closed instead.
GIT_TOP="$(git -C "$VAULT" rev-parse --show-toplevel 2>/dev/null)"
if [ "$GIT_TOP" != "$VAULT" ]; then
    if [ -n "$GIT_TOP" ]; then
        RESUME="(not a git repo yet: this folder is inside $GIT_TOP, whose history is not this vault's. Run git init here.)"
    else
        RESUME="(no git history yet: run git init, then see wiki/Git Backup)"
    fi
else
RESUME="$(git -C "$VAULT" log --oneline --grep="session close" -1 --pretty="%s" 2>/dev/null)"
if [ -z "$RESUME" ]; then
    RESUME="$(git -C "$VAULT" log --oneline -1 --pretty="%s" 2>/dev/null || echo '(no git history)')"
fi
fi

# -- Open Decisions count + titles ---------------------------------------------
# Count/list only ODs whose "Status: PENDING" field is set inside the block.
# Bold markers are optional: plain "Status:" is preferred (no bold-header slop).
# Heading-count was wrong when resolved ODs were left in PENDING block without
# being moved: same class as G41 (IH fix). Status field is canonical;
# block membership is a presentation layer that may lag.
OD_COUNT=0
OD_LIST=""
cur_id=""
cur_title=""
while IFS= read -r line; do
    if [[ "$line" =~ ^"### OD-"([0-9]+)": "(.*) ]]; then
        cur_id="${BASH_REMATCH[1]}"
        cur_title="${BASH_REMATCH[2]}"
    elif [[ -n "$cur_id" ]] && [[ "$line" =~ (\*\*)?Status:(\*\*)?[[:space:]]+PENDING[[:space:]]*$ ]]; then
        (( OD_COUNT++ )) || true
        OD_LIST+="  OD-${cur_id}: ${cur_title}"$'\n'
        cur_id=""
    fi
done < <(awk '/BEGIN_PENDING/{p=1;next} /END_PENDING/{p=0} p' \
              "$VAULT/_handoff/OPEN_DECISIONS.md" 2>/dev/null)

# -- Imported Handoffs pending count -------------------------------------------
# Count entries with "Status: PENDING REVIEW" (not RESOLVED) inside the block.
IH_COUNT="$(awk '
    /BEGIN_PENDING_REVIEW/{p=1;next}
    /END_PENDING_REVIEW/{p=0}
    p && /\*\*Status:\*\* PENDING REVIEW/{n++}
    END{print n+0}
' "$VAULT/_handoff/IMPORTED_HANDOFFS.md" 2>/dev/null)"

# -- Security fires: count from SECURITY_FIRES.md status table ---------------
# Source of truth: table rows containing "OPEN" in the status tracking table.
# C5 fix (2026-06-25): replaces PENDING_WORK.md checkbox count (was 2; actual
# source has 3: Fire 3/Anthropic key was added to SECURITY_FIRES.md without a
# corresponding PENDING_WORK.md checkbox, causing a 2-vs-3 miscount at session
# start). Now both this script and the source file agree on the same count.
# OD-44(B): `grep -c` always prints a count (even 0) and exits non-zero on
# no-match: the `|| echo 0` fallback would then APPEND a second "0", producing
# "0\n0" and crashing later `-gt` tests. Drop the fallback; pipe a sanitize
# tail through `head -1 | tr -dc 0-9` so the var is guaranteed clean.
SEC_COUNT="$(grep -cE '^\|.*OPEN' \
    "$VAULT/_handoff/vip_next_session/SECURITY_FIRES.md" 2>/dev/null \
    | head -1 | tr -dc '0-9')"
SEC_COUNT="${SEC_COUNT:-0}"

# Named OPEN fires: parse table rows matching '| Fire N: <title> | OPEN'.
# Provides per-fire visibility rather than an opaque count (D-A.1, 2026-07-06).
SEC_NAMED=""
while IFS= read -r line; do
    label="$(echo "$line" | awk -F'\\|' '{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}')"
    [ -n "$label" ] && SEC_NAMED+="  ${label}: OPEN"$'\n'
done < <(grep -E '^\|.*OPEN' "$VAULT/_handoff/vip_next_session/SECURITY_FIRES.md" 2>/dev/null)

# -- Push incongruence (active failures in PUSH_INCONGRUENCE.md) ---------------
PUSH_FAIL_COUNT="$(grep -c '^- [0-9]\{4\}-.*push failed' "$VAULT/_handoff/PUSH_INCONGRUENCE.md" 2>/dev/null; true)"

# -- Last 3 MIGRATION_LOG date-header entries ----------------------------------
# Grab lines starting with "YYYY-MM-DD" (entry separators), last 3.
MLOG="$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}: ' \
             "$VAULT/_handoff/MIGRATION_LOG.txt" 2>/dev/null \
     | tail -3)"

# -- GOTCHAS count + mtime -----------------------------------------------------
GOTCHAS_COUNT="$(grep -cE '^#{2,3} G[0-9]+' "$VAULT/_handoff/GOTCHAS.md" 2>/dev/null | head -1 | tr -dc '0-9')"
GOTCHAS_COUNT="${GOTCHAS_COUNT:-0}"
GOTCHAS_MTIME="$(stat -c '%Y' "$VAULT/_handoff/GOTCHAS.md" 2>/dev/null \
               | xargs -I{} date -d @{} '+%Y-%m-%d' 2>/dev/null || echo 'unknown')"

# GOTCHAS active-index: one line per entry (ID + title). GOTCHAS is append-only
# permanent; no per-entry status field. Full index surfaces the old-and-unchanged
# hazard class BOOT_DELTA is structurally blind to (D-A.2, 2026-07-06).
GOTCHAS_INDEX="$(grep -E '^### G[0-9]+: ' "$VAULT/_handoff/GOTCHAS.md" 2>/dev/null \
    | sed 's/^### //')"

# -- Erosion audit: latest file, drop count ----------------------------------
# Surfaces silently-dropped records (T7 / IH-9: wire in so drops are seen at boot)
EROSION_DIR="$VAULT/_handoff/erosion_audit"
EROSION_LATEST="$(ls -t "$EROSION_DIR/"*.md 2>/dev/null | head -1)"
EROSION_DROPS=0
EROSION_FILE=""
if [ -n "$EROSION_LATEST" ]; then
    EROSION_FILE="$(basename "$EROSION_LATEST")"
    # Count diff-removal lines: "^-" but not "---" separators
    EROSION_DROPS="$(grep -cE '^-[^-]' "$EROSION_LATEST" 2>/dev/null | head -1 | tr -dc '0-9')"
    EROSION_DROPS="${EROSION_DROPS:-0}"
fi

# -- Expired-trigger check for DEFERRED.md (IH-13 decision 2, 2026-07-02) -----
# Non-blocking C14 check: scan DEFERRED.md ACTIVE block for entries whose
# `re_surface_trigger:` value is an ISO date <= today. Named-event triggers
# are opaque to grep and are excluded: they rely on the event holder to
# re-surface. Surfaces one line per expired entry; empty when clean.
DEFERRED_EXPIRED=""
DEFERRED_FILE="$VAULT/_handoff/DEFERRED.md"
if [ -f "$DEFERRED_FILE" ]; then
    TODAY_ISO="$(date +%Y-%m-%d)"
    DEFERRED_EXPIRED="$(awk -v today="$TODAY_ISO" '
        /BEGIN_ACTIVE/{in_active=1;next}
        /END_ACTIVE/{in_active=0}
        !in_active{next}
        /^### /{sub(/^### /,"");id=$0}
        /re_surface_trigger:/{
            # Match "re_surface_trigger:" followed by an ISO date (YYYY-MM-DD).
            if (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
                d = substr($0, RSTART, RLENGTH)
                if (d <= today) {
                    printf "  %s (trigger %s expired)\n", id, d
                }
            }
        }
    ' "$DEFERRED_FILE" 2>/dev/null)"
fi

# -- Staleness counter (IH-13 decision 3, N=5, 2026-07-02) --------------------
# TSV state file: id \t boot_count \t first_seen_ts. Update each boot:
#   - Current active IDs (ODs PENDING + IHs PENDING REVIEW): increment count,
#     add row if new.
#   - IDs no longer active: prune.
# Emit any row with boot_count >= 5 as a staleness-fork line: item has
# outlived N boots without action; force choice next session.
STALENESS_FILE="$VAULT/_handoff/staleness_counter.tsv"
STALENESS_N=5
STALE_SURFACE=""

# Collect current active-item IDs from OD_LIST + IH pending block.
CURRENT_IDS_TMP="$(mktemp)"
if [ -n "$OD_LIST" ]; then
    echo "$OD_LIST" | awk '/OD-/{ if (match($0, /OD-[0-9]+/)) print substr($0, RSTART, RLENGTH) }' >> "$CURRENT_IDS_TMP"
fi
awk '
    /BEGIN_PENDING_REVIEW/{p=1;next}
    /END_PENDING_REVIEW/{p=0}
    p && /^### IH-[0-9]+/{
        if (match($0, /IH-[0-9]+/)) print substr($0, RSTART, RLENGTH)
    }
' "$VAULT/_handoff/IMPORTED_HANDOFFS.md" 2>/dev/null | while read -r ih_id; do
    # Only count IH IDs whose Status is PENDING REVIEW: awk above emitted them
    # from within the block so already filtered. Still, verify by re-check:
    if grep -A5 "^### $ih_id\b" "$VAULT/_handoff/IMPORTED_HANDOFFS.md" 2>/dev/null \
        | grep -q '\*\*Status:\*\* PENDING REVIEW'; then
        echo "$ih_id"
    fi
done >> "$CURRENT_IDS_TMP"

# Load prior counter if present.
declare -A PRIOR_COUNT PRIOR_TS
if [ -f "$STALENESS_FILE" ]; then
    while IFS=$'\t' read -r sid scount sts; do
        [ -z "$sid" ] && continue
        PRIOR_COUNT["$sid"]="$scount"
        PRIOR_TS["$sid"]="$sts"
    done < "$STALENESS_FILE"
fi

# Compose new counter file and staleness-fork lines.
NEW_COUNTER_TMP="$(mktemp)"
NOW_ISO="$(date +%Y-%m-%dT%H:%M)"
while IFS= read -r cur_id; do
    [ -z "$cur_id" ] && continue
    prior="${PRIOR_COUNT[$cur_id]:-0}"
    new_count=$((prior + 1))
    first_ts="${PRIOR_TS[$cur_id]:-$NOW_ISO}"
    printf '%s\t%s\t%s\n' "$cur_id" "$new_count" "$first_ts" >> "$NEW_COUNTER_TMP"
    if [ "$new_count" -ge "$STALENESS_N" ]; then
        STALE_SURFACE+="  ${cur_id} (${new_count} boots since ${first_ts%%T*})"$'\n'
    fi
done < "$CURRENT_IDS_TMP"

mv "$NEW_COUNTER_TMP" "$STALENESS_FILE"
rm -f "$CURRENT_IDS_TMP"

# -- Last session token metrics (SPEC_D5, 2026-07-03) ------------------------
# Reads the last row of TOKEN_LOG.tsv. Run token_report.py to add new rows.
# Columns: ts  session_id  input_tok  cache_create_tok  cache_read_tok
#          output_tok  total_tok  boot_turns  total_turns  boot_input_pct
#          tool_result_bytes
TOKEN_LOG_FILE="$VAULT/_handoff/TOKEN_LOG.tsv"
D5_LINE=""
if [ -f "$TOKEN_LOG_FILE" ]; then
    LAST_TOK_ROW="$(tail -1 "$TOKEN_LOG_FILE")"
    if [ -n "$LAST_TOK_ROW" ] && ! echo "$LAST_TOK_ROW" | grep -q '^ts'; then
        D5_DATE="$(echo "$LAST_TOK_ROW" | cut -f1 | cut -c1-10)"
        D5_IN="$(echo "$LAST_TOK_ROW"  | cut -f3)"
        D5_CR="$(echo "$LAST_TOK_ROW"  | cut -f5)"
        D5_OUT="$(echo "$LAST_TOK_ROW" | cut -f6)"
        D5_PCT="$(echo "$LAST_TOK_ROW" | cut -f10)"
        D5_KB=$(( $(echo "$LAST_TOK_ROW" | cut -f11 | tr -dc '0-9') / 1024 ))
        D5_LINE="Last session (${D5_DATE}): in=${D5_IN} cache_r=${D5_CR} out=${D5_OUT} boot=${D5_PCT}% result=${D5_KB}KB"
    fi
fi

# -- Unreviewed agent_memory count (IH-14 item 4, 2026-07-02) -----------------
# Records captured non-interactively by Path B session_close.sh §4.5 sit at
# status='unreviewed' pending human review. Surfacing the count here feeds the
# approved staleness fork: a queue that sits N sessions forces the fork.
# Without this line the unreviewed queue becomes the next buried surface.
UNREVIEWED_COUNT=0
if [ -f "__HOME__/.local/share/agent_memory/memory.db" ]; then
    UNREVIEWED_COUNT="$(sqlite3 __HOME__/.local/share/agent_memory/memory.db \
        "SELECT COUNT(*) FROM memory WHERE status='unreviewed'" 2>/dev/null | \
        tr -dc '0-9' | head -c 10)"
    UNREVIEWED_COUNT="${UNREVIEWED_COUNT:-0}"
fi

# -- Wikilink count (G44 crisis resolved 2026-07-01) --------------------------
# Surface broken-wikilink count at every session start. G44 crisis resolved;
# scope is now active navigable content only (archives, generated, plugin
# assets excluded: see check_links.py EXCLUDE_PREFIXES). Current floor is
# ~23 intentional placeholders; treat counts near that floor as stable.
# Trend up from floor = regression. Backed by check_links.py --audit --json.
WIKI_BROKEN=""
WIKI_TOTAL=""
WIKI_OK_PCT=""
WIKI_JSON="$(python3 "$VAULT/.claudian/scripts/check_links.py" --audit --json 2>/dev/null)"
if [ -n "$WIKI_JSON" ]; then
    read -r WIKI_BROKEN WIKI_TOTAL WIKI_OK_PCT < <(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['broken'], d['total'], d['ok_rate_pct'])" "$WIKI_JSON" 2>/dev/null)
fi

# -- Recent decisions from agent_memory (R3: OD-44A read-back) ---------------
# Surfaces the most recent captured decisions at session start, closing the
# read-back half of the G47 binding-gap pattern. If agent_memory.py is absent
# or the DB is empty, the section is omitted (silent OK). Output format:
#   - YYYY-MM-DD topic: text (truncated to ~100 chars)
RECENT_DECISIONS=""
AGENT_MEM_SCRIPT="__SCRIPTS_ROOT__/scripts/agent_memory.py"
if [ -x "$AGENT_MEM_SCRIPT" ] || [ -f "$AGENT_MEM_SCRIPT" ]; then
    RECENT_DECISIONS="$(python3 - "$AGENT_MEM_SCRIPT" 2>/dev/null <<'PYEOF'
import sys, os, importlib.util
spec = importlib.util.spec_from_file_location("agent_memory", sys.argv[1])
am = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(am)
    rows = list(am.active())[:5]
    for r in rows:
        # row shape: (id, type, topic, ts, text)
        ts = (r[3] or "")[:10]
        topic = (r[2] or "general")[:24]
        text = (r[4] or "").replace("\n", " ")[:100]
        print(f"  - {ts} [{topic}] {text}")
except Exception as exc:
    print(f"  (agent_memory read failed: {type(exc).__name__})", file=sys.stderr)
PYEOF
)"
fi

# -- VIP next session active items ---------------------------------------------
VIP_FILES=""
for f in "$VAULT/_handoff/vip_next_session/"*.md; do
    [ -f "$f" ] || continue
    STATUS="$(awk '/^---/{h++} h==1 && /meta_status:/{print; exit}' "$f" 2>/dev/null)"
    if echo "$STATUS" | grep -qE 'active-vip|active-fire|pending-user-action'; then
        STATUS_VAL="$(echo "$STATUS" | sed 's/.*meta_status:[[:space:]]*//')"
        VIP_FILES+="  $(basename "$f") [${STATUS_VAL}]"$'\n'
    fi
done

# -- M1 Telemetry (SPEC_D1, 2026-07-03) ---------------------------------------
# Three inhabitation lines: daily note freshness, drain backlog, weekly captures.
DAILY_DIR="$VAULT/20_personal/daily"
LAST_DAILY="$(ls -t "$DAILY_DIR"/*.md 2>/dev/null | head -1)"
M1_DAILY_DAYS="unknown"
M1_DAILY_DATE="none"
if [ -n "$LAST_DAILY" ]; then
    M1_DAILY_DATE="$(basename "$LAST_DAILY" .md)"
    TODAY_EPOCH="$(date +%s)"
    LAST_EPOCH="$(date -d "$M1_DAILY_DATE" +%s 2>/dev/null || echo "$TODAY_EPOCH")"
    M1_DAILY_DAYS=$(( (TODAY_EPOCH - LAST_EPOCH) / 86400 ))
fi

# DRAIN_REVIEW pending = drain.py HTML-comment markers that are NOT resolved.
# Fixed 2026-07-05: previous pattern grep'd bare 'MANUAL_REVIEW' which matched
# the file's own instruction prose (frontmatter + how-to-use block), producing
# false "3 pending" when the file was actually empty. drain.py writes markers
# as '<!-- MANUAL_REVIEW: ... -->'; resolved variants use the same prefix.
M1_DRAIN_ALL="$(grep -c '<!-- MANUAL_REVIEW:' "$VAULT/_handoff/DRAIN_REVIEW.md" 2>/dev/null \
    | head -1 | tr -dc '0-9')"
M1_DRAIN_DONE="$(grep -cE '<!-- MANUAL_REVIEW_(APPROVED|DECLINED):' "$VAULT/_handoff/DRAIN_REVIEW.md" 2>/dev/null \
    | head -1 | tr -dc '0-9')"
M1_DRAIN_ALL="${M1_DRAIN_ALL:-0}"
M1_DRAIN_DONE="${M1_DRAIN_DONE:-0}"
M1_DRAIN_PENDING=$(( M1_DRAIN_ALL - M1_DRAIN_DONE ))

# Captures this week (any status, ISO ts comparison)
M1_WEEK_CAPTURES="$(sqlite3 __HOME__/.local/share/agent_memory/memory.db \
    "SELECT COUNT(*) FROM memory WHERE ts >= datetime('now', '-7 days')" 2>/dev/null \
    | head -1 | tr -dc '0-9')"
M1_WEEK_CAPTURES="${M1_WEEK_CAPTURES:-0}"

# -- Boot Delta (SPEC_D1, 2026-07-03) -----------------------------------------
# Diffs OPEN_DECISIONS PENDING block, IMPORTED_HANDOFFS PENDING REVIEW block,
# and GOTCHAS entry index against prior boot snapshots. Writes BOOT_DELTA.md.
# Boot snapshots live in ~/.local/share/your-scripts/boot_snapshots/ (separate
# cadence from erosion_snapshots which are close-scoped: no shared mutable state).
BOOT_SNAP_DIR="$HOME/.local/share/your-scripts/boot_snapshots"
mkdir -p "$BOOT_SNAP_DIR"
BOOT_DELTA_FILE="$VAULT/_handoff/BOOT_DELTA.md"
BOOT_TS_FILE="$BOOT_SNAP_DIR/last_boot_ts"
BOOT_PREV_TS="(no prior boot)"
[ -f "$BOOT_TS_FILE" ] && BOOT_PREV_TS="$(cat "$BOOT_TS_FILE")"

# Extract current section text for each tracked source
OD_SNAP_CURRENT="$(awk '/BEGIN_PENDING/{p=1;next} /END_PENDING/{p=0} p' \
    "$VAULT/_handoff/OPEN_DECISIONS.md" 2>/dev/null)"
IH_SNAP_CURRENT="$(awk '/BEGIN_PENDING_REVIEW/{p=1;next} /END_PENDING_REVIEW/{p=0} p' \
    "$VAULT/_handoff/IMPORTED_HANDOFFS.md" 2>/dev/null)"
# GOTCHAS: entry header lines only (compact, low-noise delta)
GOTCHAS_SNAP_CURRENT="$(grep -E '^#{2,3} G[0-9]+' "$VAULT/_handoff/GOTCHAS.md" 2>/dev/null)"

BOOT_FIRST=0
BOOT_DELTA_BODY=""

# _snap_diff label current_text snap_file
# Modifies BOOT_FIRST and BOOT_DELTA_BODY in parent scope.
_snap_diff() {
    local label="$1" current_text="$2" snap_file="$3"
    if [ ! -f "$snap_file" ]; then
        BOOT_FIRST=1
        printf '%s' "$current_text" > "$snap_file"
        return
    fi
    local diff_out added removed
    diff_out="$(diff "$snap_file" <(printf '%s' "$current_text") 2>/dev/null)"
    if [ -n "$diff_out" ]; then
        added="$(printf '%s\n' "$diff_out" | grep '^>' | sed 's/^> //')"
        removed="$(printf '%s\n' "$diff_out" | grep '^<' | sed 's/^< //')"
        BOOT_DELTA_BODY+="### ${label}"$'\n'
        if [ -n "$added" ]; then
            BOOT_DELTA_BODY+="Added:"$'\n''```'$'\n'"${added}"$'\n''```'$'\n'
        fi
        if [ -n "$removed" ]; then
            BOOT_DELTA_BODY+="Removed:"$'\n''```'$'\n'"${removed}"$'\n''```'$'\n'
        fi
        BOOT_DELTA_BODY+=$'\n'
    fi
    printf '%s' "$current_text" > "$snap_file"
}

_snap_diff "OPEN_DECISIONS (PENDING block)" "$OD_SNAP_CURRENT" "$BOOT_SNAP_DIR/od_pending.snap"
_snap_diff "IMPORTED_HANDOFFS (PENDING REVIEW block)" "$IH_SNAP_CURRENT" "$BOOT_SNAP_DIR/ih_pending.snap"
_snap_diff "GOTCHAS (entry index)" "$GOTCHAS_SNAP_CURRENT" "$BOOT_SNAP_DIR/gotchas_headers.snap"

{
    printf '%s\n' "---"
    printf '%s\n' "title: Boot Delta"
    printf '%s\n' "generated: ${TS}"
    printf '%s\n' "meta_status: active"
    printf '%s\n' "purpose: Changes in OPEN_DECISIONS/IMPORTED_HANDOFFS/GOTCHAS since prior boot. Read instead of full files when < 24h stale."
    printf '%s\n' "update_trigger: Written by gen_session_boot.sh on every boot run."
    printf '%s\n' "---"
    printf '\n'
    printf '# Boot Delta  (generated %s)\n' "$TS"
    printf '\n'
    if [ "${BOOT_FIRST:-0}" -eq 1 ]; then
        printf 'First boot: snapshots initialized. No prior boot to diff against.\n'
    elif [ -z "$BOOT_DELTA_BODY" ]; then
        printf 'NO CHANGES since %s\n' "$BOOT_PREV_TS"
    else
        printf 'Changes since %s\n\n' "$BOOT_PREV_TS"
        printf '%s' "$BOOT_DELTA_BODY"
    fi
} > "$BOOT_DELTA_FILE"

printf '%s' "$TS" > "$BOOT_TS_FILE"

# -- Build output --------------------------------------------------------------
{
cat << HEADER
---
title: Session Boot: fast-load orientation
generated: ${TS}
meta_status: active
purpose: >
  Single-file session start. Read this instead of the 6-file first-read
  protocol. Load CLAUDE.md rules and domain files on demand only.
---

# Session Boot  (generated ${TS})

## RESUME POINT

${RESUME}

## OPEN ITEMS

HEADER

if [ "${OD_COUNT:-0}" -gt 0 ]; then
    echo "ODs pending: ${OD_COUNT}"
    echo "${OD_LIST}"
else
    echo "ODs pending: 0"
    echo ""
fi

if [ "${IH_COUNT:-0}" -gt 0 ]; then
    echo "IHs pending: ${IH_COUNT}  <- check _handoff/IMPORTED_HANDOFFS.md PENDING REVIEW block"
else
    echo "IHs pending: 0"
fi

echo ""
if [ "${SEC_COUNT:-0}" -gt 0 ]; then
    echo "[!] Security fires: ${SEC_COUNT} open  <- _handoff/vip_next_session/SECURITY_FIRES.md"
    printf '%s' "$SEC_NAMED"
else
    echo "Security fires: 0 open"
fi

if [ "${PUSH_FAIL_COUNT:-0}" -gt 0 ]; then
    echo "[!] Push failures: ${PUSH_FAIL_COUNT} active  <- _handoff/PUSH_INCONGRUENCE.md"
else
    echo "Push: OK (backend cron healthy)"
fi

if [ "${EROSION_DROPS:-0}" -gt 0 ]; then
    echo "[!] Erosion drops: ${EROSION_DROPS} removed lines in ${EROSION_FILE}  <- _handoff/erosion_audit/"
else
    echo "Erosion: clean  (latest: ${EROSION_FILE:-none})"
fi

# Sanitize WIKI_BROKEN before integer comparison: defends against multi-line
# or padded values that previously triggered `[: 0\n0: integer expected` errors
# (OD-44 Sub-item B bundle: pre-existing latent bug surfaced during R3 smoke-test).
WIKI_BROKEN_INT="$(printf '%s' "${WIKI_BROKEN:-0}" | tr -dc '0-9' | head -c 10)"
WIKI_BROKEN_INT="${WIKI_BROKEN_INT:-0}"
if [ -n "$WIKI_BROKEN" ] && [ "${WIKI_BROKEN_INT:-0}" -gt 0 ]; then
    echo "[!] Broken wikilinks: ${WIKI_BROKEN}/${WIKI_TOTAL} (${WIKI_OK_PCT}% OK, active content only)  <- see check_links.py EXCLUDE_PREFIXES for scope"
elif [ -n "$WIKI_BROKEN" ]; then
    echo "Wikilinks: OK (0 broken / ${WIKI_TOTAL} total)"
else
    echo "Wikilinks: unknown (check_links.py unavailable)"
fi

if [ "${UNREVIEWED_COUNT:-0}" -gt 0 ]; then
    echo "Unreviewed captures: ${UNREVIEWED_COUNT}  <- python3 ~/Projects/your-scripts/scripts/agent_memory.py unreviewed"
else
    echo "Unreviewed captures: 0"
fi

echo "Daily note: ${M1_DAILY_DAYS}d ago  (last: ${M1_DAILY_DATE})"
echo "Drain pending: ${M1_DRAIN_PENDING}  <- _handoff/DRAIN_REVIEW.md"
echo "Captures this week: ${M1_WEEK_CAPTURES}"
if [ -n "$D5_LINE" ]; then
    echo "${D5_LINE}"
fi

if [ -n "$DEFERRED_EXPIRED" ]; then
    echo "[!] Deferred triggers expired:"
    echo "$DEFERRED_EXPIRED"
fi

if [ -n "$STALE_SURFACE" ]; then
    echo "[!] Staleness fork (N=${STALENESS_N} boots: act now OR move to DEFERRED.md with trigger):"
    printf '%s' "$STALE_SURFACE"
fi

cat << MIDSECTION


## LAST 3 MIGRATION LOG ENTRIES

MIDSECTION

if [ -n "$MLOG" ]; then
    echo "$MLOG"
else
    echo "(no date-header entries found)"
fi

cat << FOOTER


## ACTIVE FLAGS

FOOTER

# Extract lines containing [FIRE] from SESSION_HANDOFF_CURRENT.md (if it exists)
FIRES="$(grep '[FIRE]' "$VAULT/_handoff/SESSION_HANDOFF_CURRENT.md" 2>/dev/null \
     | grep -v '^##\|^> \|^---' | head -5)"
if [ -n "$FIRES" ]; then
    echo "$FIRES"
else
    echo "(none)"
fi

if [ -n "$GOTCHAS_INDEX" ]; then
    printf '\n\n## STANDING GOTCHAS (%s entries: full read: _handoff/GOTCHAS.md)\n\n' "$GOTCHAS_COUNT"
    printf '%s\n' "$GOTCHAS_INDEX"
fi

# Project to-do: surface open items from the root PROJECT_TODO.md so building
# this system stays visible at session start alongside vault work.
PTODO="$VAULT/PROJECT_TODO.md"
if [ -f "$PTODO" ]; then
    PTODO_OPEN="$(grep -cE '^[[:space:]]*- \[ \]' "$PTODO" 2>/dev/null | head -1 | tr -dc '0-9')"
    PTODO_NEXT="$(grep -E '^[[:space:]]*- \[ \]' "$PTODO" 2>/dev/null | head -5 \
        | sed -E 's/^[[:space:]]*- \[ \][[:space:]]*/  /' | cut -c1-100)"
    printf '\n\n## PROJECT TO-DO (%s open: full list: PROJECT_TODO.md)\n\n' "${PTODO_OPEN:-0}"
    if [ -n "$PTODO_NEXT" ]; then
        printf '%s\n' "$PTODO_NEXT"
    else
        printf '(none open)\n'
    fi
fi

cat << TRAILER


## LOAD ON DEMAND

Boot delta:     _handoff/BOOT_DELTA.md  (changes since prior boot; 24h stale = full reads)
Full rules:     CLAUDE.md  (the constitution)
Architecture:   99_system/VAULT_ARCHITECTURE.md  <- what every tracking file is for
Token rule:     99_system/TOKEN_DISCIPLINE.md  <- read before any bulk work
Safety policy:  _handoff/SAFETY_POLICY.md  <- read before any delete or sweep
User context:   _handoff/USER_CONTEXT.md  (machine facts + failure modes)
Gotchas:        _handoff/GOTCHAS.md  (${GOTCHAS_COUNT} entries, updated ${GOTCHAS_MTIME})
Open decisions: _handoff/OPEN_DECISIONS.md  (${OD_COUNT} pending)
Security fires: _handoff/vip_next_session/SECURITY_FIRES.md
Project to-do:  PROJECT_TODO.md  (building this system)
Hotkeys:        OBSIDIAN_HOTKEYS.md
TRAILER

# Recent decisions (R3: OD-44A read-back, only emitted if non-empty)
if [ -n "$RECENT_DECISIONS" ]; then
    printf '\n\n## RECENT DECISIONS (agent_memory)\n\n'
    printf '%s\n' "$RECENT_DECISIONS"
fi

# VIP next session active items
if [ -n "$VIP_FILES" ]; then
    printf '\n\n## VIP NEXT SESSION (active)\n\n'
    printf '%s' "$VIP_FILES"
fi

} > "$OUT"

echo "[gen_session_boot] wrote $OUT  ($(wc -l < "$OUT") lines)"
