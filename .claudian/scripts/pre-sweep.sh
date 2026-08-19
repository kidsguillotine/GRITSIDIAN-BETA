#!/bin/bash
set -e
VAULT="__VAULT_ROOT__"
cd "$VAULT"
git add -A
git commit -m "pre-sweep checkpoint: $(date +%Y-%m-%dT%H:%M)"
echo "[x] Checkpoint committed. Safe to proceed."
echo "  Commit: $(git log -1 --oneline)"
