#!/bin/bash
# stall-risk-score.sh — Compute 6-signal stall risk score (0-100) from git history
#
# Predicts repo stall 30-60 days early. Calibrated against:
#   T10 (stalled):  98/100
#   T8  (healthy):   3/100
#   T7  (healthy):   7/100
#
# Usage: bash scripts/stall-risk-score.sh <repo_path>
#
# Output: human-readable stall risk report to stdout
#
# Signals:
#   S1: Refactor Ratio (0-25)       — refactor commits / total commits, 30-day window
#   S2: Code Add/Delete Ratio (0-20) — lines added / deleted, 30 days
#   S3: Skill Velocity (0-20)       — skills created / months active
#   S4: Commit Frequency Decay (0-15) — week-over-week trend slope
#   S5: Plan Infrastructure (0-10)  — plan-gen skill, PR tracking, quantified outcomes
#   S6: AI Surface Diversity (0-10) — count unique surface types

set -euo pipefail

REPO="${1:?Usage: stall-risk-score.sh <repo_path>}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: Directory not found: $REPO"
    exit 1
fi

cd "$REPO"

# Verify git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: Not a git repository: $REPO"
    exit 1
fi

REPO_NAME=$(basename "$(pwd)")

has_any_output() {
    awk 'NF { found = 1 } END { exit(found ? 0 : 1) }'
}

# ============================================================
# S1: Refactor Ratio (0-25)
# ============================================================
TOTAL_30D=$(git log --oneline --since="30 days ago" 2>/dev/null | wc -l | tr -d ' ')
REFACTOR_30D=0
if [ "$TOTAL_30D" -gt 0 ]; then
    REFACTOR_30D=$(git log --oneline --since="30 days ago" 2>/dev/null | grep -ciE 'refactor|restructur|cleanup|reorganiz|simplif|tidy|consolid|remove.*dead|dead.*code|eliminate') || REFACTOR_30D=0
fi

if [ "$TOTAL_30D" -gt 0 ]; then
    S1_RATIO=$(awk "BEGIN {printf \"%.2f\", $REFACTOR_30D / $TOTAL_30D}")
    S1_SCORE=$(awk "BEGIN {v = $S1_RATIO * 40; if (v > 25) v = 25; printf \"%d\", v}")
else
    S1_RATIO="0.00"
    S1_SCORE=0
fi

# ============================================================
# S2: Code Add/Delete Ratio (0-20)
# ============================================================
# S2 uses git diff --stat between HEAD and 30-day-ago commit (fast, no log traversal)
COMMIT_30D_AGO=$(git log --since="30 days ago" --format=%H 2>/dev/null | tail -1)
if [ -n "$COMMIT_30D_AGO" ]; then
    DIFF_STAT=$(git diff --shortstat --no-renames "$COMMIT_30D_AGO" HEAD 2>/dev/null || echo "0 0 0")
    ADDS_30D=$(echo "$DIFF_STAT" | awk '{for(i=1;i<=NF;i++){if($i~/insertion/)print $(i-1)}}')
    DELS_30D=$(echo "$DIFF_STAT" | awk '{for(i=1;i<=NF;i++){if($i~/deletion/)print $(i-1)}}')
    [ -z "$ADDS_30D" ] && ADDS_30D=0
    [ -z "$DELS_30D" ] && DELS_30D=0
else
    ADDS_30D=0
    DELS_30D=0
fi

if [ "$DELS_30D" -gt 0 ]; then
    ADR=$(awk "BEGIN {printf \"%.2f\", $ADDS_30D / $DELS_30D}")
else
    ADR="99.00"  # no deletions = pure growth
fi

ADR_NUM=$(echo "$ADR" | awk '{print $1+0}')
if awk "BEGIN {exit !($ADR_NUM >= 5.0)}"; then
    S2_SCORE=0
elif awk "BEGIN {exit !($ADR_NUM >= 3.0)}"; then
    S2_SCORE=5
elif awk "BEGIN {exit !($ADR_NUM >= 2.0)}"; then
    S2_SCORE=10
elif awk "BEGIN {exit !($ADR_NUM >= 1.5)}"; then
    S2_SCORE=15
else
    S2_SCORE=20
fi

# ============================================================
# S3: Skill Velocity (0-20)
# ============================================================
FIRST_COMMIT=$(git log --reverse --format=%ct -n 1 2>/dev/null | head -1)
LAST_COMMIT=$(git log --format=%ct -n 1 2>/dev/null | head -1)

if [ -n "$FIRST_COMMIT" ] && [ -n "$LAST_COMMIT" ] && [ "$FIRST_COMMIT" != "$LAST_COMMIT" ]; then
    MONTHS_ACTIVE=$(awk "BEGIN {v = ($LAST_COMMIT - $FIRST_COMMIT) / (30*86400); if (v < 1) v = 1; printf \"%.1f\", v}")
