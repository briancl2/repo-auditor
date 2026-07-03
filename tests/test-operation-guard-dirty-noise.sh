#!/usr/bin/env bash
# test-operation-guard-dirty-noise.sh — #185 regression.
#
# The dirty-start guard must degrade gracefully on generated/OS scratch: a
# target dirty ONLY with __pycache__/, *.pyc, .DS_Store, or work/ must audit
# successfully (recording the tolerated noise), while meaningful uncommitted
# source changes still block scoring. This guards both halves of #185.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$REPO_ROOT/scripts/operation-guard.sh"
CLASSIFY="$REPO_ROOT/scripts/classify-dirty-noise.py"
AUDITOR="$REPO_ROOT/scripts/repo-auditor.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "=== test-operation-guard-dirty-noise.sh ==="

[ -f "$CLASSIFY" ] || fail "classify-dirty-noise.py helper is missing"

make_repo() {
    local dir="$1"
    mkdir -p "$dir/scripts"
    (
        cd "$dir"
        git init -q
        git config user.name fixture
        git config user.email fixture@example.com
        printf 'x = 1\n' > scripts/a.py
        printf '# readme\n' > README.md
        git add -A
        git commit -qm init
    )
}

add_noise() {
    local dir="$1"
    printf 'noise\n' > "$dir/.DS_Store"
    mkdir -p "$dir/scripts/__pycache__"
    printf 'bytecode\n' > "$dir/scripts/__pycache__/a.pyc"
    mkdir -p "$dir/work/session"
    printf 'scratch\n' > "$dir/work/session/out.json"
}

# ── 1: classifier splits noise from meaningful ───────────────────────
NOISE_REPO="$TMP_ROOT/noise-only"
make_repo "$NOISE_REPO"
add_noise "$NOISE_REPO"
CLS="$(python3 "$CLASSIFY" "$NOISE_REPO")"
MEAN="$(printf '%s' "$CLS" | python3 -c 'import sys,json;print(json.load(sys.stdin)["meaningful_count"])')"
NOISY="$(printf '%s' "$CLS" | python3 -c 'import sys,json;print(json.load(sys.stdin)["tolerated_noise_count"])')"
[ "$MEAN" -eq 0 ] || fail "classifier counted noise-only tree as meaningful ($MEAN)"
[ "$NOISY" -ge 1 ] || fail "classifier did not record tolerated noise (got $NOISY)"
pass "classifier reports noise-only tree as meaningful=0, tolerated=$NOISY"

# ── 2: guard PASSES on a noise-only-dirty target ─────────────────────
if ! bash "$GUARD" "$NOISE_REPO" --lockdir "$TMP_ROOT/lock1" >"$TMP_ROOT/guard-noise.out" 2>&1; then
    cat "$TMP_ROOT/guard-noise.out" >&2
    fail "guard should PASS on a target dirty only with generated/OS noise"
fi
grep -q "tolerated noise" "$TMP_ROOT/guard-noise.out" || fail "guard should record the tolerated noise it ignored"
pass "guard passes a noise-only-dirty target and records the tolerated noise"

# ── 3: guard FAILS when meaningful source changes are present ────────
MIXED_REPO="$TMP_ROOT/mixed"
make_repo "$MIXED_REPO"
add_noise "$MIXED_REPO"
printf 'y = 2  # real change\n' >> "$MIXED_REPO/scripts/a.py"
if bash "$GUARD" "$MIXED_REPO" --lockdir "$TMP_ROOT/lock2" >"$TMP_ROOT/guard-mixed.out" 2>&1; then
    cat "$TMP_ROOT/guard-mixed.out" >&2
    fail "guard should FAIL when meaningful uncommitted source changes exist"
fi
grep -q "uncommitted files" "$TMP_ROOT/guard-mixed.out" || fail "guard FAIL output should mention uncommitted files"
pass "guard fails on meaningful source changes even alongside tolerated noise"

# ── 4: full audit run on noise-only target produces a scorecard ──────
AUDIT_OUT="$TMP_ROOT/audit-out"
if ! bash "$AUDITOR" "$NOISE_REPO" "$AUDIT_OUT" >"$TMP_ROOT/audit.out" 2>&1; then
    cat "$TMP_ROOT/audit.out" >&2
    fail "repo-auditor should score a noise-only-dirty target (no more N/A)"
fi
[ -f "$AUDIT_OUT/SCORECARD.json" ] || fail "repo-auditor should produce SCORECARD.json for a noise-only-dirty target"
python3 - "$AUDIT_OUT/SCORECARD.json" <<'PY' || fail "scorecard should record tolerated dirty noise"
import json, sys
meta = json.load(open(sys.argv[1])).get("meta", {})
assert meta.get("audit_status") == "completed", f"audit_status={meta.get('audit_status')}"
noise = meta.get("tolerated_dirty_noise")
assert isinstance(noise, dict), "meta.tolerated_dirty_noise missing"
assert noise.get("tolerated_noise_count", 0) >= 1, "tolerated_noise_count should be >= 1"
PY
pass "repo-auditor scores a noise-only-dirty target and records meta.tolerated_dirty_noise"

echo "=== test-operation-guard-dirty-noise.sh: PASS ==="
