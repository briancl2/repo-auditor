#!/usr/bin/env bash
# test-target-native-quality-gates.sh — Validate additive target-native receipts.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_PARENT="${TMPDIR:-$REPO_ROOT/work/test-tmp}"
TMP_ROOT="$TMP_PARENT/target-native-quality-gates.$$"
rm -rf "$TMP_ROOT"
mkdir -p "$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT

make_score_output() {
    local out="$1"
    local composite="$2"
    local tier1_failed="$3"
    local with_report="$4"

    mkdir -p "$out"
    python3 - "$out" "$composite" "$tier1_failed" "$with_report" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
composite = int(sys.argv[2])
tier1_failed = int(sys.argv[3])
with_report = sys.argv[4] == "yes"

scorecard = {
    "dimensions": {},
    "composite": composite,
    "max_composite": 100,
    "receipts": {
        "file": "SCORECARD_RECEIPTS.json",
        "version": "1.0.0",
        "count_reconciliation_status": "aligned",
    },
    "tier1_checks": {
        "total": 5,
        "passed": 5 - tier1_failed,
        "failed": tier1_failed,
        "failures": ["T1-DRIFT"] if tier1_failed else [],
    },
    "tier2_warnings": {"count": 0, "warnings": []},
    "meta": {
        "phase": "fixture",
        "maturity_score": 0,
        "auditor_version": "test",
        "timestamp": "2026-05-08T00:00:00Z",
    },
}
receipts = {
    "meta": {"receipt_version": "1.0.0"},
    "count_reconciliation": {"status": "aligned"},
    "dimensions": {},
}

(out / "SCORECARD.json").write_text(json.dumps(scorecard, indent=2) + "\n")
(out / "SCORECARD_RECEIPTS.json").write_text(json.dumps(receipts, indent=2) + "\n")
if with_report:
    (out / "AUDIT_REPORT.md").write_text("# Fixture report\n")
PY
}

echo "=== Target-Native Quality Gate Validation ==="

PARTIAL_TARGET="$TMP_ROOT/partial-vault-shaped"
PARTIAL_OUT="$TMP_ROOT/partial-output"
mkdir -p "$PARTIAL_TARGET/system/reports" "$PARTIAL_TARGET/system/policy"
cat > "$PARTIAL_TARGET/system/reports/QUALITY_GATE.md" <<'EOF'
# Quality Gate

Status: PASS
Score: 0
State: GREEN
EOF
cat > "$PARTIAL_TARGET/system/policy/model_routing.json" <<'EOF'
{"status":"active"}
EOF
make_score_output "$PARTIAL_OUT" 28 1 no

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$PARTIAL_TARGET" "$PARTIAL_OUT"
python3 - "$PARTIAL_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipt = json.load(open(out / "TARGET_NATIVE_QUALITY_GATES.json"))
scorecard = json.load(open(out / "SCORECARD.json"))
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))

assert scorecard["composite"] == 28
assert receipt["target_gate_state"] == "pass"
assert receipt["contradiction"] == "partial_run_no_verdict"
assert receipt["generic_score"]["partial_artifact_contract"] is True
assert "AUDIT_REPORT.md" in receipt["generic_score"]["missing_required_artifacts"]
assert scorecard["receipts"]["target_native_quality_gates"]["file"] == "TARGET_NATIVE_QUALITY_GATES.json"
assert receipts["target_native_quality_gates"]["contradiction"] == "partial_run_no_verdict"
assert "does not replace" in receipt["bounded_non_claim"]
PY
echo "  ✓ partial research fixture emits partial_run_no_verdict without hiding generic score"

NO_GATE_TARGET="$TMP_ROOT/no-gate-target"
NO_GATE_OUT="$TMP_ROOT/no-gate-output"
mkdir -p "$NO_GATE_TARGET"
cat > "$NO_GATE_TARGET/README.md" <<'EOF'
# no local gate fixture
EOF
make_score_output "$NO_GATE_OUT" 70 0 yes

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$NO_GATE_TARGET" "$NO_GATE_OUT"
python3 - "$NO_GATE_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
scorecard = json.load(open(out / "SCORECARD.json"))
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard["receipts"]["target_native_quality_gates"] = {"file": "TARGET_NATIVE_QUALITY_GATES.json"}
receipts["target_native_quality_gates"] = {"status": "stale"}
(out / "SCORECARD.json").write_text(json.dumps(scorecard, indent=2) + "\n")
(out / "SCORECARD_RECEIPTS.json").write_text(json.dumps(receipts, indent=2) + "\n")
(out / "TARGET_NATIVE_QUALITY_GATES.json").write_text("{}\n")
PY
python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$NO_GATE_TARGET" "$NO_GATE_OUT"
python3 - "$NO_GATE_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
scorecard = json.load(open(out / "SCORECARD.json"))
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))

assert not (out / "TARGET_NATIVE_QUALITY_GATES.json").exists()
assert "target_native_quality_gates" not in scorecard["receipts"]
assert "target_native_quality_gates" not in receipts
assert scorecard["composite"] == 70
PY
echo "  ✓ no-gate fixture emits no target-native detail"

JSON_UNKNOWN_TARGET="$TMP_ROOT/json-unclassified-target"
JSON_UNKNOWN_OUT="$TMP_ROOT/json-unclassified-output"
mkdir -p "$JSON_UNKNOWN_TARGET"
cat > "$JSON_UNKNOWN_TARGET/quality_gate.json" <<'EOF'
["custom", "unsupported"]
EOF
make_score_output "$JSON_UNKNOWN_OUT" 70 0 yes

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$JSON_UNKNOWN_TARGET" "$JSON_UNKNOWN_OUT"
python3 - "$JSON_UNKNOWN_OUT" <<'PY'
import json
import pathlib
import sys

receipt = json.load(open(pathlib.Path(sys.argv[1]) / "TARGET_NATIVE_QUALITY_GATES.json"))
assert receipt["sources"][0]["unsupported_json_root"] == "list"
assert receipt["contradiction"] == "unclassified_requires_amendment"
PY
echo "  ✓ unsupported JSON gate roots route to amendment"

UNKNOWN_TARGET="$TMP_ROOT/unclassified-target"
UNKNOWN_OUT="$TMP_ROOT/unclassified-output"
mkdir -p "$UNKNOWN_TARGET"
cat > "$UNKNOWN_TARGET/QUALITY_GATE.md" <<'EOF'
# Custom Gate

This target has a bespoke quality control surface whose status vocabulary is not
known to repo-auditor.
EOF
make_score_output "$UNKNOWN_OUT" 70 0 yes

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$UNKNOWN_TARGET" "$UNKNOWN_OUT"
python3 - "$UNKNOWN_OUT" <<'PY'
import json
import pathlib
import sys

receipt = json.load(open(pathlib.Path(sys.argv[1]) / "TARGET_NATIVE_QUALITY_GATES.json"))
assert receipt["target_gate_state"] == "unknown"
assert receipt["contradiction"] == "unclassified_requires_amendment"
assert receipt["amendment_required"] is True
PY
echo "  ✓ unclassified gate-like fixture routes to amendment"

echo "  VERDICT: PASS"
