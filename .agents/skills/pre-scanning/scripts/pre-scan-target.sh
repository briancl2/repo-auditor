#!/bin/bash
# pre-scan-target.sh — Deterministic pre-scan of target repo (no LLM tokens)
#
# Produces PRE_SCAN.md + AI_SURFACES_FULL.md with complete AI surface inventory.
# This replaces ~30% of LLM tool calls (find, ls, wc) with pre-computed data.
#
# Usage: bash scripts/pre-scan-target.sh <target_path> <output_dir>
#
# Outputs:
#   <output_dir>/PRE_SCAN.md           — Repo structure, file counts, directory tree
#   <output_dir>/AI_SURFACES_FULL.md   — Full text of ALL AI surface files (agents, skills, instructions)
#   <output_dir>/LARGE_FILES.md        — Files >200 lines with line counts
#   <output_dir>/GITIGNORE_ANALYSIS.md — .gitignore contents + blocked paths

# Note: pipefail disabled — head in pipeline causes SIGPIPE on large repos (10K+ files)
set -uo pipefail

TARGET="${1:?Usage: pre-scan-target.sh <target_path> <output_dir>}"
OUTPUT_DIR="${2:?Usage: pre-scan-target.sh <target_path> <output_dir>}"

if [ ! -d "$TARGET" ]; then
    echo "ERROR: Target directory not found: $TARGET"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

TARGET_ABS=$(cd "$TARGET" && pwd)
REPO_NAME=$(basename "$TARGET_ABS")

