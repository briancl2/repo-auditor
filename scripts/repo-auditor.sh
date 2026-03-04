#!/usr/bin/env bash
# repo-auditor.sh — Composite repo health audit (deterministic)
#
# Wraps 5 proven deterministic tools into a single audit run:
#   1. pre-scan-target.sh    → AI surface inventory
#   2. classify-repo-maturity.sh → Phase classification
#   3. stall-risk-score.sh   → 6-signal stall risk
#   4. extract-repo-dna.sh   → 10-feature DNA fingerprint
#   5. detect-capability-drift.sh → Tool tracking drift
#
# Then runs score-audit-dimensions.sh to produce a 5-dimension scorecard.
#
# Usage: bash scripts/repo-auditor.sh <repo_path> [output_dir] [--mode deep]
#
# Modes:
#   standard (default) — 5 bash tools + dimension scorer
#   deep               — standard + semantic cross-reference analysis (5 checks)
#
# Outputs:
#   <output_dir>/AUDIT_REPORT.md   — Human-readable composite report
#   <output_dir>/SCORECARD.json    — Machine-readable 5-dimension scores
#   <output_dir>/pre-scan/         — Pre-scan artifacts (PRE_SCAN.md, etc.)
#   <output_dir>/maturity.txt      — classify-repo-maturity.sh output
#   <output_dir>/stall-risk.txt    — stall-risk-score.sh output
#   <output_dir>/dna.txt           — extract-repo-dna.sh output
#   <output_dir>/drift.txt         — detect-capability-drift.sh output
#
# Guardrails:
#   - No associative arrays (macOS bash 3.2 compat, L10)
#   - No grep -c || echo 0 under pipefail (L11)
#   - All paths relative to script dir
#
# Exit codes:
#   0 — audit completed successfully
#   1 — missing argument or tool failure

set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────
AUDIT_MODE="standard"
POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
        --mode)
            # Next arg will set AUDIT_MODE via prev_arg check
            ;;
        deep|standard)
            if [ "${prev_arg:-}" = "--mode" ]; then
                AUDIT_MODE="$arg"
            else
                POSITIONAL+=("$arg")
            fi
            ;;
        *)
            POSITIONAL+=("$arg")
            ;;
    esac
    prev_arg="$arg"
done

REPO="${POSITIONAL[0]:?Usage: repo-auditor.sh <repo_path> [output_dir] [--mode deep]}"
OUTPUT_DIR="${POSITIONAL[1]:-audit_output}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# W6 fix: validate repo path exists
if [ ! -d "$REPO" ]; then
    echo "ERROR: $REPO not found or not a directory" >&2
    exit 1
fi

# ── C4: Pre-operation guard rails (Stage 11.2) ───────────────────────
# ── C4: Shared lockdir (H3 fix: single definition, passed to guard) ──
LOCKDIR="/tmp/repo-auditor-locks"

GUARD_SCRIPT="$SCRIPT_DIR/operation-guard.sh"
if [ -x "$GUARD_SCRIPT" ]; then
    if ! bash "$GUARD_SCRIPT" "$REPO" --lockdir "$LOCKDIR" 2>&1; then
        echo "ERROR: Operation guard FAILED. Aborting audit." >&2
        exit 1
    fi
fi

# ── C4: Acquire operation lock (PID matches this process) ────────────
LOCKFILE="$LOCKDIR/$(echo "$REPO" | tr '/' '_').lock"
mkdir -p "$LOCKDIR"
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Resolve repo name for display
REPO_NAME="$(basename "$REPO")"

# Create output structure
mkdir -p "$OUTPUT_DIR/pre-scan"

echo "================================================================"
echo "Repo Auditor: $REPO_NAME"
echo "================================================================"
echo ""
echo "Target:  $REPO"
echo "Output:  $OUTPUT_DIR"
echo "Mode:    $AUDIT_MODE"
echo ""

# Track failures (no associative arrays per L10)
FAILURES=""
FAIL_COUNT=0

PRESCAN_SCRIPT="$SCRIPT_DIR/../.agents/skills/pre-scanning/scripts/pre-scan-target.sh"
if [ ! -x "$PRESCAN_SCRIPT" ]; then
    echo "ERROR: pre-scan script not found or not executable: $PRESCAN_SCRIPT" >&2
    exit 1
fi

run_tool() {
    local name="$1"
    local outfile="$2"
    shift 2
    echo "  [$name] running..."
    if "$@" > "$outfile" 2>&1; then
        echo "  [$name] ✅ done ($(wc -l < "$outfile" | tr -d ' ') lines)"
    else
        local exit_code=$?
        echo "  [$name] ⚠️  exit $exit_code (output saved)"
        # drift detector exits 1 on high drift — that's data, not failure
        if [ "$name" = "drift" ]; then
            echo "  [$name] (non-zero exit expected when drift > threshold)"
        else
            FAILURES="$FAILURES $name"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
}

echo "--- Running 5 audit tools ---"
echo ""

