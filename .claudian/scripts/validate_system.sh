#!/usr/bin/env bash
# validate_system.sh: Referential integrity validator (C1 + C2 + C3 + C4 + C6 + OD-residue)
#
# C1: SYSTEM_DOC_MAP.md -> filesystem                              [hard-block]
#     Every file listed in the map must exist on disk.
#     Closes the silent-rot gap where deleting a mapped file leaves a dangling
#     entry that no forward orphan check catches (confirmed live 2026-06-25:
#     4 dangling entries found and repaired from last session's consolidation).
#
# C2: filesystem -> SYSTEM_DOC_MAP + SYMLINK_REGISTRY              [VIP item]
#     Every .md in _handoff/ + 99_system/ (excl. archive/handoff_history/
#     erosion_audit/) must appear in SYSTEM_DOC_MAP. Also checks
#     .claudian/scripts/ .sh/.py files against SYMLINK_REGISTRY (option B).
#     Formalizes the §Orphan Check snippet in SYSTEM_DOC_MAP.md.
#     Non-blocking: emits UNMAPPED: lines, never increments ERRORS.
#
# C3: SYMLINK_REGISTRY.md -> symlink resolution                    [hard-block]
#     Every active symlink must exist and resolve to a live canonical target.
#     Closes the silent-degrade gap where a broken symlink causes agent_runner
#     to silently no-op features (interaction_log, op_log, idempotency).
#
# C4: SCRIPT_REGISTRY.md <-> .claudian/scripts/ roster            [hard-block]
#     Two-way diff: registry entry without file (MISSING_SCRIPT) or
#     file on disk without registry entry (UNMAPPED_SCRIPT).
#
# C6: MIGRATION_LOG.txt format lint                               [VIP item]
#     Post-convention entries (>= 2026-06-25) must match ^YYYY-MM-DD: .
#     Pre-convention colon entries are permanently grandfathered (G40).
#     Non-blocking: emits FORMAT_VIOLATION: lines, never increments ERRORS.
#
# OD-residue: OPEN_DECISIONS.md PENDING block consistency           [VIP item]
#     Warns when a "### OD-N" heading in the PENDING block carries
#     "**Status:** RESOLVED": the count-divergence class C5 left open.
#     Makes stranded resolved ODs visible before they corrupt session counts.
#     Non-blocking: emits OD_RESIDUE: lines, never increments ERRORS.
#
# Usage:
#   bash validate_system.sh         : exit 1 on DANGLING or BROKEN_LINK
#   bash validate_system.sh --soft  : exit 0 always (for hourly cron)
#
# Output lines:
#   DANGLING: <rel-path>                 : C1 miss (file in map, not on disk)
#   UNMAPPED: <rel-path>                 : C2 miss (file on disk, not in map)
#   BROKEN_LINK: <rel-path> -> <target>  : C3 miss (symlink missing or dead)
#   MISSING_SCRIPT: <name>              : C4 miss (in registry, not on disk)
#   UNMAPPED_SCRIPT: <name>             : C4 miss (on disk, not in registry)
#   FORMAT_VIOLATION: line N: <content> : C6 miss (wrong date-header format)
#   OD_RESIDUE: OD-N in PENDING block has non-PENDING status: evict to RESOLVED section
#   OK C1/C2/C3/C4/C6/OD-residue: ...
#   VALIDATE: OK  |  VALIDATE: N hard error(s) found
#
# Location: vault/.claudian/scripts/ (vault-only infrastructure)
#   NOT in .claudian/scripts/: this is personal vault tooling, not product.
#   Per SYMLINK_REGISTRY "Vault-Only Scripts" table.
#
# Wired into:
#   session_close.sh : called first; exit 1 blocks the close sequence
#   hourly_snapshot.sh: called with --soft; output logged, never blocks push
#
# Spec: 99_system/SCRIPT_SPECS.md (what each check means)
# Added: 2026-06-25 (C1+C3+C4); C2+C6 added 2026-06-25 (OD-34+OD-35)

set -uo pipefail

VAULT="${VAULT:-__VAULT_ROOT__}"

# Fail loud rather than validating nothing. A validator that reports OK because it
# examined zero files is worse than no validator (see GOTCHAS G16: no output is not
# the same as nothing wrong).
if [ ! -d "$VAULT" ]; then
    echo "FATAL: vault path does not exist: $VAULT" >&2
    echo "  Run setup.sh to replace the placeholder, or pass VAULT=/path explicitly." >&2
    exit 2
