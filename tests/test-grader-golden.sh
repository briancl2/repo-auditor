#!/usr/bin/env bash
# tests/test-grader-golden.sh — Golden fixture test for session grader
#
# Validates that score-session.sh produces correct, predictable output
# on a known fixture. This addresses C3 critique: "no correctness test."
#
# Expected scores for golden fixture:
#   hypothesis_discipline: 3/3 (WORK.md fully filled)
#   gate_integrity: 3/4 (trailer check depends on git state, not fixture)
#   measurement_completeness: 3/4 (SCORECARD won't exist on first run)
#   learning_extraction: 0/3 (no new learnings in fixture)
#   Total: 9/15 (PARTIAL)
#
# The test validates:
#   1. Grader produces valid JSON output
#   2. All 4 dimensions present with correct max values
#   3. hypothesis_discipline = 3/3 (fully deterministic from fixture)
#   4. Composite is numeric and verdict is valid
#   5. On re-grade (second run), measurement_completeness gains 1pt (10/15)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE_SRC="$REPO_ROOT/tests/fixtures/golden-work-dir"
TEST_TMPDIR=$(mktemp -d)
FIXTURE="$TEST_TMPDIR/golden-work-dir"
OUTPUT="$FIXTURE/OPERATING_MODEL_SCORECARD.json"

cleanup() { rm -rf "$TEST_TMPDIR"; }
trap cleanup EXIT

echo "=== Golden Fixture Grader Test ==="

cp -R "$FIXTURE_SRC" "$FIXTURE"

# Clean any prior output
rm -f "$OUTPUT"

# Run 1: First grade
echo "  Run 1: First grade..."
bash "$REPO_ROOT/scripts/score-session.sh" "$FIXTURE" "golden-test" > /dev/null 2>&1

FAIL=0

# Check 1: Output exists
if [ ! -f "$OUTPUT" ]; then
    echo "  FAIL: OPERATING_MODEL_SCORECARD.json not produced"
    exit 1
fi
echo "  PASS: Output file exists"

# Check 2: Valid JSON with expected structure
if ! python3 -c "
import json, sys
d = json.load(open('$OUTPUT'))
assert 'dimensions' in d, 'missing dimensions'
assert 'composite' in d, 'missing composite'
assert 'verdict' in d, 'missing verdict'
dims = d['dimensions']
assert 'hypothesis_discipline' in dims, 'missing hypothesis_discipline'
assert 'gate_integrity' in dims, 'missing gate_integrity'
assert 'measurement_completeness' in dims, 'missing measurement_completeness'
assert 'learning_extraction' in dims, 'missing learning_extraction'
assert dims['hypothesis_discipline']['max'] == 3, f'hd max wrong: {dims[\"hypothesis_discipline\"][\"max\"]}'
assert dims['gate_integrity']['max'] == 4, f'gi max wrong: {dims[\"gate_integrity\"][\"max\"]}'
assert dims['measurement_completeness']['max'] == 4, f'mc max wrong: {dims[\"measurement_completeness\"][\"max\"]}'
assert dims['learning_extraction']['max'] == 3, f'le max wrong: {dims[\"learning_extraction\"][\"max\"]}'
print('  PASS: Valid JSON with correct structure and max values')
" 2>&1; then
    echo "  FAIL: JSON structure invalid"
    FAIL=1
fi

# Check 3: hypothesis_discipline = 3/3 (deterministic from fixture)
HD_SCORE=$(python3 -c "import json; print(json.load(open('$OUTPUT'))['dimensions']['hypothesis_discipline']['score'])")
if [ "$HD_SCORE" != "3" ]; then
    echo "  FAIL: hypothesis_discipline expected 3, got $HD_SCORE"
    FAIL=1
else
    echo "  PASS: hypothesis_discipline = 3/3"
fi

# Check 4: Composite is numeric, verdict is valid
python3 -c "
import json
d = json.load(open('$OUTPUT'))
score = d['composite']['score']
assert isinstance(score, int), f'composite score not int: {type(score)}'
assert 0 <= score <= 15, f'composite out of range: {score}'
assert d['verdict'] in ('PASS', 'PARTIAL', 'FAIL'), f'invalid verdict: {d[\"verdict\"]}'
print(f'  PASS: Composite {score}/15, verdict {d[\"verdict\"]}')
"

# Run 2: Re-grade (SCORECARD now exists, measurement_completeness should gain 1pt)
echo "  Run 2: Re-grade..."
RUN1_MC=$(python3 -c "import json; print(json.load(open('$OUTPUT'))['dimensions']['measurement_completeness']['score'])")
bash "$REPO_ROOT/scripts/score-session.sh" "$FIXTURE" "golden-regrade" > /dev/null 2>&1
RUN2_MC=$(python3 -c "import json; print(json.load(open('$OUTPUT'))['dimensions']['measurement_completeness']['score'])")

if [ "$RUN2_MC" -gt "$RUN1_MC" ]; then
    echo "  PASS: Re-grade measurement_completeness improved ($RUN1_MC -> $RUN2_MC)"
else
    echo "  FAIL: Re-grade should improve measurement_completeness ($RUN1_MC -> $RUN2_MC)"
    FAIL=1
fi

# Summary
echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "  VERDICT: PASS (5/5 golden fixture checks)"
else
    echo "  VERDICT: FAIL"
    exit 1
fi
