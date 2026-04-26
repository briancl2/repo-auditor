#!/usr/bin/env bash
# test-score-operation.sh — Validate command-output ROI audit output gate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCORER="$REPO_ROOT/scripts/score-operation.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/repo-auditor-scoreop.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

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

make_base_fixture() {
    local out="$1"
    mkdir -p "$out/pre-scan"
    printf '%s\n' '# Pre Scan' 'AI surfaces inventoried.' > "$out/pre-scan/PRE_SCAN.md"
    printf '%s\n' 'Phase: 3' 'Maturity classifier complete.' > "$out/maturity.txt"
    printf '%s\n' 'stall risk: 12' > "$out/stall-risk.txt"
    printf '%s\n' 'repo dna: shell python markdown' > "$out/dna.txt"
    printf '%s\n' 'drift: low' > "$out/drift.txt"
    printf '%s\n' '{"receipt_version":"1.0.0"}' > "$out/SCORECARD_RECEIPTS.json"
    python3 - "$out/SCORECARD.json" <<'PY'
import json
import sys

payload = {
    "composite": 72,
    "dimensions": {
        "D1_governance": 14,
        "D2_surface_health": 14,
        "D3_skill_maturity": 14,
        "D4_measurement": 15,
        "D5_self_improvement": 15,
    },
    "detection_findings": [{"id": "DS-1", "summary": "bounded fixture signal"}],
}
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
PY
    {
        printf '%s\n' '# Audit Report' ''
        printf '%s\n' 'Command evidence summary: make check exited 0 and wrote SCORECARD.json.'
        printf '%s\n' 'Command evidence summary: git status was clean after the read-only audit.'
        for i in $(seq 1 25); do
            printf 'Finding summary line %s with bounded evidence refs.\n' "$i"
        done
    } > "$out/AUDIT_REPORT.md"
}

echo "=== score-operation.sh command-output ROI tests ==="

GOOD="$TMP_ROOT/good"
make_base_fixture "$GOOD"
GOOD_OUT="$TMP_ROOT/good.json"
bash "$SCORER" "$GOOD" --json > "$GOOD_OUT"
GOOD_VERDICT="$(python3 -c "import json; print(json.load(open('$GOOD_OUT'))['verdict'])")"
GOOD_RECEIPT="$(python3 -c "import json; print(json.load(open('$GOOD_OUT'))['command_output_roi_receipt']['verdict'])")"
check_cmd "summarized command evidence passes" test "$GOOD_VERDICT" = "PASS"
check_cmd "json output includes passing command-output ROI receipt" test "$GOOD_RECEIPT" = "pass"

FENCED="$TMP_ROOT/fenced"
make_base_fixture "$FENCED"
{
    cat "$GOOD/AUDIT_REPORT.md"
    printf '%s\n' '' '```text'
    for i in $(seq 1 40); do printf 'PASS: make check raw transcript line %s\n' "$i"; done
    printf '%s\n' '```'
} > "$FENCED/AUDIT_REPORT.md"
FENCED_OUT="$TMP_ROOT/fenced.json"
bash "$SCORER" "$FENCED" --json > "$FENCED_OUT"
check_cmd "fenced raw transcript fails closed" test "$(python3 -c "import json; print(json.load(open('$FENCED_OUT'))['verdict'])")" = "FAIL"
check_cmd "fenced raw transcript reports ROI violation" grep -q 'Command-output ROI violation' "$FENCED_OUT"

PLAINTEXT="$TMP_ROOT/plaintext"
make_base_fixture "$PLAINTEXT"
{
    cat "$GOOD/AUDIT_REPORT.md"
    printf '%s\n' ''
    for i in $(seq 1 30); do printf 'FAIL: audit raw transcript line %s\n' "$i"; done
} > "$PLAINTEXT/AUDIT_REPORT.md"
PLAINTEXT_OUT="$TMP_ROOT/plaintext.json"
bash "$SCORER" "$PLAINTEXT" --json > "$PLAINTEXT_OUT"
check_cmd "plaintext raw transcript fails closed" test "$(python3 -c "import json; print(json.load(open('$PLAINTEXT_OUT'))['verdict'])")" = "FAIL"