else
    MONTHS_ACTIVE="1.0"
fi

SKILL_COUNT=$(find . -maxdepth 5 -name "SKILL.md" -not -path "./.git/*" -not -path "*/tests/*" -not -path "*/fixtures/*" 2>/dev/null | wc -l | tr -d ' ')
SKILL_RATE=$(awk "BEGIN {printf \"%.2f\", $SKILL_COUNT / $MONTHS_ACTIVE}")

SKILL_RATE_NUM=$(echo "$SKILL_RATE" | awk '{print $1+0}')
if awk "BEGIN {exit !($SKILL_RATE_NUM >= 5.0)}"; then
    S3_SCORE=0
elif awk "BEGIN {exit !($SKILL_RATE_NUM >= 1.0)}"; then
    S3_SCORE=5
elif awk "BEGIN {exit !($SKILL_RATE_NUM >= 0.1)}"; then
    S3_SCORE=10
elif awk "BEGIN {exit !($SKILL_RATE_NUM > 0)}"; then
    S3_SCORE=15
else
    S3_SCORE=20
fi

# Adjustment: if < 2 months, halve score (too early to judge)
MONTHS_NUM=$(echo "$MONTHS_ACTIVE" | awk '{print $1+0}')
if awk "BEGIN {exit !($MONTHS_NUM < 2)}"; then
    S3_SCORE=$((S3_SCORE / 2))
fi

# ============================================================
# S4: Commit Frequency Decay (0-15)
# ============================================================
W4=$(git log --oneline --since="28 days ago" --until="21 days ago" 2>/dev/null | wc -l | tr -d ' ')
W3=$(git log --oneline --since="21 days ago" --until="14 days ago" 2>/dev/null | wc -l | tr -d ' ')
W2=$(git log --oneline --since="14 days ago" --until="7 days ago" 2>/dev/null | wc -l | tr -d ' ')
W1=$(git log --oneline --since="7 days ago" 2>/dev/null | wc -l | tr -d ' ')

# Simple linear slope: (W1 - W4) / 3
if [ "$W4" -gt 0 ] || [ "$W1" -gt 0 ]; then
    SLOPE=$(awk "BEGIN {printf \"%.1f\", ($W1 - $W4) / 3}")
else
    SLOPE="0.0"
fi

SLOPE_NUM=$(echo "$SLOPE" | awk '{print $1+0}')
if awk "BEGIN {exit !($SLOPE_NUM >= 0)}"; then
    S4_SCORE=0
elif awk "BEGIN {exit !($SLOPE_NUM >= -5)}"; then
    S4_SCORE=5
elif awk "BEGIN {exit !($SLOPE_NUM >= -15)}"; then
    S4_SCORE=10
else
    S4_SCORE=15
fi

# ============================================================
# S5: Plan Infrastructure Index (0-10)
# ============================================================
PLAN_INFRA=0

# Has plan-generation skill?
if find . -maxdepth 5 -path "*/plan*" -name "SKILL.md" -not -path "./.git/*" 2>/dev/null | has_any_output; then
    PLAN_INFRA=$((PLAN_INFRA + 3))
fi

# Plans have PR/commit tracking?
PLAN_FILES=$(find . -maxdepth 4 -not -path "./.git/*" \( -iname "*plan*" -o -iname "*roadmap*" \) -name "*.md" -type f 2>/dev/null | awk 'NR <= 20 { print }')
if [ -n "$PLAN_FILES" ]; then
    SHA_PLANS=0
    while IFS= read -r pf; do
        [ -z "$pf" ] && continue
        grep -qE '[a-f0-9]{7,40}' "$pf" 2>/dev/null && SHA_PLANS=$((SHA_PLANS + 1))
    done <<< "$PLAN_FILES"
    if [ "$SHA_PLANS" -gt 0 ]; then
        PLAN_INFRA=$((PLAN_INFRA + 3))
    fi
fi

# Plans have quantified outcomes?
if [ -n "$PLAN_FILES" ]; then
    QUANT_PLANS=0
    while IFS= read -r pf; do
        [ -z "$pf" ] && continue
        grep -qiE 'before.*after|delta|metric|measur|quantif' "$pf" 2>/dev/null && QUANT_PLANS=$((QUANT_PLANS + 1))
    done <<< "$PLAN_FILES"
    if [ "$QUANT_PLANS" -gt 0 ]; then
        PLAN_INFRA=$((PLAN_INFRA + 2))
    fi
fi

# Plans in single directory?
if [ -n "$PLAN_FILES" ]; then
    PLAN_DIRS=$(echo "$PLAN_FILES" | xargs -I{} dirname {} | sort -u | wc -l | tr -d ' ')
    if [ "$PLAN_DIRS" -le 2 ]; then
        PLAN_INFRA=$((PLAN_INFRA + 2))
    fi
fi

