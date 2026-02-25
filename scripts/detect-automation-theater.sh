#!/usr/bin/env bash
# detect-automation-theater.sh — Find capabilities that exist but are never used
#
# DS-21: Automation Theater — capabilities that exist on paper but aren't exercised.
# More dangerous than missing capabilities because they create false confidence.
#
# Checks 7 theater signals:
#   S1: Hook scripts exist but not installed in .git/hooks/
#   S2: Makefile targets exist but zero evidence of invocation
#   S3: Skills exist but zero session-log tool calls reference them
#   S4: AGENTS.md protocol steps exist but artifacts show bypassing
#   S5: Agent files exist with zero session-log dispatches
#   S6: Enforcement defaults to soft (bypass allowed without env var)
#   S7: --no-verify appears in committed artifacts
#
# Usage: bash scripts/detect-automation-theater.sh <repo_path> [session_logs_dir]
#
# Exit codes:
#   0 — no theater signals found
#   1 — ≥1 theater signal found
#
# Guardrails: macOS bash 3.2 compat (no associative arrays, L10)

set -uo pipefail

REPO="${1:?Usage: detect-automation-theater.sh <repo_path> [session_logs_dir]}"
SESSION_DIR="${2:-}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: $REPO not found" >&2
    exit 2
fi

REPO_NAME="$(basename "$REPO")"
SIGNALS=0
FINDINGS=""

add_finding() {
    local sig="$1"
    local desc="$2"
    SIGNALS=$((SIGNALS + 1))
    FINDINGS="${FINDINGS}  ${sig}: ${desc}\n"
}

echo "================================================================"
echo "DS-21: Automation Theater Detection"
echo "================================================================"
echo ""
echo "  Repo: $REPO_NAME"
echo "  Path: $REPO"
echo ""

# --- S1: Hook scripts exist but not installed ---
echo "  [S1] Hook installation gap..."
S1_SCRIPTS=0
S1_INSTALLED=0
for hook_type in pre-commit pre-push; do
    script_count=$(find "$REPO" -maxdepth 3 \( -name "*${hook_type}*hook*" -o -name "*${hook_type}*.sh" \) 2>/dev/null | wc -l | tr -d ' ')
    if [ "$script_count" -gt 0 ]; then
        S1_SCRIPTS=$((S1_SCRIPTS + 1))
        if [ -f "$REPO/.git/hooks/$hook_type" ]; then
            S1_INSTALLED=$((S1_INSTALLED + 1))
        fi
    fi
done
if [ "$S1_SCRIPTS" -gt 0 ] && [ "$S1_INSTALLED" -lt "$S1_SCRIPTS" ]; then
    add_finding "S1" "Hook scripts: $S1_SCRIPTS found, $S1_INSTALLED installed (gap: $((S1_SCRIPTS - S1_INSTALLED)))"
fi
echo "    scripts=$S1_SCRIPTS installed=$S1_INSTALLED"

# --- S2: Makefile targets with zero invocation evidence ---
echo "  [S2] Makefile target usage..."
if [ -f "$REPO/Makefile" ]; then
    # Count targets
    TARGET_COUNT=$(grep -cE '^[a-zA-Z_-]+:' "$REPO/Makefile") || TARGET_COUNT=0
    # Check for review target specifically (most critical)
    HAS_REVIEW=$(grep -cE '^review:' "$REPO/Makefile") || HAS_REVIEW=0
    # Check git log for evidence of make targets being used
    MAKE_EVIDENCE=$(git -C "$REPO" log --format=%B -n 200 2>/dev/null | grep -ciE 'make (review|test|lint|score|validate|inventory)') || MAKE_EVIDENCE=0
    echo "    targets=$TARGET_COUNT review=$HAS_REVIEW usage_evidence=$MAKE_EVIDENCE"
    if [ "$HAS_REVIEW" -gt 0 ] && [ "$MAKE_EVIDENCE" -eq 0 ]; then
        add_finding "S2" "Makefile has 'review' target but 0 usage evidence in last 200 commits"
    fi
else
    echo "    no Makefile"
fi

