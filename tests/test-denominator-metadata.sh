#!/usr/bin/env bash
# test-denominator-metadata.sh — Validate count reconciliation denominator metadata.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$REPO_ROOT/tests/test-output-denominator-metadata"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

echo "=== Denominator Metadata Validation ==="
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT/target/ignored-private" "$TEST_ROOT/output"

TARGET_REPO="$TEST_ROOT/target"
OUTPUT_DIR="$TEST_ROOT/output"

cat > "$TARGET_REPO/.auditorignore" <<'EOF'
# private target path should not be copied into SCORECARD_RECEIPTS.json
ignored-private/
EOF
cat > "$TARGET_REPO/AGENTS.md" <<'EOF'
# Fixture Agents
EOF
cat > "$TARGET_REPO/README.md" <<'EOF'
# Fixture
EOF
cat > "$TARGET_REPO/ignored-private/secret-shape.txt" <<'EOF'
do not emit this path in scorecard receipts
EOF

cat > "$OUTPUT_DIR/pre-scan-log.txt" <<'EOF'
================================================================
Pre-Scan Complete: target
================================================================
Total files:        2
Auditorignore:      yes
AI surfaces:        1 (0a, 0s, 1i, 0p)
EOF

cat > "$OUTPUT_DIR/maturity.txt" <<EOF
Path: $TARGET_REPO
AGENTS.md: YES
LEARNINGS.md: no
HYPOTHESES.md: no
CI pipeline: no
Scoring tools: 1
Files: 2
Skills: 0
Agents: 0
PHASE: 1 — Assisted
EOF

cat > "$OUTPUT_DIR/stall-risk.txt" <<'EOF'
SCORE: 10
EOF

cat > "$OUTPUT_DIR/dna.txt" <<'EOF'
Governance: 1
Scoring Layers: 1
Self-Audit Depth: 1
Abstraction Depth: 1
Skill Density: 0 / 2 files
Skill Velocity: 0.0
Agent Organicity: 0.0
Maturity Score: 10
Trajectory: 10
Plan Infrastructure: 1
Co-Evolution Ratio: 0.0
EOF

cat > "$OUTPUT_DIR/drift.txt" <<'EOF'
Undocumented: 0 (0%)
EOF

bash "$REPO_ROOT/scripts/score-audit-dimensions.sh" "$OUTPUT_DIR" \
    > "$TEST_ROOT/scorer.log"

python3 - "$OUTPUT_DIR/SCORECARD_RECEIPTS.json" <<'PY'
import json
import sys

receipts_path = sys.argv[1]
receipts = json.load(open(receipts_path))
recon = receipts["count_reconciliation"]

assert recon["status"] == "aligned", recon
assert recon["authoritative_total_files"] == 2, recon
assert recon["pre_scan_total_files"] == 2, recon
assert recon["maturity_total_files"] == 2, recon
assert recon["dna_total_files"] == 2, recon

semantics = recon["denominator_semantics"]
assert semantics["name"] == "auditor_pruned_analysis_scorecard_denominator", semantics
assert "auditor-pruned" in semantics["authoritative_total_files_meaning"], semantics
assert semantics["count_behavior"].startswith("metadata-only"), semantics

classes = recon["excluded_path_classes"]
for path_class in [
    ".git",
    ".venv",
    "venv",
    "node_modules",
    ".tox",
    ".mypy_cache",
    "__pycache__",
    "vendor",
    ".eggs",
]:
    assert path_class in classes["default_pruned_directories"], classes
assert ".DS_Store" in classes["default_excluded_files"], classes

auditorignore = classes["auditorignore"]
assert auditorignore["active"] is True, auditorignore
assert auditorignore["entry_count"] == 1, auditorignore
assert auditorignore["entry_count_status"] == "known", auditorignore
assert auditorignore["entries_emitted"] is False, auditorignore

serialized = json.dumps(recon, sort_keys=True)
assert "ignored-private" not in serialized, serialized
assert "secret-shape" not in serialized, serialized
PY

echo "  ✓ metadata names denominator, includes excluded classes, and preserves counts"
echo "  VERDICT: PASS"
