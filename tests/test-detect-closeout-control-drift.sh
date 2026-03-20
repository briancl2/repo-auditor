#!/usr/bin/env bash
# test-detect-closeout-control-drift.sh — Validate DS-44 against healthy and drift fixtures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-closeout-control-drift.sh"
HEALTHY_FIXTURE="$REPO_ROOT/tests/fixtures/closeout-control-healthy"
DRIFT_FIXTURE="$REPO_ROOT/tests/fixtures/closeout-control-drift"

echo "=== DS-44 Fixture Validation ==="

healthy_json=$(bash "$SCRIPT" "$HEALTHY_FIXTURE")
printf '%s' "$healthy_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
assert data["ds_id"] == "DS-44"
assert data["fired"] is False
assert data["work_dirs_scanned"] == 1
assert data["disposition_gap_count"] == 0
assert data["helper_drift_count"] == 0
assert data["telemetry_anomaly_count"] == 0
'
echo "  ✓ healthy fixture"

drift_json=$(bash "$SCRIPT" "$DRIFT_FIXTURE")
printf '%s' "$drift_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
assert data["ds_id"] == "DS-44"
assert data["fired"] is True
assert data["work_dirs_scanned"] == 1
assert data["disposition_gap_count"] == 1
assert data["helper_drift_count"] >= 1
assert data["telemetry_anomaly_count"] >= 1
'
echo "  ✓ drift fixture"

echo "  VERDICT: PASS"
