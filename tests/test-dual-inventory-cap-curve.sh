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

python3 "$REPO_ROOT/scripts/measure-dual-inventory-cap-curve.py" "$TARGET" "$OUTPUT" --caps 20,200 > "$TMP_ROOT/stdout.json"

python3 - "$OUTPUT/dual-inventory-cap-curve.json" "$OUTPUT/dual-inventory-cap-curve.csv" <<'PY'
import csv
import json
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
assert rows[1]["full_status"] == "available", rows[1]
assert rows[1]["full_scan_limit_reached"] is False, rows[1]
assert "does not authorize cleanup" in summary["non_authorization"], summary
csv_rows = list(csv.DictReader(open(sys.argv[2])))
assert len(csv_rows) == 2, csv_rows
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
