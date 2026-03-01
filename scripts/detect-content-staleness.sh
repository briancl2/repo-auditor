#!/usr/bin/env bash
# detect-content-staleness.sh — DS-31: Content Staleness Detection
# Detects instruction surface content drift: claimed vs actual assertions.
#
# Usage: bash scripts/detect-content-staleness.sh <repo_path> [output_dir]
#
# Single parameterized framework with 4 check classes:
#   CS-COUNT:  Compare a claimed numeric count against computed count
#   CS-RANGE:  Compare a claimed ID range (e.g., "L1-L311") against actual max
#   CS-XFILE:  Compare a claimed value in file A against actual value in file B
#   CS-STAGE:  Verify stage/phase references are consistent with tracker file
#
# Output: Tri-state per check (PASS/FAIL/SKIP) with self-check.
# Exits 0 on all-pass, 1 on any fail, 2 on script error.

set -euo pipefail

REPO="${1:-.}"
OUTPUT_DIR="${2:-}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: Repository path '$REPO' does not exist" >&2
    exit 2
fi

cd "$REPO"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
PASS_LINES=""
FAIL_LINES=""
SKIP_LINES=""

# ──────────────────────────────────────────────────────────────────────
# Helper: record check result
# ──────────────────────────────────────────────────────────────────────
record_pass() {
    local id="$1" msg="$2"
    PASS_COUNT=$((PASS_COUNT + 1))
    PASS_LINES="${PASS_LINES}  PASS ${id}: ${msg}\n"
}

record_fail() {
    local id="$1" msg="$2"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_LINES="${FAIL_LINES}  FAIL ${id}: ${msg}\n"
}

record_skip() {
    local id="$1" msg="$2"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    SKIP_LINES="${SKIP_LINES}  SKIP ${id}: ${msg}\n"
}

# ──────────────────────────────────────────────────────────────────────
# CS-1: CS-COUNT — Learning count in AGENTS.md vs actual LEARNINGS.md
# ──────────────────────────────────────────────────────────────────────
if [ -f "AGENTS.md" ] && [ -f "LEARNINGS.md" ]; then
    # Extract claimed count: look for "NNN operational learnings" or "NNN learnings"
    CLAIMED_COUNT=$(grep -oE '[0-9]+ operational learning' "AGENTS.md" | head -1 | grep -oE '[0-9]+' || true)
    if [ -z "$CLAIMED_COUNT" ]; then
        CLAIMED_COUNT=$(grep -oE '[0-9]+ learnings' "AGENTS.md" | head -1 | grep -oE '[0-9]+' || true)
    fi

    if [ -n "$CLAIMED_COUNT" ]; then
        # Count actual learnings: lines starting with | L followed by digits
        ACTUAL_COUNT=$(grep -cE '^\| L[0-9]+' "LEARNINGS.md" 2>/dev/null || echo "0")
        if [ "$CLAIMED_COUNT" -eq "$ACTUAL_COUNT" ]; then
            record_pass "CS-1" "AGENTS.md claims ${CLAIMED_COUNT} learnings, actual ${ACTUAL_COUNT} (match)"
        else
            record_fail "CS-1" "AGENTS.md claims \"${CLAIMED_COUNT} operational learnings\", actual ${ACTUAL_COUNT} (LEARNINGS.md)"
        fi
    else
        record_skip "CS-1" "No learning count claim found in AGENTS.md"
    fi
else
    record_skip "CS-1" "AGENTS.md or LEARNINGS.md not found"
fi

# ──────────────────────────────────────────────────────────────────────
# CS-2: CS-RANGE — Learning ID range in AGENTS.md vs actual max
# ──────────────────────────────────────────────────────────────────────
if [ -f "AGENTS.md" ] && [ -f "LEARNINGS.md" ]; then
    # Extract claimed range: "L1-LNNN" pattern
    CLAIMED_MAX=$(grep -oE 'L1-L[0-9]+' "AGENTS.md" | head -1 | grep -oE '[0-9]+$' || true)

    if [ -n "$CLAIMED_MAX" ]; then
        # Find actual max learning ID
        ACTUAL_MAX=$(grep -oE '^\| L([0-9]+)' "LEARNINGS.md" | grep -oE '[0-9]+' | sort -n | tail -1 || true)
        if [ -z "$ACTUAL_MAX" ]; then
            ACTUAL_MAX=0
        fi

        if [ "$CLAIMED_MAX" -eq "$ACTUAL_MAX" ]; then
            record_pass "CS-2" "AGENTS.md claims L1-L${CLAIMED_MAX}, actual max L${ACTUAL_MAX} (match)"
        else
            record_fail "CS-2" "AGENTS.md claims \"L1-L${CLAIMED_MAX}\", actual max L${ACTUAL_MAX}"
        fi
    else
        record_skip "CS-2" "No L1-LNNN range found in AGENTS.md"
    fi
