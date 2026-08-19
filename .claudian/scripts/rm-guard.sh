#!/usr/bin/env bash
# rm-guard.sh: PreToolUse hook blocking rm on vault content files
# Called by Claude Code before every Bash tool use.
# Receives tool invocation JSON on stdin.
# Exit 0: allow. Exit 1: block with error message to stderr.
# Fails open (exit 0) if input cannot be parsed: never block valid commands silently.

set -euo pipefail

INPUT=$(cat 2>/dev/null || true)

# If no input, allow
if [ -z "$INPUT" ]; then
  exit 0
fi

# Extract command field from tool input JSON
CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Handle flat {command: ...} or nested {tool_input: {command: ...}}
    if 'command' in d:
        print(d['command'])
    elif 'tool_input' in d and isinstance(d['tool_input'], dict) and 'command' in d['tool_input']:
        print(d['tool_input']['command'])
except Exception:
    pass
" 2>/dev/null || true)

# If no command found, allow
if [ -z "$CMD" ]; then
  exit 0
fi

# Block rm on protected extensions
if echo "$CMD" | grep -qE '\brm\b.*\.(md|txt|csv)(\b|\s|$)'; then
  printf 'BLOCKED [rm-guard]: rm on .md/.txt/.csv is prohibited by CLAUDE.md.\n' >&2
  printf 'Correct approach: mv <file> %s/.trash/<unique-name>\n' '__VAULT_ROOT__' >&2
  exit 1
fi

exit 0
