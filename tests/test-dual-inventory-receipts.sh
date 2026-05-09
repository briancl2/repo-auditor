#!/usr/bin/env bash
# test-dual-inventory-receipts.sh — Validate additive dual inventory receipts.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_PARENT="${TMPDIR:-$REPO_ROOT/work/test-tmp}"
TMP_ROOT="$TMP_PARENT/dual-inventory.$$"
rm -rf "$TMP_ROOT"
mkdir -p "$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT

make_score_output() {
    local out="$1"
    mkdir -p "$out"
    python3 - "$out" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
scorecard = {
    "dimensions": {},
    "composite": 42,
    "max_composite": 100,
    "receipts": {
        "file": "SCORECARD_RECEIPTS.json",
        "version": "1.0.0",
        "count_reconciliation_status": "aligned",
    },
    "tier1_checks": {
        "total": 5,
        "passed": 5,
        "failed": 0,
        "failures": [],
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
PY
}

echo "=== Dual Inventory Receipt Validation ==="

POPULATED_TARGET="$TMP_ROOT/populated-target"
POPULATED_OUT="$TMP_ROOT/populated-output"
mkdir -p "$POPULATED_TARGET/.agents/skills/example" \
    "$POPULATED_TARGET/.agents" \
    "$POPULATED_TARGET/docs" \
    "$POPULATED_TARGET/scripts" \
    "$POPULATED_TARGET/tests" \
    "$POPULATED_TARGET/ignored-private"
cat > "$POPULATED_TARGET/.auditorignore" <<'EOF'
ignored-private/
EOF
cat > "$POPULATED_TARGET/AGENTS.md" <<'EOF'
# Fixture instructions
EOF
cat > "$POPULATED_TARGET/.agents/reviewer.agent.md" <<'EOF'
# Reviewer
EOF
cat > "$POPULATED_TARGET/.agents/skills/example/SKILL.md" <<'EOF'
# Example Skill
EOF
cat > "$POPULATED_TARGET/docs/design.md" <<'EOF'
# Design
EOF
cat > "$POPULATED_TARGET/scripts/check.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$POPULATED_TARGET/tests/test-example.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$POPULATED_TARGET/ignored-private/secret-shape.txt" <<'EOF'
do not emit this path
EOF
make_score_output "$POPULATED_OUT"

python3 "$REPO_ROOT/scripts/collect-dual-inventory.py" "$POPULATED_TARGET" "$POPULATED_OUT"
python3 - "$POPULATED_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
scorecard = json.load(open(out / "SCORECARD.json"))
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
primary = receipts["primary_surface_inventory"]
full = receipts["full_facts_inventory"]
pointer = scorecard["receipts"]["dual_inventory"]

assert scorecard["composite"] == 42
assert primary["status"] == "available", primary
assert primary["scan_limit"] == 200, primary
assert primary["scan_limit_reached"] is False, primary
assert primary["total_unique_paths"] >= 4, primary
assert "AGENTS.md" in primary["categories"]["instruction_roots"]["paths"], primary
assert ".agents/reviewer.agent.md" in primary["categories"]["agent_definitions"]["paths"], primary
assert ".agents/skills/example/SKILL.md" in primary["categories"]["skill_definitions"]["paths"], primary
assert full["status"] == "available", full
assert full["scan_limit"] == 200, full
assert full["scan_limit_reached"] is False, full
assert full["denominator_mode"] == "not_measured", full
assert full["auditor_pruned_total_files"] is None, full
assert full["scan_coverage_ratio"] is None, full
assert full["paths_emitted"] is False, full
assert full["auditorignore"]["active"] is True, full
assert full["auditorignore"]["entries_emitted"] is False, full
assert pointer["file"] == "SCORECARD_RECEIPTS.json", pointer
assert pointer["primary_surface_inventory_status"] == "available", pointer
assert pointer["full_facts_inventory_status"] == "available", pointer
assert pointer["full_facts_denominator_mode"] == "not_measured", pointer
assert pointer["full_facts_auditor_pruned_total_files"] is None, pointer
assert pointer["full_facts_scan_coverage_ratio"] is None, pointer
assert pointer["non_authorization"] is True, pointer
serialized = json.dumps(receipts, sort_keys=True)
assert "ignored-private" not in serialized, serialized
assert "secret-shape" not in serialized, serialized
assert "never cleanup authorization" in primary["non_authorization_statement"], primary
PY
echo "  ✓ populated target emits primary and full-facts inventory without changing score"

IN_TARGET_OUTPUT_TARGET="$TMP_ROOT/in-target-output-target"
IN_TARGET_OUTPUT="$IN_TARGET_OUTPUT_TARGET/audit-output"
mkdir -p "$IN_TARGET_OUTPUT_TARGET/src" "$IN_TARGET_OUTPUT"
cat > "$IN_TARGET_OUTPUT_TARGET/AGENTS.md" <<'EOF'
# Real target instructions
EOF
cat > "$IN_TARGET_OUTPUT_TARGET/src/app.py" <<'EOF'
print("target")
EOF
make_score_output "$IN_TARGET_OUTPUT"
cat > "$IN_TARGET_OUTPUT/AGENTS.md" <<'EOF'
# Generated output should not count as target instructions
EOF
python3 "$REPO_ROOT/scripts/collect-dual-inventory.py" "$IN_TARGET_OUTPUT_TARGET" "$IN_TARGET_OUTPUT"
python3 - "$IN_TARGET_OUTPUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
primary = receipts["primary_surface_inventory"]
full = receipts["full_facts_inventory"]
serialized = json.dumps(receipts, sort_keys=True)

assert primary["status"] == "available", primary
assert primary["categories"]["instruction_roots"]["paths"] == ["AGENTS.md"], primary
assert full["total_files_scanned"] == 2, full
assert "audit-output" not in serialized, serialized
assert "Generated output" not in serialized, serialized
PY
echo "  ✓ output directory inside target is pruned from target inventory"

EMPTY_TARGET="$TMP_ROOT/empty-primary-target"
EMPTY_OUT="$TMP_ROOT/empty-primary-output"
mkdir -p "$EMPTY_TARGET/src"
cat > "$EMPTY_TARGET/src/app.py" <<'EOF'
print("hello")
EOF
make_score_output "$EMPTY_OUT"

python3 "$REPO_ROOT/scripts/collect-dual-inventory.py" "$EMPTY_TARGET" "$EMPTY_OUT"
python3 - "$EMPTY_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))
primary = receipts["primary_surface_inventory"]

assert primary["status"] == "available_empty", primary
assert primary["total_unique_paths"] == 0, primary
assert "insufficient evidence" in primary["non_authorization_statement"], primary
assert scorecard["receipts"]["dual_inventory"]["primary_surface_inventory_status"] == "available_empty"
assert scorecard["composite"] == 42
PY
echo "  ✓ empty primary inventory is explicit insufficient evidence"

LIMITED_TARGET="$TMP_ROOT/limited-target"
LIMITED_OUT="$TMP_ROOT/limited-output"
mkdir -p "$LIMITED_TARGET/many"
cat > "$LIMITED_TARGET/AGENTS.md" <<'EOF'
# Fixture instructions
EOF
idx=0
while [ "$idx" -lt 205 ]; do
    printf 'file %s\n' "$idx" > "$LIMITED_TARGET/many/file-$idx.txt"
    idx=$((idx + 1))
done
make_score_output "$LIMITED_OUT"
python3 "$REPO_ROOT/scripts/collect-dual-inventory.py" "$LIMITED_TARGET" "$LIMITED_OUT"
python3 - "$LIMITED_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))
primary = receipts["primary_surface_inventory"]
full = receipts["full_facts_inventory"]

assert primary["status"] == "available_limited", primary
assert primary["scan_limit_reached"] is True, primary
assert full["status"] == "available_limited", full
assert full["scan_limit_reached"] is True, full
assert full["total_files_scanned"] == 200, full
assert scorecard["receipts"]["dual_inventory"]["primary_surface_inventory_status"] == "available_limited"
assert scorecard["receipts"]["dual_inventory"]["full_facts_inventory_status"] == "available_limited"
assert scorecard["composite"] == 42
PY
echo "  ✓ scan-limited inventory is explicit insufficient evidence"

DENOMINATOR_OUT="$TMP_ROOT/denominator-output"
make_score_output "$DENOMINATOR_OUT"
REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES=50 \
    REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR=1 \
    python3 "$REPO_ROOT/scripts/collect-dual-inventory.py" "$LIMITED_TARGET" "$DENOMINATOR_OUT"
python3 - "$DENOMINATOR_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))
full = receipts["full_facts_inventory"]
pointer = scorecard["receipts"]["dual_inventory"]

assert full["status"] == "available_limited", full
assert full["scan_limit"] == 50, full
assert full["total_files_scanned"] == 50, full
assert full["denominator_mode"] == "full_walk", full
assert full["auditor_pruned_total_files"] == 206, full
assert full["scan_coverage_ratio"] == round(50 / 206, 6), full
assert full["git_tracked_file_count"] is None, full
assert pointer["full_facts_denominator_mode"] == "full_walk", pointer
assert pointer["full_facts_auditor_pruned_total_files"] == 206, pointer
assert pointer["full_facts_scan_coverage_ratio"] == round(50 / 206, 6), pointer
assert pointer["non_authorization"] is True, pointer
PY
echo "  ✓ opt-in denominator mode reports coverage without changing score"

UNAVAILABLE_OUT="$TMP_ROOT/unavailable-output"
make_score_output "$UNAVAILABLE_OUT"
python3 "$REPO_ROOT/scripts/collect-dual-inventory.py" "$TMP_ROOT/missing-target" "$UNAVAILABLE_OUT"
python3 - "$UNAVAILABLE_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))
primary = receipts["primary_surface_inventory"]
full = receipts["full_facts_inventory"]

assert primary["status"] == "unavailable", primary
assert full["status"] == "unavailable", full
assert "not found" in primary["unavailable_reason"], primary
assert scorecard["receipts"]["dual_inventory"]["primary_surface_inventory_status"] == "unavailable"
assert scorecard["receipts"]["dual_inventory"]["full_facts_inventory_status"] == "unavailable"
assert scorecard["receipts"]["dual_inventory"]["non_authorization"] is True
assert scorecard["composite"] == 42
PY
echo "  ✓ unavailable inventory fails informationally without changing score"

echo "  VERDICT: PASS"
