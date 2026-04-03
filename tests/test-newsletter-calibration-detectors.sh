#!/usr/bin/env bash
# test-newsletter-calibration-detectors.sh — Validate DS-45/DS-46 fixtures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DS45="$REPO_ROOT/scripts/detect-workflow-contract-drift.sh"
DS46="$REPO_ROOT/scripts/detect-llm-validation-gap.sh"

WF_HEALTHY="$REPO_ROOT/tests/fixtures/workflow-contract-healthy"
WF_DRIFT="$REPO_ROOT/tests/fixtures/workflow-contract-drift"
LLM_HEALTHY="$REPO_ROOT/tests/fixtures/llm-validation-healthy"
LLM_GAP="$REPO_ROOT/tests/fixtures/llm-validation-gap"

echo "=== Newsletter Calibration Detector Fixtures ==="

healthy_wf_json=$(bash "$DS45" "$WF_HEALTHY")
printf '%s' "$healthy_wf_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-45"
assert data["fired"] is False
assert data["helper_signal_count"] >= 2
assert data["missing_surface_signal_count"] == 0
'
echo "  ✓ DS-45 healthy fixture"

drift_wf_json=$(bash "$DS45" "$WF_DRIFT")
printf '%s' "$drift_wf_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-45"
assert data["fired"] is True
assert data["helper_signal_count"] >= 2
assert data["missing_surface_signal_count"] >= 2
'
echo "  ✓ DS-45 drift fixture"

healthy_llm_json=$(bash "$DS46" "$LLM_HEALTHY")
printf '%s' "$healthy_llm_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-46"
assert data["fired"] is False
assert data["llm_execution_reference_count"] >= 1
'
echo "  ✓ DS-46 healthy fixture"

gap_llm_json=$(bash "$DS46" "$LLM_GAP")
printf '%s' "$gap_llm_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-46"
assert data["fired"] is True
assert data["validator_reference_count"] >= 1
'
echo "  ✓ DS-46 gap fixture"

echo "  VERDICT: PASS"