PRESCAN="$TMP_ROOT/prescan"
make_base_fixture "$PRESCAN"
{
    cat "$GOOD/pre-scan/PRE_SCAN.md"
    printf '%s\n' ''
    for i in $(seq 1 30); do printf 'PASS: pre-scan raw transcript line %s\n' "$i"; done
} > "$PRESCAN/pre-scan/PRE_SCAN.md"
PRESCAN_OUT="$TMP_ROOT/prescan.json"
bash "$SCORER" "$PRESCAN" --json > "$PRESCAN_OUT"
check_cmd "pre-scan raw transcript fails closed" test "$(python3 -c "import json; print(json.load(open('$PRESCAN_OUT'))['verdict'])")" = "FAIL"

TXT_DUMP="$TMP_ROOT/txt-dump"
make_base_fixture "$TXT_DUMP"
{
    printf '%s\n' 'Phase: 3'
    for i in $(seq 1 30); do printf 'PASS: maturity raw transcript line %s\n' "$i"; done
} > "$TXT_DUMP/maturity.txt"
TXT_DUMP_OUT="$TMP_ROOT/txt-dump.json"
bash "$SCORER" "$TXT_DUMP" --json > "$TXT_DUMP_OUT"
check_cmd "required txt raw transcript fails closed" test "$(python3 -c "import json; print(json.load(open('$TXT_DUMP_OUT'))['verdict'])")" = "FAIL"

JSON_DUMP="$TMP_ROOT/json-dump"
make_base_fixture "$JSON_DUMP"
python3 - "$JSON_DUMP/SCORECARD.json" <<'PY'
import json
import sys

path = sys.argv[1]
payload = json.load(open(path, encoding="utf-8"))
payload["raw_notes"] = "\n".join(f"PASS: score raw JSON transcript {i}" for i in range(30))
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
PY
JSON_DUMP_OUT="$TMP_ROOT/json-dump.json"
bash "$SCORER" "$JSON_DUMP" --json > "$JSON_DUMP_OUT"
check_cmd "JSON string raw transcript fails closed" test "$(python3 -c "import json; print(json.load(open('$JSON_DUMP_OUT'))['verdict'])")" = "FAIL"

DS_JSON_DUMP="$TMP_ROOT/ds-json-dump"
make_base_fixture "$DS_JSON_DUMP"
python3 - "$DS_JSON_DUMP/DS-34-plus-results.json" <<'PY'
import json
import sys

payload = {"raw_notes": "\n".join(f"PASS: DS-34 raw transcript {i}" for i in range(30))}
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
PY
DS_JSON_DUMP_OUT="$TMP_ROOT/ds-json-dump.json"
bash "$SCORER" "$DS_JSON_DUMP" --json > "$DS_JSON_DUMP_OUT"
check_cmd "DS-34 JSON string raw transcript fails closed" test "$(python3 -c "import json; print(json.load(open('$DS_JSON_DUMP_OUT'))['verdict'])")" = "FAIL"

JSON_SEPARATE="$TMP_ROOT/json-separate"
make_base_fixture "$JSON_SEPARATE"
python3 - "$JSON_SEPARATE/SCORECARD.json" <<'PY'
import json
import sys

path = sys.argv[1]
payload = json.load(open(path, encoding="utf-8"))
payload["summary_a"] = "\n".join(f"PASS: separate summary A line {i}" for i in range(6))
payload["summary_b"] = "\n".join(f"PASS: separate summary B line {i}" for i in range(6))
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
PY
JSON_SEPARATE_OUT="$TMP_ROOT/json-separate.json"
bash "$SCORER" "$JSON_SEPARATE" --json > "$JSON_SEPARATE_OUT"
check_cmd "separate JSON command summaries do not combine into false raw run" test "$(python3 -c "import json; print(json.load(open('$JSON_SEPARATE_OUT'))['verdict'])")" = "PASS"

RECEIPT_ALLOWED="$TMP_ROOT/receipt-allowed"
make_base_fixture "$RECEIPT_ALLOWED"
{
    printf '%s\n' '# Raw Receipt' '```text'
    for i in $(seq 1 70); do printf 'PASS: retained raw receipt line %s\n' "$i"; done
    printf '%s\n' '```'
} > "$RECEIPT_ALLOWED/COMMAND_RECEIPT.md"
RECEIPT_OUT="$TMP_ROOT/receipt.json"
bash "$SCORER" "$RECEIPT_ALLOWED" --json > "$RECEIPT_OUT"
check_cmd "raw receipt artifact remains allowed" test "$(python3 -c "import json; print(json.load(open('$RECEIPT_OUT'))['verdict'])")" = "PASS"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
