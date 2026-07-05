#!/usr/bin/env bash
# test-floor-receipt-conformance.sh — Assert this repo's own fleet
# consistency-floor receipt passes the canonical static validator.
#
# Auto-picked-up by `make test` (for t in tests/test-*.sh). This is the
# per-repo static-conformance gate for repo-agent-core (BMA #1214 Phase 4
# item b): it rides inside the already-required `test` check, adding no new
# required status context.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-floor-receipt.sh"
RECEIPT="$REPO_ROOT/docs/repo-agent-fleet-consistency-floor-receipt.md"

PASS=0
FAIL=0

check() {
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

echo "=== Floor receipt conformance (self) ==="

check "canonical validator script exists" test -f "$VALIDATOR"
check "floor receipt exists" test -f "$RECEIPT"
check "receipt conforms to floor v0.2 (static validator)" \
    bash "$VALIDATOR" "$RECEIPT"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
