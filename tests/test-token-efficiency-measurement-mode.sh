#!/usr/bin/env bash
# test-token-efficiency-measurement-mode.sh — additive measurement-mode pilot
# replay for the retained BMA token-efficiency corpus.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_PACK="$REPO_ROOT/tests/fixtures/token-efficiency-measurement-pilot/source-pack.json"
SUMMARY_SOURCE="$REPO_ROOT/tests/fixtures/token-efficiency-transfer/token-allocation-report-summary-production-2026-03-17.json"
LABELS_SOURCE="$REPO_ROOT/tests/fixtures/token-efficiency-transfer/benchmark-labels-v1.json"
BRIEFS_SOURCE="$REPO_ROOT/tests/fixtures/token-efficiency-measurement-pilot/agentic-root-cause-briefs.json"
WORKFLOWS_SOURCE="$REPO_ROOT/tests/fixtures/token-efficiency-measurement-pilot/workflow-investigations.json"
PACKETS_SOURCE="$REPO_ROOT/tests/fixtures/token-efficiency-measurement-pilot/hotspot-evidence-packets.json"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

check_cmd() {
    local desc="$1"
    shift
    if "$@"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== token-efficiency measurement mode ==="

for fixture in \
    "$SOURCE_PACK" \
    "$SUMMARY_SOURCE" \
    "$LABELS_SOURCE" \
    "$BRIEFS_SOURCE" \
    "$WORKFLOWS_SOURCE" \
    "$PACKETS_SOURCE"
do
    check_cmd "fixture exists: $(basename "$fixture")" test -f "$fixture"
done

OUTPUT_DIR="$TMPDIR/output"
set +e
python3 "$REPO_ROOT/scripts/token-efficiency-measure.py" \
    --source-pack "$SOURCE_PACK" \
    --output-dir "$OUTPUT_DIR"
RC=$?
set -e

check_cmd "positive replay exits 0" test "$RC" -eq 0
check_cmd "measurement summary written" test -f "$OUTPUT_DIR/TOKEN_MEASUREMENT_SUMMARY.json"
check_cmd "evidence packets written" test -f "$OUTPUT_DIR/HOTSPOT_EVIDENCE_PACKETS.json"
check_cmd "root-cause briefs written" test -f "$OUTPUT_DIR/AGENTIC_ROOT_CAUSE_BRIEFS.json"
check_cmd "workflow investigations written" test -f "$OUTPUT_DIR/WORKFLOW_INVESTIGATIONS.json"

check_cmd "positive replay preserves required fields and hotspot order" python3 - "$SUMMARY_SOURCE" "$OUTPUT_DIR" <<'PY'
import json
import pathlib
import sys

summary = json.load(open(sys.argv[1]))
output_dir = pathlib.Path(sys.argv[2])
measurement = json.load(open(output_dir / "TOKEN_MEASUREMENT_SUMMARY.json"))
packets = json.load(open(output_dir / "HOTSPOT_EVIDENCE_PACKETS.json"))

assert measurement["measurement_status"] == "pass"
topline = summary["topline_metrics"]
for field in (
    "decision_readiness",
    "proxy_rows",
    "proxy_share_pct",
    "unlinked_rows",
    "unlinked_share_pct",
):
    assert measurement[field] == topline[field], field

source_top3 = [row["hotspot_id"] for row in summary["hotspots"][:3]]
measured_top3 = [row["hotspot_id"] for row in measurement["hotspots"][:3]]
packet_top3 = [row["hotspot_id"] for row in packets["packets"][:3]]
assert measured_top3 == source_top3
assert packet_top3 == source_top3

source_first = summary["hotspots"][0]
measured_first = measurement["hotspots"][0]
assert measured_first["classification_confidence"] == source_first["classification_confidence"]
assert measured_first["actionability_status"] == source_first["actionability_status"]
assert packets["packets"][0]["instrumentation_gap"] is False
assert measurement["comparison_window"]["trend_status"] == summary["history_context"]["trend_status"]
assert measurement["comparison_window"]["delta_vs_latest"] == summary["history_context"]["delta_vs_latest"]
assert measurement["hotspot_ranking"][0]["hotspot_id"] == source_top3[0]
assert measurement["hotspot_ranking"][0]["impact_rank"] == source_first["impact_rank"]
assert measurement["attribution_summary"]["exact_attribution_policy"] == "fail_closed"
assert measurement["attribution_summary"]["join_confidence_counts"]["direct"] >= 1
PY

MISSING_LABELS_DIR="$TMPDIR/missing-labels"
mkdir -p "$MISSING_LABELS_DIR"
cp "$SOURCE_PACK" "$MISSING_LABELS_DIR/source-pack.json"
python3 - "$MISSING_LABELS_DIR/source-pack.json" "$SUMMARY_SOURCE" "$BRIEFS_SOURCE" "$WORKFLOWS_SOURCE" "$PACKETS_SOURCE" <<'PY'
import json
import sys

path, summary_source, briefs_source, workflows_source, packets_source = sys.argv[1:6]
payload = json.load(open(path))
payload["sources"]["benchmark_labels"] = "missing-labels.json"
payload["sources"]["summary_production"] = summary_source
payload["sources"]["agentic_root_cause_briefs"] = briefs_source
payload["sources"]["workflow_investigations"] = workflows_source
payload["sources"]["hotspot_evidence_packets"] = packets_source
with open(path, "w") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY

set +e
python3 "$REPO_ROOT/scripts/token-efficiency-measure.py" \
    --source-pack "$MISSING_LABELS_DIR/source-pack.json" \
    --output-dir "$MISSING_LABELS_DIR/output"
MISSING_LABELS_RC=$?
set -e

check_cmd "missing labels exits fail-closed" test "$MISSING_LABELS_RC" -eq 2
check_cmd "missing labels stays measurement-blocked" python3 - "$MISSING_LABELS_DIR/output/TOKEN_MEASUREMENT_SUMMARY.json" <<'PY'
import json
import sys

summary = json.load(open(sys.argv[1]))
assert summary["measurement_status"] == "measurement_blocked"
assert any(gap["code"] == "missing_benchmark_labels" for gap in summary["instrumentation_gaps"])
PY

ATTRIBUTION_DIR="$TMPDIR/missing-attribution"
mkdir -p "$ATTRIBUTION_DIR"
cp "$SOURCE_PACK" "$ATTRIBUTION_DIR/source-pack.json"
cp "$PACKETS_SOURCE" "$ATTRIBUTION_DIR/hotspot-evidence-packets.json"
python3 - "$ATTRIBUTION_DIR/hotspot-evidence-packets.json" "$ATTRIBUTION_DIR/source-pack.json" "$LABELS_SOURCE" "$SUMMARY_SOURCE" "$BRIEFS_SOURCE" "$WORKFLOWS_SOURCE" <<'PY'
import json
import sys

packets_path, source_pack_path, labels_source, summary_source, briefs_source, workflows_source = sys.argv[1:7]
packets = json.load(open(packets_path))
del packets["packets"][0]["retained_evidence"]["session_refs"][0]["join_confidence"]
with open(packets_path, "w") as handle:
    json.dump(packets, handle, indent=2)
    handle.write("\n")

source_pack = json.load(open(source_pack_path))
source_pack["sources"]["benchmark_labels"] = labels_source
source_pack["sources"]["summary_production"] = summary_source
source_pack["sources"]["agentic_root_cause_briefs"] = briefs_source
source_pack["sources"]["workflow_investigations"] = workflows_source
source_pack["sources"]["hotspot_evidence_packets"] = "hotspot-evidence-packets.json"
with open(source_pack_path, "w") as handle:
    json.dump(source_pack, handle, indent=2)
    handle.write("\n")
PY

set +e
python3 "$REPO_ROOT/scripts/token-efficiency-measure.py" \
    --source-pack "$ATTRIBUTION_DIR/source-pack.json" \
    --output-dir "$ATTRIBUTION_DIR/output"
ATTRIBUTION_RC=$?
set -e

check_cmd "missing join confidence exits fail-closed" test "$ATTRIBUTION_RC" -eq 2
check_cmd "missing join confidence records instrumentation gap" python3 - "$ATTRIBUTION_DIR/output/HOTSPOT_EVIDENCE_PACKETS.json" <<'PY'
import json
import sys

packets = json.load(open(sys.argv[1]))
first = packets["packets"][0]
assert first["measurement_status"] == "measurement_blocked"
assert first["instrumentation_gap"] is True
assert "missing_session_join_confidence" in first["instrumentation_gap_reasons"]
PY

echo ""
echo "=== test-token-efficiency-measurement-mode.sh: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ] || exit 1
