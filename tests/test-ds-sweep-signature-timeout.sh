#!/usr/bin/env bash
# test-ds-sweep-signature-timeout.sh — #184 regression.
#
# The DS-34+ post-audit sweep must never hang: each signature runs under a
# per-signature wall-clock budget, and a hung command is reaped with a 124
# fail-fast signal. This verifies (a) the run-with-timeout.sh wrapper reaps a
# hung child and passes fast exit codes through, and (b) the sweep runner emits
# progress and completes bounded on a repo (never hangs).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "=== test-ds-sweep-signature-timeout.sh ==="

WRAP="$REPO_ROOT/scripts/run-with-timeout.sh"
[ -f "$WRAP" ] || fail "run-with-timeout.sh helper is missing"

# (a) A command that exceeds its budget is reaped and reported as 124, bounded.
start=$(date +%s)
rc=0
bash "$WRAP" 1 sleep 30 >/dev/null 2>&1 || rc=$?
elapsed=$(( $(date +%s) - start ))
if [ "$rc" -ne 124 ]; then
    fail "expected exit 124 for a command exceeding its budget, got $rc"
fi
if [ "$elapsed" -gt 15 ]; then
    fail "timeout wrapper did not reap the hung child promptly (elapsed ${elapsed}s)"
fi
pass "run-with-timeout.sh reaps a hung child with 124 and bounded elapsed (${elapsed}s)"

# (b) A fast command runs to completion and its own exit code passes through.
rc=0
bash "$WRAP" 10 true >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 passthrough for a fast success, got $rc"
rc=0
bash "$WRAP" 10 sh -c 'exit 7' >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 7 ] || fail "expected exit 7 passthrough for a fast failure, got $rc"
pass "run-with-timeout.sh passes fast command exit codes through unchanged"

# (c) The sweep runner emits [i/N] progress and completes bounded on a repo.
TARGET="$TMP_ROOT/target"
OUT="$TMP_ROOT/out"
mkdir -p "$TARGET"
(
    cd "$TARGET"
    git init -q
    git config user.name fixture
    git config user.email fixture@example.com
    printf '# fixture\n' > README.md
    printf 'x = 1\n' > a.py
    git add -A
    git commit -qm init
)

# Bound the whole sweep so a genuine hang fails the test fast rather than
# stalling. The sweep must finish well within this envelope.
rc=0
bash "$WRAP" 300 bash "$REPO_ROOT/scripts/detect-new-signatures.sh" "$TARGET" "$OUT" \
    >"$TMP_ROOT/sweep.out" 2>"$TMP_ROOT/sweep.err" || rc=$?
if [ "$rc" -eq 124 ]; then
    fail "DS-34+ sweep hung past its bounded envelope (never-hang guarantee broken)"
fi
[ "$rc" -eq 0 ] || { cat "$TMP_ROOT/sweep.err" >&2; fail "sweep exited non-zero ($rc)"; }
grep -q "\[1/" "$TMP_ROOT/sweep.err" || fail "sweep did not emit [i/N] per-signature progress"
[ -f "$OUT/DS-34-plus-results.json" ] || fail "sweep did not produce DS-34-plus-results.json"
python3 -c "import json;json.load(open('$OUT/DS-34-plus-results.json'))" \
    || fail "sweep result JSON is not valid"
pass "DS-34+ sweep emits progress and completes bounded with a valid result bundle"

echo "=== test-ds-sweep-signature-timeout.sh: PASS ==="
