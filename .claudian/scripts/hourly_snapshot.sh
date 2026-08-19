#!/usr/bin/env bash
# hourly_snapshot.sh: hourly commit + push for the VAULT repo only.
#
# Location: vault/.claudian/scripts/ (vault-only infrastructure; NOT a
# product-repo script). Per the repository-scope-separation rule
# (CLAUDE.md): personal-cadence automation operates on the vault repo
# only: never on your-scripts (distributable product), your-scripts-paid,
# or your-stack (runtime stack). Those repos receive curated
# commits via explicit, named release/sync scripts: not personal cron.
#
# Called from crontab (see DIRECTIVE_IMPLEMENTATION_SPEC.md, Directive 2):
#   0 * * * * __VAULT_ROOT__/.claudian/scripts/hourly_snapshot.sh
#
# Behavior:
#   - vault repo only: git add -A; allow-empty commit; push.
#   - Push failures append a line to _handoff/PUSH_INCONGRUENCE.md.
#   - Logs to .claudian/logs/hourly.log.
#
# History: a prior version of this script iterated three repos
# (vault + your-scripts + PAS). That conflated product-repo lifecycle
# with personal-cadence automation. Reverted 2026-06-23; scope
# narrowed to vault.
#
# Spec: _handoff/vip_next_session/DIRECTIVE_IMPLEMENTATION_SPEC.md (Directive 2)

set -uo pipefail

VAULT=__VAULT_ROOT__
TS="$(date -Iseconds)"
LOG="$VAULT/.claudian/logs/hourly.log"
INCONGRUENCE="$VAULT/_handoff/PUSH_INCONGRUENCE.md"
mkdir -p "$(dirname "$LOG")"

log() { echo "$TS $*" >> "$LOG"; }
flag_incongruence() { echo "- $TS: $*" >> "$INCONGRUENCE"; }

if [ ! -d "$VAULT/.git" ]; then
  log "ERR: $VAULT has no .git directory"
  exit 1
fi

cd "$VAULT" || { log "ERR: cd failed for $VAULT"; exit 1; }

git add -A 2>>"$LOG" || log "WARN: git add -A failed"
git commit -m "auto: hourly snapshot $(date +%Y-%m-%dT%H:%M)" --allow-empty 2>>"$LOG"

if ! git push 2>>"$LOG"; then
  flag_incongruence "push failed for $VAULT (see $LOG tail)"
  log "PUSH_FAILED: $VAULT"
  exit 1
fi

log "OK: $VAULT"

# Regenerate SESSION_BOOT.md so session start reads current state (≤1 hour stale)
GEN_BOOT="$VAULT/.claudian/scripts/gen_session_boot.sh"
if [[ -x "$GEN_BOOT" ]]; then
  bash "$GEN_BOOT" >> "$LOG" 2>&1
fi

# Referential integrity check (soft mode: logs errors but never blocks push)
VALIDATE="$VAULT/.claudian/scripts/validate_system.sh"
if [[ -x "$VALIDATE" ]]; then
  bash "$VALIDATE" --soft >> "$LOG" 2>&1
fi

# VO memory docs (knowledge.md + projects.md) regenerated at session-close only.
# Removed from hourly cron 2026-07-01: those files carry memory_source:true and
# VO reads them as agent memory; hourly automated rewrite bypasses Explicit
# Confirmation Gate. Session-close regen keeps a human in the loop.

exit 0
