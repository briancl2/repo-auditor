#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

write_lines() {
    local target="$1"
    shift
    printf '%s\n' "$@" > "$target"
}

FIXTURE_REPO="$TMP_ROOT/fixture-repo"
SNAPSHOT_DIR="$TMP_ROOT/snapshot-repo"
AUDIT_OUTPUT="$TMP_ROOT/audit-output"
mkdir -p "$FIXTURE_REPO/work/vtest/post-audit"

(
    cd "$FIXTURE_REPO"
    git init -q
    git config user.name fixture
    git config user.email fixture@example.com
    write_lines tracked.txt "clean"
    write_lines delete-me.txt "delete me"
    write_lines work/vtest/post-audit/SCORECARD.json '{"composite":55}'
    git add tracked.txt delete-me.txt work/vtest/post-audit/SCORECARD.json
    git commit -qm "fixture"
    write_lines tracked.txt "dirty"
    rm delete-me.txt
    write_lines added.txt "added"
    write_lines work/vtest/post-audit/SCORECARD.json '{"composite":99}'
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
    --allow-dirty-closeout-post-audit >"$TMP_ROOT/removed-flag-guard.out" 2>&1; then
    cat "$TMP_ROOT/removed-flag-guard.out" >&2
    fail "operation-guard should reject the removed dirty-closeout override flag"
fi
grep -q "has been removed" "$TMP_ROOT/removed-flag-guard.out" || fail "operation-guard should explain that the dirty-closeout override was removed"
pass "operation-guard rejects the removed dirty-closeout override flag"

if bash "$REPO_ROOT/scripts/repo-auditor.sh" \
    "$FIXTURE_REPO" \
    "$AUDIT_OUTPUT" \
    --allow-dirty-closeout-post-audit >"$TMP_ROOT/removed-flag-auditor.out" 2>&1; then
    cat "$TMP_ROOT/removed-flag-auditor.out" >&2
    fail "repo-auditor should reject the removed dirty-closeout override flag"
fi
grep -q "has been removed" "$TMP_ROOT/removed-flag-auditor.out" || fail "repo-auditor should explain that the dirty-closeout override was removed"
pass "repo-auditor rejects the removed dirty-closeout override flag"

python3 "$REPO_ROOT/scripts/prepare-clean-audit-snapshot.py" \
    "$FIXTURE_REPO" \
    "$SNAPSHOT_DIR" \
    --exclude-relpath "work/vtest/post-audit" >"$TMP_ROOT/snapshot.json"

[ -d "$SNAPSHOT_DIR/.git" ] || fail "snapshot helper should create a git repo"
[ -f "$SNAPSHOT_DIR/tracked.txt" ] || fail "snapshot should contain tracked files"
grep -q '^dirty$' "$SNAPSHOT_DIR/tracked.txt" || fail "snapshot should overlay modified tracked content"
[ -f "$SNAPSHOT_DIR/added.txt" ] || fail "snapshot should overlay untracked added files"
[ ! -e "$SNAPSHOT_DIR/delete-me.txt" ] || fail "snapshot should preserve tracked deletions"
[ ! -e "$SNAPSHOT_DIR/work/vtest/post-audit" ] || fail "snapshot should exclude stale post-audit output paths"
if [ -n "$(git -C "$SNAPSHOT_DIR" status --porcelain)" ]; then
    fail "snapshot repo should be clean after overlay commit"
fi
pass "snapshot helper produces a clean overlay of modified, added, deleted, and excluded paths"

if bash "$REPO_ROOT/scripts/repo-auditor.sh" "$SNAPSHOT_DIR" "$AUDIT_OUTPUT" >"$TMP_ROOT/snapshot-audit.out" 2>&1; then
    :
else
    cat "$TMP_ROOT/snapshot-audit.out" >&2
    fail "repo-auditor should run normally against the clean snapshot repo"
fi
[ -f "$AUDIT_OUTPUT/SCORECARD.json" ] || fail "repo-auditor should still produce a scorecard from the clean snapshot repo"
pass "repo-auditor accepts the clean snapshot repo through ordinary guardrails"

echo "=== test-operation-guard-closeout-dirty.sh: PASS ==="
