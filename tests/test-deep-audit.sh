#!/usr/bin/env bash
# tests/test-deep-audit.sh — Validate deep-audit.py against known-defect fixture
#
# Acceptance criterion (Stage 11.3): deep audit on BMA produces >=3 findings
# that current bash audit misses, validated against known-defect fixture.
#
# Usage: bash tests/test-deep-audit.sh <bma_repo_path>
#
# Exit codes:
#   0 — PASS (>=3 known defects detected)
#   1 — FAIL (fewer than 3 detected, or runtime error)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_BMA_PATH=""
if [ -d "$REPO_ROOT/../build-meta-analysis" ]; then
    DEFAULT_BMA_PATH="$(cd "$REPO_ROOT/../build-meta-analysis" && pwd)"
fi
BMA_PATH="${1:-$DEFAULT_BMA_PATH}"
if [ -z "$BMA_PATH" ]; then
    echo "Usage: test-deep-audit.sh <bma_repo_path>" >&2
    exit 1
fi

DEEP_AUDIT="$REPO_ROOT/scripts/deep-audit.py"
FIXTURE="$REPO_ROOT/tests/fixtures/bma-known-defects.json"
OUTPUT_DIR=$(mktemp -d)
MINIMUM_HITS=3

trap 'rm -rf "$OUTPUT_DIR"' EXIT

echo "=== Deep Audit Validation Test ==="
echo "  Target: $BMA_PATH"
echo "  Fixture: $FIXTURE"
echo "  Min hits: $MINIMUM_HITS"
echo ""

# Guard: verify inputs exist
if [ ! -f "$DEEP_AUDIT" ]; then
    echo "FAIL: deep-audit.py not found at $DEEP_AUDIT"
    exit 1
fi
if [ ! -f "$FIXTURE" ]; then
    echo "FAIL: Fixture not found at $FIXTURE"
    exit 1
fi
if [ ! -d "$BMA_PATH" ]; then
    echo "FAIL: BMA repo not found at $BMA_PATH"
    exit 1
fi

# Run deep audit
echo "--- Running deep-audit.py ---"
if ! python3 "$DEEP_AUDIT" "$BMA_PATH" --output-dir "$OUTPUT_DIR" --json > "$OUTPUT_DIR/stdout.json" 2>&1; then
    echo "FAIL: deep-audit.py exited non-zero"
    cat "$OUTPUT_DIR/stdout.json" 2>/dev/null || true
    exit 1
fi

FINDINGS_FILE="$OUTPUT_DIR/DEEP_FINDINGS.json"
if [ ! -f "$FINDINGS_FILE" ]; then
    echo "FAIL: DEEP_FINDINGS.json not produced"
    exit 1
fi

# Validate against fixture
echo ""
echo "--- Validating against known-defect fixture ---"
echo ""

HITS=0
TOTAL_DEFECTS=0

# Use Python to cross-reference findings against fixture
RESULT=$(python3 -c "
import json, sys

findings = json.load(open('$FINDINGS_FILE'))
fixture = json.load(open('$FIXTURE'))

defects = fixture['known_defects']
found_findings = findings['findings']

hits = 0
total = len(defects)
results = []

for defect in defects:
    did = defect['id']
    check = defect['check']
    matched = False
    
    for f in found_findings:
        if f['check'] != check:
            continue
        # Match by check type + key terms in finding description
        desc_lower = f['finding'].lower()
        defect_desc_lower = defect['description'].lower()
        
        # Extract key identifiers from defect description
        key_terms = []
        if 'file' in defect:
            for part in defect['file'].split(','):
                part = part.strip()
                # Extract filename/dirname
                key = part.rsplit('/', 1)[-1] if '/' in part else part
                key_terms.append(key.lower())
        
        # Check if any key term appears in the finding
        for term in key_terms:
            if term in desc_lower or term in f.get('file', '').lower():
                matched = True
                break
        
        if matched:
            break
    
    status = 'HIT' if matched else 'MISS'
    results.append(f'  {did}: {status} -- {defect[\"description\"][:70]}')
    if matched:
        hits += 1

for r in results:
    print(r)
print(f'---')
print(f'HITS={hits}')
print(f'TOTAL={total}')
" 2>&1)

echo "$RESULT"
echo ""

HITS=$(echo "$RESULT" | grep "^HITS=" | cut -d= -f2)
TOTAL_DEFECTS=$(echo "$RESULT" | grep "^TOTAL=" | cut -d= -f2)

# Also report total findings count
TOTAL_FINDINGS=$(python3 -c "import json; print(json.load(open('$FINDINGS_FILE'))['total_findings'])" 2>/dev/null || echo "?")

echo "--- Summary ---"
echo "  Known defects matched: $HITS / $TOTAL_DEFECTS"
echo "  Total deep findings:   $TOTAL_FINDINGS"
echo "  Minimum required:      $MINIMUM_HITS"
echo ""

if [ "$HITS" -ge "$MINIMUM_HITS" ]; then
    echo "PASS: Deep audit detected $HITS/$TOTAL_DEFECTS known defects (>= $MINIMUM_HITS required)"
    exit 0
else
    echo "FAIL: Deep audit detected only $HITS/$TOTAL_DEFECTS known defects (need >= $MINIMUM_HITS)"
    exit 1
fi
