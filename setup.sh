#!/usr/bin/env bash
# Claudian Starter: one-time placeholder replacement.
# Run this once, from inside the starter directory, after copying it to where
# you want your vault to live. It rewrites the __PLACEHOLDER__ tokens in-place.
#
# Usage:
#   ./setup.sh                 # interactive; sensible defaults
#   VAULT_ROOT=/path ./setup.sh --yes   # non-interactive
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- defaults ---------------------------------------------------------------
VAULT_ROOT_DEFAULT="$HERE"
SCRIPTS_ROOT_DEFAULT="$HERE/.claudian/scripts"
STACK_ROOT_DEFAULT=""                    # empty = local stack not used
SENSITIVE_STORE_DEFAULT="$HERE/_sensitive"
HOME_DEFAULT="$HOME"

AUTO=0
[[ "${1:-}" == "--yes" ]] && AUTO=1

ask() { # ask VAR "prompt" "default"
  local __var="$1" __prompt="$2" __def="$3" __val
  if [[ $AUTO -eq 1 || -n "${!__var:-}" ]]; then
    __val="${!__var:-$__def}"
  else
    read -r -p "$__prompt [$__def]: " __val || true
    __val="${__val:-$__def}"
  fi
  printf -v "$__var" '%s' "$__val"
}

echo "== Claudian Starter setup =="
ask VAULT_ROOT      "Absolute path to this vault"                 "$VAULT_ROOT_DEFAULT"
ask SCRIPTS_ROOT    "Canonical scripts dir"                       "$VAULT_ROOT/.claudian/scripts"
ask SENSITIVE_STORE "Where sensitive files are routed (outside git)" "$SENSITIVE_STORE_DEFAULT"
ask STACK_ROOT      "Local docker stack dir (blank if unused)"    "$STACK_ROOT_DEFAULT"
ask HOME_PLACEHOLDER "Home directory"                             "$HOME_DEFAULT"

echo ""
echo "  VAULT_ROOT      = $VAULT_ROOT"
echo "  SCRIPTS_ROOT    = $SCRIPTS_ROOT"
echo "  SENSITIVE_STORE = $SENSITIVE_STORE"
echo "  STACK_ROOT      = ${STACK_ROOT:-<unused>}"
echo "  HOME            = $HOME_PLACEHOLDER"
echo ""
if [[ $AUTO -eq 0 ]]; then
  read -r -p "Apply these replacements? [y/N] " ok || true
  [[ "${ok:-}" =~ ^[Yy]$ ]] || { echo "aborted."; exit 1; }
fi

# STACK_ROOT blank -> leave a clear marker rather than an empty path
STACK_SUB="${STACK_ROOT:-/path/to/your/stack}"

FILES=$(grep -rlE "__(VAULT_ROOT|SCRIPTS_ROOT|STACK_ROOT|SENSITIVE_STORE|HOME)__" "$HERE" 2>/dev/null || true)
for f in $FILES; do
  sed -i \
    -e "s#__VAULT_ROOT__#${VAULT_ROOT}#g" \
    -e "s#__SCRIPTS_ROOT__#${SCRIPTS_ROOT}#g" \
    -e "s#__STACK_ROOT__#${STACK_SUB}#g" \
    -e "s#__SENSITIVE_STORE__#${SENSITIVE_STORE}#g" \
    -e "s#__HOME__#${HOME_PLACEHOLDER}#g" \
    "$f"
done

mkdir -p "$SENSITIVE_STORE" "$VAULT_ROOT/.trash"
chmod +x "$HERE"/.claudian/scripts/*.sh "$HERE"/.claudian/hooks/* 2>/dev/null || true

echo ""
echo "Done. Replaced placeholders in $(echo "$FILES" | wc -w) files."
echo "Next: read SETUP.md 'After setup.sh' section, then install hooks."
