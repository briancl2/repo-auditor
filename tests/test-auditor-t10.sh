#!/usr/bin/env bash
# test-auditor-t10.sh — Functional test: run auditor on T10 and verify SCORECARD
#
# Usage: bash tests/test-auditor-t10.sh [target-path]
#   Default target: ~/repos/build-meta-analysis/targets/T10

set -euo pipefail

AUDITOR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$HOME/repos/build-meta-analysis/targets/T10}"
OUTPUT_DIR="$AUDITOR_DIR/tests/test-output-t10"

echo "=== Auditor Functional Test: T10 ==="
echo "  Target: $TARGET"
echo "  Output: $OUTPUT_DIR"

# Clean previous test output
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Check target exists
if [ ! -d "$TARGET" ]; then
  echo "SKIP: Target not found at $TARGET"
  echo "  Set target path: bash tests/test-auditor-t10.sh /path/to/target"
  exit 0
fi

# Run auditor (standard mode — 0 LLM tokens)
echo ""
echo "--- Running repo-auditor.sh ---"
bash "$AUDITOR_DIR/scripts/repo-auditor.sh" "$TARGET" "$OUTPUT_DIR"

# Verify SCORECARD.json exists and is valid JSON
echo ""
echo "--- Verifying outputs ---"

if [ ! -f "$OUTPUT_DIR/SCORECARD.json" ]; then
  echo "FAIL: SCORECARD.json not found"
  exit 1
fi

# Check JSON validity
if python3 -c "import json; json.load(open('$OUTPUT_DIR/SCORECARD.json'))" 2>/dev/null; then
  echo "  ✓ SCORECARD.json — valid JSON"
else
  echo "  ✗ SCORECARD.json — INVALID JSON"
  exit 1
fi

# Check required keys
python3 -c "
import json, sys
with open('$OUTPUT_DIR/SCORECARD.json') as f:
    data = json.load(f)
required = ['dimensions', 'composite', 'max_composite', 'meta']
missing = [k for k in required if k not in data]
if missing:
    print(f'FAIL: Missing keys: {missing}')
    sys.exit(1)
dims = data.get('dimensions', {})
expected_dims = ['D1_governance', 'D2_surface_health', 'D3_skill_maturity', 'D4_measurement', 'D5_self_improvement']
missing_dims = [d for d in expected_dims if d not in dims]
if missing_dims:
    print(f'FAIL: Missing dimensions: {missing_dims}')
    sys.exit(1)
composite = data.get('composite', 0)
print(f'  ✓ SCORECARD.json — 5 dimensions, composite={composite}')
"

# Check AUDIT_REPORT.md if present
if [ -f "$OUTPUT_DIR/AUDIT_REPORT.md" ]; then
  LINES=$(wc -l < "$OUTPUT_DIR/AUDIT_REPORT.md" | tr -d ' ')
  echo "  ✓ AUDIT_REPORT.md — ${LINES}L"
fi

# Clean up
rm -rf "$OUTPUT_DIR"
echo ""
echo "=== VERDICT: PASS ==="
