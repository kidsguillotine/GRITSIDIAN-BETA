#!/bin/bash
set -e
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
cd "$VAULT"
git add -A
git commit -m "pre-sweep checkpoint: $(date +%Y-%m-%dT%H:%M)"
echo "[x] Checkpoint committed. Safe to proceed."
echo "  Commit: $(git log -1 --oneline)"
