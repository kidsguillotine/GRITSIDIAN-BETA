#!/usr/bin/env bash
# vault_decision_check.sh: pre-decision verification for any file pair
# Usage: bash vault_decision_check.sh <file_A> <file_B>
# Output: size comparison, head diff, content subset check, sensitive flag, recommendation
set -euo pipefail

A="$1"
B="$2"

if [[ ! -f "$A" || ! -f "$B" ]]; then
  echo "ERROR: both files must exist"
  echo "  A: $A"
  echo "  B: $B"
  exit 1
fi

SIZE_A=$(wc -c < "$A")
SIZE_B=$(wc -c < "$B")
LINES_A=$(wc -l < "$A")
LINES_B=$(wc -l < "$B")

echo "=== FILE COMPARISON ==="
echo "A: $SIZE_A bytes, $LINES_A lines  ->  $(basename "$A")"
echo "B: $SIZE_B bytes, $LINES_B lines  ->  $(basename "$B")"
echo ""

echo "=== SENSITIVE FLAG CHECK ==="
PATTERNS="CRM|password|recovery|backup|ancestry|finance|paystub|Offer_Letter|Employment_Agreement|Direct_Deposit|I-9|FormI9|W-2|W-4|SSN"
echo -n "A: "; echo "$A" | grep -qiE "$PATTERNS" && echo "WARNING: SENSITIVE MATCH" || echo "clean"
echo -n "B: "; echo "$B" | grep -qiE "$PATTERNS" && echo "WARNING: SENSITIVE MATCH" || echo "clean"
# Full-path scan for date-suffix variants that escape basename matching
echo -n "Date-suffix variant scan (A): "
echo "$A" | grep -qiE "_20[0-9]{2}-[0-9]{2}" && echo "WARNING: DATE-SUFFIX: check sensitive patterns on parent path" || echo "none"
echo -n "Date-suffix variant scan (B): "
echo "$B" | grep -qiE "_20[0-9]{2}-[0-9]{2}" && echo "WARNING: DATE-SUFFIX: check sensitive patterns on parent path" || echo "none"
echo ""

echo "=== DOUBLE EXTENSION CHECK ==="
echo -n "A: "; basename "$A" | grep -E '\.[a-z]+\.[a-z]+$' \
  && echo "  ARTIFACT NAME: likely drop candidate" || echo "  clean"
echo -n "B: "; basename "$B" | grep -E '\.[a-z]+\.[a-z]+$' \
  && echo "  ARTIFACT NAME: likely drop candidate" || echo "  clean"
echo ""

echo "=== HEAD 20 DIFF ==="
diff <(head -20 "$A") <(head -20 "$B") || true
echo ""

echo "=== CONTENT SUBSET CHECK ==="
CONTENT_A=$(cat "$A")
CONTENT_B=$(cat "$B")
if [[ "$CONTENT_B" == *"$CONTENT_A"* ]]; then
  echo "A is subset of B: B is keeper"
elif [[ "$CONTENT_A" == *"$CONTENT_B"* ]]; then
  echo "B is subset of A: A is keeper"
else
  echo "Neither is a strict substring: check diff above; manual review may be required"
fi
echo ""

echo "=== RECOMMENDATION ==="
A_DOUBLE=$(basename "$A" | grep -cE '\.[a-z]+\.[a-z]+$' || true)
B_DOUBLE=$(basename "$B" | grep -cE '\.[a-z]+\.[a-z]+$' || true)

# Both have double-ext -> fall through to size/subset logic
# Only one has double-ext -> that one is the drop candidate
# Neither has double-ext -> use size + subset
if [[ "$A_DOUBLE" -gt 0 && "$B_DOUBLE" -eq 0 ]]; then
  echo "KEEP B, DROP A (A has artifact double-extension)"
elif [[ "$B_DOUBLE" -gt 0 && "$A_DOUBLE" -eq 0 ]]; then
  echo "KEEP A, DROP B (B has artifact double-extension)"
elif [[ "$A_DOUBLE" -gt 0 && "$B_DOUBLE" -gt 0 ]]; then
  if [[ "$SIZE_A" -lt "$SIZE_B" ]]; then
    echo "BOTH have double-extensions; B is larger: likely keep B, drop A (verify subset)"
  else
    echo "BOTH have double-extensions; A is larger: likely keep A, drop B (verify subset)"
  fi
elif [[ "$SIZE_A" -lt "$SIZE_B" ]]; then
  echo "KEEP B (larger): verify A is subset before dropping"
else
  echo "KEEP A (larger): verify B is subset before dropping"
fi
