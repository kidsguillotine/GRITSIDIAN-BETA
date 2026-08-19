#!/usr/bin/env bash
# constants.sh: Shared literals for vault shell scripts
# ======================================================
# Source this file at the top of any script that uses the values below:
#   source "$(dirname "$0")/constants.sh"
#
# This file IS the canonical source for shared literals. See DOC_STANDARD section 9.
# Add new constants there AND here simultaneously.
# C9 in validate_system.sh warns when a script hardcodes a value from this file.

# -- Service ports -------------------------------------------------------------
PORT_OBSIDIAN_HTTPS=27124
PORT_OBSIDIAN_HTTP=27123
PORT_VO_MCP=27182
PORT_OLLAMA=11434
PORT_AGENT_RUNNER=8766
PORT_CHROMADB=8000
PORT_CALENDAR=8090
PORT_N8N=5678

# -- Formatting ----------------------------------------------------------------
# Em-dash U+2014: used in MIGRATION_LOG date-headers and grep patterns
EM_DASH="-"
MIGRATION_DATE_PATTERN="^[0-9]{4}-[0-9]{2}-[0-9]{2}: "

# -- Block markers (format contracts) -----------------------------------------
OD_BEGIN="<!-- BEGIN_PENDING -->"
OD_END="<!-- END_PENDING -->"
IH_BEGIN="<!-- BEGIN_PENDING_REVIEW -->"
IH_END="<!-- END_PENDING_REVIEW -->"

# -- Thresholds ----------------------------------------------------------------
DEDUP_THRESHOLD="0.99"
C6_CUTOFF_DATE="2026-06-25"

# -- Paths ---------------------------------------------------------------------
VAULT_DEFAULT="__VAULT_ROOT__"
GRITSIDIAN_SCRIPTS="__SCRIPTS_ROOT__/scripts"
AGENT_MEMORY_DB="${HOME}/.local/share/agent_memory/memory.db"
