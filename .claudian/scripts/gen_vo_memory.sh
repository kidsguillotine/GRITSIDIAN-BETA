#!/usr/bin/env bash
# gen_vo_memory.sh: Regenerate knowledge.md and projects.md from templates + canonical include markers
# =============================================================================
# OD-47 option B rewrite (2026-07-01). This generator no longer embeds
# canonical content. It reads templates from .claudian/config/vo_memory_template.*.md
# and resolves VO_MEMORY_RESOLVE markers by extracting sections from canonical
# docs (CLAUDE.md, SYMLINK_REGISTRY.md, PENDING_WORK.md).
#
# Spec: _handoff/vip_next_session/GEN_VO_MEMORY_REWRITE_SPEC.md
#
# Called by:
#   generate_handoff.sh : at session close
#   hourly_snapshot.sh  : after commit
#
# Standalone: bash .claudian/scripts/gen_vo_memory.sh [--output-dir <dir>]
#   --output-dir <dir>  Write knowledge.md and projects.md to <dir> instead of
#                       the default 99_system/obsilo-memory/. Used by step-7
#                       dry-run diff against current live memory.
#
# Failure mode: broken include (missing target file, missing/duplicate/mismatched
# markers) emits a VO_MEMORY_RESOLVE_ERROR block inline AND sets exit code 1.
# Silent failure is forbidden per the spec.

set -uo pipefail

VAULT="${VAULT:-__VAULT_ROOT__}"
CONFIG_DIR="$VAULT/.claudian/config"
OUTPUT_DIR="$VAULT/99_system/obsilo-memory"

# CLI: --output-dir <path>
while [ $# -gt 0 ]; do
  case "$1" in
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "[gen_vo_memory] unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

DATE="$(date '+%Y-%m-%d')"
TS="$(python3 -c 'from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())')"

EXIT_CODE=0

# -- Dynamic data --------------------------------------------------------------

RESUME="$(git -C "$VAULT" log --oneline --grep='session close' -1 --pretty='%s' 2>/dev/null || true)"
[ -z "$RESUME" ] && RESUME="$(git -C "$VAULT" log --oneline -1 --pretty='%s' 2>/dev/null || echo '(no git history)')"

# Folder Schema: walk filesystem, look up description in folder_desc.yaml.
# Unknown folders are silently omitted (add a row to folder_desc.yaml to surface them).
FOLDER_DESC_FILE="$CONFIG_DIR/folder_desc.yaml"
FOLDER_ROWS=""
if [ ! -f "$FOLDER_DESC_FILE" ]; then
  FOLDER_ROWS="| (error) | folder_desc.yaml not found at $FOLDER_DESC_FILE |"
  EXIT_CODE=1
else
  while IFS= read -r dir; do
    base="$(basename "$dir")"
    case "$base" in .*) continue ;; esac
    desc="$(awk -F': ' -v key="$base" '
      $1 == key {
        # everything after the first ": " is the value; strip surrounding quotes
        idx = index($0, ": ")
        val = substr($0, idx + 2)
        sub(/^"/, "", val); sub(/"$/, "", val)
        print val
        exit
      }
    ' "$FOLDER_DESC_FILE")"
    if [ -n "$desc" ]; then
      FOLDER_ROWS+="| \`${base}/\` | ${desc} |"$'\n'
    fi
  done < <(find "$VAULT" -mindepth 1 -maxdepth 1 -type d | sort)
fi

# Phase content: PHASE_STATE.md body after frontmatter
PHASE_CONTENT="$(awk '/^---$/{n++;next} n>=2{print}' \
  "$VAULT/_handoff/PHASE_STATE.md" 2>/dev/null \
  || echo '(PHASE_STATE.md not readable)')"

# GOTCHAS compact form: heading + up to 3 non-blank content lines per entry
GOTCHAS_COUNT="$(grep -cE '^#{2,3} G[0-9]+' \
  "$VAULT/_handoff/GOTCHAS.md" 2>/dev/null | head -1 | tr -dc '0-9')"
GOTCHAS_COUNT="${GOTCHAS_COUNT:-0}"

GOTCHAS_COMPACT="$(awk '
  BEGIN { in_g=0; n=0; first=1 }
  /^#{2,3} G[0-9]+/ {
    if (!first) printf "\n"
    print; in_g=1; n=0; first=0; next
  }
  !in_g { next }
  /^[[:space:]]*$/ { next }
  n < 3 { print; n++; next }
  { next }
' "$VAULT/_handoff/GOTCHAS.md" 2>/dev/null)"

# Security fires count
SEC_COUNT="$(awk '
  /^## .*IMMEDIATE.*SECURITY/{p=1;next}
  p && /^## /{p=0}
  p && /^- \[ \]/{n++}
  END{print n+0}
