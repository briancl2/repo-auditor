#!/bin/bash
# extract-repo-dna.sh — Extract 10-feature Repo DNA fingerprint
#
# Produces a maturity fingerprint from git history + filesystem (0 LLM tokens).
# Features: S (surfaces), K (skill density), Ao (agent organicity), Sc (scoring),
#           Kv (skill velocity), G (governance), Pi (plan infra), Cp (cross-platform),
#           Ad (self-audit depth), Ab (abstraction depth)
#
# Usage: bash scripts/extract-repo-dna.sh <repo_path>

set -euo pipefail

REPO="${1:?Usage: extract-repo-dna.sh <repo_path>}"
[ ! -d "$REPO" ] && echo "ERROR: Not found: $REPO" && exit 1
cd "$REPO"

REPO_NAME=$(basename "$(pwd)")

# .auditorignore support — exclude archival directories from file counts
FIND_EXCLUDES="-not -path './.git/*' -not -name '.DS_Store'"
if [ -f ".auditorignore" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | sed 's/#.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$line" ] && continue
        dir=$(echo "$line" | sed 's|/$||')
        FIND_EXCLUDES="$FIND_EXCLUDES -not -path './${dir}/*'"
    done < ".auditorignore"
fi

TOTAL_FILES=$(eval "find . -type f $FIND_EXCLUDES" 2>/dev/null | wc -l | tr -d ' ')

# ============================================================
# S: Surface Count (0-20)
# ============================================================
S=0
[ -f "AGENTS.md" ] && S=$((S + 1))
[ -f "CLAUDE.md" ] && S=$((S + 1))
[ -f ".github/copilot-instructions.md" ] && S=$((S + 1))
EXTRA_INST=$(eval "find . -maxdepth 5 -name '*.instructions.md' $FIND_EXCLUDES" 2>/dev/null | wc -l | tr -d ' ')
S=$((S + EXTRA_INST))
[ "$S" -gt 20 ] && S=20

# ============================================================
# K: Skill Density (0-100)
# ============================================================
SKILL_COUNT=$(eval "find . -maxdepth 5 -name 'SKILL.md' $FIND_EXCLUDES -not -path '*/tests/*' -not -path '*/fixtures/*'" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL_FILES" -gt 0 ]; then
    K=$(awk "BEGIN {v = $SKILL_COUNT / $TOTAL_FILES * 1000; if (v > 100) v = 100; printf \"%d\", v}")
else
    K=0
fi

# ============================================================
# Ao: Agent Organicity (0.0-1.0)
# ============================================================
AGENT_FILES=$(eval "find . -maxdepth 5 -name '*.agent.md' $FIND_EXCLUDES -not -path '*/tests/*' -not -path '*/fixtures/*' -not -path '*/archive/*'" 2>/dev/null || true)
AGENT_COUNT=0
[ -n "$AGENT_FILES" ] && AGENT_COUNT=$(echo "$AGENT_FILES" | wc -l | tr -d ' ')

GENERIC_COUNT=0
if [ "$AGENT_COUNT" -gt 0 ]; then
    GENERIC_COUNT=$(echo "$AGENT_FILES" | xargs -I{} basename {} .agent.md | grep -ciE '^speckit\.|^template\.|^default\.|^example\.|^sample\.' 2>/dev/null) || GENERIC_COUNT=0
fi

if [ "$AGENT_COUNT" -gt 0 ]; then
    ORGANIC=$((AGENT_COUNT - GENERIC_COUNT))
    Ao=$(awk "BEGIN {printf \"%.1f\", $ORGANIC / $AGENT_COUNT}")
else
    Ao="0.0"
fi

# ============================================================
# Sc: Scoring Layer Count (0-10)
# ============================================================
Sc=0
# Structural scorers (file existence checks)
find . -maxdepth 4 -not -path './.git/*' \( -name "preflight*.sh" -o -name "check-*.sh" \) 2>/dev/null | grep -q . && Sc=$((Sc + 1))
# Heuristic scorers (content grep)
find . -maxdepth 4 -not -path './.git/*' \( -name "score-*.sh" -o -name "score*.py" \) 2>/dev/null | grep -q . && Sc=$((Sc + 1))
# Validation scripts
find . -maxdepth 4 -not -path './.git/*' \( -name "validate-*.sh" -o -name "validate_*.py" \) 2>/dev/null | grep -q . && Sc=$((Sc + 1))
# Test suites
find . -maxdepth 4 -not -path './.git/*' \( -name "test_*.py" -o -name "*_test.py" -o -name "test-*.sh" \) 2>/dev/null | grep -q . && Sc=$((Sc + 1))
# CI workflows
[ -d ".github/workflows" ] && find .github/workflows -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | grep -q . && Sc=$((Sc + 1))
# Makefile test targets
[ -f "Makefile" ] && grep -qE '^(test|check|lint|validate|score|review):' Makefile 2>/dev/null && Sc=$((Sc + 1))
# pytest/jest config
{ [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "jest.config.js" ]; } && Sc=$((Sc + 1))
# Panel/LLM judges
find . -maxdepth 4 -not -path './.git/*' \( -name "*panel*" -o -name "*judge*" -o -name "*llm-judge*" \) 2>/dev/null | grep -q . && Sc=$((Sc + 1))
[ "$Sc" -gt 10 ] && Sc=10

# ============================================================
# Kv: Skill Velocity (0.0-1.0)
# ============================================================
if [ "$SKILL_COUNT" -gt 0 ] && git rev-parse --git-dir >/dev/null 2>&1; then
    RECENT_SKILLS=$(git log --since="30 days ago" --diff-filter=A --name-only 2>/dev/null | grep -c "SKILL.md") || RECENT_SKILLS=0
    Kv=$(awk "BEGIN {v = $RECENT_SKILLS / $SKILL_COUNT; if (v > 1) v = 1; printf \"%.1f\", v}")
else
    Kv="0.0"
fi

# ============================================================
# G: Governance Coverage (0-5)
# ============================================================
G=0
[ -f "AGENTS.md" ] && G=$((G + 1))
[ -f "LEARNINGS.md" ] && G=$((G + 1))
[ -f "HYPOTHESES.md" ] && G=$((G + 1))
[ -d ".github/workflows" ] && G=$((G + 1))
# Operating protocol check (numbered workflow in AGENTS.md)
[ -f "AGENTS.md" ] && grep -qE '^[0-9]+\.' AGENTS.md 2>/dev/null && G=$((G + 1))

# ============================================================
# Pi: Plan Infrastructure (0-4)
# ============================================================
Pi=0
PLAN_FILES=$(find . -maxdepth 4 -not -path './.git/*' \( -iname "*plan*" -o -iname "*roadmap*" \) -name "*.md" -type f 2>/dev/null | head -20)
[ -n "$PLAN_FILES" ] && Pi=1  # ad-hoc plans exist

# Template-based plans?
find . -maxdepth 5 -path "*template*" -iname "*plan*" -not -path './.git/*' 2>/dev/null | grep -q . && Pi=2

# Skill-generated plans?
find . -maxdepth 5 -path "*plan*" -name "SKILL.md" -not -path './.git/*' 2>/dev/null | grep -q . && Pi=3

# PR-tracked + quantified outcomes?
if [ -n "$PLAN_FILES" ]; then
    HAS_PR=0
    while IFS= read -r pf; do
        [ -z "$pf" ] && continue
        grep -qE '[a-f0-9]{7,40}' "$pf" 2>/dev/null && HAS_PR=1 && break
    done <<< "$PLAN_FILES"
    HAS_QUANT=0
    while IFS= read -r pf; do
        [ -z "$pf" ] && continue
        grep -qiE 'before.*after|delta|metric|quantif' "$pf" 2>/dev/null && HAS_QUANT=1 && break
    done <<< "$PLAN_FILES"
    [ "$HAS_PR" -eq 1 ] && [ "$HAS_QUANT" -eq 1 ] && Pi=4
fi

# ============================================================
# Cp: Cross-Platform Span (1-4)
# ============================================================
Cp=0
[ -d ".github/agents" ] || [ -d ".github/skills" ] && Cp=$((Cp + 1))
[ -d ".claude" ] || [ -d ".claude/skills" ] && Cp=$((Cp + 1))
[ -d ".codex" ] && Cp=$((Cp + 1))
[ -d ".agents" ] || [ -d ".agents/skills" ] && Cp=$((Cp + 1))
[ "$Cp" -eq 0 ] && Cp=1  # minimum 1 (local)

# ============================================================
# Ad: Self-Audit Depth (0-6)
# ============================================================
Ad=0
# Stage 1: Manual checks (evidence of any audit-related files)
find . -maxdepth 4 -iname "*audit*" -not -path './.git/*' 2>/dev/null | grep -q . && Ad=1
# Stage 2: Scripted validation
find . -maxdepth 4 -not -path './.git/*' \( -name "validate-*.sh" -o -name "check-*.sh" -o -name "preflight*.sh" \) 2>/dev/null | grep -q . && Ad=2
# Stage 3: Agent-driven audit
AUDIT_AGENTS=0
while IFS= read -r af; do
    [ -z "$af" ] && continue
    grep -qiE "audit" "$af" 2>/dev/null && AUDIT_AGENTS=1 && break
done < <(find . -maxdepth 5 -name "*.agent.md" -not -path './.git/*' 2>/dev/null | head -30)
[ "$AUDIT_AGENTS" -eq 1 ] && Ad=3
# Stage 4: Multi-model comparison
find . -maxdepth 5 -iname "*comparison*" -o -iname "*multi-model*" -o -iname "*cross-model*" 2>/dev/null | grep -q . && Ad=4
# Stage 5: Self-evaluating (runtime logs + meta-reviews)
find . -maxdepth 5 -iname "*runtime*log*" -o -iname "*self-audit*" -o -iname "*meta-review*" 2>/dev/null | grep -q . && Ad=5
# Stage 6: Self-scheduling (CI-triggered audits)
if [ -d ".github/workflows" ]; then
    CI_AUDIT=0
    while IFS= read -r wf; do
        [ -z "$wf" ] && continue
        grep -qiE 'schedule.*audit|audit.*cron|cron.*audit' "$wf" 2>/dev/null && CI_AUDIT=1 && break
    done < <(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null)
    [ "$CI_AUDIT" -eq 1 ] && Ad=6
fi

# ============================================================
# Ab: Abstraction Depth (0-4)
# ============================================================
Ab=0
[ "$AGENT_COUNT" -gt 0 ] && Ab=1                          # agents exist
[ "$SKILL_COUNT" -gt 0 ] && [ "$AGENT_COUNT" -gt 0 ] && Ab=2  # agents use skills
# Skills generate plans?
find . -maxdepth 5 -path "*plan*" -name "SKILL.md" -not -path './.git/*' 2>/dev/null | grep -q . && Ab=3
# Optimizers use audit findings?
OPTIM_AGENTS=0
while IFS= read -r af; do
    [ -z "$af" ] && continue
    grep -qiE "optim" "$af" 2>/dev/null && OPTIM_AGENTS=1 && break
done < <(find . -maxdepth 5 -name "*.agent.md" -not -path './.git/*' 2>/dev/null | head -30)
[ "$OPTIM_AGENTS" -eq 1 ] && [ "$Ad" -ge 3 ] && Ab=4

# ============================================================
# Derived Metrics
# ============================================================
K_GT_0=0; [ "$K" -gt 0 ] && K_GT_0=1
SC_GT_0=0; [ "$Sc" -gt 0 ] && SC_GT_0=1
KV_GT_0=0; [ "$Kv" != "0.0" ] && KV_GT_0=1
AD_GT_0=0; [ "$Ad" -gt 0 ] && AD_GT_0=1

MATURITY=$((S + K_GT_0 * 10 + Sc * 5 + G * 3 + Ad * 4 + Ab * 5))
[ "$MATURITY" -gt 100 ] && MATURITY=100

# Use awk for trajectory to preserve fractional Kv
Kv_num=$(echo "$Kv" | awk '{print $1+0}')
TRAJ=$(awk "BEGIN {v = $Kv_num * 50 + $SC_GT_0 * $KV_GT_0 * 20 + $AD_GT_0 * 10; printf \"%d\", v}")

# Co-Evolution Ratio (bonus metric)
if [ "$AGENT_COUNT" -gt 0 ]; then
    COEVO=$(awk "BEGIN {printf \"%.2f\", $SKILL_COUNT / $AGENT_COUNT}")
else
    COEVO=$(awk "BEGIN {printf \"%.2f\", $SKILL_COUNT / 1}")
fi

# ============================================================
# Output
# ============================================================
echo "================================================================"
echo "Repo DNA Fingerprint: $REPO_NAME"
echo "================================================================"
echo ""
echo "  DNA = [$S, $K, $Ao, $Sc, $Kv, $G, $Pi, $Cp, $Ad, $Ab]"
echo ""
echo "--- Features ---"
printf "  S  Surface Count:       %2d    (instruction files)\n" "$S"
printf "  K  Skill Density:       %2d    (%d skills / %d files × 1000)\n" "$K" "$SKILL_COUNT" "$TOTAL_FILES"
printf "  Ao Agent Organicity:    %s   (organic / total agents)\n" "$Ao"
printf "  Sc Scoring Layers:      %2d    (distinct scoring mechanisms)\n" "$Sc"
printf "  Kv Skill Velocity:      %s   (recent / total skills)\n" "$Kv"
printf "  G  Governance:          %2d/5  (AGENTS.md, LEARNINGS, HYPOTHESES, CI, protocol)\n" "$G"
printf "  Pi Plan Infrastructure: %2d/4  (0=none, 1=adhoc, 2=template, 3=skill-gen, 4=PR+quantified)\n" "$Pi"
printf "  Cp Cross-Platform:      %2d    (platform directories)\n" "$Cp"
printf "  Ad Self-Audit Depth:    %2d/6  (0=none → 6=CI-scheduled)\n" "$Ad"
printf "  Ab Abstraction Depth:   %2d/4  (0=flat → 4=optimizer-uses-audit)\n" "$Ab"
echo ""
echo "--- Derived Metrics ---"
printf "  Maturity Score:     %3d/100\n" "$MATURITY"
printf "  Trajectory:         %3d     (>40 growing, 10-40 stable, <10 stalled)\n" "$TRAJ"
printf "  Co-Evolution Ratio: %s\n" "$COEVO"
echo ""
echo "--- Counts ---"
printf "  Agents: %d  Skills: %d  Files: %d\n" "$AGENT_COUNT" "$SKILL_COUNT" "$TOTAL_FILES"
echo "================================================================"
