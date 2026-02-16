#!/bin/bash
# classify-repo-maturity.sh — Classify a repository's AI maturity phase (0-5)
#
# Usage: bash scripts/classify-repo-maturity.sh <repo_path>
#
# Implements the 5-phase AI maturity model from research/frameworks/MATURITY_MODEL.md

set -euo pipefail

REPO="${1:?Usage: classify-repo-maturity.sh <repo_path>}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: Directory not found: $REPO"
    exit 1
fi

cd "$REPO"

# Count AI surfaces (max depth 5 to avoid traversal slowness on large repos)
AGENTS=$(find . -maxdepth 5 -name "*.agent.md" -not -path './.git/*' -not -path '*/tests/*' -not -path '*/fixtures/*' -not -path '*/archive/*' -not -path '*/Archive/*' 2>/dev/null | wc -l | tr -d ' ')
SKILLS=$(find . -maxdepth 5 -name "SKILL.md" -not -path './.git/*' -not -path '*/tests/*' -not -path '*/fixtures/*' -not -path '*/benchmarks/*' 2>/dev/null | wc -l | tr -d ' ')

# Co-Evolution Ratio (P10-1): skills / max(agents, 1)
# Healthy repos have ratio ≥1.0 (skills keep pace with agents)
# Stalled repos have ratio <0.2 (agents without skills)
if [ "$AGENTS" -gt 0 ]; then
    COEVO_RATIO=$(awk "BEGIN {printf \"%.2f\", $SKILLS / $AGENTS}")
else
    COEVO_RATIO=$(awk "BEGIN {printf \"%.2f\", $SKILLS / 1}")
fi

# Broadened scoring detection (L51): check multiple naming patterns + CI + tests
SCORING_SCRIPTS=$(find . -maxdepth 4 -not -path './.git/*' -not -path '*/node_modules/*' \( -name "score-*.sh" -o -name "score*.py" -o -name "validate-*.sh" -o -name "validate_*.py" -o -name "test_*.py" -o -name "*_test.py" -o -name "test-*.sh" \) 2>/dev/null | wc -l | tr -d ' ')
CI_WORKFLOWS=0
if [ -d ".github/workflows" ]; then
    CI_WORKFLOWS=$(find .github/workflows -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | wc -l | tr -d ' ')
fi
MAKEFILE_TESTS=0
if [ -f "Makefile" ]; then
    MAKEFILE_TESTS=$(grep -cE '^(test|check|lint|validate|score|review):' Makefile 2>/dev/null)
    MAKEFILE_TESTS=${MAKEFILE_TESTS:-0}
fi
PYTEST_EXISTS=0
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    PYTEST_EXISTS=1
fi
SCORING=$((SCORING_SCRIPTS + CI_WORKFLOWS + MAKEFILE_TESTS + PYTEST_EXISTS))

