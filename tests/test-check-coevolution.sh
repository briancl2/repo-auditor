#!/usr/bin/env bash
# Regression tests for the co-evolution guard.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass_count=0

write_paths() {
    local name="$1"
    shift
    local path="$TMP_ROOT/$name.txt"
    : > "$path"
    for changed_path in "$@"; do
        printf '%s\n' "$changed_path" >> "$path"
    done
    printf '%s\n' "$path"
}

expect_pass() {
    local label="$1"
    local paths_file="$2"
    if bash "$REPO_ROOT/scripts/check-coevolution.sh" --changed-paths-file "$paths_file" > "$TMP_ROOT/out.txt" 2>&1; then
        echo "  PASS: $label"
        pass_count=$((pass_count + 1))
    else
        echo "  FAIL: $label"
        cat "$TMP_ROOT/out.txt"
        exit 1
    fi
}

expect_fail() {
    local label="$1"
    local paths_file="$2"
    if bash "$REPO_ROOT/scripts/check-coevolution.sh" --changed-paths-file "$paths_file" > "$TMP_ROOT/out.txt" 2>&1; then
        echo "  FAIL: $label"
        cat "$TMP_ROOT/out.txt"
        exit 1
    fi
    if ! grep -Fq "governed surface edits require" "$TMP_ROOT/out.txt"; then
        echo "  FAIL: $label did not explain co-evolution requirement"
        cat "$TMP_ROOT/out.txt"
        exit 1
    fi
    echo "  PASS: $label"
    pass_count=$((pass_count + 1))
}

echo "=== Co-Evolution Guard Tests ==="

expect_pass "docs-only changes are ignored" "$(write_paths docs_only README.md docs/invocation-contract.md)"
expect_fail "detection signature without tests fails" "$(write_paths detect_only scripts/detect-new-signal.sh)"
expect_pass "detection signature with test passes" "$(write_paths detect_test scripts/detect-new-signal.sh tests/test-detect-new-signal.sh)"
expect_fail "schema without tests fails" "$(write_paths schema_only schemas/SCORECARD.schema.json)"
expect_pass "agent surface with fixture passes" "$(write_paths agent_fixture .agents/repo-auditor.agent.md tests/fixtures/agent/sample.md)"
expect_fail "github agent surface without tests fails" "$(write_paths github_agent_only .github/agents/repo-auditor.agent.md)"
expect_pass "valid fixture pairing outside tests passes" "$(write_paths fixture_pair schemas/OPPORTUNITIES.schema.json fixtures/schema/sample.json)"

echo ""
echo "=== test-check-coevolution.sh: $pass_count pass, 0 fail ==="
