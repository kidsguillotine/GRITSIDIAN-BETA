#!/bin/bash
# vault_setup.sh: idempotent vault setup
# Run once after cloning. Re-running is safe (idempotent).
# Location: .claudian/scripts/vault_setup.sh
# Usage: bash .claudian/scripts/vault_setup.sh
#
# NOTE: This script reflects ACTUAL setup on this machine, not aspirational.
# - trash: uses `mv <file> $VAULT/.trash/` (Obsidian-native, reversible). Not trash-cli.
# - auto-commit: obsidian-git plugin handles it (autoSaveInterval=60). No cron.
# - if you want a separate cron OR to install trash-cli, add it manually.

set -e

VAULT="__VAULT_ROOT__"
GRITSIDIAN_SCRIPTS="__SCRIPTS_ROOT__/scripts"

# Canonical scripts that live in your-scripts/scripts/ and symlink into vault.
# Source: 99_system/SYMLINK_REGISTRY.md
SYMLINKED_SCRIPTS=(
    agent_memory.py
    agent_runner.py
    chroma_reconcile.py
    chunk_store.py
    classify.py
    dedup_pipeline.py
    frontmatter_to_ics.py
    inference.py
    interaction_log.py
    link_safe_move.py
    merge_files.py
    op_idempotency.py
    op_log.py
    rebuild_mocs.py
    reconcile_session.py
    requirements.txt
    schedule_surface.py
    scrap_surface.py
    state_hook.py
    task_surface.py
    time_context.py
    validate_frontmatter.py
    vault_agent.py
)

echo "=== VAULT SETUP ==="
echo "Vault: $VAULT"
echo "Date: $(date)"
echo ""

# -- 1. git init (idempotent) ----------------------------------
echo "[1/3] Checking git repository..."
cd "$VAULT"

if git rev-parse --git-dir &>/dev/null; then
    echo "  [x] Git already initialized"
    echo "  Branch: $(git branch --show-current)"
    echo "  Last commit: $(git log -1 --oneline 2>/dev/null || echo 'no commits yet')"
else
    echo "  Initializing git repository..."
    git init
    git add -A
    git commit -m "baseline: initial vault snapshot $(date -Iseconds)"
    echo "  [x] Git initialized and baseline committed"
fi

# -- 2. Script symlinks -> your-scripts/scripts/ canonical --------
echo ""
echo "[2/3] Verifying script symlinks..."

if [ ! -d "$GRITSIDIAN_SCRIPTS" ]; then
    echo "  WARNING: your-scripts/scripts/ not found at $GRITSIDIAN_SCRIPTS"
    echo "    Clone the your-scripts repo first, then re-run this script."
    echo "    Skipping symlink check."
else
    VAULT_SCRIPTS="$VAULT/.claudian/scripts"
    CREATED=0
    SKIPPED=0
    BROKEN=0

    for script in "${SYMLINKED_SCRIPTS[@]}"; do
        link_path="$VAULT_SCRIPTS/$script"
        canonical="$GRITSIDIAN_SCRIPTS/$script"

        if [ ! -f "$canonical" ]; then
            echo "  [ ] canonical missing: $canonical"
            BROKEN=$((BROKEN + 1))
            continue
        fi

        if [ -L "$link_path" ]; then
            actual_target=$(readlink "$link_path")
            if [ "$actual_target" = "$canonical" ]; then
                SKIPPED=$((SKIPPED + 1))
                continue
            else
                echo "  (cycle) retargeting $script (was: $actual_target)"
                rm "$link_path"
            fi
        elif [ -f "$link_path" ]; then
            echo "  WARNING: $script is a real file, not a symlink: backing up to ${script}.local-copy"
            mv "$link_path" "$link_path.local-copy"
        fi

        ln -s "$canonical" "$link_path"
        CREATED=$((CREATED + 1))
    done

    echo "  [x] symlinks: $SKIPPED already correct, $CREATED created/fixed, $BROKEN broken"
fi

# -- 3. pre-sweep.sh -------------------------------------------
echo ""
echo "[3/3] Checking pre-sweep.sh..."

PRESWEEP="$VAULT/.claudian/scripts/pre-sweep.sh"

if [ -f "$PRESWEEP" ]; then
    echo "  [x] pre-sweep.sh already exists"
else
    cat > "$PRESWEEP" << 'PRESWEEP_EOF'
#!/bin/bash
# pre-sweep.sh: run before ANY bulk vault operation
# Usage: bash .claudian/scripts/pre-sweep.sh
set -e
VAULT="__VAULT_ROOT__"
cd "$VAULT"
git add -A
git commit -m "pre-sweep checkpoint: $(date +%Y-%m-%dT%H:%M)"
echo "[x] Checkpoint committed. Safe to proceed."
echo "  Commit: $(git log -1 --oneline)"
PRESWEEP_EOF
    chmod +x "$PRESWEEP"
    echo "  [x] pre-sweep.sh created at .claudian/scripts/pre-sweep.sh"
fi

# -- Summary ---------------------------------------------------
echo ""
echo "=== SETUP COMPLETE ==="
echo ""
echo "  git status:        $(git -C $VAULT log -1 --oneline 2>/dev/null)"
echo "  auto-commit:       obsidian-git plugin (autoSaveInterval=60 min)"
echo "  trash mechanism:   mv <file> $VAULT/.trash/"
echo "  pre-sweep:         bash $PRESWEEP"
echo ""
echo "Before any bulk operation: bash $PRESWEEP"
