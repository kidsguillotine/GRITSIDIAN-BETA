#!/usr/bin/env bash
# parse_file.sh: standard content spot-check for any file
# Usage: bash parse_file.sh <filepath>
# Output: head 60 / middle 30 / tail 60 with line numbers and date scan

set -euo pipefail

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: file not found: $FILE"
  exit 1
fi

TOTAL=$(wc -l < "$FILE")
MID_START=$(( TOTAL / 2 - 15 ))
[[ $MID_START -lt 1 ]] && MID_START=1

echo "FILE: $FILE"
echo "TOTAL LINES: $TOTAL"
echo ""

echo "=== HEAD 60 (lines 1-60) ==="
head -60 "$FILE"
echo ""

echo "=== MIDDLE 30 (lines $MID_START-$((MID_START + 30))) ==="
sed -n "${MID_START},$((MID_START + 30))p" "$FILE"
echo ""

TAIL_START=$(( TOTAL - 59 ))
[[ $TAIL_START -lt 1 ]] && TAIL_START=1
echo "=== TAIL 60 (lines ${TAIL_START}-$TOTAL) ==="
tail -60 "$FILE"
echo ""

echo "=== DATE SCAN ==="
grep -nE "[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}" "$FILE" \
  | head -20 || echo "no dates found"
echo ""

echo "=== FRONTMATTER CHECK ==="
awk '/^---$/{c++; if(c==1) start=NR; if(c==2){print "frontmatter: lines " start " to " NR; exit}} END{if(c<2) print "no closed frontmatter block"}' "$FILE"
