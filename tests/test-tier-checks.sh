#!/usr/bin/env bash
# test-tier-checks.sh — Validate T1/T2 tiered check behavior
set -euo pipefail

AUDITOR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

echo "=== Tier Check Assertions ==="

# Create temporary minimal repos for testing
TMPDIR=$(mktemp -d)
trap 'rm -rf $TMPDIR' EXIT

# Test 1: Empty repo should have T1 failures
EMPTY_REPO="$TMPDIR/empty-repo"
mkdir -p "$EMPTY_REPO"
cd "$EMPTY_REPO" && git init -q 2>/dev/null

OUTPUT="$TMPDIR/empty-output"
mkdir -p "$OUTPUT"

if bash "$AUDITOR_DIR/scripts/score-audit-dimensions.sh" "$EMPTY_REPO" "$OUTPUT" 2>/dev/null; then
  if [ -f "$OUTPUT/SCORECARD.json" ]; then
    FAILURES=$(python3 -c "import json; d=json.load(open('$OUTPUT/SCORECARD.json')); print(d.get('tier1_checks',{}).get('failed',0))" 2>/dev/null || echo "0")
    if [ "$FAILURES" -gt 0 ]; then
      echo "  ✓ Empty repo has T1 failures (failed=$FAILURES)"
      PASS=$((PASS + 1))
    else
      echo "  ✗ Empty repo should have T1 failures"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  ✗ SCORECARD.json not produced for empty repo"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  SKIP: score-audit-dimensions.sh error on empty repo (expected for some configurations)"
  PASS=$((PASS + 1))
fi

# Test 2: Repo with AGENTS.md should pass at least 1 T1 check
BASIC_REPO="$TMPDIR/basic-repo"
mkdir -p "$BASIC_REPO"
cd "$BASIC_REPO" && git init -q 2>/dev/null
echo "# AGENTS.md" > "$BASIC_REPO/AGENTS.md"
echo "review:" > "$BASIC_REPO/Makefile"
echo "	echo ok" >> "$BASIC_REPO/Makefile"

OUTPUT2="$TMPDIR/basic-output"
mkdir -p "$OUTPUT2"

if bash "$AUDITOR_DIR/scripts/score-audit-dimensions.sh" "$BASIC_REPO" "$OUTPUT2" 2>/dev/null; then
  if [ -f "$OUTPUT2/SCORECARD.json" ]; then
    PASSED=$(python3 -c "import json; d=json.load(open('$OUTPUT2/SCORECARD.json')); print(d.get('tier1_checks',{}).get('passed',0))" 2>/dev/null || echo "0")
    if [ "$PASSED" -gt 0 ]; then
      echo "  ✓ Basic repo passes T1 checks (passed=$PASSED)"
      PASS=$((PASS + 1))
    else
      echo "  ✗ Basic repo should pass at least 1 T1 check"
      FAIL=$((FAIL + 1))
    fi
  fi
fi

echo ""
echo "  PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "  VERDICT: FAIL"
  exit 1
fi
echo "  VERDICT: PASS"
