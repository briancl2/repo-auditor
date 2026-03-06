#!/usr/bin/env bash
# scripts/work-close.sh — Work contract finalizer for repo-auditor
#
# Captures post-audit SCORECARD, computes integer delta vs baseline,
# writes DELTA.md. REFUSES (exit 1) without learnings extraction.
# Adapted from build-meta-analysis work-close.sh, stripped of outer-loop specifics.
# Deterministic. macOS bash 3.2 compatible.
#
# Usage:
#   work-close.sh <work-dir>
#   work-close.sh <work-dir> --no-novel-findings "rationale"
#
# Requires: pre-audit baseline from work-init.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK_DIR="${1:?Usage: work-close.sh <work-dir> [--no-novel-findings \"rationale\"]}"
shift

# ── Parse flags ──────────────────────────────────────────────────────
NO_NOVEL_FINDINGS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --no-novel-findings) NO_NOVEL_FINDINGS="${2:?--no-novel-findings requires a rationale}"; shift 2 ;;
        *) shift ;;
    esac
done

# ── Resolve work dir ─────────────────────────────────────────────────
if [[ ! "$WORK_DIR" = /* ]]; then
    WORK_DIR="$REPO_ROOT/$WORK_DIR"
fi

# ── Validate work directory ──────────────────────────────────────────
if [ ! -d "$WORK_DIR" ]; then
    echo "ERROR: Work directory not found: $WORK_DIR" >&2
    exit 1
fi

if [ ! -f "$WORK_DIR/WORK.md" ]; then
    echo "ERROR: No WORK.md found in $WORK_DIR" >&2
    echo "  Run 'make work DESC=\"...\"' to initialize a work contract first." >&2
    exit 1
fi

# ── Validate hypothesis is not a placeholder ─────────────────────────
if grep -qF '{what you expect' "$WORK_DIR/WORK.md"; then
    echo "ERROR: Gate 3 — WORK.md still contains hypothesis placeholder text." >&2
    echo "  Fill in the Hypothesis section before closing the work contract." >&2
    exit 1
fi

echo "=== Work Close: $WORK_DIR ==="

# ── Gate 3a: Pre-audit must exist ────────────────────────────────────
if [ ! -f "$WORK_DIR/pre-audit/SCORECARD.json" ]; then
    echo "ERROR: No pre-audit baseline found at $WORK_DIR/pre-audit/SCORECARD.json" >&2
    echo "  The work contract was not properly initialized." >&2
    exit 1
fi

# ── Gate 3b: Learning extraction required ────────────────────────────
LEARNINGS_ADDED=0
if [ -f LEARNINGS.md ] && [ -f "$WORK_DIR/.learnings_baseline_count" ]; then
    BASELINE_COUNT=$(cat "$WORK_DIR/.learnings_baseline_count")
    CURRENT_COUNT=$(grep -cE '^\| L[0-9]+' LEARNINGS.md 2>/dev/null || echo "0")
    LEARNINGS_ADDED=$((CURRENT_COUNT - BASELINE_COUNT))
fi

if [ "$LEARNINGS_ADDED" -le 0 ] && [ -z "$NO_NOVEL_FINDINGS" ]; then
    echo "" >&2
    echo "ERROR: Gate 3 — Learning extraction required before closing work contract." >&2
    echo "  LEARNINGS.md has $LEARNINGS_ADDED new L-number entries (need ≥1)." >&2
    echo "  Either:" >&2
    echo "    (a) Append at least one L-number to LEARNINGS.md, or" >&2
    echo "    (b) Re-run with: bash scripts/work-close.sh \"$WORK_DIR\" --no-novel-findings \"rationale\"" >&2
    echo "" >&2
    exit 1
fi

# ── Gate 3c: Post-audit ──────────────────────────────────────────────
echo "  Running post-audit..."
mkdir -p "$WORK_DIR/post-audit"
if bash scripts/repo-auditor.sh . "$WORK_DIR/post-audit" > /dev/null 2>&1; then
    echo "  Post-audit complete."
else
    echo "  WARNING: Post-audit failed. DELTA will be unavailable."
fi

# ── Compute delta ────────────────────────────────────────────────────
PRE_SCORE="?"
POST_SCORE="?"
DELTA="?"
if [ -f "$WORK_DIR/pre-audit/SCORECARD.json" ] && [ -f "$WORK_DIR/post-audit/SCORECARD.json" ]; then
    if [ -f scripts/compare-scorecards.sh ]; then
        bash scripts/compare-scorecards.sh "$WORK_DIR/pre-audit/SCORECARD.json" "$WORK_DIR/post-audit/SCORECARD.json" > "$WORK_DIR/compare-output.txt" 2>&1 || true
    fi
    PRE_SCORE=$(python3 -c "import json; print(json.load(open('$WORK_DIR/pre-audit/SCORECARD.json')).get('composite','?'))" 2>/dev/null || echo "?")
    POST_SCORE=$(python3 -c "import json; print(json.load(open('$WORK_DIR/post-audit/SCORECARD.json')).get('composite','?'))" 2>/dev/null || echo "?")
    if [ "$PRE_SCORE" != "?" ] && [ "$POST_SCORE" != "?" ]; then
        DELTA=$((POST_SCORE - PRE_SCORE))
    fi
fi

# ── Write DELTA.md ───────────────────────────────────────────────────
cat > "$WORK_DIR/DELTA.md" <<EOF
# Delta Report

| Metric | Pre | Post | Delta |
|--------|-----|------|-------|
| Composite | $PRE_SCORE | $POST_SCORE | $DELTA |

## Learnings Added: $LEARNINGS_ADDED

$(if [ -n "$NO_NOVEL_FINDINGS" ]; then echo "**No-novel-findings:** $NO_NOVEL_FINDINGS"; fi)

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "  DELTA.md written."

# ── Session grader (soft dependency) ─────────────────────────────────
SESSION_ID=$(basename "$WORK_DIR")
if [ -f scripts/score-session.sh ]; then
    echo "  Running session grader..."
    if bash scripts/score-session.sh "$WORK_DIR" "$SESSION_ID" 2>&1; then
        echo "  Session grader complete."
    else
        echo "  WARNING: Session grader failed (non-blocking)."
    fi
else
    echo "  WARNING: scripts/score-session.sh not found (skipping session grader)."
fi

# ── Operations ledger (13.1.5: T1 mechanical) ─────────────────────────
# Append JSONL event to work/OPERATIONS_LEDGER.jsonl for fleet-level observability.
# Schema: compatible with BMA score-ledger-event.schema.json.
OPS_LEDGER="$REPO_ROOT/work/OPERATIONS_LEDGER.jsonl"
_ops_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
_ops_rid=$(echo "ops-$(basename "$WORK_DIR")-$PRE_SCORE-$POST_SCORE" | shasum -a 256 | head -c 16)
_ops_ver=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
# Quote scores as strings to handle "?" fallback values safely
_ops_event="{\"event_type\":\"work-close\",\"run_id\":\"$_ops_rid\",\"timestamp\":\"$_ops_ts\",\"target_id\":\"$(basename "$REPO_ROOT")\",\"source\":{\"script\":\"work-close.sh\",\"version\":\"$_ops_ver\"},\"data\":{\"composite_pre\":\"$PRE_SCORE\",\"composite_post\":\"$POST_SCORE\",\"delta\":\"$DELTA\",\"learnings_added\":$LEARNINGS_ADDED,\"work_dir\":\"$(basename "$WORK_DIR")\"}}"
if echo "$_ops_event" | python3 -c "import json,sys; json.loads(sys.stdin.read())" 2>/dev/null; then
    echo "$_ops_event" >> "$OPS_LEDGER"
    echo "  Ops ledger: recorded (delta=$DELTA, learnings=$LEARNINGS_ADDED)"
else
    echo "  WARNING: Ops ledger event failed JSON validation (skipped)."
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "=== Work Close Summary ==="
echo "  Work Dir:    $WORK_DIR"
echo "  Pre-Score:   $PRE_SCORE"
echo "  Post-Score:  $POST_SCORE"
echo "  Delta:       $DELTA"
echo "  Learnings:   $LEARNINGS_ADDED new"
if [ -n "$NO_NOVEL_FINDINGS" ]; then
    echo "  NNF:         $NO_NOVEL_FINDINGS"
fi
echo "  Artifacts:   DELTA.md$([ -f "$WORK_DIR/OPERATING_MODEL_SCORECARD.json" ] && echo ', OPERATING_MODEL_SCORECARD.json')"
echo "=== Done ==="
