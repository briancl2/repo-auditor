#!/usr/bin/env bash
# test-compare-scorecards.sh — Validate compare-scorecards output and exits.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

TEST_ROOT="$REPO_DIR/work/test-compare-scorecards-$$"
PASS=0
FAIL=0
LAST_OUT=""

trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT"

pass() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ✗ $1"
  FAIL=$((FAIL + 1))
}

write_scorecard() {
  local path="$1"
  local composite="$2"
  local d1="$3"
  local d2="$4"
  local d3="$5"
  local d4="$6"
  local d5="$7"
  local t1_pass="$8"
  local t1_fail="$9"
  local phase="${10}"

  {
    printf '{\n'
    printf '  "composite": %s,\n' "$composite"
    printf '  "dimensions": {\n'
    printf '    "D1_governance": {"score": %s},\n' "$d1"
    printf '    "D2_surface_health": {"score": %s},\n' "$d2"
    printf '    "D3_skill_maturity": {"score": %s},\n' "$d3"
    printf '    "D4_measurement": {"score": %s},\n' "$d4"
    printf '    "D5_self_improvement": {"score": %s}\n' "$d5"
    printf '  },\n'
    printf '  "tier1_checks": {"passed": %s, "failed": %s},\n' "$t1_pass" "$t1_fail"
    printf '  "meta": {"phase": "%s"}\n' "$phase"
    printf '}\n'
  } > "$path"
}

assert_contains() {
  local file="$1"
  local expected="$2"
  local label="$3"

  if grep -Fq "$expected" "$file"; then
    pass "$label"
  else
    fail "$label"
    echo "    missing: $expected"
    echo "    file: $file"
  fi
}

assert_matches() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    echo "    missing pattern: $pattern"
    echo "    file: $file"
  fi
}

run_expect_success() {
  local name="$1"
  local before="$2"
  local after="$3"
  local out="$TEST_ROOT/$name.out"
  local err="$TEST_ROOT/$name.err"

  if bash scripts/compare-scorecards.sh "$before" "$after" > "$out" 2> "$err"; then
    pass "$name exits 0"
  else
    fail "$name exits 0"
    cat "$err"
  fi
  LAST_OUT="$out"
}

run_expect_failure() {
  local name="$1"
  local before="$2"
  local after="$3"
  local out="$TEST_ROOT/$name.out"
  local err="$TEST_ROOT/$name.err"
  local rc

  set +e
  bash scripts/compare-scorecards.sh "$before" "$after" > "$out" 2> "$err"
  rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    pass "$name exits non-zero"
  else
    fail "$name exits non-zero"
  fi
  LAST_OUT="$out"
}

echo "=== Compare Scorecards Validation ==="

BEFORE="$TEST_ROOT/before.json"
STABLE_AFTER="$TEST_ROOT/stable-after.json"
PASS_AFTER="$TEST_ROOT/pass-after.json"
REGRESSION_AFTER="$TEST_ROOT/regression-after.json"
MISSING="$TEST_ROOT/missing-scorecard.json"

write_scorecard "$BEFORE" 40 8 9 7 8 8 4 1 "phase-alpha"
write_scorecard "$STABLE_AFTER" 40 8 9 7 8 8 4 1 "phase-alpha"
write_scorecard "$PASS_AFTER" 45 9 9 8 9 10 5 0 "phase-beta"
write_scorecard "$REGRESSION_AFTER" 37 7 8 7 7 8 3 2 "phase-regression"

run_expect_success "stable" "$BEFORE" "$STABLE_AFTER"
STABLE_OUT="$LAST_OUT"
assert_contains "$STABLE_OUT" "VERDICT: STABLE (delta 0 to +1)" "stable verdict is reported"
assert_matches "$STABLE_OUT" 'COMPOSITE:[[:space:]]+40[[:space:]]+40[[:space:]]+=' "stable composite delta is shown"

run_expect_success "pass" "$BEFORE" "$PASS_AFTER"
PASS_OUT="$LAST_OUT"
assert_contains "$PASS_OUT" "VERDICT: PASS (delta ≥ +2)" "pass verdict is reported"
assert_contains "$PASS_OUT" "Phase:  phase-alpha → phase-beta" "phase transition is reported"
assert_contains "$PASS_OUT" "T1 checks: 4/5 → 5/5" "T1 transition is reported"
assert_matches "$PASS_OUT" 'D1 Governance:[[:space:]]+8[[:space:]]+9[[:space:]]+\+1' "D1 delta is shown"
assert_matches "$PASS_OUT" 'D2 Surface:[[:space:]]+9[[:space:]]+9[[:space:]]+=' "D2 stable dimension delta is shown"
assert_matches "$PASS_OUT" 'D3 Skill:[[:space:]]+7[[:space:]]+8[[:space:]]+\+1' "D3 delta is shown"
assert_matches "$PASS_OUT" 'D4 Measurement:[[:space:]]+8[[:space:]]+9[[:space:]]+\+1' "D4 delta is shown"
assert_matches "$PASS_OUT" 'D5 Self-Improve:[[:space:]]+8[[:space:]]+10[[:space:]]+\+2' "D5 delta is shown"
assert_matches "$PASS_OUT" 'COMPOSITE:[[:space:]]+40[[:space:]]+45[[:space:]]+\+5' "composite pass delta is shown"

run_expect_failure "regression" "$BEFORE" "$REGRESSION_AFTER"
REGRESSION_OUT="$LAST_OUT"
assert_contains "$REGRESSION_OUT" "VERDICT: REGRESSION (delta < 0)" "regression verdict is reported"

run_expect_failure "missing-before" "$MISSING" "$PASS_AFTER"
MISSING_ERR="$TEST_ROOT/missing-before.err"
assert_contains "$MISSING_ERR" "ERROR: $MISSING not found" "missing input path is reported"

echo ""
echo "  PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "  VERDICT: FAIL"
  exit 1
fi

echo "  VERDICT: PASS"