# --- S3: Skills with zero session-log invocations ---
echo "  [S3] Skill invocation evidence..."
SKILL_COUNT=0
SKILL_DIRS=""
for sd in "$REPO/.agents/skills" "$REPO/.github/skills"; do
    if [ -d "$sd" ]; then
        while IFS= read -r skill_dir; do
            SKILL_COUNT=$((SKILL_COUNT + 1))
            skill_name=$(basename "$skill_dir")
            SKILL_DIRS="${SKILL_DIRS} ${skill_name}"
        done < <(find "$sd" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    fi
done
echo "    skills_found=$SKILL_COUNT"
# Session log check deferred to S3 in session-tool-matrix.py (requires session data)
if [ -n "$SESSION_DIR" ] && [ -d "$SESSION_DIR" ]; then
    SESSION_COUNT=$(find "$SESSION_DIR" -name "*.jsonl*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SESSION_COUNT" -gt 0 ] && [ "$SKILL_COUNT" -gt 0 ]; then
        # Quick check: any skill name mentioned in session logs?
        SKILL_MENTIONS=0
        for skill_name in $SKILL_DIRS; do
            hits=$(zgrep -l "$skill_name" "$SESSION_DIR"/*.jsonl* 2>/dev/null | wc -l | tr -d ' ')
            SKILL_MENTIONS=$((SKILL_MENTIONS + hits))
        done
        ZERO_USE_SKILLS=$((SKILL_COUNT - (SKILL_MENTIONS > 0 ? 1 : 0)))
        echo "    sessions=$SESSION_COUNT skill_mentions=$SKILL_MENTIONS"
        # Simplified: if review skill exists but 0 mentions
        if echo "$SKILL_DIRS" | grep -q "reviewing-code-locally" && ! zgrep -ql "review\|local_review" "$SESSION_DIR"/*.jsonl* 2>/dev/null; then
            add_finding "S3" "reviewing-code-locally skill exists but 0 invocations across $SESSION_COUNT sessions"
        fi
    fi
else
    echo "    (no session logs provided — skipping invocation check)"
fi

# --- S4: Protocol bypass evidence ---
echo "  [S4] Protocol bypass evidence..."
BYPASS_COUNT=0
# Check committed artifacts for --no-verify
NOVERIFY_IN_ARTIFACTS=$(find "$REPO" -maxdepth 2 -name "HANDOFF-*.md" -o -name "*.txt" 2>/dev/null | head -50 | xargs grep -l "\-\-no-verify" 2>/dev/null | wc -l | tr -d ' ')
# Check git log messages
NOVERIFY_IN_LOG=$(git -C "$REPO" log --format=%B -n 200 2>/dev/null | grep -c "\-\-no-verify" || echo 0)
BYPASS_COUNT=$((NOVERIFY_IN_ARTIFACTS + NOVERIFY_IN_LOG))
echo "    --no-verify in artifacts=$NOVERIFY_IN_ARTIFACTS in_log=$NOVERIFY_IN_LOG"
if [ "$BYPASS_COUNT" -gt 2 ]; then
    add_finding "S4" "--no-verify appears $BYPASS_COUNT times in artifacts/logs (systematic bypass)"
fi

# --- S5: Agent files with zero dispatch evidence ---
echo "  [S5] Agent dispatch evidence..."
AGENT_COUNT=0
for ad in "$REPO/.agents" "$REPO/.github/agents"; do
    if [ -d "$ad" ]; then
        ac=$(find "$ad" -name "*.agent.md" 2>/dev/null | wc -l | tr -d ' ')
        AGENT_COUNT=$((AGENT_COUNT + ac))
    fi
done
echo "    agents=$AGENT_COUNT"
# If ≥5 agents but zero skills, flag DS-8-style imported framework (already caught, but also theater)
if [ "$AGENT_COUNT" -ge 5 ] && [ "$SKILL_COUNT" -eq 0 ]; then
    add_finding "S5" "$AGENT_COUNT agents but 0 skills — imported framework never customized (DS-8 + theater)"
fi

# --- S6: Soft enforcement defaults ---
echo "  [S6] Enforcement depth..."
SOFT_ENFORCE=0
for hook_script in $(find "$REPO" -maxdepth 3 -name "*hook*.sh" 2>/dev/null); do
    # Check for bypass-by-default patterns:
    # - BLOCK_UNREVIEWED:-0 = pre-push defaults to allow (soft)
    # - STRICT_REVIEW:-0 = pre-commit v1 defaults to allow (soft)
    # - exit 0 after fail = review failure doesn't block
    # Exclude SKIP_REVIEW — that's the v2 hard-default pattern (block by default,
    # explicit opt-out). The presence of SKIP_REVIEW is NOT a soft enforcement signal.
    if grep -qE 'BLOCK_UNREVIEWED:-0|STRICT_REVIEW:-0' "$hook_script" 2>/dev/null; then
        SOFT_ENFORCE=$((SOFT_ENFORCE + 1))
    fi
done
echo "    soft_enforce_hooks=$SOFT_ENFORCE"
if [ "$SOFT_ENFORCE" -gt 0 ]; then
    add_finding "S6" "$SOFT_ENFORCE hook script(s) default to soft enforcement (bypass allowed)"
fi

# --- S7: --no-verify frequency in git history ---
echo "  [S7] Commit bypass frequency..."
TOTAL_COMMITS=$(git -C "$REPO" rev-list --count HEAD 2>/dev/null || echo 0)
# Check recent commits for --no-verify evidence
# We can't directly detect --no-verify from git log, but we CAN check if
# the pre-commit hook output appears in any committed artifacts
RECENT_COMMITS=$(git -C "$REPO" rev-list --count --since="30 days ago" HEAD 2>/dev/null || echo 0)
echo "    total_commits=$TOTAL_COMMITS recent_30d=$RECENT_COMMITS"
# If we have session logs, check for git commit --no-verify in tool calls
if [ -n "$SESSION_DIR" ] && [ -d "$SESSION_DIR" ]; then
    NOVERIFY_SESSIONS=$(zgrep -l "no-verify\|no.verify" "$SESSION_DIR"/*.jsonl* 2>/dev/null | wc -l | tr -d ' ')
    echo "    sessions_with_no_verify=$NOVERIFY_SESSIONS"
    if [ "$NOVERIFY_SESSIONS" -gt 3 ]; then
        add_finding "S7" "--no-verify found in $NOVERIFY_SESSIONS sessions (systematic commit bypass)"
    fi
fi

# --- S8: Dead code density (DS-21enh) ---
echo "  [S8] Dead code density..."
ACTIVE_SCRIPTS=0
ARCHIVED_SCRIPTS=0
# Count active scripts (excluding archive dirs)
ACTIVE_SCRIPTS=$(find "$REPO" -type f -name '*.sh' \
  ! -path '*/archive/*' ! -path '*/.git/*' ! -path '*/node_modules/*' \
  2>/dev/null | wc -l | tr -d ' ')
# Count archived scripts
ARCHIVED_SCRIPTS=$(find "$REPO" -type f -name '*.sh' -path '*/archive/*' \
  ! -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
TOTAL_SCRIPTS=$((ACTIVE_SCRIPTS + ARCHIVED_SCRIPTS))
echo "    active=$ACTIVE_SCRIPTS archived=$ARCHIVED_SCRIPTS total=$TOTAL_SCRIPTS"
if [ "$TOTAL_SCRIPTS" -gt 0 ]; then
    DEAD_RATIO=$((ARCHIVED_SCRIPTS * 100 / TOTAL_SCRIPTS))
    echo "    dead_code_density=${DEAD_RATIO}%"
    if [ "$DEAD_RATIO" -gt 10 ]; then
        add_finding "S8" "Dead code density ${DEAD_RATIO}% (${ARCHIVED_SCRIPTS}/${TOTAL_SCRIPTS} scripts archived) — consider cleanup"
    fi
fi

# --- Summary ---
echo ""
echo "================================================================"
echo "  THEATER SIGNALS: $SIGNALS"
if [ "$SIGNALS" -gt 0 ]; then
    echo ""
    echo -e "$FINDINGS"
fi
echo "================================================================"

if [ "$SIGNALS" -gt 0 ]; then
    exit 1
fi
exit 0
