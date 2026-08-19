#!/usr/bin/env bash
# gen_last_modified.sh: Generate LAST_MODIFIED_INDEX.md from git log
# ====================================================================
# Produces a generated index of when each key system doc was last touched
# in git. Do not hand-maintain per-file dates: run this instead.
#
# Output: 99_system/LAST_MODIFIED_INDEX.md
# Run:    bash .claudian/scripts/gen_last_modified.sh
# Called: on demand (not wired into cron: low priority, H4)
#
# Canonical doc: 99_system/LAST_MODIFIED_INDEX.md (generated)

set -uo pipefail

VAULT="${VAULT:-__VAULT_ROOT__}"
OUT="$VAULT/99_system/LAST_MODIFIED_INDEX.md"
TS="$(date '+%Y-%m-%dT%H:%M')"

# Key system docs to index (relative to vault root)
DOCS=(
  # Operator / session start
  "CLAUDE.md"
  "_handoff/SESSION_BOOT.md"
  "_handoff/SESSION_HANDOFF_CURRENT.md"
  # Explicit-gate
  "_handoff/OPEN_DECISIONS.md"
  "_handoff/IMPORTED_HANDOFFS.md"
  # Continuity
  "_handoff/GOTCHAS.md"
  "_handoff/PENDING_WORK.md"
  "_handoff/MIGRATION_LOG.txt"
  # Architecture
  "99_system/MASTER_PLAN_v2.md"
  "99_system/NEXT_ACTIONS.md"
  "99_system/AUTOMATION_BACKLOG.md"
  "99_system/VAULT_FUNCTION_PLAN.md"
  # System index docs
  "99_system/SYSTEM_DOC_MAP.md"
  "99_system/AGENTS_AND_TOOLS.md"
  "99_system/SCRIPT_SPECS.md"
  "99_system/SCRIPT_REGISTRY.md"
  "99_system/SYMLINK_REGISTRY.md"
  # Standards / contracts
  "99_system/DOC_STANDARD.md"
  # Safety
  "_handoff/vip_next_session/SECURITY_FIRES.md"
  # Tools
  "99_system/VO_TOOL_MANIFEST.md"
  "99_system/CROSS_REPO_SCRIPTS.md"
)

{
cat <<HEADER
---
title: Last Modified Index
generated: ${TS}
meta_status: generated
purpose: >
  Git-derived last-modification dates for key system docs.
  Never hand-edit: regenerate with gen_last_modified.sh.
update_trigger: Run gen_last_modified.sh after any significant session.
---

# Last Modified Index

> Generated ${TS}: do not hand-edit.
> Run: \`bash .claudian/scripts/gen_last_modified.sh\`

| Doc | Last git touch | Last commit message |
|---|---|---|
HEADER

for doc in "${DOCS[@]}"; do
  filepath="$VAULT/$doc"
  if [[ ! -f "$filepath" ]]; then
    printf "| \`%s\` |: | (file not found) |\n" "$doc"
    continue
  fi
  date_str="$(git -C "$VAULT" log -1 --format="%cs" -- "$doc" 2>/dev/null)"
  msg="$(git -C "$VAULT" log -1 --format="%s" -- "$doc" 2>/dev/null | cut -c1-60)"
  if [[ -z "$date_str" ]]; then
    date_str="(untracked)"
    msg=""
  fi
  printf "| \`%s\` | %s | %s |\n" "$doc" "$date_str" "$msg"
done

} > "$OUT"

echo "[gen_last_modified] wrote $OUT ($(wc -l < "$OUT") lines)"