# 1. Pre-scan (writes to directory, not stdout)
echo "  [pre-scan] running..."
if bash "$PRESCAN_SCRIPT" "$REPO" "$OUTPUT_DIR/pre-scan" > "$OUTPUT_DIR/pre-scan-log.txt" 2>&1; then
    if [ -f "$OUTPUT_DIR/pre-scan/PRE_SCAN.md" ]; then
        PRESCAN_LINES=$(wc -l < "$OUTPUT_DIR/pre-scan/PRE_SCAN.md" | tr -d ' ')
    else
        PRESCAN_LINES="unknown"
    fi
    echo "  [pre-scan] ✅ done ($PRESCAN_LINES lines)"
else
    rc=$?
    echo "  [pre-scan] ⚠️  exit $rc"
    FAILURES="$FAILURES pre-scan"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 2-5. Tools that write to stdout
run_tool "maturity" "$OUTPUT_DIR/maturity.txt" bash "$SCRIPT_DIR/classify-repo-maturity.sh" "$REPO"
run_tool "stall-risk" "$OUTPUT_DIR/stall-risk.txt" bash "$SCRIPT_DIR/stall-risk-score.sh" "$REPO"
run_tool "dna" "$OUTPUT_DIR/dna.txt" bash "$SCRIPT_DIR/extract-repo-dna.sh" "$REPO"
run_tool "drift" "$OUTPUT_DIR/drift.txt" bash "$SCRIPT_DIR/detect-capability-drift.sh" "$REPO"

echo ""

# --- Score dimensions ---
echo "--- Scoring 5 audit dimensions ---"
echo ""
if bash "$SCRIPT_DIR/score-audit-dimensions.sh" "$OUTPUT_DIR" 2>"$OUTPUT_DIR/scorer-errors.txt"; then
    # Validate JSON
    if python3 -c "import json; json.load(open('$OUTPUT_DIR/SCORECARD.json'))" 2>/dev/null; then
        echo "  [scorecard] ✅ SCORECARD.json written (valid JSON)"
    else
        echo "  [scorecard] ⚠️  SCORECARD.json written but INVALID JSON"
        FAILURES="$FAILURES scorecard-json"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo "  [scorecard] ⚠️  scorer failed"
    FAILURES="$FAILURES scorecard"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Generate composite report ---
echo ""
echo "--- Generating AUDIT_REPORT.md ---"
echo ""

# Extract key metrics for the report
PHASE="unknown"
STALL_SCORE="?"
MATURITY_SCORE="?"
TRAJECTORY="?"
DRIFT_PCT="?"
CO_EVO="?"
TOTAL_FILES="?"
AI_SURFACES="?"

# Parse maturity output
if [ -f "$OUTPUT_DIR/maturity.txt" ]; then
    PHASE=$(grep "^PHASE:" "$OUTPUT_DIR/maturity.txt" | head -1 | sed 's/PHASE: *//' | sed 's/ *$//')
fi

# Parse stall-risk output
if [ -f "$OUTPUT_DIR/stall-risk.txt" ]; then
    STALL_SCORE=$(grep "SCORE:" "$OUTPUT_DIR/stall-risk.txt" | head -1 | sed 's/.*SCORE: *//' | sed 's/ .*//')
fi

# Parse DNA output
if [ -f "$OUTPUT_DIR/dna.txt" ]; then
    MATURITY_SCORE=$(grep "Maturity Score:" "$OUTPUT_DIR/dna.txt" | head -1 | sed 's/.*Maturity Score: *//' | sed 's/ *$//')
    TRAJECTORY=$(grep "Trajectory:" "$OUTPUT_DIR/dna.txt" | head -1 | sed 's/.*Trajectory: *//' | sed 's/ *$//')
    CO_EVO=$(grep "Co-Evolution Ratio:" "$OUTPUT_DIR/dna.txt" | head -1 | sed 's/.*Co-Evolution Ratio: *//' | sed 's/ *$//')
fi

# Parse drift output
if [ -f "$OUTPUT_DIR/drift.txt" ]; then
    DRIFT_PCT=$(grep "Undocumented:" "$OUTPUT_DIR/drift.txt" | head -1 | sed 's/.*(//' | sed 's/).*//')
fi

# Parse pre-scan log
if [ -f "$OUTPUT_DIR/pre-scan-log.txt" ]; then
    TOTAL_FILES=$(grep "^Total files:" "$OUTPUT_DIR/pre-scan-log.txt" | head -1 | sed 's/.*: *//' | sed 's/ *$//' || true)
    AI_SURFACES=$(grep "^AI surfaces:" "$OUTPUT_DIR/pre-scan-log.txt" | head -1 | sed 's/.*: *//' | sed 's/ *$//' || true)
fi

# Read scorecard if it exists
SCORECARD_SUMMARY=""
if [ -f "$OUTPUT_DIR/SCORECARD.json" ]; then
    SCORECARD_SUMMARY=$(cat "$OUTPUT_DIR/SCORECARD.json")
fi

