#!/usr/bin/env bash
# test-dual-inventory-cap-curve.sh — Validate cap-curve measurement helper.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/repo-auditor-cap-curve.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

TARGET="$TMP_ROOT/target"
OUTPUT="$TMP_ROOT/output"
mkdir -p "$TARGET/many"
cat > "$TARGET/AGENTS.md" <<'EOF'
# Instructions
EOF
idx=0
while [ "$idx" -lt 80 ]; do
    printf 'file %s\n' "$idx" > "$TARGET/many/file-$idx.txt"
    idx=$((idx + 1))
done

REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR=1 \
    python3 "$REPO_ROOT/scripts/measure-dual-inventory-cap-curve.py" "$TARGET" "$OUTPUT" --caps 20,200 > "$TMP_ROOT/stdout.json"

python3 - "$OUTPUT/dual-inventory-cap-curve.json" "$OUTPUT/dual-inventory-cap-curve.csv" <<'PY'
import csv
import json
import math
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text())
rows = summary["rows"]
assert summary["completed_runs"] == 2, summary
assert summary["limited_runs"] == 1, summary
assert summary["available_runs"] == 1, summary
assert summary["mutation_detected"] is False, summary
assert rows[0]["full_status"] == "available_limited", rows[0]
assert rows[0]["full_scan_limit_reached"] is True, rows[0]
assert rows[0]["full_denominator_mode"] == "full_walk", rows[0]
assert rows[0]["full_auditor_pruned_total_files"] == 81, rows[0]
assert rows[0]["full_scan_limit_guidance_status"] == "rerun_with_higher_cap", rows[0]
assert rows[0]["full_minimum_complete_cap"] == 81, rows[0]
assert rows[0]["full_recommended_rerun_cap"] == 90, rows[0]
assert rows[0]["full_trusted_local_override"] == "REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES=90", rows[0]
assert rows[0]["full_recommended_rerun_cap"] == math.ceil(rows[0]["full_minimum_complete_cap"] * 1.10), rows[0]
assert rows[1]["full_status"] == "available", rows[1]
assert rows[1]["full_scan_limit_reached"] is False, rows[1]
assert rows[1]["full_scan_limit_guidance_status"] == "not_needed", rows[1]
assert "does not authorize cleanup" in summary["non_authorization"], summary
csv_rows = list(csv.DictReader(open(sys.argv[2])))
assert len(csv_rows) == 2, csv_rows
assert csv_rows[0]["full_recommended_rerun_cap"] == "90", csv_rows[0]
PY

IN_TARGET_OUTPUT="$TARGET/measurement-output"
python3 "$REPO_ROOT/scripts/measure-dual-inventory-cap-curve.py" "$TARGET" "$IN_TARGET_OUTPUT" --caps 20,200 > "$TMP_ROOT/in-target-stdout.json"
python3 - "$IN_TARGET_OUTPUT/dual-inventory-cap-curve.json" <<'PY'
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text())
rows = summary["rows"]
assert summary["output_inside_target"] is True, summary
assert summary["retention_copy_performed_after_measurement"] is True, summary
assert rows[0]["full_total_files_scanned"] == 20, rows[0]
assert rows[1]["full_status"] == "available", rows[1]
PY

echo "PASS: dual-inventory cap curve measurement"