else
    record_skip "CS-2" "AGENTS.md or LEARNINGS.md not found"
fi

# ──────────────────────────────────────────────────────────────────────
# CS-3: CS-XFILE — Skills count in table vs skills on disk
# ──────────────────────────────────────────────────────────────────────
if [ -f "AGENTS.md" ]; then
    # Count skill table rows: lines like "| N | skill-name |"
    # Look in the Skills section — count rows with "| NUMBER | name |"
    TABLE_SKILL_COUNT=$(grep -cE '^\| [0-9]+ \|.*\|' "AGENTS.md" 2>/dev/null || echo "0")

    # Count skills on disk
    DISK_SKILL_COUNT=0
    for skill_dir in .agents/skills .github/skills; do
        if [ -d "$skill_dir" ]; then
            DISK_SKILL_COUNT=$(find "$skill_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
            break
        fi
    done

    # Only check if we found skills on disk (otherwise skip for non-skill repos)
    if [ "$DISK_SKILL_COUNT" -gt 0 ]; then
        # The table may also have numbered rows for scripts, agents, etc.
        # Use the Skills section header to scope the search
        SKILLS_SECTION_COUNT=""
        # Extract "Skills (N)" from AGENTS.md header
        SKILLS_HEADER_COUNT=$(grep -oE 'Skills \(([0-9]+)\)' "AGENTS.md" | head -1 | grep -oE '[0-9]+' || true)

        if [ -n "$SKILLS_HEADER_COUNT" ]; then
            if [ "$SKILLS_HEADER_COUNT" -eq "$DISK_SKILL_COUNT" ]; then
                record_pass "CS-3" "AGENTS.md claims ${SKILLS_HEADER_COUNT} skills, actual ${DISK_SKILL_COUNT} on disk (match)"
            else
                record_fail "CS-3" "AGENTS.md claims ${SKILLS_HEADER_COUNT} skills, actual ${DISK_SKILL_COUNT} on disk"
            fi
        else
            record_skip "CS-3" "No Skills (N) header found in AGENTS.md"
        fi
    else
        record_skip "CS-3" "No skills directory found on disk"
    fi
else
    record_skip "CS-3" "AGENTS.md not found"
fi

# ──────────────────────────────────────────────────────────────────────
# CS-4: CS-STAGE — SUSPENDED/HALTED references vs current stage
# ──────────────────────────────────────────────────────────────────────
TRACKER_FILE=""
for candidate in "FLYWHEEL.md" "STATUS.md" "ROADMAP.md"; do
    if [ -f "$candidate" ]; then
        # Check for stage/phase header
        if grep -qiE 'Stage [0-9]|Phase:.*Stage' "$candidate" 2>/dev/null; then
            TRACKER_FILE="$candidate"
            break
        fi
    fi
done

if [ -n "$TRACKER_FILE" ]; then
    # Extract current stage number from tracker
    CURRENT_STAGE=$(grep -oE 'Stage ([0-9]+)' "$TRACKER_FILE" | head -1 | grep -oE '[0-9]+' || true)

    if [ -n "$CURRENT_STAGE" ]; then
        # Search all instruction surface files for SUSPENDED/HALTED references to past stages
        CS4_FOUND=0
        CS4_DETAILS=""

        for check_file in FLYWHEEL.md AGENTS.md .github/agents/*.agent.md .agents/*.agent.md; do
            # Use glob — skip if no match
            for f in $check_file; do
                [ -f "$f" ] || continue

                # Look for "SUSPENDED until Stage N" or "HALTED until Stage N" where N < current
                while IFS= read -r line; do
                    REF_STAGE=$(echo "$line" | grep -oE '(SUSPENDED|HALTED|halted|suspended) until Stage ([0-9]+)' | grep -oE '[0-9]+' || true)
                    if [ -n "$REF_STAGE" ] && [ "$REF_STAGE" -lt "$CURRENT_STAGE" ]; then
                        CS4_FOUND=$((CS4_FOUND + 1))
                        CS4_DETAILS="${CS4_DETAILS}${f}: references Stage ${REF_STAGE} (current: ${CURRENT_STAGE}); "
                    fi
                done < <(grep -iE 'SUSPENDED until Stage|HALTED until Stage' "$f" 2>/dev/null || true)

                # Also check for "Inner loop is HALTED" when inner loop might be active
                if grep -qiE 'Inner loop is HALTED|inner loop.*HALTED' "$f" 2>/dev/null; then
                    # Check if FLYWHEEL says inner loop is ACTIVE
                    if grep -qiE 'Inner loop ACTIVE|inner loop.*ACTIVE' "$TRACKER_FILE" 2>/dev/null; then
                        CS4_FOUND=$((CS4_FOUND + 1))
                        CS4_DETAILS="${CS4_DETAILS}${f}: says inner loop HALTED but ${TRACKER_FILE} says ACTIVE; "
                    fi
                fi
            done
        done

        if [ "$CS4_FOUND" -eq 0 ]; then
            record_pass "CS-4" "No stale stage/state references found (current: Stage ${CURRENT_STAGE})"
        else
            record_fail "CS-4" "${CS4_FOUND} stale stage references: ${CS4_DETAILS}"
        fi
    else
        record_skip "CS-4" "Cannot determine current stage from ${TRACKER_FILE}"
    fi
else
    record_skip "CS-4" "No tracker file found (FLYWHEEL.md, STATUS.md, ROADMAP.md)"
fi

# ──────────────────────────────────────────────────────────────────────
# Output
# ──────────────────────────────────────────────────────────────────────
TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))

echo "=== Content Staleness Report ==="
echo "Repo: $(basename "$(pwd)")"
echo "Checks: ${TOTAL}  PASS: ${PASS_COUNT}  FAIL: ${FAIL_COUNT}  SKIP: ${SKIP_COUNT}"
echo ""
if [ -n "$PASS_LINES" ]; then
    printf "%b" "$PASS_LINES"
fi
if [ -n "$FAIL_LINES" ]; then
    printf "%b" "$FAIL_LINES"
fi
if [ -n "$SKIP_LINES" ]; then
    printf "%b" "$SKIP_LINES"
fi
echo ""

# Self-check: verify FAIL count matches FAIL lines
FAIL_LINE_COUNT=$(printf "%b" "$FAIL_LINES" | grep -c "FAIL " 2>/dev/null || true)
FAIL_LINE_COUNT=$(echo "$FAIL_LINE_COUNT" | tr -d '[:space:]')
if [ -z "$FAIL_LINE_COUNT" ]; then FAIL_LINE_COUNT=0; fi
if [ "$FAIL_COUNT" -eq "$FAIL_LINE_COUNT" ]; then
    echo "# Self-check: FAIL count matches FAIL lines: OK"
else
    echo "# Self-check: FAIL count MISMATCH (counter=${FAIL_COUNT}, lines=${FAIL_LINE_COUNT})"
fi

# Write output file if output_dir specified
if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
    {
        echo "=== Content Staleness Report ==="
        echo "Repo: $(basename "$(pwd)")"
        echo "Checks: ${TOTAL}  PASS: ${PASS_COUNT}  FAIL: ${FAIL_COUNT}  SKIP: ${SKIP_COUNT}"
        echo ""
        printf "%b" "$PASS_LINES"
        printf "%b" "$FAIL_LINES"
        printf "%b" "$SKIP_LINES"
    } > "$OUTPUT_DIR/staleness.txt"
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo ""
    echo "RESULT: FAIL (${FAIL_COUNT} stale content assertions)"
    exit 1
else
    echo ""
    echo "RESULT: PASS (all content assertions current)"
    exit 0
fi
