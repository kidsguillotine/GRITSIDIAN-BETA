#!/usr/bin/env bash
# session_close.sh: Comprehensive session close audit + handoff generation
#
# Usage:
#   bash .claudian/scripts/session_close.sh [--dry-run]
#
# What it does:
#   1. Reports what changed this session (git log since last session-close commit)
#   2. Warns if tracking files weren't updated (PHASE_STATE, NEXT_ACTIONS, PENDING_WORK, MIGRATION_LOG)
#   3. Shows open [!] IMMEDIATE items from PENDING_WORK.md
#   4. Runs generate_handoff.sh --archive
#   5. Auto-commits vault repo with prompts for the resume point
#   6. Prints project repo reminder
#
# Call this from the end-of-day skill or when the user says "end session".

set -uo pipefail

VAULT="${VAULT:-__VAULT_ROOT__}"

# Fail loud if setup.sh was never run. Without this a script silently creates a
# folder literally named __VAULT_ROOT__ and writes into it (see GOTCHAS G27).
case "$VAULT" in
  *__VAULT_ROOT__*)
    echo "FATAL: vault path is still the setup placeholder." >&2
    echo "  Run ./setup.sh, or pass VAULT=/path/to/vault explicitly." >&2
    exit 2 ;;
esac
[ -d "$VAULT" ] || { echo "FATAL: vault path does not exist: $VAULT" >&2; exit 2; }
PROJECT="__STACK_ROOT__"
DRY_RUN=false
SKIP_CAPTURE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run)      DRY_RUN=true ;;
    --skip-capture) SKIP_CAPTURE=true ;;
  esac
done

RED='\033[0;31m'
YLW='\033[0;33m'
GRN='\033[0;32m'
BLD='\033[1m'
RST='\033[0m'

warn()  { echo -e "${YLW}WARNING:  $*${RST}"; }
ok()    { echo -e "${GRN}[x] $*${RST}"; }
fail()  { echo -e "${RED}[FAIL] $*${RST}"; }
title() { echo -e "\n${BLD}-- $* --${RST}"; }

# -- 0. Referential integrity check (C1: map->fs, C3: symlinks) ---------------
# Hard-blocks close if DANGLING or BROKEN_LINK found.
# Fix the reported path(s) before closing: they indicate deleted mapped files
# or broken symlinks that silently degrade the system.

title "REFERENTIAL INTEGRITY (C1 + C3)"
VALIDATE="$VAULT/.claudian/scripts/validate_system.sh"
if [[ -x "$VALIDATE" ]]; then
  if ! bash "$VALIDATE"; then
    fail "Integrity check FAILED: fix DANGLING/BROKEN_LINK before closing"
    fail "Re-run to see details: bash $VALIDATE"
    exit 1
  fi
else
  warn "validate_system.sh not found at $VALIDATE: skipping integrity check"
fi

# -- 1. What changed this session ---------------------------------------------

title "CHANGES THIS SESSION (since last session-close commit)"
LAST_CLOSE=$(git -C "$VAULT" log --oneline --grep="session close:" -1 --format="%H" 2>/dev/null)
if [[ -n "$LAST_CLOSE" ]]; then
  git -C "$VAULT" log --oneline "$LAST_CLOSE"..HEAD \
    --invert-grep --grep="auto:\|vault backup:\|auto: hourly" 2>/dev/null \
    || echo "  (no commits since last session-close)"
else
  echo "  (no prior session-close commit found)"
fi

# -- 2. Tracking file freshness check -----------------------------------------

