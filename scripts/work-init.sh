#!/usr/bin/env bash
# scripts/work-init.sh — Work contract initializer for repo-auditor
#
# Creates a work directory with WORK.md template and captures baseline SCORECARD.
# Adapted from build-meta-analysis work-init.sh, stripped of outer-loop specifics.
# Deterministic. macOS bash 3.2 compatible.
#
# Usage: work-init.sh "description"
# Creates: work/YYYYMMDDTHHMMSSZ/WORK.md + work/YYYYMMDDTHHMMSSZ/pre-audit/SCORECARD.json

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DESC="${1:?Usage: work-init.sh \"description\"}"

# ── Create work directory ─────────────────────────────────────────────
TIMESTAMP=$(date -u '+%Y%m%dT%H%M%SZ')
WORK_DIR="work/${TIMESTAMP}"
mkdir -p "$WORK_DIR"

# ── Write WORK.md template ───────────────────────────────────────────
cat > "$WORK_DIR/WORK.md" <<'TEMPLATE'
# Work Contract

## Description

DESC_PLACEHOLDER

## Hypothesis

> **Gate 1 Required.** State a testable prediction with PASS/FAIL criteria.

**Prediction:** {what you expect to happen}
**PASS:** {measurable success condition}
**FAIL:** {measurable failure condition}

## Work Type

{code-change | fleet-run | research | bug-fix}

## Status

- [ ] Hypothesis stated
- [ ] Work completed
- [ ] Learnings extracted (or --no-novel-findings)
- [ ] work-close run

TEMPLATE

# Replace placeholder with actual description
sed -i '' "s|DESC_PLACEHOLDER|${DESC}|" "$WORK_DIR/WORK.md"

# ── Snapshot LEARNINGS.md baseline (for content-aware Gate 3) ─────────
if [ -f LEARNINGS.md ]; then
    grep -cE '^\| L[0-9]+' LEARNINGS.md > "$WORK_DIR/.learnings_baseline_count" 2>/dev/null || echo "0" > "$WORK_DIR/.learnings_baseline_count"
else
    echo "0" > "$WORK_DIR/.learnings_baseline_count"
fi

# ── Baseline audit ────────────────────────────────────────────────────
echo "=== Work Init: $WORK_DIR ==="
echo "  Description: $DESC"
mkdir -p "$WORK_DIR/pre-audit"

if [ -f scripts/repo-auditor.sh ]; then
    if bash scripts/repo-auditor.sh . "$WORK_DIR/pre-audit" > /dev/null 2>&1; then
        SCORE=$(python3 -c "import json; print(json.load(open('$WORK_DIR/pre-audit/SCORECARD.json')).get('composite','?'))" 2>/dev/null || echo "?")
        echo "  Baseline: $SCORE/100"
    else
        echo "  WARNING: Audit failed — baseline not captured"
    fi
else
    echo "  WARNING: repo-auditor.sh not found — baseline not captured"
fi

echo "  WORK.md: $WORK_DIR/WORK.md"
echo ""
echo "Next steps:"
echo "  1. Fill in Hypothesis in $WORK_DIR/WORK.md"
echo "  2. Do the work"
echo "  3. make work-close WORK=$WORK_DIR"