fi
PAS="__STACK_ROOT__"

SOFT=false
[[ "${1:-}" == "--soft" ]] && SOFT=true

ERRORS=0

# --- C1: SYSTEM_DOC_MAP -> filesystem ----------------------------------------
#
# Parses SYSTEM_DOC_MAP.md section by section:
#   - "### <folder/>..." lines set the current folder context
#   - Table data rows extract the doc name from the first column
#   - Builds expected path = VAULT/folder/doc and checks existence
#
# Skips:
#   - Header/separator rows ("Doc", "---")
#   - Wildcard/template entries (contain * or <)
#   - Entries without a recognizable file extension
c1_check() {
  local map="$VAULT/99_system/SYSTEM_DOC_MAP.md"
  local checked=0 dangling=0
  local folder=""

  while IFS= read -r line; do
    # Any header (## or ###): update or clear folder context.
    # This prevents the "cascade" bug where a folder set by a ### subsection
    # persists into the next ## top-level section (which uses a different base).
    if [[ "$line" =~ ^##+[[:space:]] ]]; then
      # Try to extract a vault-relative path from the header title.
      # Path token: starts with word-char or dot, contains path chars, ends with /
      if [[ "$line" =~ ^##+[[:space:]]([._a-zA-Z0-9][a-zA-Z0-9_./-]*/) ]]; then
        local candidate="${BASH_REMATCH[1]}"
        # Skip non-vault repo sections: those files aren't in $VAULT
        if [[ "$candidate" == "your-stack/"* || \
              "$candidate" == "your-scripts/"* ]]; then
          folder=""
        else
          folder="$candidate"
        fi
      else
        # No path in header (e.g. "## High-Centrality Nodes", "## Orphan Check")
        #: skip this section entirely
        folder=""
      fi
      continue
    fi
    [[ -z "$folder" ]] && continue

    # Table data row: must have at least two pipe-delimited columns
    [[ "$line" =~ ^\|[[:space:]]*([^|]+)[[:space:]]*\|.*\|.* ]] || continue
    local doc="${BASH_REMATCH[1]}"
    doc=$(echo "$doc" | xargs)   # trim surrounding whitespace
    doc="${doc//\`/}"            # strip markdown backticks

    # Skip header rows
    [[ "$doc" == "Doc" || "$doc" == "Folder" || "$doc" == "File" || \
       "$doc" == "Script" || "$doc" == "Symlink"* || "$doc" == "Block"* ]] && continue
    # Skip separator rows
    [[ "$doc" == ---* ]] && continue
    # Skip empty
    [[ -z "$doc" ]] && continue
    # Skip strikethrough (inline-archived) entries: ~~filename~~
    [[ "$doc" == "~~"* ]] && continue
    # Skip wildcard / template entries (contain * or <YYYY> etc.)
    [[ "$doc" == *\** || "$doc" == *\<* ]] && continue
    # Skip block-descriptor entries like "SESSION_HANDOFF_YYYYMMDD_vN.md (52+ files)"
    [[ "$doc" == *"("* ]] && continue
    # Skip symlink reference entries like "**symlink** -> ..."
    [[ "$doc" == "**symlink**"* ]] && continue
    # Skip entries without a recognizable file extension
    [[ "$doc" != *.md && "$doc" != *.txt && "$doc" != *.sh && \
       "$doc" != *.py && "$doc" != *.yaml && "$doc" != *.json ]] && continue

    local full="$VAULT/${folder}${doc}"
    checked=$((checked + 1))
    if [[ ! -e "$full" ]]; then
      echo "DANGLING: ${folder}${doc}"
      dangling=$((dangling + 1))
      ERRORS=$((ERRORS + 1))
    fi
  done < "$map"

  if [[ $dangling -eq 0 ]]; then
    echo "OK C1: $checked entries checked, 0 dangling"
  else
    echo "FAIL C1: $checked entries checked, $dangling dangling"
  fi
}

# --- C2: filesystem -> SYSTEM_DOC_MAP + SYMLINK_REGISTRY ---------------------
#
# Formalizes the §Orphan Check bash snippet in SYSTEM_DOC_MAP.md.
# _handoff/ + 99_system/: every .md must appear in SYSTEM_DOC_MAP.
# .claudian/prompts/ + .claudian/config/: every .md/.yaml vs SYSTEM_DOC_MAP.
# .claudian/scripts/ (option B): every .sh/.py vs SYMLINK_REGISTRY.
#
# NON-BLOCKING: emits UNMAPPED: / WARN lines; never increments ERRORS.
c2_check() {
  local map="$VAULT/99_system/SYSTEM_DOC_MAP.md"
  local registry="$VAULT/99_system/SYMLINK_REGISTRY.md"
  local unmapped=0 checked=0

  # _handoff/ + 99_system/: recursive, excluding block-tracked subdirs
  while IFS= read -r filepath; do
    local bn
    bn="$(basename "$filepath")"
    checked=$((checked + 1))
    if ! grep -qF "$bn" "$map" 2>/dev/null; then
      local rel="${filepath#$VAULT/}"
      echo "UNMAPPED: $rel"
      unmapped=$((unmapped + 1))
    fi
  done < <(find "$VAULT/_handoff" "$VAULT/99_system" \
                -name "*.md" \
                -not -path "*/archive/*" \
                -not -path "*/handoff_history/*" \
                -not -path "*/erosion_audit/*" \
                -not -name "reconcile_*.md" \
                2>/dev/null)

  # .claudian/prompts/ + .claudian/config/ -> SYSTEM_DOC_MAP
  for dir in "$VAULT/.claudian/prompts" "$VAULT/.claudian/config"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*.md "$dir"/*.yaml; do
      [[ -f "$f" ]] || continue
      local bn
      bn="$(basename "$f")"
      checked=$((checked + 1))
      if ! grep -qF "$bn" "$map" 2>/dev/null; then
        local rel="${f#$VAULT/}"
        echo "UNMAPPED: $rel"
        unmapped=$((unmapped + 1))
      fi
    done
  done

  # .claudian/scripts/ -> SYMLINK_REGISTRY (option B: added OD-34 resolution)
  for f in "$VAULT/.claudian/scripts"/*.sh "$VAULT/.claudian/scripts"/*.py; do
    [[ -f "$f" ]] || continue
    local bn
    bn="$(basename "$f")"
    # Skip non-script files
    [[ "$bn" == "__"* || "$bn" == "requirements.txt" ]] && continue
    checked=$((checked + 1))
    if ! grep -qF "$bn" "$registry" 2>/dev/null; then
      local rel="${f#$VAULT/}"
      echo "UNMAPPED: $rel  (not in SYMLINK_REGISTRY)"
      unmapped=$((unmapped + 1))
    fi
  done

  if [[ $unmapped -eq 0 ]]; then
    echo "OK C2: $checked files checked, 0 unmapped"
  else
    echo "WARN C2: $checked files checked, $unmapped unmapped (VIP: add to SYSTEM_DOC_MAP or SYMLINK_REGISTRY)"
  fi
  # Never increments ERRORS: non-blocking
}

# --- C3: SYMLINK_REGISTRY -> symlink resolution -------------------------------
#
# Parses the "## Active Symlinks" section of SYMLINK_REGISTRY.md.
# Table format: | <symlink-path> | <canonical> | <date> |
# Determines base directory from symlink path prefix:
#   .claudian/  -> VAULT
#   docs/       -> PAS
#   scripts/    -> PAS
# Checks:
#   1. Symlink path exists as a symlink (or regular file for vault-only scripts)
#   2. If it's a symlink, it resolves to an existing target
c3_check() {
  local registry="$VAULT/99_system/SYMLINK_REGISTRY.md"
  local checked=0 broken=0
  local in_active=false

  while IFS= read -r line; do
    # Enter Active Symlinks section
    [[ "$line" =~ ^##[[:space:]]Active[[:space:]]Symlinks ]] && { in_active=true; continue; }
    # Exit at next top-level section (## but not ### subsection, not Active)
    if [[ "$in_active" == true && \
          "$line" =~ ^##[[:space:]][^#] && \
          ! "$line" =~ ^##[[:space:]]Active ]]; then
      break
    fi
    [[ "$in_active" == false ]] && continue

    # Table data row (2+ pipe-delimited columns)
    [[ "$line" =~ ^\|[[:space:]]*([^|]+)[[:space:]]*\|.*\|.* ]] || continue
    local symlink_col="${BASH_REMATCH[1]}"
    symlink_col=$(echo "$symlink_col" | xargs)
    symlink_col="${symlink_col//\`/}"  # strip backticks

    # Skip header / separator rows
    [[ "$symlink_col" == "Symlink"* || "$symlink_col" == ---* || -z "$symlink_col" ]] && continue

    # Resolve base directory from prefix
    local full_link
    if [[ "$symlink_col" == .claudian/* ]]; then
      full_link="$VAULT/$symlink_col"
    elif [[ "$symlink_col" == docs/* ]]; then
      full_link="$PAS/$symlink_col"
    elif [[ "$symlink_col" == scripts/* ]]; then
      full_link="$PAS/$symlink_col"
    else
      continue  # unknown prefix: skip
    fi

    checked=$((checked + 1))

    if [[ ! -L "$full_link" && ! -e "$full_link" ]]; then
      # Neither symlink nor file at that path
      echo "BROKEN_LINK: $symlink_col: does not exist"
      broken=$((broken + 1))
      ERRORS=$((ERRORS + 1))
    elif [[ -L "$full_link" && ! -e "$full_link" ]]; then
      # Symlink exists but target is missing (dangling symlink)
      local target
      target=$(readlink "$full_link" 2>/dev/null || echo "unknown")
      echo "BROKEN_LINK: $symlink_col -> $target (target missing)"
      broken=$((broken + 1))
      ERRORS=$((ERRORS + 1))
    fi
    # If -e but not -L: it's a regular file (expected for vault-only scripts
    # in .claudian/scripts/ that aren't actually symlinks): OK
  done < "$registry"

  if [[ $broken -eq 0 ]]; then
    echo "OK C3: $checked symlinks checked, 0 broken"
  else
    echo "FAIL C3: $checked symlinks checked, $broken broken"
  fi
}

# --- C4: SCRIPT_REGISTRY -> .claudian/scripts/ roster reconciliation ---------
#
# Two-way diff between the SCRIPT_REGISTRY.md table and .claudian/scripts/*.py:
#   UNMAPPED_SCRIPT: .py exists on disk but has no SCRIPT_REGISTRY entry
#   MISSING_SCRIPT:  entry is in SCRIPT_REGISTRY but file is absent from disk
#
# Scope: only the "## .claudian/scripts/" section of SCRIPT_REGISTRY.
# Vault-only .claudian/scripts/ entries are tracked separately (different table).
# Skips requirements.txt, __pycache__, and any non-.py files on disk.
#
# Closes the silent-drift gap: new script added to .claudian/scripts/ without
# a SCRIPT_REGISTRY entry (or vice versa) fails loud rather than accruing
# undocumented tech debt.
c4_check() {
  local registry="$VAULT/99_system/SCRIPT_REGISTRY.md"
  local scripts_dir="${SCRIPTS_DIR:-$VAULT/.claudian/scripts}"
  local drift=0

  # Extract .py filenames from the .claudian/scripts/ section of SCRIPT_REGISTRY
  # Stops at the next ## heading.
  local reg_scripts
  reg_scripts=$(awk -F'|' '
    /^## \.claudian\/scripts\//{in_sec=1; next}
    /^## / && in_sec {in_sec=0}
    in_sec {
      val=$2
      gsub(/[[:space:]`]/, "", val)
      if (val ~ /\.py$/) print val
    }
  ' "$registry" 2>/dev/null | sort)

  # Actual .py files on disk (basename only, sorted)
  local fs_scripts
  fs_scripts=$(ls "$scripts_dir"/*.py 2>/dev/null | xargs -I{} basename {} | sort)

  local reg_count=0

  # REGISTRY -> fs: every registered script must exist on disk
  while IFS= read -r script; do
    [[ -z "$script" ]] && continue
    reg_count=$((reg_count + 1))
    if ! echo "$fs_scripts" | grep -qx "$script"; then
      echo "MISSING_SCRIPT: $script (SCRIPT_REGISTRY entry has no file in .claudian/scripts/)"
      drift=$((drift + 1))
      ERRORS=$((ERRORS + 1))
    fi
  done <<< "$reg_scripts"

  # fs -> REGISTRY: every disk .py must have a SCRIPT_REGISTRY entry
  while IFS= read -r script; do
    [[ -z "$script" ]] && continue
    if ! echo "$reg_scripts" | grep -qx "$script"; then
      echo "UNMAPPED_SCRIPT: $script (in .claudian/scripts/, missing from SCRIPT_REGISTRY)"
      drift=$((drift + 1))
      ERRORS=$((ERRORS + 1))
    fi
  done <<< "$fs_scripts"

  if [[ $drift -eq 0 ]]; then
    echo "OK C4: $reg_count registry entries checked, 0 roster drift"
  else
    echo "FAIL C4: $drift roster drift(s) found"
  fi
}

# --- C6: MIGRATION_LOG format lint -------------------------------------------
#
# Scans _handoff/MIGRATION_LOG.txt for date-header lines that don't match
# the canonical em-dash format gen_session_boot.sh expects.
# Canonical: ^YYYY-MM-DD: <description>  (em-dash U+2014; confirmed gen_session_boot.sh:65)
# Violation: typically colon format ^YYYY-MM-DD: ... (G40 failure mode)
#
# NON-BLOCKING: emits FORMAT_VIOLATION: lines; never increments ERRORS.
# Scope: post-convention entries only (>= C6_CUTOFF). Pre-cutoff entries use
# colon format by design (G40) and are permanently grandfathered. A violation
# here means a NEW write used the wrong format: the signal is unburied.
c6_check() {
  local mlog="$VAULT/_handoff/MIGRATION_LOG.txt"
  local C6_CUTOFF="2026-06-25"  # First full day after G40 adoption: pre-convention 2026-06-24 colon entries grandfathered
  local violations=0 checked=0

  while IFS= read -r numbered_line; do
    # grep -n output: "lineno:content"
    local lineno="${numbered_line%%:*}"
    local content="${numbered_line#*:}"
    # Skip pre-convention entries (lexicographic ISO date compare)
    local entry_date="${content:0:10}"
    [[ "$entry_date" < "$C6_CUTOFF" ]] && continue
    checked=$((checked + 1))
    # Canonical: date followed by space + em-dash + space
    if ! echo "$content" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}: '; then
      echo "FORMAT_VIOLATION: line $lineno: $content"
      violations=$((violations + 1))
    fi
  done < <(grep -nE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' "$mlog" 2>/dev/null)

  if [[ $violations -eq 0 ]]; then
    echo "OK C6: $checked post-convention date-header lines checked, 0 format violations"
  else
    echo "WARN C6: $checked post-convention lines, $violations FORMAT_VIOLATION(s): new bad write detected"
  fi
  # Never increments ERRORS: non-blocking
}

# NON-BLOCKING: warns when a resolved OD is stranded in the PENDING block.
# Closes the count-divergence class C5 left open: the PENDING block and the
# **Status:** field are two representations of resolved-state that can drift.
# Stranded entries corrupt gen_session_boot.sh OD count and mislead session start.
od_residue_check() {
  local od_file="$VAULT/_handoff/OPEN_DECISIONS.md"
  local residues=0
  local cur_id=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^"### OD-"([0-9]+) ]]; then
      cur_id="${BASH_REMATCH[1]}"
    elif [[ -n "$cur_id" ]] && echo "$line" | grep -qE '(\*\*)?Status:(\*\*)?'; then
      # Status line found for this entry: check if it's not PENDING
      if ! [[ "$line" =~ \*\*Status:\*\*[[:space:]]+PENDING[[:space:]]*$ ]]; then
        echo "OD_RESIDUE: OD-${cur_id} in PENDING block has non-PENDING status: evict to RESOLVED section"
        (( residues++ )) || true
      fi
      cur_id=""  # status consumed; reset for next entry
    fi
  done < <(awk '/BEGIN_PENDING/{p=1;next} /END_PENDING/{p=0} p' "$od_file" 2>/dev/null)

  if [[ $residues -eq 0 ]]; then
    echo "OK OD-residue: PENDING block clean"
  else
    echo "WARN OD-residue: $residues resolved OD(s) stranded in PENDING block: evict before session close"
  fi
  # Never increments ERRORS: non-blocking
}

# -- C8: Format contract linter -----------------------------------------------
# Verifies that HIGH-priority block markers (format contracts) are intact in
# docs consumed by scripts. A missing marker silently breaks PENDING counting.
# Source: 99_system/DOC_STANDARD.md section 8 (format contracts). Non-blocking.
c8_check() {
  local issues=0

  # OPEN_DECISIONS.md: BEGIN_PENDING / END_PENDING
  local od_file="$VAULT/_handoff/OPEN_DECISIONS.md"
  if [[ -f "$od_file" ]]; then
    grep -qF "<!-- BEGIN_PENDING -->" "$od_file" || { echo "WARN C8: OPEN_DECISIONS.md missing <!-- BEGIN_PENDING --> marker"; (( issues++ )) || true; }
    grep -qF "<!-- END_PENDING -->" "$od_file"   || { echo "WARN C8: OPEN_DECISIONS.md missing <!-- END_PENDING --> marker"; (( issues++ )) || true; }
  else
    echo "WARN C8: OPEN_DECISIONS.md not found at $od_file"
    (( issues++ )) || true
  fi

  # IMPORTED_HANDOFFS.md: BEGIN_PENDING_REVIEW / END_PENDING_REVIEW
  local ih_file="$VAULT/_handoff/IMPORTED_HANDOFFS.md"
  if [[ -f "$ih_file" ]]; then
    grep -qF "<!-- BEGIN_PENDING_REVIEW -->" "$ih_file" || { echo "WARN C8: IMPORTED_HANDOFFS.md missing <!-- BEGIN_PENDING_REVIEW --> marker"; (( issues++ )) || true; }
    grep -qF "<!-- END_PENDING_REVIEW -->" "$ih_file"   || { echo "WARN C8: IMPORTED_HANDOFFS.md missing <!-- END_PENDING_REVIEW --> marker"; (( issues++ )) || true; }
  else
    echo "WARN C8: IMPORTED_HANDOFFS.md not found at $ih_file"
    (( issues++ )) || true
  fi

  if [[ $issues -eq 0 ]]; then
    echo "OK C8: format contracts intact (4 block markers present)"
  fi
  # Non-blocking (VIP item: never increments ERRORS)
}

# -- C9: BRE/ERE trap linter --------------------------------------------------
# Scans shell scripts for the G42 pattern: grep called with '^\|' or similar
# pipe-at-start patterns in BRE mode (without -E/-P). These silently match
# every line instead of filtering table rows.
# Source: GOTCHAS.md G42. Non-blocking.
c9_check() {
  local issues=0
  local scripts_dir="$VAULT/.claudian/scripts"

  # Pattern: grep calls containing '^\| (caret+backslash+pipe) without -E or -P.
  # Targets G42 exactly: table-row anchors in BRE mode silently match everything.
  # Fixed string '^\| matches the literal pattern; then filter lines that already
  # have -E/-P on the same line (those are correct ERE calls).
  while IFS= read -r hit; do
    echo "WARN C9: possible BRE \\| trap: $hit"
    (( issues++ )) || true
  done < <(grep -rnF "'^\\|" "$scripts_dir"/*.sh 2>/dev/null \
           | grep -vE '\-[a-zA-Z]*[EP]' \
           | grep -v '#' || true)
  # Fix 2026-06-26: was "'^\\\\" (looked for '^\\: wrong), now "'^\\|" (literal '^\|)
  # Combined-flag fix: -vE '\-[EP]' -> '-[a-zA-Z]*[EP]' to also catch -cE, -rnE etc.
  # Positive test confirmed: "grep '^\|.*x'" -> WARN fires. Correct -cE -> excluded.

  if [[ $issues -eq 0 ]]; then
    echo "OK C9: no BRE \\| trap patterns found in .claudian/scripts/*.sh"
  fi
  # Non-blocking (VIP item: never increments ERRORS)
}

# -- C10: Broken wikilink count -----------------------------------------------
# Counts broken wikilinks (EXT + DRIFT + ORPHAN) across the active vault via
# check_links.py. This is the integrity-layer fix for the G44 silent-failure
# class: the original integrity layer (C1-C9) verified the scaffolding
# describing itself, but never looked at whether wikilinks resolved. C10 closes
# that gap. Non-blocking soft-warn until baseline ≥95% OK rate, then re-evaluate.
# Source: WIKILINK_CRISIS_REPAIR_PLAN.md §3 + G44.
c10_check() {
  local resolver="$VAULT/.claudian/scripts/check_links.py"
  if [[ ! -f "$resolver" ]]; then
    echo "WARN C10: check_links.py not found at $resolver: skipping wikilink count"
    return
  fi
  local audit_json
  audit_json=$(python3 "$resolver" --audit --json 2>/dev/null)
  if [[ -z "$audit_json" ]]; then
    echo "WARN C10: check_links.py --audit --json produced no output"
    return
  fi
  # Parse JSON via python rather than shelling jq (jq not guaranteed present).
  local broken total ok_pct
  read -r broken total ok_pct < <(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['broken'], d['total'], d['ok_rate_pct'])" "$audit_json" 2>/dev/null)
  if [[ -z "$broken" ]]; then
    echo "WARN C10: failed to parse --audit JSON output"
    return
  fi
  # Crisis threshold: ≥95% OK = resolved (see _handoff/archive/WIKILINK_CRISIS_RESOLVED_2026-07-01.md)
  local ok_int
  ok_int=$(python3 -c "print(int(float('$ok_pct') >= 95))" 2>/dev/null)
  if [[ "$broken" == "0" ]]; then
    echo "OK C10: 0 broken wikilinks ($total total, 100.0% OK)"
  elif [[ "$ok_int" == "1" ]]; then
    echo "OK C10: $broken/$total broken wikilinks ($ok_pct% OK): G44 crisis RESOLVED (≥95% threshold met)"
  else
    echo "WARN C10: $broken/$total broken wikilinks ($ok_pct% OK): G44 crisis ongoing; see GOTCHAS G44"
  fi
  # Non-blocking: repair is gated, not validator-gated
}

# -- C11: IH completion state: PHASE_STATE vs IMPORTED_HANDOFFS --------------
# For each IH-N row in PHASE_STATE.md marked COMPLETE, look for an
# **Execution state:** field in IMPORTED_HANDOFFS.md for that IH.
# If the field exists and still says "in progress," that is a stale tracking
# state: work is done but the doc was not updated to match.
# Closes the silent-drift class caught manually for IH-9 on 2026-07-01 (sat
# IN PROGRESS 5 days after H1-H5 were complete).
# NON-BLOCKING: emits IH_STALE: lines; never increments ERRORS.
# OD-52 approved 2026-07-01.
c11_check() {
  local phase_state="$VAULT/_handoff/PHASE_STATE.md"
  local ih_file="$VAULT/_handoff/IMPORTED_HANDOFFS.md"

  if [[ ! -f "$phase_state" || ! -f "$ih_file" ]]; then
    echo "WARN C11: PHASE_STATE.md or IMPORTED_HANDOFFS.md not found: skipping"
    return
  fi

  local issues=0 checked=0

  while IFS= read -r line; do
    # Table rows only
    [[ "$line" =~ ^\| ]] || continue
    # Col 1 must contain IH-N; col 2 must contain COMPLETE
    [[ "$line" =~ \|[[:space:]]*[^|]*IH-([0-9]+)[^|]*\|[^|]*COMPLETE ]] || continue
    local ih_num="${BASH_REMATCH[1]}"
    checked=$((checked + 1))

    # Find the **Execution state:** line in the IH-N section of IMPORTED_HANDOFFS
    local exec_state
    exec_state=$(awk -v n="$ih_num" '
      /^### / { in_sec = ($0 ~ ("IH-" n "[^0-9]")) ? 1 : 0; next }
      in_sec && /\*\*Execution state:\*\*/ { print; exit }
    ' "$ih_file" 2>/dev/null)

    if [[ -n "$exec_state" ]] && echo "$exec_state" | grep -qi "in progress"; then
      echo "IH_STALE: IH-$ih_num: PHASE_STATE=COMPLETE but Execution state still shows 'in progress' in IMPORTED_HANDOFFS: update the field"
      issues=$((issues + 1))
    fi
  done < "$phase_state"

  if [[ $issues -eq 0 ]]; then
    echo "OK C11: $checked IH COMPLETE rows checked, 0 stale execution states"
  else
    echo "WARN C11: $issues IH(s) with stale Execution state in IMPORTED_HANDOFFS"
  fi
  # Non-blocking: never increments ERRORS
}

# -- C12: Pipeline script SKIP_DIRS vs vault filesystem -----------------------
# For schedule_surface.py, task_surface.py, frontmatter_to_ics.py: extracts
# non-dot folder names from the _SKIP_DIRS / SKIP_DIRS set literal (using
# python3 for reliable parse of multi-line set literals) and verifies each
# exists as a directory in $VAULT. Catches the 05_pre-inbox class: a folder
# reference added by copy-paste that never existed in the vault (caught by hand
# 2026-07-01, removed same session).
# NON-BLOCKING: emits SKIP_DIR_MISSING: lines; never increments ERRORS.
# OD-53 approved 2026-07-01.
c12_check() {
  local product_scripts="${SCRIPTS_DIR:-$VAULT/.claudian/scripts}"
  local issues=0 checked=0

  for script in schedule_surface.py task_surface.py frontmatter_to_ics.py; do
    local path="$product_scripts/$script"
    [[ -f "$path" ]] || continue

    # Use python3 to parse the SKIP_DIRS set literal reliably across multi-line defs
    local dirs
    dirs=$(python3 - "$path" <<'PYEOF'
import re, sys
try:
    content = open(sys.argv[1]).read()
    # Match _SKIP_DIRS, SKIP_DIRS, skip_dirs: any case of the pattern
    m = re.search(r'(?:_?SKIP_DIRS|_?skip_dirs)\s*=\s*\{([^}]+)\}', content, re.DOTALL)
    if m:
        for s in re.findall(r'"([^"]+)"|\'([^\']+)\'', m.group(1)):
            print(s[0] or s[1])
except Exception:
    pass
PYEOF
)

    while IFS= read -r dir; do
      [[ -z "$dir" ]] && continue
      # Skip dot-prefixed infrastructure dirs (.git, .obsidian, .trash, etc.)
      [[ "$dir" == .* ]] && continue
      checked=$((checked + 1))
      if [[ ! -d "$VAULT/$dir" ]]; then
        echo "SKIP_DIR_MISSING: '$dir': referenced in $script SKIP_DIRS but '$VAULT/$dir' does not exist"
        issues=$((issues + 1))
      fi
    done <<< "$dirs"
  done

  if [[ $issues -eq 0 ]]; then
    echo "OK C12: $checked non-dot SKIP_DIRS entries checked, all vault dirs exist"
  else
    echo "WARN C12: $issues SKIP_DIR_MISSING: stale folder reference(s) in pipeline script config"
  fi
  # Non-blocking: never increments ERRORS
}

# -- C13: SUPERSESSION_INDEX AUDIT PENDING surface ----------------------------
# Greps SUPERSESSION_INDEX.md for "AUDIT PENDING" text after the YAML
# frontmatter. Emits one warn per section found. Catches the silent-defer class
# where a supersession audit is flagged but has no session-close surface path -
# e.g. your-stack/docs/decision_log.md twice-deferred 2026-06-26 ->
# 2026-07-01 with no mechanism to flag age on the third deferral.
# NON-BLOCKING: emits SUPERSESSION_AUDIT_PENDING: lines; never increments ERRORS.
# OD-54 approved 2026-07-01.
c13_check() {
  local supersession="$VAULT/99_system/SUPERSESSION_INDEX.md"
  if [[ ! -f "$supersession" ]]; then
    echo "WARN C13: SUPERSESSION_INDEX.md not found at expected path"
    return
  fi

  local issues=0 cur_section="" past_frontmatter=false dash_count=0

  while IFS= read -r line; do
    # Skip YAML frontmatter (everything up to and including the closing ---)
    if [[ "$past_frontmatter" == false ]]; then
      if [[ "$line" == "---" ]]; then
        dash_count=$((dash_count + 1))
        [[ $dash_count -ge 2 ]] && past_frontmatter=true
      fi
      continue
    fi

    # Track current ## section for output context
    if [[ "$line" =~ ^##[[:space:]] ]]; then
      cur_section="${line#\#\# }"
    fi

    # Surface any AUDIT PENDING marker
    if echo "$line" | grep -qi "AUDIT PENDING"; then
      echo "SUPERSESSION_AUDIT_PENDING: ${cur_section:-unknown section}: see SUPERSESSION_INDEX.md"
      issues=$((issues + 1))
    fi
  done < "$supersession"

  if [[ $issues -eq 0 ]]; then
    echo "OK C13: SUPERSESSION_INDEX.md: no AUDIT PENDING sections"
  else
    echo "WARN C13: $issues AUDIT PENDING section(s) in SUPERSESSION_INDEX.md: review before deferring again"
  fi
  # Non-blocking: never increments ERRORS
}

# --- Run ---------------------------------------------------------------------

c1_check
c2_check
c3_check
c4_check
c6_check
od_residue_check
c8_check
c9_check
c10_check
c11_check
c12_check
c13_check

if [[ $ERRORS -gt 0 && "$SOFT" == "false" ]]; then
  echo "VALIDATE: $ERRORS error(s) found: fix DANGLING/BROKEN_LINK before session close"
  exit 1
elif [[ $ERRORS -gt 0 ]]; then
  echo "VALIDATE: $ERRORS error(s) found (soft mode: non-blocking)"
  exit 0
else
  echo "VALIDATE: OK"
  exit 0
fi