title "TRACKING FILE UPDATES (were these touched this session?)"
TRACKING_FILES=(
  "_handoff/PHASE_STATE.md"
  "_handoff/NEXT_ACTIONS.md"
  "_handoff/PENDING_WORK.md"
  "_handoff/MIGRATION_LOG.txt"
  "_handoff/GOTCHAS.md"
)
ALL_OK=true
for f in "${TRACKING_FILES[@]}"; do
  if git -C "$VAULT" diff --name-only HEAD -- "$f" 2>/dev/null | grep -q "$f"; then
    ok "$f: modified"
  elif git -C "$VAULT" diff --name-only HEAD "$LAST_CLOSE" -- "$f" 2>/dev/null | grep -q "$f" 2>/dev/null; then
    ok "$f: modified this session"
  else
    # Check if it was in any commit since last close
    CHANGED=$(git -C "$VAULT" log --oneline "$LAST_CLOSE"..HEAD -- "$f" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$CHANGED" -gt 0 ]]; then
      ok "$f: updated ($CHANGED commits)"
    else
      warn "$f: NOT updated this session"
      ALL_OK=false
    fi
  fi
done
[[ "$ALL_OK" == "true" ]] && ok "All tracking files updated." || warn "Some tracking files may be stale: review before closing."

# -- 3. Open IMMEDIATE items ---------------------------------------------------

title "OPEN [!] IMMEDIATE ITEMS (from PENDING_WORK.md)"
# Extract unchecked items under [!] sections
awk '/^## [!]/,/^## [o]|^## [o]|^## [o]|^## [o]|^---/' "$VAULT/_handoff/PENDING_WORK.md" \
  | grep "^- \[ \]" \
  | sed 's/^- \[ \] /  • /' \
  || echo "  (none found or file unreadable)"

# -- 4. Uncommitted content files warning -------------------------------------

title "GIT STATUS (vault)"
UNCOMMITTED=$(git -C "$VAULT" status --short 2>/dev/null \
  | grep -v "\.ajson\|\.meta\.json\|workspace\.json\|knowledge\.db" \
  | grep -v "^?? .*\.md$" \
  | wc -l | tr -d ' ')
if [[ "$UNCOMMITTED" -gt 0 ]]; then
  warn "$UNCOMMITTED uncommitted non-noise files:"
  git -C "$VAULT" status --short 2>/dev/null \
    | grep -v "\.ajson\|\.meta\.json\|workspace\.json\|knowledge\.db"
else
  ok "Vault clean (noise files expected)"
fi

# -- 4.5. MEMORY CAPTURE (R1 rework Path B: non-interactive, 2026-07-02) -----
# Runs reconcile_session.py to find decision-signal snippets from this session
# that weren't captured to agent_memory, then writes EVERY miss candidate as
# status='unreviewed' (excluded from active()/search() by default). Human
# review happens off-close by reading the reconcile_YYYYMMDD_HHMMSS.md report
# on the user's clock: not as a live prompt at session close.
#
# History: the pre-2026-07-02 implementation prompted per-item with `read`
# inside a piped while loop, which re-bound stdin to the miss-list stream
# (not the terminal): the inner read consumed miss-lines as answers,
# producing 0 captures with no error in ALL contexts (tty and non-tty).
# IH-13 documents the diagnosis. Path B (this implementation) is the seat's
# original 06-18 architecture: capture decoupled from the live agent, running
# non-interactively at close; review moves to the human on their clock.
#
# Bypass with --skip-capture if you genuinely don't want to capture this run.
# DRY_RUN: reconcile still runs (miss-list is surfaced), no captures written.
#
# Review workflow:
#   python3 agent_memory.py unreviewed           # list captured-but-unreviewed
#   python3 agent_memory.py capture "<text>" decision "<topic>" \
#           --status active --force               # promote (same content-hash)

title "MEMORY CAPTURE (reconcile_session: non-interactive Path B)"
RECONCILE_SCRIPT="__SCRIPTS_ROOT__/scripts/reconcile_session.py"
AGENT_MEM_SCRIPT="__SCRIPTS_ROOT__/scripts/agent_memory.py"

if [[ "$SKIP_CAPTURE" == "true" ]]; then
  warn "Capture skipped (--skip-capture flag set): agent_memory not updated this session"
elif [[ ! -f "$RECONCILE_SCRIPT" ]]; then
  warn "reconcile_session.py not found at $RECONCILE_SCRIPT: skipping capture (audit gap)"
else
  RECONCILE_OUT="$VAULT/_handoff/reconcile_$(date +%Y%m%d_%H%M%S).md"
  python3 "$RECONCILE_SCRIPT" --output "$RECONCILE_OUT" 2>&1 | tail -5 || true
  if [[ -f "$RECONCILE_OUT" ]]; then
    MISS_COUNT=$(grep -c '^\[[0-9]' "$RECONCILE_OUT" 2>/dev/null || echo 0)
    echo ""
    echo "  Reconcile report: $RECONCILE_OUT"
    if [[ "$MISS_COUNT" -eq 0 ]]; then
      ok "agent_memory in sync (0 miss candidates)"
    elif [[ "$DRY_RUN" == "true" ]]; then
      warn "$MISS_COUNT miss candidates found: [DRY RUN] not capturing. Review report."
    else
      warn "$MISS_COUNT miss candidates found: capturing as 'unreviewed' (non-interactive):"
      CAPTURED_N=0
      FAILED_N=0
      while IFS= read -r miss_line; do
        # Strip leading "[NN] " from "[01] snippet text..."
        snippet="${miss_line#\[*\] }"
        # Infer topic from signal markers (last-match wins on purpose; specific > generic)
        topic="general"
        [[ "$snippet" =~ MIGRATION_LOG ]] && topic="migration"
        [[ "$snippet" =~ G[0-9]+ ]]       && topic="gotchas"
        [[ "$snippet" =~ RESOLVED ]]      && topic="resolved"
        [[ "$snippet" =~ OD-[0-9]+ ]]     && topic="open_decisions"
        if python3 "$AGENT_MEM_SCRIPT" capture "$snippet" "decision" "$topic" \
             --status unreviewed >/dev/null 2>&1; then
          CAPTURED_N=$((CAPTURED_N + 1))
        else
          FAILED_N=$((FAILED_N + 1))
        fi
      done < <(grep '^\[[0-9]' "$RECONCILE_OUT")
      echo "  Capture summary: $CAPTURED_N captured as 'unreviewed' ($FAILED_N failed) of $MISS_COUNT total"
      echo "  Review: python3 $AGENT_MEM_SCRIPT unreviewed"
      echo "  Promote: python3 $AGENT_MEM_SCRIPT capture \"<text>\" decision \"<topic>\" --status active --force"
    fi
  else
    warn "reconcile_session.py produced no output file: check stderr above"
  fi
fi

# -- 5. Regenerate handoff -----------------------------------------------------

title "REGENERATING SESSION_HANDOFF_CURRENT.md"
if [[ "$DRY_RUN" == "false" ]]; then
  bash "$VAULT/.claudian/scripts/generate_handoff.sh" --archive
else
  echo "  [DRY RUN] Would run: generate_handoff.sh --archive"
fi

# -- 6. Vault commit -----------------------------------------------------------

title "VAULT COMMIT"
if [[ "$DRY_RUN" == "false" ]]; then
  git -C "$VAULT" add \
    "_handoff/SESSION_HANDOFF_CURRENT.md" \
    "_handoff/PHASE_STATE.md" \
    "_handoff/NEXT_ACTIONS.md" \
    "_handoff/PENDING_WORK.md" \
    "_handoff/MIGRATION_LOG.txt" \
    "_handoff/GOTCHAS.md" \
    "_handoff/handoff_history/" \
    2>/dev/null || true

  # Check if there's anything to commit
  STAGED=$(git -C "$VAULT" diff --staged --name-only 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$STAGED" -gt 0 ]]; then
    echo "  Staged $STAGED files. Agent: create commit with format:"
    echo -e "  ${BLD}git -C $VAULT commit -m \"session close: <task>: awaiting <gate>\"${RST}"
  else
    echo "  Nothing new to stage in tracking files."
  fi
else
  echo "  [DRY RUN] Would stage tracking files and prompt for commit."
fi

# -- 7. Project repo status ----------------------------------------------------

title "PROJECT REPO STATUS ($PROJECT)"
PROJ_UNCOMMITTED=$(git -C "$PROJECT" status --short 2>/dev/null | wc -l | tr -d ' ')
if [[ "$PROJ_UNCOMMITTED" -gt 0 ]]; then
  warn "$PROJ_UNCOMMITTED uncommitted files in project repo:"
  git -C "$PROJECT" status --short 2>/dev/null
  echo "  Commit with: git -C $PROJECT commit -m \"docs: <description>\""
else
  ok "Project repo clean."
fi

# -- 8. SCRIPT_REGISTRY freshness check (P2: advisory, non-blocking) ---------

title "SCRIPT_REGISTRY FRESHNESS (advisory)"
UNREGISTERED=false
for f in __SCRIPTS_ROOT__/scripts/*.py; do
  bname="$(basename "$f")"
  if ! grep -q "$bname" "$VAULT/99_system/SCRIPT_REGISTRY.md" 2>/dev/null; then
    warn "UNREGISTERED script: $bname: add to 99_system/SCRIPT_REGISTRY.md"
    UNREGISTERED=true
  fi
done
[[ "$UNREGISTERED" == "false" ]] && ok "All your-scripts/scripts/*.py appear in SCRIPT_REGISTRY.md"

# -- 9. VIP next session freshness check (P3: advisory, non-blocking) ---------

title "VIP_NEXT_SESSION FRESHNESS (advisory)"
VIP_UNMAPPED=false
for f in "$VAULT/_handoff/vip_next_session/"*.md; do
  [ -f "$f" ] || continue
  bname="$(basename "$f")"
  if ! grep -q "$bname" "$VAULT/99_system/SYSTEM_DOC_MAP.md" 2>/dev/null; then
    warn "UNMAPPED VIP: $bname: add to SYSTEM_DOC_MAP.md vip_next_session table"
    VIP_UNMAPPED=true
  fi
done
[[ "$VIP_UNMAPPED" == "false" ]] && ok "All vip_next_session/ files appear in SYSTEM_DOC_MAP.md"

# -- 10. Final checklist -------------------------------------------------------

title "SESSION CLOSE CHECKLIST"
cat << 'CHECKLIST'
  Before finishing:
  [ ] PHASE_STATE.md reflects completed work (mark tasks [x])
  [ ] NEXT_ACTIONS.md reflects new gates (update track, remove done items)
  [ ] PENDING_WORK.md updated (new open items added, done items checked off)
  [ ] MIGRATION_LOG.txt appended (if files moved/deleted)
  [ ] GOTCHAS.md appended (if new failure/workaround discovered)
  [ ] decision_log.md updated (if architectural decisions made)
  [ ] Vault committed with: "session close: <task>: awaiting <gate>"
  [ ] Project repo committed if docs changed
  [ ] Security P0 (key revocation): check PENDING_WORK.md [!] SECURITY section
CHECKLIST

echo ""
echo "Run this script again with --dry-run to preview without making changes."
