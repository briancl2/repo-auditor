#!/usr/bin/env bash
# test-auditor-schemas.sh — Validate all JSON schemas in the repo
set -euo pipefail

AUDITOR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

echo "=== Auditor Schema Validation ==="

for schema in "$AUDITOR_DIR/schemas"/*.schema.json; do
  NAME="$(basename "$schema")"
  if python3 -c "import json; json.load(open('$schema'))" 2>/dev/null; then
    echo "  ✓ $NAME"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $NAME — INVALID"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "  PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "  VERDICT: FAIL"
  exit 1
fi
echo "  VERDICT: PASS"