S5_SCORE=$((10 - PLAN_INFRA))
[ "$S5_SCORE" -lt 0 ] && S5_SCORE=0

# ============================================================
# S6: AI Surface Diversity (0-10)
# ============================================================
SURFACE_TYPES=0

# Has agents?
AGENT_COUNT=$(find . -maxdepth 5 -name "*.agent.md" -not -path "./.git/*" -not -path "*/tests/*" -not -path "*/fixtures/*" 2>/dev/null | wc -l | tr -d ' ')
[ "$AGENT_COUNT" -gt 0 ] && SURFACE_TYPES=$((SURFACE_TYPES + 1))

# Has skills?
[ "$SKILL_COUNT" -gt 0 ] && SURFACE_TYPES=$((SURFACE_TYPES + 1))

# Has scoring?
SCORING_COUNT=$(find . -maxdepth 4 -not -path "./.git/*" \( -name "score-*.sh" -o -name "validate-*.sh" -o -name "test-*.sh" -o -name "test_*.py" -o -name "*_test.py" \) 2>/dev/null | wc -l | tr -d ' ')
[ "$SCORING_COUNT" -gt 0 ] && SURFACE_TYPES=$((SURFACE_TYPES + 1))

# Has governance?
HAS_GOV=0
for doc in HYPOTHESES.md LEARNINGS.md AGENTS.md CLAUDE.md; do
    [ -f "$doc" ] && HAS_GOV=1 && break
done
[ "$HAS_GOV" -eq 1 ] && SURFACE_TYPES=$((SURFACE_TYPES + 1))

# Has CI for AI?
if [ -d ".github/workflows" ]; then
    CI_AI=0
    while IFS= read -r wf; do
        [ -z "$wf" ] && continue
        grep -qiE 'agent|skill|score|audit|lint' "$wf" 2>/dev/null && CI_AI=$((CI_AI + 1))
    done < <(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null)
    [ "$CI_AI" -gt 0 ] && SURFACE_TYPES=$((SURFACE_TYPES + 1))
fi

S6_DIFF=$((5 - SURFACE_TYPES))
[ "$S6_DIFF" -lt 0 ] && S6_DIFF=0
S6_SCORE=$((S6_DIFF * 2))

# ============================================================
# Composite Score
# ============================================================
TOTAL_SCORE=$((S1_SCORE + S2_SCORE + S3_SCORE + S4_SCORE + S5_SCORE + S6_SCORE))

# Risk level
if [ "$TOTAL_SCORE" -le 20 ]; then
    RISK_LEVEL="LOW"
    RISK_EMOJI="🟢"
elif [ "$TOTAL_SCORE" -le 40 ]; then
    RISK_LEVEL="WATCH"
    RISK_EMOJI="🟡"
elif [ "$TOTAL_SCORE" -le 60 ]; then
    RISK_LEVEL="WARNING"
    RISK_EMOJI="🟠"
elif [ "$TOTAL_SCORE" -le 80 ]; then
    RISK_LEVEL="HIGH"
    RISK_EMOJI="🔴"
else
    RISK_LEVEL="CRITICAL"
    RISK_EMOJI="🚨"
fi

# ============================================================
# Output
# ============================================================
echo "================================================================"
echo "Stall Risk Score: $REPO_NAME"
echo "================================================================"
echo ""
echo "  SCORE: $TOTAL_SCORE / 100   $RISK_EMOJI $RISK_LEVEL"
echo ""
echo "--- Signal Breakdown ---"
echo ""
printf "  S1 Refactor Ratio:       %2d/25  (ratio=%-5s, %d/%d commits)\n" "$S1_SCORE" "$S1_RATIO" "$REFACTOR_30D" "$TOTAL_30D"
printf "  S2 Add/Delete Ratio:     %2d/20  (adr=%-5s, +%d/-%d lines)\n" "$S2_SCORE" "$ADR" "$ADDS_30D" "$DELS_30D"
printf "  S3 Skill Velocity:       %2d/20  (rate=%-5s skills/mo, %d skills, %.1f months)\n" "$S3_SCORE" "$SKILL_RATE" "$SKILL_COUNT" "$MONTHS_NUM"
printf "  S4 Commit Freq Decay:    %2d/15  (slope=%-5s, weeks: %d→%d→%d→%d)\n" "$S4_SCORE" "$SLOPE" "$W4" "$W3" "$W2" "$W1"
printf "  S5 Plan Infrastructure:  %2d/10  (infra=%d/10)\n" "$S5_SCORE" "$PLAN_INFRA"
printf "  S6 Surface Diversity:    %2d/10  (types=%d/5)\n" "$S6_SCORE" "$SURFACE_TYPES"
echo ""
echo "--- Thresholds ---"
echo "  0-20  🟢 Low       21-40 🟡 Watch"
echo "  41-60 🟠 Warning   61-80 🔴 High"
echo "  81-100 🚨 Critical"
echo "================================================================"
