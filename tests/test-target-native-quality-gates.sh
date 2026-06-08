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
assert receipt["raw_target_gate_state"] == "pass"
assert receipt["target_gate_state"] == "partial_run"
assert receipt["contradiction"] == "partial_run_no_verdict"
assert receipt["generic_score"]["partial_artifact_contract"] is True
assert "AUDIT_REPORT.md" in receipt["generic_score"]["missing_required_artifacts"]
assert scorecard["receipts"]["target_native_quality_gates"]["file"] == "TARGET_NATIVE_QUALITY_GATES.json"
assert receipts["target_native_quality_gates"]["contradiction"] == "partial_run_no_verdict"
assert "does not replace" in receipt["bounded_non_claim"]
PY
echo "  ✓ partial research fixture emits partial_run without hiding generic score"

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

receipt = json.load(open(out / "TARGET_NATIVE_QUALITY_GATES.json"))

assert receipt["raw_target_gate_state"] == "no_retained_gate"
assert receipt["target_gate_state"] == "no_retained_gate"
assert receipt["contradiction"] == "unresolved"
assert scorecard["receipts"]["target_native_quality_gates"]["status"] == "no_retained_gate"
assert receipts["target_native_quality_gates"]["target_gate_state"] == "no_retained_gate"
assert scorecard["composite"] == 70
PY
echo "  ✓ no-gate fixture emits classified no_retained_gate receipt"

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
assert receipt["raw_target_gate_state"] == "unknown"
assert receipt["target_gate_state"] == "amendment_required_unknown"
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
assert receipt["raw_target_gate_state"] == "unknown"
assert receipt["target_gate_state"] == "amendment_required_unknown"
assert receipt["contradiction"] == "unclassified_requires_amendment"
assert receipt["amendment_required"] is True
PY
echo "  ✓ unclassified gate-like fixture routes to amendment"

WARNING_TARGET="$TMP_ROOT/warning-target"
WARNING_OUT="$TMP_ROOT/warning-output"
mkdir -p "$WARNING_TARGET"
cat > "$WARNING_TARGET/QUALITY_GATE.md" <<'EOF'
# Quality Gate

Status: WARNING
EOF
make_score_output "$WARNING_OUT" 70 0 yes

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$WARNING_TARGET" "$WARNING_OUT"
python3 - "$WARNING_OUT" <<'PY'
import json
import pathlib
import sys

receipt = json.load(open(pathlib.Path(sys.argv[1]) / "TARGET_NATIVE_QUALITY_GATES.json"))
assert receipt["raw_target_gate_state"] == "warning"
assert receipt["target_gate_state"] == "parseable_warning"
assert receipt["contradiction"] == "unresolved"
PY
echo "  ✓ parseable warning gate stays distinct from fail/pass"

STALE_TARGET="$TMP_ROOT/stale-fleet-target"
STALE_OUT="$TMP_ROOT/stale-fleet-output"
mkdir -p "$STALE_TARGET"
cat > "$STALE_TARGET/QUALITY_GATE.md" <<'EOF'
# Quality Gate

Status: PASS
EOF
make_score_output "$STALE_OUT" 28 1 yes

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$STALE_TARGET" "$STALE_OUT"
python3 - "$STALE_OUT" <<'PY'
import json
import pathlib
import sys

receipt = json.load(open(pathlib.Path(sys.argv[1]) / "TARGET_NATIVE_QUALITY_GATES.json"))
assert receipt["raw_target_gate_state"] == "pass"
assert receipt["target_gate_state"] == "stale_fleet_metric"
assert receipt["contradiction"] == "fleet_metric_stale"
PY
echo "  ✓ pass gate with low generic score classifies as stale fleet metric"

TRUE_RISK_TARGET="$TMP_ROOT/true-target-risk"
TRUE_RISK_OUT="$TMP_ROOT/true-target-risk-output"
mkdir -p "$TRUE_RISK_TARGET"
cat > "$TRUE_RISK_TARGET/QUALITY_GATE.md" <<'EOF'
# Quality Gate

Status: FAIL
EOF
make_score_output "$TRUE_RISK_OUT" 70 0 yes

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$TRUE_RISK_TARGET" "$TRUE_RISK_OUT"
python3 - "$TRUE_RISK_OUT" <<'PY'
import json
import pathlib
import sys

receipt = json.load(open(pathlib.Path(sys.argv[1]) / "TARGET_NATIVE_QUALITY_GATES.json"))
assert receipt["raw_target_gate_state"] == "fail"
assert receipt["target_gate_state"] == "true_target_risk"
assert receipt["contradiction"] == "true_target_risk"
PY
echo "  ✓ fail gate with healthy generic score classifies as true target risk"

MISSING_ARTIFACT_TARGET="$TMP_ROOT/missing-artifact-target"
MISSING_ARTIFACT_OUT="$TMP_ROOT/missing-artifact-output"
mkdir -p "$MISSING_ARTIFACT_TARGET" "$MISSING_ARTIFACT_OUT"
cat > "$MISSING_ARTIFACT_OUT/AUDIT_RUN_RECEIPT.json" <<'EOF'
{
  "status": "failed",
  "missing_required_artifacts": ["SCORECARD.json", "SCORECARD_RECEIPTS.json"],
  "artifact_status": "partial"
}
EOF

python3 "$REPO_ROOT/scripts/collect-target-native-quality-gates.py" "$MISSING_ARTIFACT_TARGET" "$MISSING_ARTIFACT_OUT"
python3 - "$MISSING_ARTIFACT_OUT" <<'PY'
import json
import pathlib
import sys

receipt = json.load(open(pathlib.Path(sys.argv[1]) / "TARGET_NATIVE_QUALITY_GATES.json"))
assert receipt["raw_target_gate_state"] == "no_retained_gate"
assert receipt["target_gate_state"] == "partial_run"
assert receipt["status"] == "partial"
assert receipt["generic_score"]["partial_artifact_contract"] is True
assert "SCORECARD.json" in receipt["generic_score"]["missing_required_artifacts"]
assert "SCORECARD_RECEIPTS.json" in receipt["generic_score"]["missing_required_artifacts"]
PY
echo "  ✓ failed audit without scorecard still emits partial_run receipt"

python3 - "$REPO_ROOT" \
    "$PARTIAL_OUT" \
    "$NO_GATE_OUT" \
    "$JSON_UNKNOWN_OUT" \
    "$UNKNOWN_OUT" \
    "$WARNING_OUT" \
    "$STALE_OUT" \
    "$TRUE_RISK_OUT" <<'PY'
import json
import pathlib
import sys

import jsonschema

repo_root = pathlib.Path(sys.argv[1])
schema = json.load(open(repo_root / "schemas/SCORECARD.schema.json"))
pointer_schema = schema["properties"]["receipts"]["properties"]["target_native_quality_gates"]
validator = jsonschema.Draft7Validator(pointer_schema)

for raw_out in sys.argv[2:]:
    out = pathlib.Path(raw_out)
    scorecard = json.load(open(out / "SCORECARD.json"))
    pointer = scorecard["receipts"]["target_native_quality_gates"]
    errors = sorted(validator.iter_errors(pointer), key=lambda item: item.path)
    assert not errors, (out, errors[0].message if errors else "")
PY
echo "  ✓ generated SCORECARD target-native pointers satisfy schema"

echo "  VERDICT: PASS"
