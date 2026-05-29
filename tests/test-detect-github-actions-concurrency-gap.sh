#!/usr/bin/env bash
# test-detect-github-actions-concurrency-gap.sh — Validate DS-48 fixtures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DS48="$REPO_ROOT/scripts/detect-github-actions-concurrency-gap.sh"

HEALTHY_WORKFLOW="$REPO_ROOT/tests/fixtures/github-actions-concurrency-healthy-workflow"
HEALTHY_JOBS="$REPO_ROOT/tests/fixtures/github-actions-concurrency-healthy-jobs"
GAP="$REPO_ROOT/tests/fixtures/github-actions-concurrency-gap"
PARTIAL="$REPO_ROOT/tests/fixtures/github-actions-concurrency-partial-job-gap"
MANUAL_ONLY="$REPO_ROOT/tests/fixtures/github-actions-concurrency-manual-only"

echo "=== DS-48 GitHub Actions Concurrency Gap Fixtures ==="

healthy_workflow_json=$(bash "$DS48" "$HEALTHY_WORKFLOW")
printf '%s' "$healthy_workflow_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-48"
assert data["fired"] is False
assert data["triggered_workflow_count"] == 1
assert data["workflow_level_concurrency_count"] == 1
assert data["gap_count"] == 0
'
echo "  ✓ DS-48 workflow-level healthy fixture"

healthy_jobs_json=$(bash "$DS48" "$HEALTHY_JOBS")
printf '%s' "$healthy_jobs_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-48"
assert data["fired"] is False
assert data["triggered_workflow_count"] == 1
assert data["job_level_concurrency_workflow_count"] == 1
assert data["gap_count"] == 0
'
echo "  ✓ DS-48 job-level healthy fixture"

gap_json=$(bash "$DS48" "$GAP")
printf '%s' "$gap_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-48"
assert data["fired"] is True
assert data["triggered_workflow_count"] == 1
assert data["gap_count"] == 1
assert "missing_jobs=test" in data["evidence"]
'
echo "  ✓ DS-48 missing-concurrency fixture"

partial_json=$(bash "$DS48" "$PARTIAL")
printf '%s' "$partial_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-48"
assert data["fired"] is True
assert data["gap_count"] == 1
assert "missing_jobs=test" in data["evidence"]
'
echo "  ✓ DS-48 partial job-level fixture"

manual_json=$(bash "$DS48" "$MANUAL_ONLY")
printf '%s' "$manual_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-48"
assert data["fired"] is False
assert data["triggered_workflow_count"] == 0
assert data["gap_count"] == 0
'
echo "  ✓ DS-48 manual-only fixture"

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/ds48-runner.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT
bash "$REPO_ROOT/scripts/detect-new-signatures.sh" "$GAP" "$tmpdir/out" > "$tmpdir/run.json"
python3 - "$tmpdir/run.json" "$tmpdir/out/DS-34-plus-results.json" <<'PY'
import json
import sys
stdout_report = json.load(open(sys.argv[1]))
output_report = json.load(open(sys.argv[2]))
for report in (stdout_report, output_report):
    assert "DS-48" in report["capability_metadata"]["signature_order"], report
    ds48 = [item for item in report["results"] if item.get("ds_id") == "DS-48"][0]
    assert ds48["fired"] is True
    assert ds48["gap_count"] == 1
PY
echo "  ✓ DS-48 registered in DS-34+ runner"

echo "  VERDICT: PASS"
