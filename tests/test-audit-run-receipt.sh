#!/usr/bin/env bash
# test-audit-run-receipt.sh — Validate audit run receipt status semantics.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$REPO_ROOT/tests/test-output-audit-run-receipt"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

create_fixture_repo() {
    local repo_path="$1"

    mkdir -p "$repo_path/.agents/skills/reviewing-code-locally" \
        "$repo_path/.github/workflows" "$repo_path/specs/001-sample" \
        "$repo_path/scripts" "$repo_path/tests"

    cat > "$repo_path/AGENTS.md" <<'EOF'
# Fixture Agents

Use reviewing-code-locally before large changes.
EOF
    cat > "$repo_path/LEARNINGS.md" <<'EOF'
# Fixture Learnings

| ID | Learning | Source |
|---|---|---|
| L1 | Keep receipts machine-readable. | fixture |
EOF
    cat > "$repo_path/HYPOTHESES.md" <<'EOF'
# Fixture Hypotheses
EOF
    cat > "$repo_path/.agents/skills/reviewing-code-locally/SKILL.md" <<'EOF'
# reviewing-code-locally
EOF
    cat > "$repo_path/.github/workflows/ci.yml" <<'EOF'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
EOF
    cat > "$repo_path/specs/001-sample/spec.md" <<'EOF'
# Sample Spec
EOF
    cat > "$repo_path/scripts/score-demo.sh" <<'EOF'
#!/usr/bin/env bash
echo score
EOF
    chmod +x "$repo_path/scripts/score-demo.sh"
    cat > "$repo_path/tests/test-demo.sh" <<'EOF'
#!/usr/bin/env bash
echo test
EOF
    chmod +x "$repo_path/tests/test-demo.sh"
    cat > "$repo_path/Makefile" <<'EOF'
review:
	@echo review
EOF

    (
        cd "$repo_path"
        git init -q
        git config user.name fixture
        git config user.email fixture@example.com
        git add .
        git commit -qm "fixture"
    )
}

assert_complete_receipt() {
    local out_dir="$1"
    python3 - "$out_dir" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipt = json.load(open(out / "AUDIT_RUN_RECEIPT.json"))
scorecard = json.load(open(out / "SCORECARD.json"))

assert receipt["status"] == "completed", receipt
assert receipt["artifact_status"] == "completed", receipt
assert receipt["exit_code"] == 0, receipt
assert receipt["missing_required_artifacts"] == [], receipt
assert scorecard["meta"]["audit_status"] == "completed", scorecard["meta"]
assert scorecard["meta"]["artifact_status"] == "completed", scorecard["meta"]
assert scorecard["meta"]["missing_required_artifacts"] == [], scorecard["meta"]

dimension_sum = sum(dim["score"] for dim in scorecard["dimensions"].values())
assert scorecard["composite"] == dimension_sum, scorecard
assert scorecard["max_composite"] == 100, scorecard
assert all(dim["max"] == 20 for dim in scorecard["dimensions"].values()), scorecard
PY
}

assert_partial_receipt() {
    local out_dir="$1"
    python3 - "$out_dir" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipt = json.load(open(out / "AUDIT_RUN_RECEIPT.json"))
scorecard = json.load(open(out / "SCORECARD.json"))

assert receipt["status"] == "partial", receipt
assert receipt["artifact_status"] == "partial", receipt
assert receipt["exit_code"] == 3, receipt
assert receipt["reason"] and "report generation failed" in receipt["reason"], receipt
assert "AUDIT_REPORT.md" in receipt["missing_required_artifacts"], receipt
assert "report-generation" in receipt["failed_tools"], receipt
assert scorecard["meta"]["audit_status"] == "partial", scorecard["meta"]
assert scorecard["meta"]["artifact_status"] == "partial", scorecard["meta"]
assert "AUDIT_REPORT.md" in scorecard["meta"]["missing_required_artifacts"], scorecard["meta"]
assert "report generation failed" in scorecard["meta"]["audit_status_reason"], scorecard["meta"]

dimension_sum = sum(dim["score"] for dim in scorecard["dimensions"].values())
assert scorecard["composite"] == dimension_sum, scorecard
PY
}

assert_failed_receipt() {
    local out_dir="$1"
    python3 - "$out_dir" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipt = json.load(open(out / "AUDIT_RUN_RECEIPT.json"))

assert receipt["status"] == "failed", receipt
assert receipt["exit_code"] == 2, receipt
assert receipt["reason"], receipt
assert "target not found" in receipt["reason"], receipt
assert "target" in receipt["failed_tools"], receipt
assert "SCORECARD.json" in receipt["missing_required_artifacts"], receipt
PY
}

echo "=== Audit Run Receipt Validation ==="
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"
mkdir -p "$TEST_ROOT/tmp"
export TMPDIR="$TEST_ROOT/tmp"

COMPLETE_REPO="$TEST_ROOT/complete-repo"
COMPLETE_OUT="$TEST_ROOT/complete-output"
create_fixture_repo "$COMPLETE_REPO"
mkdir -p "$COMPLETE_OUT"
bash "$REPO_ROOT/scripts/repo-auditor.sh" "$COMPLETE_REPO" "$COMPLETE_OUT" \
    > "$TEST_ROOT/complete.log" 2>&1
assert_complete_receipt "$COMPLETE_OUT"
echo "  ✓ completed audit writes completed receipt and preserves score semantics"

PARTIAL_REPO="$TEST_ROOT/partial-repo"
PARTIAL_OUT="$TEST_ROOT/partial-output"
create_fixture_repo "$PARTIAL_REPO"
mkdir -p "$PARTIAL_OUT/AUDIT_REPORT.md"
set +e
bash "$REPO_ROOT/scripts/repo-auditor.sh" "$PARTIAL_REPO" "$PARTIAL_OUT" \
    > "$TEST_ROOT/partial.log" 2>&1
PARTIAL_RC=$?
set -e
if [ "$PARTIAL_RC" -eq 0 ]; then
    echo "FAIL: partial report-generation case should exit non-zero"
    exit 1
fi
assert_partial_receipt "$PARTIAL_OUT"
echo "  ✓ report-generation failure writes partial receipt and scorecard metadata"

FAILED_OUT="$TEST_ROOT/failed-output"
set +e
bash "$REPO_ROOT/scripts/repo-auditor.sh" "$TEST_ROOT/missing-target" "$FAILED_OUT" \
    > "$TEST_ROOT/failed.log" 2>&1
FAILED_RC=$?
set -e
if [ "$FAILED_RC" -eq 0 ]; then
    echo "FAIL: missing target case should exit non-zero"
    exit 1
fi
assert_failed_receipt "$FAILED_OUT"
echo "  ✓ failed audit writes failed receipt with reason"

echo "  VERDICT: PASS"