cat > "$OUTPUT_DIR/AUDIT_REPORT.md" << EOF
# Audit Report: $REPO_NAME

> Generated by repo-auditor.sh (deterministic)
> Date: $(date +%Y-%m-%d)
> Target: $REPO

## Summary

| Metric | Value |
|---|---|
| Phase | $PHASE |
| Maturity Score | $MATURITY_SCORE |
| Stall Risk | $STALL_SCORE/100 |
| Trajectory | $TRAJECTORY |
| Co-Evolution Ratio | $CO_EVO |
| Drift | $DRIFT_PCT |
| Total Files | $TOTAL_FILES |
| AI Surfaces | $AI_SURFACES |

## Dimension Scorecard

\`\`\`json
$SCORECARD_SUMMARY
\`\`\`

## Tool Outputs

| Tool | Output File | Status |
|---|---|---|
| pre-scan-target.sh | pre-scan/ | $([ -f "$OUTPUT_DIR/pre-scan/PRE_SCAN.md" ] && echo "✅" || echo "❌") |
| classify-repo-maturity.sh | maturity.txt | $([ -s "$OUTPUT_DIR/maturity.txt" ] && echo "✅" || echo "❌") |
| stall-risk-score.sh | stall-risk.txt | $([ -s "$OUTPUT_DIR/stall-risk.txt" ] && echo "✅" || echo "❌") |
| extract-repo-dna.sh | dna.txt | $([ -s "$OUTPUT_DIR/dna.txt" ] && echo "✅" || echo "❌") |
| detect-capability-drift.sh | drift.txt | $([ -s "$OUTPUT_DIR/drift.txt" ] && echo "✅" || echo "❌") |

## Failures

$(if [ "$FAIL_COUNT" -eq 0 ]; then echo "None."; else echo "**$FAIL_COUNT tool(s) failed:** $FAILURES"; fi)
EOF

echo "  ✅ AUDIT_REPORT.md written"
echo ""
echo "================================================================"
echo "Audit Complete: $REPO_NAME"
echo "================================================================"
echo "  Phase:          $PHASE"
echo "  Maturity:       $MATURITY_SCORE"
echo "  Stall Risk:     $STALL_SCORE/100"
echo "  Drift:          $DRIFT_PCT"
echo "  Co-Evo Ratio:   $CO_EVO"
echo "  Tool failures:  $FAIL_COUNT"
echo ""
echo "Outputs:"
echo "  $OUTPUT_DIR/AUDIT_REPORT.md"
echo "  $OUTPUT_DIR/SCORECARD.json"
echo "================================================================"

# ── Deep mode: Semantic cross-reference analysis (Stage 11.3) ────────
if [ "$AUDIT_MODE" = "deep" ]; then
    DEEP_SCRIPT="$SCRIPT_DIR/deep-audit.py"
    if [ -f "$DEEP_SCRIPT" ]; then
        echo ""
        echo "--- Running Deep Semantic Analysis ---"
        echo ""
        if python3 "$DEEP_SCRIPT" "$REPO" --output-dir "$OUTPUT_DIR" 2>&1; then
            echo "  [deep-audit] Semantic analysis complete"
            # Append deep findings summary to AUDIT_REPORT.md
            if [ -f "$OUTPUT_DIR/DEEP_FINDINGS.json" ]; then
                DEEP_COUNT=$(python3 -c "import json; d=json.load(open('$OUTPUT_DIR/DEEP_FINDINGS.json')); print(d['total_findings'])" 2>/dev/null || echo "0")
                DEEP_HIGH=$(python3 -c "import json; d=json.load(open('$OUTPUT_DIR/DEEP_FINDINGS.json')); print(d['findings_by_severity']['HIGH'])" 2>/dev/null || echo "0")
                cat >> "$OUTPUT_DIR/AUDIT_REPORT.md" << DEEPEOF

## Deep Semantic Analysis

| Metric | Value |
|---|---|
| Mode | deep |
| Total findings | $DEEP_COUNT |
| HIGH severity | $DEEP_HIGH |

See DEEP_FINDINGS.json for full details.
DEEPEOF
            fi
        else
            echo "  [deep-audit] WARNING: Semantic analysis failed (non-fatal)"
        fi
    else
        echo "  [deep-audit] WARNING: deep-audit.py not found at $DEEP_SCRIPT"
    fi
fi

# ── C1: Runtime evaluation of audit quality (Stage 11.2) ─────────────
EVAL_SCRIPT="$SCRIPT_DIR/score-operation.sh"
if [ -x "$EVAL_SCRIPT" ]; then
    echo ""
    bash "$EVAL_SCRIPT" "$OUTPUT_DIR" || true
    # Also produce JSON artifact alongside audit outputs
    bash "$EVAL_SCRIPT" "$OUTPUT_DIR" --json > "$OUTPUT_DIR/OPERATION_EVAL.json" 2>/dev/null || true
fi

# Lockfile cleanup handled by trap EXIT (set at lock acquisition)

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