# ============================================================
# .auditorignore support — prune archival directories from traversal
# Format: one directory per line (trailing / optional), # comments, blank lines
# Uses array-safe construction to avoid eval fragility (v158b critique fix).
# Pruning matters here: filtering excluded paths out of results still walks the
# entire tree, which can dominate self-audit runs when tracked work history is
# large.
# ============================================================
FIND_PRUNE_MATCHES=(
    -path "$TARGET_ABS/.git" -o
    -path '*/.venv' -o
    -path '*/venv' -o
    -path '*/node_modules' -o
    -path '*/.tox' -o
    -path '*/.mypy_cache' -o
    -path '*/__pycache__' -o
    -path '*/vendor' -o
    -path '*/.eggs'
)
AUDITORIGNORE_ACTIVE="no"
if [ -f "$TARGET_ABS/.auditorignore" ]; then
    AUDITORIGNORE_ACTIVE="yes"
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and blank lines
        line=$(echo "$line" | sed 's/#.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$line" ] && continue
        # Strip trailing slash for consistency
        dir=$(echo "$line" | sed 's|/$||')
        FIND_PRUNE_MATCHES+=(-o -path "$TARGET_ABS/$dir")
    done < "$TARGET_ABS/.auditorignore"
fi

find_target() {
    find "$TARGET_ABS" \
        \( "${FIND_PRUNE_MATCHES[@]}" \) -prune -o \
        "$@" -not -name '.DS_Store' -print 2>/dev/null
}

find_target_null() {
    find "$TARGET_ABS" \
        \( "${FIND_PRUNE_MATCHES[@]}" \) -prune -o \
        "$@" -not -name '.DS_Store' -print0 2>/dev/null
}

# ============================================================
# Count files by category (all find commands respect .auditorignore)
# ============================================================
TOTAL_FILES=$(find_target -type f | wc -l | tr -d ' ')

AGENT_FILES=$(find_target -maxdepth 5 -type f -name '*.agent.md' -not -path '*/tests/*' -not -path '*/fixtures/*' -not -path '*/archive/*' -not -path '*/Archive/*' || true)
AGENT_COUNT=0
[ -n "$AGENT_FILES" ] && AGENT_COUNT=$(echo "$AGENT_FILES" | wc -l | tr -d ' ')

SKILL_FILES=$(find_target -maxdepth 5 -type f -name 'SKILL.md' -not -path '*/tests/*' -not -path '*/fixtures/*' -not -path '*/benchmarks/*' || true)
SKILL_COUNT=0
[ -n "$SKILL_FILES" ] && SKILL_COUNT=$(echo "$SKILL_FILES" | wc -l | tr -d ' ')

INSTRUCTION_FILES=$(find_target -maxdepth 5 -type f \( -name '*.instructions.md' -o -name 'copilot-instructions.md' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) || true)
INSTRUCTION_COUNT=0
[ -n "$INSTRUCTION_FILES" ] && INSTRUCTION_COUNT=$(echo "$INSTRUCTION_FILES" | wc -l | tr -d ' ')

PROMPT_FILES=$(find_target -maxdepth 5 -type f -name '*.prompt.md' || true)
PROMPT_COUNT=0
[ -n "$PROMPT_FILES" ] && PROMPT_COUNT=$(echo "$PROMPT_FILES" | wc -l | tr -d ' ')

SCORING_FILES=$(find_target -maxdepth 4 -type f \( -name 'score-*.sh' -o -name 'score*.py' -o -name 'validate-*.sh' -o -name 'validate_*.py' -o -name 'test_*.py' -o -name '*_test.py' -o -name 'test-*.sh' \) || true)
SCORING_COUNT=0
[ -n "$SCORING_FILES" ] && SCORING_COUNT=$(echo "$SCORING_FILES" | wc -l | tr -d ' ')

AI_SURFACE_TOTAL=$((AGENT_COUNT + SKILL_COUNT + INSTRUCTION_COUNT + PROMPT_COUNT))

# Git info (if available)
COMMIT_COUNT=0
LAST_COMMIT_DATE="unknown"
if [ -d "$TARGET_ABS/.git" ]; then
    COMMIT_COUNT=$(cd "$TARGET_ABS" && git rev-list --count HEAD 2>/dev/null || echo 0)
    LAST_COMMIT_DATE=$(cd "$TARGET_ABS" && git log -1 --format=%cd --date=short 2>/dev/null || echo "unknown")
fi

# Co-Evolution Ratio
if [ "$AGENT_COUNT" -gt 0 ]; then
    COEVO_RATIO=$(awk "BEGIN {printf \"%.2f\", $SKILL_COUNT / $AGENT_COUNT}")
else
    COEVO_RATIO=$(awk "BEGIN {printf \"%.2f\", $SKILL_COUNT / 1}")
fi

# Determine tier
if [ "$TOTAL_FILES" -le 200 ]; then
    TIER="small"
    RECOMMENDED_BUDGET=200
    RECOMMENDED_MODE="single"
elif [ "$TOTAL_FILES" -le 500 ]; then
    TIER="medium"
    RECOMMENDED_BUDGET=300
    RECOMMENDED_MODE="single"
elif [ "$TOTAL_FILES" -le 1000 ]; then
    TIER="large"
    RECOMMENDED_BUDGET=400
    RECOMMENDED_MODE="multi"
else
    TIER="xlarge"
    RECOMMENDED_BUDGET=500
    RECOMMENDED_MODE="multi"
fi

# ============================================================
# PRE_SCAN.md — Repo structure + metadata
# ============================================================
{
    echo "# Pre-Scan Report: $REPO_NAME"
    echo ""
    echo "> Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "> Method: deterministic bash scan"
    echo ""
    echo "## Repo Metadata"
    echo ""
    echo "| field | value |"
    echo "|---|---|"
    echo "| Repo name | $REPO_NAME |"
    echo "| Path | $TARGET_ABS |"
    echo "| Total files | $TOTAL_FILES |"
    echo "| Commits | $COMMIT_COUNT |"
    echo "| Last commit | $LAST_COMMIT_DATE |"
    echo "| Tier | $TIER ($RECOMMENDED_MODE session recommended) |"
    echo "| Recommended scan budget | $RECOMMENDED_BUDGET |"
    echo "| Co-Evolution Ratio | $COEVO_RATIO |"
    echo ""
    echo "## AI Surface Inventory ($AI_SURFACE_TOTAL surfaces)"
    echo ""
    echo "| type | count | files |"
    echo "|---|---|---|"
    echo "| Agents | $AGENT_COUNT | $(if [ -n "$AGENT_FILES" ]; then echo "$AGENT_FILES" | head -5 | sed "s|$TARGET_ABS/||g" | tr '\n' ', ' | sed 's/,$//'; else echo 'none'; fi) |"
    echo "| Skills | $SKILL_COUNT | $(if [ -n "$SKILL_FILES" ]; then echo "$SKILL_FILES" | head -5 | sed "s|$TARGET_ABS/||g" | tr '\n' ', ' | sed 's/,$//'; else echo 'none'; fi) |"
    echo "| Instructions | $INSTRUCTION_COUNT | $(if [ -n "$INSTRUCTION_FILES" ]; then echo "$INSTRUCTION_FILES" | sed "s|$TARGET_ABS/||g" | tr '\n' ', ' | sed 's/,$//'; else echo 'none'; fi) |"
    echo "| Prompts | $PROMPT_COUNT | $(if [ -n "$PROMPT_FILES" ]; then echo "$PROMPT_FILES" | head -5 | sed "s|$TARGET_ABS/||g" | tr '\n' ', ' | sed 's/,$//'; else echo 'none'; fi) |"
    echo "| Scoring | $SCORING_COUNT | $(if [ -n "$SCORING_FILES" ]; then echo "$SCORING_FILES" | head -5 | sed "s|$TARGET_ABS/||g" | tr '\n' ', ' | sed 's/,$//'; else echo 'none'; fi) |"
    echo ""
    echo "## Governance Docs"
    echo ""
    for doc in AGENTS.md CLAUDE.md CONTRIBUTING.md PRINCIPLES.md CONSTITUTION.md HYPOTHESES.md LEARNINGS.md MODERNIZATION_ROADMAP.md; do
        if [ -f "$TARGET_ABS/$doc" ]; then
            lines=$(wc -l < "$TARGET_ABS/$doc" | tr -d ' ')
            echo "- **$doc**: ${lines}L"
        fi
    done
    if [ -f "$TARGET_ABS/.github/copilot-instructions.md" ]; then
        lines=$(wc -l < "$TARGET_ABS/.github/copilot-instructions.md" | tr -d ' ')
        echo "- **.github/copilot-instructions.md**: ${lines}L"
    fi
    echo ""
    echo "## Directory Structure (depth 2)"
    echo ""
    echo '```'
    find_target -maxdepth 2 -type d | sed "s|$TARGET_ABS/||g" | sed "s|$TARGET_ABS||g" | sort | head -60
    echo '```'
    echo ""
    echo "## File Distribution"
    echo ""
    echo "| extension | count |"
    echo "|---|---|"
    find_target -type f -name '*.*' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -15 | while read count ext; do
        echo "| .$ext | $count |"
    done
    echo ""
} > "$OUTPUT_DIR/PRE_SCAN.md"

# ============================================================
# AI_SURFACES_FULL.md — Full text of ALL AI surface files
# ============================================================
{
    echo "# AI Surfaces — Full Contents"
    echo ""
    echo "> Complete text of all $AI_SURFACE_TOTAL AI surface files."
    echo "> This guarantees 100% AI surface coverage regardless of scan budget."
    echo ""

    # Instruction files first (highest priority)
    for f in $(echo "$INSTRUCTION_FILES" | sort); do
        [ -z "$f" ] && continue
        rel=$(echo "$f" | sed "s|$TARGET_ABS/||g")
        lines=$(wc -l < "$f" | tr -d ' ')
        echo "## $rel (${lines}L)"
        echo ""
        echo '```markdown'
        head -500 "$f"
        if [ "$lines" -gt 500 ]; then
            echo ""
            echo "... [TRUNCATED at 500 lines — file has ${lines} lines total]"
        fi
        echo '```'
        echo ""
    done

    # Agent files
    for f in $(echo "$AGENT_FILES" | sort); do
        [ -z "$f" ] && continue
        rel=$(echo "$f" | sed "s|$TARGET_ABS/||g")
        lines=$(wc -l < "$f" | tr -d ' ')
        echo "## $rel (${lines}L)"
        echo ""
        echo '```markdown'
        head -300 "$f"
        if [ "$lines" -gt 300 ]; then
            echo ""
            echo "... [TRUNCATED at 300 lines — file has ${lines} lines total]"
        fi
        echo '```'
        echo ""
    done

    # Skill files (SKILL.md + scan for scripts/ and references/ siblings)
    for f in $(echo "$SKILL_FILES" | sort); do
        [ -z "$f" ] && continue
        rel=$(echo "$f" | sed "s|$TARGET_ABS/||g")
        lines=$(wc -l < "$f" | tr -d ' ')
        echo "## $rel (${lines}L)"
        echo ""
        echo '```markdown'
        head -200 "$f"
        if [ "$lines" -gt 200 ]; then
            echo ""
            echo "... [TRUNCATED at 200 lines]"
        fi
        echo '```'
        echo ""
    done

    # Prompt files
    for f in $(echo "$PROMPT_FILES" | sort); do
        [ -z "$f" ] && continue
        rel=$(echo "$f" | sed "s|$TARGET_ABS/||g")
        lines=$(wc -l < "$f" | tr -d ' ')
        echo "## $rel (${lines}L)"
        echo ""
        echo '```markdown'
        head -200 "$f"
        if [ "$lines" -gt 200 ]; then
            echo ""
            echo "... [TRUNCATED at 200 lines]"
        fi
        echo '```'
        echo ""
    done
} > "$OUTPUT_DIR/AI_SURFACES_FULL.md"

AI_SURFACES_SIZE=$(wc -c < "$OUTPUT_DIR/AI_SURFACES_FULL.md" | tr -d ' ')
AI_SURFACES_LINES=$(wc -l < "$OUTPUT_DIR/AI_SURFACES_FULL.md" | tr -d ' ')

# ============================================================
# LARGE_FILES.md — Files > 200 lines
# ============================================================
{
    echo "# Large Files (>200 lines)"
    echo ""
    echo "| file | lines | type |"
    echo "|---|---|---|"
    find_target_null -type f | xargs -0 wc -l 2>/dev/null | sort -rn | \
    awk -v prefix="$TARGET_ABS/" '
        /^[[:space:]]*[0-9]+[[:space:]]+total$/ { next }
        {
            line=$0
            sub(/^[[:space:]]+/, "", line)
            lines=line
            sub(/[[:space:]].*$/, "", lines)
            if ((lines + 0) <= 200) {
                next
            }
            file=line
            sub(/^[0-9]+[[:space:]]+/, "", file)
            rel=file
            sub("^" prefix, "", rel)
            ext=rel
            if (ext ~ /\./) {
                sub(/^.*\./, "", ext)
            } else {
                ext="unknown"
            }
            print "| " rel " | " lines " | " ext " |"
        }
    ' | head -50
    echo ""
} > "$OUTPUT_DIR/LARGE_FILES.md"

LARGE_COUNT=$(grep -c '^|' "$OUTPUT_DIR/LARGE_FILES.md" 2>/dev/null) || LARGE_COUNT=0
LARGE_COUNT=$((LARGE_COUNT - 2))  # subtract header rows
[ "$LARGE_COUNT" -lt 0 ] && LARGE_COUNT=0

# ============================================================
# GITIGNORE_ANALYSIS.md — .gitignore contents + implications
# ============================================================
{
    echo "# .gitignore Analysis"
    echo ""
    if [ -f "$TARGET_ABS/.gitignore" ]; then
        echo "## Contents"
        echo ""
        echo '```'
        cat "$TARGET_ABS/.gitignore"
        echo '```'
        echo ""
        echo "## Blocked Paths (Do NOT recommend files in these locations)"
        echo ""
        grep -v '^#' "$TARGET_ABS/.gitignore" | grep -v '^$' | while read pattern; do
            echo "- \`$pattern\`"
        done || true
    else
        echo "No .gitignore found. All paths are valid recommendation targets."
    fi
    echo ""
} > "$OUTPUT_DIR/GITIGNORE_ANALYSIS.md"

# ============================================================
# Summary
# ============================================================
echo "================================================================"
echo "Pre-Scan Complete: $REPO_NAME"
echo "================================================================"
echo "Total files:        $TOTAL_FILES"
echo "Auditorignore:      $AUDITORIGNORE_ACTIVE"
echo "AI surfaces:        $AI_SURFACE_TOTAL (${AGENT_COUNT}a, ${SKILL_COUNT}s, ${INSTRUCTION_COUNT}i, ${PROMPT_COUNT}p)"
echo "Co-Evolution Ratio: $COEVO_RATIO"
echo "Large files (>200L): $LARGE_COUNT"
echo "Tier:               $TIER → $RECOMMENDED_MODE session, budget $RECOMMENDED_BUDGET"
echo "AI dump size:       $AI_SURFACES_LINES lines, $AI_SURFACES_SIZE bytes"
echo ""
echo "Outputs:"
echo "  $OUTPUT_DIR/PRE_SCAN.md            (repo structure)"
echo "  $OUTPUT_DIR/AI_SURFACES_FULL.md    (full AI surface text)"
echo "  $OUTPUT_DIR/LARGE_FILES.md         (files >200L)"
echo "  $OUTPUT_DIR/GITIGNORE_ANALYSIS.md  (.gitignore analysis)"
echo "================================================================"
