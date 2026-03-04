#!/usr/bin/env bash
# scripts/score-operation.sh — Runtime evaluation of audit quality (C1: Runtime Eval)
#
# Evaluates the QUALITY of a completed audit operation — not whether it ran,
# but whether the output was complete, correct, and useful.
#
# This complements score-session.sh (which measures session PROCESS: hypothesis,
# gates, learnings) by measuring operational OUTPUT QUALITY (dimension coverage,
# detection signature hit rate, data completeness, consistency).
#
# Usage: bash scripts/score-operation.sh <audit_output_dir> [--json]
#
# Checks (8 total, 20 points max):
#   1. SCORECARD.json exists and valid (3pt)
#   2. All 5 dimensions scored (not null/0) (3pt)
#   3. AUDIT_REPORT.md exists and non-trivial (2pt)
#   4. All 5 tool outputs present (3pt)
#   5. Detection signature coverage (2pt)
#   6. No fallback/timeout indicators (2pt)
#   7. SCORECARD composite in valid range (2pt)
#   8. Phase classification present and non-empty (3pt)
#
# Exit codes:
#   0 — evaluation complete (score in stdout)
#   1 — missing inputs
#
# Source: Stage 11.1 T8 pattern audit (C1). Addresses fleet gap:
#   "Fleet repos have score-session.sh (22-point session grader) but this measures
#    session PROCESS, not operational OUTPUT QUALITY."

set -euo pipefail

AUDIT_DIR="${1:?Usage: score-operation.sh <audit_output_dir> [--json]}"
JSON_MODE="false"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for arg in "$@"; do
    if [ "$arg" = "--json" ]; then JSON_MODE="true"; fi
done

if [ ! -d "$AUDIT_DIR" ]; then
    echo "ERROR: Audit output directory not found: $AUDIT_DIR" >&2
    exit 1
fi

SCORE=0
MAX=20
ISSUES=""
EVIDENCE=""

add_score() {
    local pts="$1"
    local label="$2"
    SCORE=$((SCORE + pts))
    EVIDENCE="${EVIDENCE}  +${pts}pt: $label\n"
}

add_issue() {
    local label="$1"
    ISSUES="${ISSUES}  - $label\n"
}

# ── Check 1: SCORECARD.json exists and valid JSON (3pt) ──────────────
SCORECARD="$AUDIT_DIR/SCORECARD.json"
if [ -f "$SCORECARD" ]; then
    if python3 -c "import json; json.load(open('$SCORECARD'))" 2>/dev/null; then
        add_score 3 "SCORECARD.json exists and valid JSON"
    else
        add_score 1 "SCORECARD.json exists but invalid JSON"
        add_issue "SCORECARD.json is not valid JSON"
    fi
else
    add_issue "SCORECARD.json missing"
fi

