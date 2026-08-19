#!/usr/bin/env bash
# vip_index_scan.sh: Frontmatter-index scan for session start
# =============================================================
# Reads ONLY the YAML frontmatter block of each .md file in a directory.
# Used to decide which files need full-reads at session start without
# paying the cost of reading the body.
#
# Usage:
#   bash .claudian/scripts/vip_index_scan.sh [DIR]
#   DIR defaults to _handoff/vip_next_session/
#   Example: bash .claudian/scripts/vip_index_scan.sh _handoff/imported/
#
# Output:
#   One block per file: filename + all frontmatter fields, prefixed with "  ".
#
# Decision rule (from Frontmatter-Status Hard rule in CLAUDE.md):
#   active-vip | active-fire | pending-user-action -> full read
#   standing-rule                                  -> full read first session, cached after
#   SUPERSEDED / status: REVIEWED / RESOLVED       -> skip body
#   meta_status: active (README-type)              -> header only
#
# Added: 2026-06-26 (DIRECTIVE_IMPLEMENTATION_SPEC.md Directive 1 optional step)

set -uo pipefail

VAULT="${VAULT:-__VAULT_ROOT__}"
DIR="${1:-$VAULT/_handoff/vip_next_session}"

if [ ! -d "$DIR" ]; then
    echo "ERROR: directory not found: $DIR" >&2
    exit 1
fi

echo "=== Frontmatter index: $DIR ==="
echo ""

count=0
for f in "$DIR"/*.md; do
    [ -f "$f" ] || continue
    (( count++ )) || true
    echo "--- $(basename "$f") ---"
    awk '/^---$/{n++; next} n==1 {print "  "$0} n==2 {exit}' "$f"
    echo ""
done

echo "=== $count file(s) scanned ==="
