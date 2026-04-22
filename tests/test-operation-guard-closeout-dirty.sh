#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

FIXTURE_REPO="$TMP_ROOT/fixture-repo"
mkdir -p "$FIXTURE_REPO"

(
    cd "$FIXTURE_REPO"
    git init -q
    git config user.name fixture
    git config user.email fixture@example.com
    cat > tracked.txt <<'EOF'
clean
EOF
    git add tracked.txt
    git commit -qm "fixture"
    echo "dirty" >> tracked.txt
)

echo "=== test-operation-guard-closeout-dirty.sh ==="

if bash "$REPO_ROOT/scripts/operation-guard.sh" "$FIXTURE_REPO" >"$TMP_ROOT/default.out" 2>&1; then
    cat "$TMP_ROOT/default.out" >&2
    fail "default operation guard should reject dirty target repos"
fi
grep -q "Target git state" "$TMP_ROOT/default.out" || fail "default guard output should mention target git state"
grep -q "uncommitted files" "$TMP_ROOT/default.out" || fail "default guard output should mention uncommitted files"
pass "default operation guard rejects dirty target repos"

if bash "$REPO_ROOT/scripts/operation-guard.sh" \
    "$FIXTURE_REPO" \
    --allow-dirty-closeout-post-audit >"$TMP_ROOT/allow.out" 2>&1; then
    :
else
    cat "$TMP_ROOT/allow.out" >&2
    fail "closeout-post-audit override should admit the dirty target repo"
fi
grep -q "closeout-post-audit" "$TMP_ROOT/allow.out" || fail "override output should record closeout-post-audit allowance"
pass "closeout-post-audit override admits dirty target repos narrowly"

if bash "$REPO_ROOT/scripts/operation-guard.sh" "$FIXTURE_REPO" --unexpected-override >"$TMP_ROOT/bad-token.out" 2>&1; then
    cat "$TMP_ROOT/bad-token.out" >&2
    fail "unrecognized dirty-state override token should not bypass the guard"
fi
grep -q "Target git state" "$TMP_ROOT/bad-token.out" || fail "invalid-token output should still mention target git state"
pass "invalid dirty-state override token still fails closed"

SCOPED_STAGING_DIR="${TMPDIR:-/tmp}/20260422T000000Z.post-audit.run.scoped.$$"
INVALID_POST_AUDIT_DIR="$TMP_ROOT/not-a-closeout-post-audit"
trap 'rm -rf "$TMP_ROOT" "$SCOPED_STAGING_DIR"' EXIT

if bash "$REPO_ROOT/scripts/repo-auditor.sh" \
    "$FIXTURE_REPO" \
    "$SCOPED_STAGING_DIR" \
    --allow-dirty-closeout-post-audit >"$TMP_ROOT/public-flag.out" 2>&1; then
    cat "$TMP_ROOT/public-flag.out" >&2
    fail "repo-auditor should reject the closeout dirty override without the work-close caller token"
fi
grep -q "reserved for work-close callers" "$TMP_ROOT/public-flag.out" || fail "repo-auditor should explain missing work-close caller token"
pass "repo-auditor rejects public closeout dirty overrides without caller scoping"

if REPO_AUDITOR_CLOSEOUT_CALLER=1 \
    bash "$REPO_ROOT/scripts/repo-auditor.sh" \
    "$FIXTURE_REPO" \
    "$INVALID_POST_AUDIT_DIR" \
    --allow-dirty-closeout-post-audit >"$TMP_ROOT/invalid-scope.out" 2>&1; then
    cat "$TMP_ROOT/invalid-scope.out" >&2
    fail "repo-auditor should reject closeout dirty overrides outside the real self-audit scope"
fi
grep -q "requires a self-audit" "$TMP_ROOT/invalid-scope.out" || fail "repo-auditor should explain invalid closeout self-audit scope"
pass "repo-auditor requires a real self-audit closeout scope for dirty overrides"

(
    cd "$FIXTURE_REPO"
    if REPO_AUDITOR_CLOSEOUT_CALLER=1 \
        bash "$REPO_ROOT/scripts/repo-auditor.sh" \
        . \
        "$SCOPED_STAGING_DIR" \
        --allow-dirty-closeout-post-audit >"$TMP_ROOT/scoped-allow.out" 2>&1; then
        :
    else
        cat "$TMP_ROOT/scoped-allow.out" >&2
        fail "repo-auditor should admit the scoped closeout dirty override for a real self-audit"
    fi
)
[ -f "$SCOPED_STAGING_DIR/SCORECARD.json" ] || fail "scoped closeout dirty override should still produce a SCORECARD.json"
pass "repo-auditor admits dirty closeout overrides only for scoped self-audit work-close calls"

echo "=== test-operation-guard-closeout-dirty.sh: PASS ==="