# ── Check 2: All 5 dimensions scored (3pt) ───────────────────────────
if [ -f "$SCORECARD" ]; then
    DIMS_SCORED=$(python3 -c "
import json, sys
try:
    sc = json.load(open('$SCORECARD'))
    dims = sc.get('dimensions', {})
    scored = sum(1 for v in dims.values() if v is not None and v != 0)
    print(scored)
except:
    print(0)
" 2>/dev/null || echo "0")
    if [ "$DIMS_SCORED" -ge 5 ]; then
        add_score 3 "All 5 dimensions scored ($DIMS_SCORED/5)"
    elif [ "$DIMS_SCORED" -ge 3 ]; then
        add_score 1 "Partial dimensions scored ($DIMS_SCORED/5)"
        add_issue "Only $DIMS_SCORED/5 dimensions have non-zero scores"
    else
        add_issue "Too few dimensions scored ($DIMS_SCORED/5)"
    fi
fi

# ── Check 3: AUDIT_REPORT.md exists and non-trivial (2pt) ────────────
REPORT="$AUDIT_DIR/AUDIT_REPORT.md"
if [ -f "$REPORT" ]; then
    REPORT_LINES=$(wc -l < "$REPORT" | tr -d ' ')
    if [ "$REPORT_LINES" -ge 20 ]; then
        add_score 2 "AUDIT_REPORT.md exists ($REPORT_LINES lines)"
    else
        add_score 1 "AUDIT_REPORT.md exists but sparse ($REPORT_LINES lines)"
        add_issue "AUDIT_REPORT.md is sparse ($REPORT_LINES lines, expect >=20)"
    fi
else
    add_issue "AUDIT_REPORT.md missing"
fi

# ── Check 4: All 5 tool outputs present (3pt) ────────────────────────
TOOL_FILES="pre-scan/PRE_SCAN.md maturity.txt stall-risk.txt dna.txt drift.txt"
TOOLS_FOUND=0
TOOLS_MISSING=""
for f in $TOOL_FILES; do
    if [ -f "$AUDIT_DIR/$f" ]; then
        TOOLS_FOUND=$((TOOLS_FOUND + 1))
    else
        TOOLS_MISSING="$TOOLS_MISSING $f"
    fi
done
if [ "$TOOLS_FOUND" -eq 5 ]; then
    add_score 3 "All 5 tool outputs present"
elif [ "$TOOLS_FOUND" -ge 3 ]; then
    add_score 1 "Partial tool outputs ($TOOLS_FOUND/5)"
    add_issue "Missing tool outputs:$TOOLS_MISSING"
else
    add_issue "Most tool outputs missing ($TOOLS_FOUND/5):$TOOLS_MISSING"
fi

# ── Check 5: Detection signature coverage (2pt) ──────────────────────
# Count how many detect-*.sh scripts are available and how many produced results
DS_SCRIPTS=$(find "$SCRIPT_DIR" -maxdepth 1 -name 'detect-*.sh' -type f 2>/dev/null | wc -l | tr -d ' ')
DS_RESULTS=0
if [ -d "$AUDIT_DIR/pre-scan" ]; then
    DS_RESULTS=$(find "$AUDIT_DIR" -name 'ds-*.json' -o -name 'DS-*.json' -o -name 'detect-*.txt' 2>/dev/null | wc -l | tr -d ' ')
fi
# Also check AUDIT_REPORT for detection signatures or SCORECARD
if [ -f "$SCORECARD" ]; then
    DS_IN_SCORECARD=$(python3 -c "
import json
try:
    sc = json.load(open('$SCORECARD'))
    findings = sc.get('detection_findings', sc.get('findings', []))
    print(len(findings) if isinstance(findings, list) else 0)
except:
    print(0)
" 2>/dev/null || echo "0")
    DS_RESULTS=$((DS_RESULTS + DS_IN_SCORECARD))
fi
if [ "$DS_SCRIPTS" -gt 0 ] && [ "$DS_RESULTS" -gt 0 ]; then
    add_score 2 "Detection signatures ran ($DS_RESULTS results from $DS_SCRIPTS scripts)"
elif [ "$DS_SCRIPTS" -eq 0 ]; then
    add_score 1 "No detection signature scripts found (skip)"
else
    add_issue "Detection signatures available ($DS_SCRIPTS scripts) but 0 results produced"
fi

# ── Check 6: No fallback/timeout indicators (2pt) ────────────────────
FALLBACK_SIGNALS=0
if grep -qi 'timeout\|fallback\|timed out\|TIMEOUT' "$AUDIT_DIR"/*.txt "$AUDIT_DIR"/*.md 2>/dev/null; then
    FALLBACK_SIGNALS=$((FALLBACK_SIGNALS + 1))
fi
if grep -qi 'error.*tool\|tool.*failed\|FAIL.*tool' "$AUDIT_DIR"/*.md 2>/dev/null; then
    FALLBACK_SIGNALS=$((FALLBACK_SIGNALS + 1))
fi
if [ "$FALLBACK_SIGNALS" -eq 0 ]; then
    add_score 2 "No fallback or timeout indicators"
else
    add_score 1 "Fallback/timeout indicators detected ($FALLBACK_SIGNALS signals)"
    add_issue "Fallback or timeout detected in audit artifacts"
fi

# ── Check 7: SCORECARD composite in valid range 1-100 (2pt) ──────────
if [ -f "$SCORECARD" ]; then
    COMPOSITE=$(python3 -c "
import json
try:
    sc = json.load(open('$SCORECARD'))
    print(sc.get('composite', sc.get('composite_score', -1)))
except:
    print(-1)
" 2>/dev/null || echo "-1")
    if [ "$COMPOSITE" -ge 1 ] 2>/dev/null && [ "$COMPOSITE" -le 100 ] 2>/dev/null; then
        add_score 2 "Composite score valid ($COMPOSITE/100)"
    else
        add_issue "Composite score out of range: $COMPOSITE"
    fi
fi

# ── Check 8: Phase classification present (3pt) ──────────────────────
MATURITY="$AUDIT_DIR/maturity.txt"
if [ -f "$MATURITY" ]; then
    PHASE=$(grep -oiE '(Phase|PHASE)[: ]+[0-5]' "$MATURITY" 2>/dev/null | head -1 || echo "")
    if [ -n "$PHASE" ]; then
        add_score 3 "Phase classification present ($PHASE)"
    else
        add_score 1 "maturity.txt exists but no Phase classification found"
        add_issue "Phase classification missing from maturity.txt"
    fi
else
    add_issue "maturity.txt missing (no phase classification)"
fi

# ── Output ────────────────────────────────────────────────────────────
if [ "$JSON_MODE" = "true" ]; then
    # Output JSON for machine consumption
    ISSUES_JSON=$(printf '%b' "$ISSUES" | sed 's/^  - //' | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(lines))
" 2>/dev/null || echo '[]')
    VERDICT="PASS"
    if [ "$SCORE" -lt 14 ]; then VERDICT="FAIL"; fi
    if [ "$SCORE" -ge 14 ] && [ "$SCORE" -lt 18 ]; then VERDICT="WARN"; fi

    python3 -c "
import json, sys
result = {
    'score': $SCORE,
    'max': $MAX,
    'verdict': '$VERDICT',
    'audit_dir': '$AUDIT_DIR',
    'issues': $ISSUES_JSON,
    'timestamp': __import__('datetime').datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
}
json.dump(result, sys.stdout, indent=2)
print()
"
else
    echo "OPERATION EVAL: Audit Quality Assessment"
    echo "  Audit dir: $AUDIT_DIR"
    echo ""
    printf "%b" "$EVIDENCE"
    if [ -n "$ISSUES" ]; then
        echo ""
        echo "Issues detected (session grader would miss these):"
        printf "%b" "$ISSUES"
    fi
    echo ""
    VERDICT="PASS"
    if [ "$SCORE" -lt 14 ]; then VERDICT="FAIL"; fi
    if [ "$SCORE" -ge 14 ] && [ "$SCORE" -lt 18 ]; then VERDICT="WARN"; fi
    echo "OPERATION EVAL: $SCORE/$MAX ($VERDICT)"
    if [ "$VERDICT" = "FAIL" ]; then
        echo "  NOTE: Score below 14/$MAX threshold. Audit output quality is degraded."
    fi
fi

exit 0