PROMPTS=$(find . -maxdepth 5 -name "*.prompt.md" -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
INSTRUCTIONS=$(find . -maxdepth 5 -name "*.instructions.md" -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')

# DS-8: Imported-framework agents (L52) — bulk-imported generic agents not customized
IMPORTED_FRAMEWORK=0
if [ "$AGENTS" -gt 3 ] && [ "$SKILLS" -eq 0 ]; then
    # Check if agents were likely imported (all share a common prefix pattern)
    COMMON_PREFIX=$(find . -maxdepth 5 -name "*.agent.md" -not -path './.git/*' -not -path '*/tests/*' -not -path '*/fixtures/*' 2>/dev/null | xargs -I{} basename {} .agent.md | sort | head -10 | sed 's/[^a-z].*//g' | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
    [ "${COMMON_PREFIX:-0}" -gt 3 ] && IMPORTED_FRAMEWORK=1
fi

# Check governance docs
HAS_HYPOTHESES=0; [ -f "HYPOTHESES.md" ] && HAS_HYPOTHESES=1
HAS_LEARNINGS=0; [ -f "LEARNINGS.md" ] && HAS_LEARNINGS=1
HAS_AGENTS_MD=0; [ -f "AGENTS.md" ] && HAS_AGENTS_MD=1
HAS_CLAUDE_MD=0; [ -f "CLAUDE.md" ] && HAS_CLAUDE_MD=1
HAS_COPILOT=0; [ -f ".github/copilot-instructions.md" ] && HAS_COPILOT=1
HAS_CI=0; [ -d ".github/workflows" ] && HAS_CI=1

# Check cross-platform
HAS_GITHUB_SKILLS=0; [ -d ".github/skills" ] && HAS_GITHUB_SKILLS=1
HAS_CLAUDE_SKILLS=0; [ -d ".claude/skills" ] && HAS_CLAUDE_SKILLS=1
HAS_AGENTS_SKILLS=0; [ -d ".agents/skills" ] && HAS_AGENTS_SKILLS=1
DUAL_PLATFORM=0
[ "$HAS_GITHUB_SKILLS" -eq 1 ] && [ "$HAS_CLAUDE_SKILLS" -eq 1 ] && DUAL_PLATFORM=1

# Check intelligence/reference
HAS_INTELLIGENCE=0
for idir in reference intelligence references system/prompting system/reports docs/reference; do
    [ -d "$idir" ] && HAS_INTELLIGENCE=1 && break
done

# Check self-audit agents
SELF_AUDIT=0
AUDIT_AGENTS=$(find . -maxdepth 4 -name "*.agent.md" -not -path './.git/*' 2>/dev/null | head -50 | xargs grep -liE "audit|optimize|critic|diagnostic" 2>/dev/null | wc -l | tr -d ' ')
[ "$AUDIT_AGENTS" -gt 0 ] && SELF_AUDIT=1

# Total files (quick estimate, maxdepth 5)
TOTAL_FILES=$(find . -maxdepth 5 -type f -not -path './.git/*' -not -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' ')

# Classification
PHASE=0
PHASE_NAME="Pre-Agentic"
EVIDENCE=""

if [ "$AGENTS" -eq 0 ] && [ "$SKILLS" -eq 0 ] && [ "$HAS_COPILOT" -eq 0 ] && [ "$HAS_AGENTS_MD" -eq 0 ]; then
    PHASE=0; PHASE_NAME="Pre-Agentic"
    EVIDENCE="0 agents, 0 skills, 0 instruction surfaces"
elif [ "$SKILLS" -eq 0 ]; then
    if [ "$AGENTS" -le 1 ]; then
        PHASE=1; PHASE_NAME="Bootstrap"
        EVIDENCE="${AGENTS} agents, 0 skills"
    else
        PHASE=2; PHASE_NAME="Capability Build"
        EVIDENCE="${AGENTS} agents, 0 skills"
        [ "$AGENTS" -gt 5 ] && PHASE_NAME="Capability Build (STALLED)"
        [ "$IMPORTED_FRAMEWORK" -eq 1 ] && PHASE_NAME="Capability Build (STALLED — DS-8: imported framework)"
    fi
elif [ "$SKILLS" -ge 5 ] && [ "$SCORING" -ge 1 ]; then
    if [ "$HAS_INTELLIGENCE" -eq 1 ] && { [ "$SCORING" -ge 3 ] || [ "$HAS_CI" -eq 1 ]; }; then
        if [ "$SELF_AUDIT" -eq 1 ] || [ "$DUAL_PLATFORM" -eq 1 ]; then
            PHASE=5; PHASE_NAME="Self-Improving"
            EVIDENCE="${AGENTS}a, ${SKILLS}s, ${SCORING} scorers, self-audit=${SELF_AUDIT}, dual-platform=${DUAL_PLATFORM}"
        else
            PHASE=4; PHASE_NAME="Production"
            EVIDENCE="${AGENTS}a, ${SKILLS}s, ${SCORING} scorers, intelligence=${HAS_INTELLIGENCE}, CI=${HAS_CI}"
        fi
    else
        PHASE=3; PHASE_NAME="Systematization"
        EVIDENCE="${AGENTS}a, ${SKILLS}s, ${SCORING} scorers"
    fi
elif [ "$SKILLS" -ge 1 ]; then
    PHASE=2; PHASE_NAME="Capability Build"
    EVIDENCE="${AGENTS}a, ${SKILLS}s"
else
    PHASE=1; PHASE_NAME="Bootstrap"
    EVIDENCE="Instruction surfaces only"
fi

# Output
echo "================================================================"
echo "AI Maturity Classification"
echo "================================================================"
echo "Repo:        $(basename "$REPO")"
echo "Path:        $REPO"
echo "Files:       $TOTAL_FILES"
echo ""
echo "PHASE:       $PHASE — $PHASE_NAME"
echo "Evidence:    $EVIDENCE"
echo ""
echo "--- Surface Inventory ---"
echo "Agents:          $AGENTS"
echo "Skills:          $SKILLS"
echo "Scoring tools:   $SCORING (scripts=$SCORING_SCRIPTS, CI=$CI_WORKFLOWS, Makefile=$MAKEFILE_TESTS, pytest=$PYTEST_EXISTS)"
echo "Prompts:         $PROMPTS"
echo "Instructions:    $INSTRUCTIONS"
echo ""
echo "--- Governance ---"
echo "AGENTS.md:       $([ $HAS_AGENTS_MD -eq 1 ] && echo 'YES' || echo 'no')"
echo "CLAUDE.md:       $([ $HAS_CLAUDE_MD -eq 1 ] && echo 'YES' || echo 'no')"
echo "copilot-inst:    $([ $HAS_COPILOT -eq 1 ] && echo 'YES' || echo 'no')"
echo "HYPOTHESES.md:   $([ $HAS_HYPOTHESES -eq 1 ] && echo 'YES' || echo 'no')"
echo "LEARNINGS.md:    $([ $HAS_LEARNINGS -eq 1 ] && echo 'YES' || echo 'no')"
echo "CI pipeline:     $([ $HAS_CI -eq 1 ] && echo 'YES' || echo 'no')"
echo ""
echo "--- Maturity Signals ---"
echo "Intelligence:    $([ $HAS_INTELLIGENCE -eq 1 ] && echo 'YES' || echo 'no')"
echo "Dual platform:   $([ $DUAL_PLATFORM -eq 1 ] && echo 'YES' || echo 'no')"
echo "Self-audit:      $([ $SELF_AUDIT -eq 1 ] && echo 'YES' || echo 'no')"
echo "DS-8 imported:   $([ $IMPORTED_FRAMEWORK -eq 1 ] && echo 'YES (stall risk)' || echo 'no')"
echo "Co-Evo Ratio:    $COEVO_RATIO (skills/agents — healthy ≥1.0, stalled <0.2)"
echo "================================================================"