' "$VAULT/_handoff/PENDING_WORK.md" 2>/dev/null || echo '?')"

# -- Resolver -----------------------------------------------------------------
#
# resolve_include <rel_path> <section_id>
# Emits content between VO_MEMORY_INCLUDE_BEGIN/END markers on stdout.
# On any failure (file missing, wrong marker count), emits a
# VO_MEMORY_RESOLVE_ERROR line and sets EXIT_CODE=1.

resolve_include() {
  local rel_path="$1"
  local section_id="$2"
  local target="$VAULT/$rel_path"

  if [ ! -f "$target" ]; then
    printf 'VO_MEMORY_RESOLVE_ERROR: file not found: %s (section %s)\n' "$rel_path" "$section_id"
    EXIT_CODE=1
    return
  fi

  local n_begin n_end
  n_begin="$(grep -cE "^<!-- VO_MEMORY_INCLUDE_BEGIN: ${section_id} -->$" "$target" 2>/dev/null || echo 0)"
  n_end="$(grep -cE "^<!-- VO_MEMORY_INCLUDE_END: ${section_id} -->$" "$target" 2>/dev/null || echo 0)"

  if [ "$n_begin" != "1" ] || [ "$n_end" != "1" ]; then
    printf 'VO_MEMORY_RESOLVE_ERROR: %s :: %s: expected 1 BEGIN + 1 END, got %s BEGIN + %s END\n' \
      "$rel_path" "$section_id" "$n_begin" "$n_end"
    EXIT_CODE=1
    return
  fi

  awk -v id="$section_id" '
    $0 == ("<!-- VO_MEMORY_INCLUDE_BEGIN: " id " -->") { inside=1; next }
    $0 == ("<!-- VO_MEMORY_INCLUDE_END: " id " -->")   { inside=0; next }
    inside { print }
  ' "$target"
}

# process_template <template_path> <output_path>
# Resolves RESOLVE markers first, then substitutes placeholders via perl -0777.
process_template() {
  local template="$1"
  local output="$2"

  if [ ! -f "$template" ]; then
    # Optional layer. No template means this install does not use VO memory, which
    # is the normal case for a fresh vault. Skip without failing.
    echo "[gen_vo_memory] skip: no template at $template (optional, not configured)"
    return 0
  fi

  local resolved
  resolved="$(mktemp)"

  # Pass 1: resolve RESOLVE markers line-by-line
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^\<\!--\ VO_MEMORY_RESOLVE:\ (.+)\ ::\ (.+)\ --\>$ ]]; then
      local rel="${BASH_REMATCH[1]}"
      local id="${BASH_REMATCH[2]}"
      resolve_include "$rel" "$id" >> "$resolved"
    else
      printf '%s\n' "$line" >> "$resolved"
    fi
  done < "$template"

  # Pass 2: placeholder substitution via python3 (str.replace is literal -
  # safe with &, \, and multi-line values). Explicit error check because a
  # silent failure here would emit an empty memory file.
  export TS DATE RESUME FOLDER_ROWS PHASE_CONTENT GOTCHAS_COUNT GOTCHAS_COMPACT SEC_COUNT
  if ! python3 -c '
import os, sys
data = open(sys.argv[1]).read()
subs = {
  "{{TS}}": os.environ["TS"],
  "{{DATE}}": os.environ["DATE"],
  "{{RESUME}}": os.environ["RESUME"],
  "{{FOLDER_ROWS}}": os.environ["FOLDER_ROWS"],
  "{{PHASE_CONTENT}}": os.environ["PHASE_CONTENT"],
  "{{GOTCHAS_COUNT}}": os.environ["GOTCHAS_COUNT"],
  "{{GOTCHAS_COMPACT}}": os.environ["GOTCHAS_COMPACT"],
  "{{SEC_COUNT}}": os.environ["SEC_COUNT"],
}
for k, v in subs.items():
    data = data.replace(k, v)
sys.stdout.write(data)
' "$resolved" > "$output"; then
    echo "[gen_vo_memory] ERROR: placeholder substitution failed for $output" >&2
    EXIT_CODE=1
    rm -f "$resolved"
    return
  fi

  rm -f "$resolved"
  echo "[gen_vo_memory] wrote $output ($(wc -l < "$output") lines)"
}

# -- Execute -------------------------------------------------------------------

process_template "$CONFIG_DIR/vo_memory_template.knowledge.md" "$OUTPUT_DIR/knowledge.md"
process_template "$CONFIG_DIR/vo_memory_template.projects.md" "$OUTPUT_DIR/projects.md"

if [ "$EXIT_CODE" -ne 0 ]; then
  echo "[gen_vo_memory] one or more VO_MEMORY_RESOLVE_ERROR blocks emitted: inspect output" >&2
fi

exit "$EXIT_CODE"
