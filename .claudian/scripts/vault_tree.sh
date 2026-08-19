#!/usr/bin/env bash
# vault_tree.sh: Print vault folder structure 6 levels deep
# Excludes: .git, __pycache__, node_modules, venv/env/.venv, .obsidian cache,
#           *.pyc, *.pyo, .DS_Store, Thumbs.db, .ajson files
#
# Usage:
#   bash vault_tree.sh                     # runs from vault root
#   bash vault_tree.sh /some/other/path    # explicit root

ROOT="${1:-__VAULT_ROOT__}"

# Prune patterns for find -prune (directories to skip entirely)
PRUNE_DIRS=(
  ".git"
  "__pycache__"
  "node_modules"
  "venv"
  ".venv"
  "env"
  ".obsidian"
  ".trash"
  "chroma_db"
  "chromadb"
  ".cache"
)

# Build the -path prune expression
PRUNE_EXPR=()
for d in "${PRUNE_DIRS[@]}"; do
  PRUNE_EXPR+=( -o -name "$d" -prune )
done

echo "Vault tree: root: $ROOT"
echo "Depth: 6 | Excluded: ${PRUNE_DIRS[*]}"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

# Use find + awk to render an indented tree
find "$ROOT" \
  \( -name ".git" -prune \
     -o -name "__pycache__" -prune \
     -o -name "node_modules" -prune \
     -o -name "venv" -prune \
     -o -name ".venv" -prune \
     -o -name "env" -prune \
     -o -name ".obsidian" -prune \
     -o -name ".trash" -prune \
     -o -name "chroma_db" -prune \
     -o -name "chromadb" -prune \
     -o -name ".cache" -prune \
  \) \
  -o \( \
     ! -name "*.pyc" \
     ! -name "*.pyo" \
     ! -name ".DS_Store" \
     ! -name "Thumbs.db" \
     ! -name "*.ajson" \
     ! -name ".gitignore" \
     -mindepth 1 \
     -maxdepth 6 \
     -print \
  \) | sort | awk -v root="$ROOT" '
{
  # Strip the root prefix
  path = $0
  sub(root "/", "", path)

  # Count depth by counting "/"
  n = split(path, parts, "/")
  indent = ""
  for (i = 1; i < n; i++) indent = indent "  "

  # Mark directories vs files
  name = parts[n]
  print indent "--- " name
}
'

echo "============================================================"
echo "Done."
