#!/usr/bin/env bash
# install.sh: copy versioned git hooks into .git/hooks/
# Run once after cloning. Git hooks are NOT tracked, so each clone needs install.
#
# Usage:  bash .claudian/hooks/install.sh

set -euo pipefail
REPO_ROOT=$(git rev-parse --show-toplevel)
HOOK_SRC="$REPO_ROOT/.claudian/hooks"
HOOK_DST="$REPO_ROOT/.git/hooks"

for hook in pre-commit; do
  if [[ -f "$HOOK_SRC/$hook" ]]; then
    cp "$HOOK_SRC/$hook" "$HOOK_DST/$hook"
    chmod +x "$HOOK_DST/$hook"
    echo "Installed: $hook"
  fi
done

echo "Done. Hooks active in $HOOK_DST"
