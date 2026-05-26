#!/usr/bin/env bash
# test-detect-closeout-control-drift.sh — Validate DS-44 against healthy and drift fixtures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-closeout-control-drift.sh"
HEALTHY_FIXTURE="$REPO_ROOT/tests/fixtures/closeout-control-healthy"
DRIFT_FIXTURE="$REPO_ROOT/tests/fixtures/closeout-control-drift"

echo "=== DS-44 Fixture Validation ==="

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

healthy_json=$(bash "$SCRIPT" "$HEALTHY_FIXTURE")
printf '%s' "$healthy_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
assert data["ds_id"] == "DS-44"
assert data["fired"] is False
assert data["work_dirs_scanned"] == 1
assert data["pointer_closure_dirs_scanned"] == 0
assert data["disposition_gap_count"] == 0
assert data["helper_drift_count"] == 0
assert data["telemetry_anomaly_count"] == 0
assert data["pointer_duplicate_truth_count"] == 0
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
assert data["pointer_closure_dirs_scanned"] == 0
assert data["disposition_gap_count"] == 1
assert data["helper_drift_count"] >= 1
assert data["telemetry_anomaly_count"] >= 1
assert data["pointer_duplicate_truth_count"] == 0
'
echo "  ✓ drift fixture"

pointer_fixture="$tmpdir/closeout-control-pointer-duplicate"
cp -R "$HEALTHY_FIXTURE" "$pointer_fixture"
pointer_work_dir="$pointer_fixture/work/20260320T000000Z"
cat > "$pointer_work_dir/github-campaign-pointer.json" <<'EOF'
{
  "issue": 20,
  "state": "closed",
  "truth": "github"
}
EOF
cat > "$pointer_work_dir/completion-manifest.json" <<'EOF'
{
  "status": "completed"
}
EOF
cat > "$pointer_work_dir/completion-manifest.md" <<'EOF'
# Completion Manifest
EOF
cat > "$pointer_work_dir/handoff-sync-facts.json" <<'EOF'
{
  "synced": true
}
EOF
cat > "$pointer_work_dir/session-end-review.md" <<'EOF'
# Session End Review
EOF
cat > "$pointer_work_dir/ask-reconciliation.md" <<'EOF'
# Ask Reconciliation
EOF

pointer_json=$(bash "$SCRIPT" "$pointer_fixture")
printf '%s' "$pointer_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
assert data["ds_id"] == "DS-44"
assert data["fired"] is True
assert data["work_dirs_scanned"] == 1
assert data["pointer_closure_dirs_scanned"] == 1
assert data["disposition_gap_count"] == 0
assert data["helper_drift_count"] == 0
assert data["telemetry_anomaly_count"] == 0
assert data["pointer_duplicate_truth_count"] == 1
assert "completion-manifest.json" in data["evidence"]
assert "closeout-disposition.json" in data["evidence"]
'
echo "  ✓ pointer duplicate fixture"

echo "  VERDICT: PASS"
