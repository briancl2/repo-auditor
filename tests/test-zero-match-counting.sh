#!/usr/bin/env bash
# test-zero-match-counting.sh — Regression coverage for harvested L6 transfer
#
# Covers two Stage 14.1.3 proof cases:
# 1. classify-repo-maturity.sh must not abort when zero agent files match
#    the self-audit keyword set.
# 2. detect-feed-forward-stall.sh must evaluate the recent overall commit
#    window, not stale historical LEARNINGS commits.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_TMPDIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() { rm -rf "$TEST_TMPDIR"; }
trap cleanup EXIT

check() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected=$expected, actual=$actual)"
        FAIL=$((FAIL + 1))
    fi
}

init_git_repo() {
    local repo="$1"
    git -C "$repo" init -q
    git -C "$repo" config user.name "Codex Test"
    git -C "$repo" config user.email "codex@example.com"
}

commit_all() {
    local repo="$1" msg="$2"
    git -C "$repo" add .
    git -C "$repo" commit -qm "$msg"
}

echo "=== test-zero-match-counting.sh: zero-match + recent-window regressions ==="

echo ""
echo "-- T1: classify-repo-maturity survives zero self-audit matches --"
FIX_A="$TEST_TMPDIR/fixture-classify"
mkdir -p "$FIX_A/.agents"
cat > "$FIX_A/.agents/generic.agent.md" <<'EOF'
name: generic-helper
description: does basic repository chores
EOF
set +e
CLASSIFY_OUTPUT=$(bash "$REPO_ROOT/scripts/classify-repo-maturity.sh" "$FIX_A" 2>&1)
CLASSIFY_CODE=$?
set -e
check "classify exits 0 on generic agent repo" "0" "$CLASSIFY_CODE"
SELF_AUDIT_LINE=0
if printf '%s\n' "$CLASSIFY_OUTPUT" | grep -q "Self-audit:      no"; then
    SELF_AUDIT_LINE=1
fi
check "classify reports self-audit=no when no agents match" "1" "$SELF_AUDIT_LINE"

echo ""
echo "-- T2: DS-32 ignores stale LEARNINGS changes outside recent commit window --"
FIX_B="$TEST_TMPDIR/fixture-ds32-stale"
mkdir -p "$FIX_B"
init_git_repo "$FIX_B"
cat > "$FIX_B/LEARNINGS.md" <<'EOF'
# LEARNINGS

| # | Learning | Source |
|---|---|---|
| L1 | Initial learning | seed |
EOF
commit_all "$FIX_B" "init learnings"
for i in 1 2 3 4 5 6; do
    echo "$i" >> "$FIX_B/README.md"
    commit_all "$FIX_B" "docs $i"
done
set +e
DS32_STALE_OUTPUT=$(bash "$REPO_ROOT/scripts/detect-feed-forward-stall.sh" "$FIX_B" --sessions 1 --json 2>&1)
DS32_STALE_CODE=$?
set -e
check "DS-32 exits healthy when learnings are outside recent window" "0" "$DS32_STALE_CODE"
STALE_NEW_L=0
STALE_FIRES=0
if printf '%s\n' "$DS32_STALE_OUTPUT" | grep -q '"new_lnumbers":0'; then
    STALE_NEW_L=1
fi
if printf '%s\n' "$DS32_STALE_OUTPUT" | grep -q '"fires":false'; then
    STALE_FIRES=1
fi
check "DS-32 reports new_lnumbers=0 for stale learnings" "1" "$STALE_NEW_L"
check "DS-32 does not fire on stale learnings alone" "1" "$STALE_FIRES"

echo ""
echo "-- T3: DS-32 fires on recent learnings with no structural follow-through --"
FIX_C="$TEST_TMPDIR/fixture-ds32-fire"
mkdir -p "$FIX_C"
init_git_repo "$FIX_C"
cat > "$FIX_C/LEARNINGS.md" <<'EOF'
# LEARNINGS

| # | Learning | Source |
|---|---|---|
| L1 | Initial learning | seed |
EOF
commit_all "$FIX_C" "init learnings"
cat > "$FIX_C/LEARNINGS.md" <<'EOF'
# LEARNINGS

| # | Learning | Source |
|---|---|---|
| L1 | Initial learning | seed |
| L2 | New learning | session |
EOF
commit_all "$FIX_C" "add learning only"
set +e
DS32_FIRE_OUTPUT=$(bash "$REPO_ROOT/scripts/detect-feed-forward-stall.sh" "$FIX_C" --sessions 1 --json 2>&1)
DS32_FIRE_CODE=$?
set -e
check "DS-32 exits 1 when recent learning lacks structural follow-through" "1" "$DS32_FIRE_CODE"
FIRE_FLAG=0
if printf '%s\n' "$DS32_FIRE_OUTPUT" | grep -q '"fires":true'; then
    FIRE_FLAG=1
fi
check "DS-32 reports fires=true for recent learning-only change" "1" "$FIRE_FLAG"

echo ""
echo "-- T4: DS-32 stays healthy when recent structural change follows learning --"
FIX_D="$TEST_TMPDIR/fixture-ds32-structural"
mkdir -p "$FIX_D"
init_git_repo "$FIX_D"
cat > "$FIX_D/LEARNINGS.md" <<'EOF'
# LEARNINGS

| # | Learning | Source |
|---|---|---|
| L1 | Initial learning | seed |
EOF
commit_all "$FIX_D" "init learnings"
cat > "$FIX_D/LEARNINGS.md" <<'EOF'
# LEARNINGS

| # | Learning | Source |
|---|---|---|
| L1 | Initial learning | seed |
| L2 | New learning | session |
EOF
commit_all "$FIX_D" "add learning"
mkdir -p "$FIX_D/scripts"
cat > "$FIX_D/scripts/example.sh" <<'EOF'
#!/usr/bin/env bash
echo structural
EOF
commit_all "$FIX_D" "add structural follow-through"
set +e
DS32_OK_OUTPUT=$(bash "$REPO_ROOT/scripts/detect-feed-forward-stall.sh" "$FIX_D" --sessions 1 --json 2>&1)
DS32_OK_CODE=$?
set -e
check "DS-32 exits healthy when structural change is in recent window" "0" "$DS32_OK_CODE"
OK_STRUCT=0
if printf '%s\n' "$DS32_OK_OUTPUT" | grep -q '"structural_changes":1'; then
    OK_STRUCT=1
fi
check "DS-32 counts recent structural change" "1" "$OK_STRUCT"

echo ""
echo "=== test-zero-match-counting.sh: $PASS pass, $FAIL fail ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
