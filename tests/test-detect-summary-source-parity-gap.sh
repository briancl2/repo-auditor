#!/usr/bin/env bash
# test-detect-summary-source-parity-gap.sh — Validate DS-47 fixtures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DS47="$REPO_ROOT/scripts/detect-summary-source-parity-gap.sh"

HEALTHY="$REPO_ROOT/tests/fixtures/summary-source-parity-healthy"
GAP="$REPO_ROOT/tests/fixtures/summary-source-parity-gap"
OUT_SCOPE="$REPO_ROOT/tests/fixtures/summary-source-parity-out-of-scope"

echo "=== DS-47 Summary-Source Parity Gap Fixtures ==="

healthy_json=$(bash "$DS47" "$HEALTHY")
printf '%s' "$healthy_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-47"
assert data["fired"] is False
assert data["in_scope_file_count"] >= 1
assert data["gap_count"] == 0
'
echo "  ✓ DS-47 healthy fixture"

gap_json=$(bash "$DS47" "$GAP")
printf '%s' "$gap_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-47"
assert data["fired"] is True
assert data["gap_count"] >= 1
assert data["in_scope_file_count"] >= 1
'
echo "  ✓ DS-47 gap fixture"

out_scope_json=$(bash "$DS47" "$OUT_SCOPE")
printf '%s' "$out_scope_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-47"
assert data["fired"] is False
assert data["gap_count"] == 0
assert data["out_of_scope_count"] >= 1
'
echo "  ✓ DS-47 out-of-scope fixture"

echo "  VERDICT: PASS"
