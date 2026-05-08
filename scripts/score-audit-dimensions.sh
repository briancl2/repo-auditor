#!/usr/bin/env bash
# score-audit-dimensions.sh — Score 5 audit dimensions from tool outputs
#
# Reads the output files produced by repo-auditor.sh and computes a 0-20
# score for each dimension (max composite = 100).
#
# Usage: bash scripts/score-audit-dimensions.sh <audit_output_dir>
#
# Reads:
#   <dir>/maturity.txt      — classify-repo-maturity.sh output
#   <dir>/stall-risk.txt    — stall-risk-score.sh output
#   <dir>/dna.txt           — extract-repo-dna.sh output
#   <dir>/drift.txt         — detect-capability-drift.sh output
#   <dir>/pre-scan-log.txt  — pre-scan stdout log
#
# Writes:
#   <dir>/SCORECARD.json    — Machine-readable dimension scores
#
# Dimension scoring (each 0-20):
#   D1 Governance:       G governance score (0-5) × 4
#   D2 Surface Health:   surface count + co-evo + drift (composite)
#   D3 Skill Maturity:   skill density + velocity + organicity
#   D4 Measurement:      scoring layers + audit depth + abstraction
#   D5 Self-Improvement:  inverted stall risk + trajectory + plan infra
#
# Guardrails: No associative arrays (L10), no grep -c || echo 0 (L11).

set -euo pipefail

DIR="${1:?Usage: score-audit-dimensions.sh <audit_output_dir>}"

# --- Helper: safe numeric extraction ---
extract_num() {
    local file="$1"
    local pattern="$2"
    local default="${3:-0}"
    if [ -f "$file" ]; then
        local val
        val=$(grep "$pattern" "$file" | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1) || true
        if [ -n "$val" ]; then
            echo "$val"
            return
        fi
    fi
    echo "$default"
}

# --- Helper: coerce to integer (handles floats safely for bash arithmetic) ---
to_int() {
    echo "$1" | awk '{printf "%d", $1 + 0}'
}

# --- Extract raw values ---

# Extract REPO_PATH early (needed for spec-kit governance/scoring signals)
REPO_PATH=""
if [ -f "$DIR/maturity.txt" ]; then
    REPO_PATH=$(grep "^Path:" "$DIR/maturity.txt" | head -1 | sed 's/^Path: *//' | sed 's/ *$//')
fi

# From maturity.txt
GOV_AGENTS_MD="no"
GOV_LEARNINGS="no"
GOV_HYPOTHESES="no"
GOV_CI="no"
GOV_PROTOCOL="no"
if [ -f "$DIR/maturity.txt" ]; then
    GOV_AGENTS_MD=$(grep "^AGENTS.md:" "$DIR/maturity.txt" | head -1 | awk '{print $2}') || GOV_AGENTS_MD="no"
    GOV_LEARNINGS=$(grep "^LEARNINGS.md:" "$DIR/maturity.txt" | head -1 | awk '{print $2}') || GOV_LEARNINGS="no"
    GOV_HYPOTHESES=$(grep "^HYPOTHESES.md:" "$DIR/maturity.txt" | head -1 | awk '{print $2}') || GOV_HYPOTHESES="no"
    GOV_CI_RAW=$(grep "^CI pipeline:" "$DIR/maturity.txt" | head -1 | awk '{print $NF}') || GOV_CI_RAW="no"
    case "$(echo "$GOV_CI_RAW" | tr '[:upper:]' '[:lower:]')" in
        yes|no) GOV_CI="$GOV_CI_RAW" ;;
        *) GOV_CI="no" ;;
    esac
    # Protocol: any consolidated instruction surface satisfies this (L104).
    # AGENTS.md is the canonical required surface; CLAUDE.md and copilot-instructions.md
    # are optional alternates that also satisfy protocol. This is counted separately from
    # GOV_AGENTS_MD to avoid double-counting: GOV_AGENTS_MD = "AGENTS.md exists",
    # GOV_PROTOCOL = "at least one consolidated instruction surface exists".
    # A repo with only AGENTS.md gets GOV_AGENTS_MD=YES + GOV_PROTOCOL=YES.
    if grep -qE "^AGENTS.md:.*YES|^copilot-inst:.*YES|^CLAUDE.md:.*YES" "$DIR/maturity.txt" 2>/dev/null; then
        GOV_PROTOCOL="YES"
    fi
fi

# Count governance hits (case-insensitive per W2)
GOV_COUNT=0
for item in "$GOV_AGENTS_MD" "$GOV_LEARNINGS" "$GOV_HYPOTHESES" "$GOV_CI" "$GOV_PROTOCOL"; do
    case "$(echo "$item" | tr '[:upper:]' '[:lower:]')" in
        yes) GOV_COUNT=$((GOV_COUNT + 1)) ;;
    esac
done

# Spec-kit governance: populated constitution.md counts as governance signal
# Non-template check: must have >10 lines and not contain only placeholders
GOV_SPECKIT=0
if [ -n "$REPO_PATH" ]; then
    for const_path in "$REPO_PATH/.specify/memory/constitution.md" "$REPO_PATH/CONSTITUTION.md"; do
        if [ -f "$const_path" ]; then
            const_lines=$(wc -l < "$const_path" | tr -d ' ')
            placeholders=$(grep -c '\[PRINCIPLE\]\|\[PLACEHOLDER\]\|\[TODO\]' "$const_path" 2>/dev/null) || placeholders=0
            if [ "$const_lines" -gt 10 ] && [ "$placeholders" -lt 3 ]; then
                GOV_SPECKIT=1
                break
            fi
        fi
    done
    # Add to governance count (max stays at 5 original + 1 speckit = 6)
    GOV_COUNT=$((GOV_COUNT + GOV_SPECKIT))
fi

# From DNA (extract as strings, coerce to int only when needed for arithmetic)
DNA_G=$(extract_num "$DIR/dna.txt" "Governance:" 0)
DNA_G_INT=$(to_int "$DNA_G")
DNA_SC=$(extract_num "$DIR/dna.txt" "Scoring Layers:" 0)
DNA_SC_INT=$(to_int "$DNA_SC")
DNA_AD=$(extract_num "$DIR/dna.txt" "Self-Audit Depth:" 0)
DNA_AD_INT=$(to_int "$DNA_AD")
DNA_AB=$(extract_num "$DIR/dna.txt" "Abstraction Depth:" 0)
DNA_AB_INT=$(to_int "$DNA_AB")
DNA_K=$(extract_num "$DIR/dna.txt" "Skill Density:" 0)
DNA_K_INT=$(to_int "$DNA_K")
DNA_KV=$(extract_num "$DIR/dna.txt" "Skill Velocity:" 0)
DNA_AO=$(extract_num "$DIR/dna.txt" "Agent Organicity:" 0)
DNA_MATURITY=$(extract_num "$DIR/dna.txt" "Maturity Score:" 0)
DNA_MATURITY_INT=$(to_int "$DNA_MATURITY")
DNA_TRAJECTORY=$(extract_num "$DIR/dna.txt" "Trajectory:" 0)
DNA_TRAJECTORY_INT=$(to_int "$DNA_TRAJECTORY")
DNA_PI=$(extract_num "$DIR/dna.txt" "Plan Infrastructure:" 0)
DNA_PI_INT=$(to_int "$DNA_PI")
CO_EVO=$(extract_num "$DIR/dna.txt" "Co-Evolution Ratio:" 0)

# From stall-risk
STALL_SCORE_RAW=$(extract_num "$DIR/stall-risk.txt" "SCORE:" 50)
STALL_SCORE=$(to_int "$STALL_SCORE_RAW")

# From drift — extract the percentage inside parens, not the count
DRIFT_PCT_RAW=0
if [ -f "$DIR/drift.txt" ]; then
    DRIFT_PCT_RAW=$(grep "Undocumented:" "$DIR/drift.txt" | head -1 | sed 's/.*(\([0-9]*\)%).*/\1/') || DRIFT_PCT_RAW=0
    if [ -z "$DRIFT_PCT_RAW" ]; then DRIFT_PCT_RAW=0; fi
    # B1 fix: validate numeric — non-numeric means sed didn't match the (NN%) pattern
    if ! echo "$DRIFT_PCT_RAW" | grep -qE '^[0-9]+$'; then DRIFT_PCT_RAW=0; fi
fi

# Surface count + total files from pre-scan log
SURFACE_COUNT=0
TOTAL_FILES=0
PRE_SCAN_TOTAL_FILES=0
if [ -f "$DIR/pre-scan-log.txt" ]; then
    SURFACE_COUNT=$(grep "^AI surfaces:" "$DIR/pre-scan-log.txt" | head -1 | sed 's/^AI surfaces:[[:space:]]*//' | grep -oE '^[0-9]+' | head -1) || SURFACE_COUNT=0
    if [ -z "$SURFACE_COUNT" ]; then SURFACE_COUNT=0; fi
    TOTAL_FILES=$(grep "^Total files:" "$DIR/pre-scan-log.txt" | head -1 | sed 's/^Total files:[[:space:]]*//' | grep -oE '^[0-9]+' | head -1) || TOTAL_FILES=0
    if [ -z "$TOTAL_FILES" ]; then TOTAL_FILES=0; fi
    PRE_SCAN_TOTAL_FILES="$TOTAL_FILES"
fi

# Scoring tools count from maturity
SCORING_TOOLS=0
MATURITY_TOTAL_FILES=0
if [ -f "$DIR/maturity.txt" ]; then
    SCORING_TOOLS=$(grep "^Scoring tools:" "$DIR/maturity.txt" | head -1 | grep -oE '[0-9]+' | head -1) || SCORING_TOOLS=0
    if [ -z "$SCORING_TOOLS" ]; then SCORING_TOOLS=0; fi
    MATURITY_TOTAL_FILES=$(grep "^Files:" "$DIR/maturity.txt" | head -1 | grep -oE '[0-9]+' | head -1) || MATURITY_TOTAL_FILES=0
    if [ -z "$MATURITY_TOTAL_FILES" ]; then MATURITY_TOTAL_FILES=0; fi
fi

# Skill and agent counts
SKILL_COUNT=0
AGENT_COUNT=0
if [ -f "$DIR/maturity.txt" ]; then
    SKILL_COUNT=$(grep "^Skills:" "$DIR/maturity.txt" | head -1 | grep -oE '[0-9]+' | head -1) || SKILL_COUNT=0
    if [ -z "$SKILL_COUNT" ]; then SKILL_COUNT=0; fi
    AGENT_COUNT=$(grep "^Agents:" "$DIR/maturity.txt" | head -1 | grep -oE '[0-9]+' | head -1) || AGENT_COUNT=0
    if [ -z "$AGENT_COUNT" ]; then AGENT_COUNT=0; fi
fi

DNA_TOTAL_FILES=0
if [ -f "$DIR/dna.txt" ]; then
    DNA_TOTAL_FILES=$(grep "Skill Density:" "$DIR/dna.txt" | head -1 | sed 's/.*\/ *\([0-9][0-9]*\) files.*/\1/') || DNA_TOTAL_FILES=0
    if [ -z "$DNA_TOTAL_FILES" ] || ! echo "$DNA_TOTAL_FILES" | grep -qE '^[0-9]+$'; then DNA_TOTAL_FILES=0; fi
fi
if [ "$DNA_TOTAL_FILES" -eq 0 ] 2>/dev/null; then DNA_TOTAL_FILES="$TOTAL_FILES"; fi
if [ "$MATURITY_TOTAL_FILES" -eq 0 ] 2>/dev/null; then MATURITY_TOTAL_FILES="$TOTAL_FILES"; fi

COUNT_RECON_STATUS="aligned"
COUNT_RECON_NOTE="maturity.txt, dna.txt, and pre-scan-log.txt agree on the counted file surface used for scorer receipts."
if [ "$TOTAL_FILES" -ne "$MATURITY_TOTAL_FILES" ] || [ "$TOTAL_FILES" -ne "$DNA_TOTAL_FILES" ]; then
    COUNT_RECON_STATUS="mismatch"
    COUNT_RECON_NOTE="Count surfaces disagree and require reconciliation before this scorecard can act as a portable widening receipt."
fi

AUDITORIGNORE_ACTIVE=false
AUDITORIGNORE_ENTRY_COUNT=0
AUDITORIGNORE_ENTRY_COUNT_STATUS="none"
if [ -f "$DIR/pre-scan-log.txt" ]; then
    AUDITORIGNORE_RAW=$(awk -F: '/^Auditorignore:/ { split($2, parts, /[[:space:]]+/); for (idx in parts) if (parts[idx] != "") { print parts[idx]; exit } }' "$DIR/pre-scan-log.txt" 2>/dev/null || true)
    case "$AUDITORIGNORE_RAW" in
        yes|YES|Yes|true|TRUE|True)
            AUDITORIGNORE_ACTIVE=true
            AUDITORIGNORE_ENTRY_COUNT_STATUS="unknown"
            ;;
    esac
fi
if [ -n "$REPO_PATH" ] && [ -f "$REPO_PATH/.auditorignore" ]; then
    AUDITORIGNORE_ACTIVE=true
    AUDITORIGNORE_ENTRY_COUNT_STATUS="known"
    AUDITORIGNORE_ENTRY_COUNT=$(
        sed 's/#.*//' "$REPO_PATH/.auditorignore" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | awk 'NF { count += 1 } END { print count + 0 }'
    ) || AUDITORIGNORE_ENTRY_COUNT=0
fi

# --- Compute dimension scores (each 0-20) ---

# D1 Governance: avg(GOV_COUNT, DNA_G) × 4 — blend avoids masking disagreement
# GOV_COUNT now includes speckit constitution signal (0-6 range)
D1_A=$((GOV_COUNT * 4))
if [ "$D1_A" -gt 20 ]; then D1_A=20; fi
D1_B=$((DNA_G_INT * 4))
D1=$(( (D1_A + D1_B) / 2 ))
if [ "$D1" -gt 20 ]; then D1=20; fi

# D2 Surface Health: surface density + co-evo health + low drift
# Surface density: surfaces / total_files × 1000 normalized to 0-8
# Avoids rewarding raw count (large repos get more surfaces regardless of health)
D2_SURF=0
if [ "$TOTAL_FILES" -gt 0 ] && [ "$SURFACE_COUNT" -gt 0 ]; then
    SURF_DENSITY=$((SURFACE_COUNT * 1000 / TOTAL_FILES))
    # Bands: ≥50‰ → 8, ≥30‰ → 6, ≥15‰ → 4, ≥5‰ → 2, <5‰ → 0
    if [ "$SURF_DENSITY" -ge 50 ]; then D2_SURF=8
    elif [ "$SURF_DENSITY" -ge 30 ]; then D2_SURF=6
    elif [ "$SURF_DENSITY" -ge 15 ]; then D2_SURF=4
    elif [ "$SURF_DENSITY" -ge 5 ]; then D2_SURF=2
    fi
fi
# Co-evo health: 0-6 (≥2.0 → 6, ≥1.0 → 4, ≥0.5 → 2, <0.5 → 0)
D2_COEVO=0
# Use integer comparison: multiply co-evo by 100
CO_EVO_INT=$(echo "$CO_EVO" | awk '{printf "%d", $1 * 100}')
if [ "$CO_EVO_INT" -ge 200 ]; then D2_COEVO=6
elif [ "$CO_EVO_INT" -ge 100 ]; then D2_COEVO=4
elif [ "$CO_EVO_INT" -ge 50 ]; then D2_COEVO=2
fi
# Drift health: 0-6 (0% → 6, ≤10% → 4, ≤20% → 2, >20% → 0)
D2_DRIFT=0
if [ "$DRIFT_PCT_RAW" -le 0 ] 2>/dev/null; then D2_DRIFT=6
elif [ "$DRIFT_PCT_RAW" -le 10 ] 2>/dev/null; then D2_DRIFT=4
elif [ "$DRIFT_PCT_RAW" -le 20 ] 2>/dev/null; then D2_DRIFT=2
fi
D2=$((D2_SURF + D2_COEVO + D2_DRIFT))
if [ "$D2" -gt 20 ]; then D2=20; fi

# D3 Skill Maturity: skill count + skill density (DNA_K) + velocity + organicity
# Skill count: 0-5 (≥20 → 5, ≥10 → 4, ≥5 → 3, ≥1 → 1, 0 → 0)
D3_COUNT=0
if [ "$SKILL_COUNT" -ge 20 ]; then D3_COUNT=5
elif [ "$SKILL_COUNT" -ge 10 ]; then D3_COUNT=4
elif [ "$SKILL_COUNT" -ge 5 ]; then D3_COUNT=3
elif [ "$SKILL_COUNT" -ge 1 ]; then D3_COUNT=1
fi
# Skill density (DNA_K): 0-5 (≥50 → 5, ≥20 → 4, ≥10 → 3, ≥1 → 1, 0 → 0)
D3_DENSITY=0
if [ "$DNA_K_INT" -ge 50 ]; then D3_DENSITY=5
elif [ "$DNA_K_INT" -ge 20 ]; then D3_DENSITY=4
elif [ "$DNA_K_INT" -ge 10 ]; then D3_DENSITY=3
elif [ "$DNA_K_INT" -ge 1 ]; then D3_DENSITY=1
fi
# Velocity: 0-5 (DNA_KV: 1.0 → 5, 0.5-0.9 → 3, 0.1-0.4 → 1, 0 → 0)
KV_INT=$(echo "$DNA_KV" | awk '{printf "%d", $1 * 10}')
D3_VEL=0
if [ "$KV_INT" -ge 10 ]; then D3_VEL=5
elif [ "$KV_INT" -ge 5 ]; then D3_VEL=3
elif [ "$KV_INT" -ge 1 ]; then D3_VEL=1
fi
# Organicity: 0-5 (DNA_AO: ≥0.8 → 5, ≥0.5 → 3, ≥0.1 → 1, 0 → 0)
AO_INT=$(echo "$DNA_AO" | awk '{printf "%d", $1 * 10}')
D3_ORG=0
if [ "$AO_INT" -ge 8 ]; then D3_ORG=5
elif [ "$AO_INT" -ge 5 ]; then D3_ORG=3
elif [ "$AO_INT" -ge 1 ]; then D3_ORG=1
fi
D3=$((D3_COUNT + D3_DENSITY + D3_VEL + D3_ORG))
if [ "$D3" -gt 20 ]; then D3=20; fi

# D4 Measurement: scoring tools + DNA scoring layers + audit depth + abstraction
# Scoring tools: 0-5 (≥20 → 5, ≥10 → 4, ≥5 → 3, ≥1 → 1, 0 → 0)
D4_SCORE=0
if [ "$SCORING_TOOLS" -ge 20 ]; then D4_SCORE=5
elif [ "$SCORING_TOOLS" -ge 10 ]; then D4_SCORE=4
elif [ "$SCORING_TOOLS" -ge 5 ]; then D4_SCORE=3
elif [ "$SCORING_TOOLS" -ge 1 ]; then D4_SCORE=1
fi
# DNA scoring layers: 0-5 (direct from DNA, cap at 5)
D4_SC=$DNA_SC_INT
if [ "$D4_SC" -gt 5 ]; then D4_SC=5; fi
# Audit depth: 0-5 (direct from DNA, cap at 5)
D4_AD=$DNA_AD_INT
if [ "$D4_AD" -gt 5 ]; then D4_AD=5; fi
# Abstraction: 0-5 (direct from DNA, cap at 5)
D4_AB=$DNA_AB_INT
if [ "$D4_AB" -gt 5 ]; then D4_AB=5; fi
D4=$((D4_SCORE + D4_SC + D4_AD + D4_AB))
if [ "$D4" -gt 20 ]; then D4=20; fi

# D5 Self-Improvement: inverted stall risk + trajectory + plan infra
# Inverted stall: 0-8 (100 - stall_score, scaled to 0-8)
D5_STALL=$(( (100 - STALL_SCORE) * 8 / 100 ))
if [ "$D5_STALL" -gt 8 ]; then D5_STALL=8; fi
if [ "$D5_STALL" -lt 0 ]; then D5_STALL=0; fi
# Trajectory: 0-6 (DNA trajectory / 100 × 6)
D5_TRAJ=$((DNA_TRAJECTORY_INT * 6 / 100))
if [ "$D5_TRAJ" -gt 6 ]; then D5_TRAJ=6; fi
# Plan infra: 0-6 (DNA_PI × 1.5, cap at 6)
D5_PI=$((DNA_PI_INT * 3 / 2))
if [ "$D5_PI" -gt 6 ]; then D5_PI=6; fi
# Spec-kit bonus: specs/*/spec.md count adds to plan infra (0-3 bonus pts)
D5_SPEC=0
SPEC_MD_COUNT=0
if [ -n "$REPO_PATH" ] && [ -d "$REPO_PATH/specs" ]; then
    SPEC_MD_COUNT=$(find "$REPO_PATH/specs" -maxdepth 3 -name 'spec.md' 2>/dev/null | wc -l | tr -d ' ') || SPEC_MD_COUNT=0
    if [ "$SPEC_MD_COUNT" -ge 5 ]; then D5_SPEC=3
    elif [ "$SPEC_MD_COUNT" -ge 3 ]; then D5_SPEC=2
    elif [ "$SPEC_MD_COUNT" -ge 1 ]; then D5_SPEC=1
    fi
fi
D5=$((D5_STALL + D5_TRAJ + D5_PI + D5_SPEC))
if [ "$D5" -gt 20 ]; then D5=20; fi

# Composite
COMPOSITE=$((D1 + D2 + D3 + D4 + D5))

# --- Tier 1 Checks (blocking) ---
T1_TOTAL=5
T1_PASSED=0
T1_FAILURES=""

# T1-DRIFT: drift_pct ≤ 30%
if [ "$DRIFT_PCT_RAW" -le 30 ] 2>/dev/null; then
    T1_PASSED=$((T1_PASSED + 1))
else
    T1_FAILURES="${T1_FAILURES}\"T1-DRIFT: drift ${DRIFT_PCT_RAW}% > 30%\","
fi

# T1-STALL: stall_risk ≤ 60
if [ "$STALL_SCORE" -le 60 ] 2>/dev/null; then
    T1_PASSED=$((T1_PASSED + 1))
else
    T1_FAILURES="${T1_FAILURES}\"T1-STALL: stall ${STALL_SCORE} > 60\","
fi

# T1-PHASE: phase ≥ 1
PHASE_NUM=$(grep "^PHASE:" "$DIR/maturity.txt" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1) || PHASE_NUM=0
if [ -z "$PHASE_NUM" ]; then PHASE_NUM=0; fi
if [ "$PHASE_NUM" -ge 1 ] 2>/dev/null; then
    T1_PASSED=$((T1_PASSED + 1))
else
    T1_FAILURES="${T1_FAILURES}\"T1-PHASE: phase ${PHASE_NUM} < 1\","
fi

# T1-FILES: total_files > 0
if [ "$TOTAL_FILES" -gt 0 ] 2>/dev/null; then
    T1_PASSED=$((T1_PASSED + 1))
else
    T1_FAILURES="${T1_FAILURES}\"T1-FILES: 0 files\","
fi

# T1-SURFACES: surface_count > 0
if [ "$SURFACE_COUNT" -gt 0 ] 2>/dev/null; then
    T1_PASSED=$((T1_PASSED + 1))
else
    T1_FAILURES="${T1_FAILURES}\"T1-SURFACES: 0 AI surfaces\","
fi

T1_FAILED=$((T1_TOTAL - T1_PASSED))
# Remove trailing comma from failures
T1_FAILURES=$(echo "$T1_FAILURES" | sed 's/,$//')

# --- Tier 2 Checks (warning) ---
T2_WARNINGS=""
T2_COUNT=0

# T2-GOV-LOW: D1 < 8
if [ "$D1" -lt 8 ]; then
    T2_WARNINGS="${T2_WARNINGS}\"T2-GOV-LOW: D1=${D1} < 8\","
    T2_COUNT=$((T2_COUNT + 1))
fi

# T2-SKILL-ZERO: skill_count = 0
if [ "$SKILL_COUNT" -eq 0 ] 2>/dev/null; then
    T2_WARNINGS="${T2_WARNINGS}\"T2-SKILL-ZERO: 0 skills\","
    T2_COUNT=$((T2_COUNT + 1))
fi

# T2-COEVO-LOW: co_evo < 0.5
CO_EVO_CHECK=$(echo "$CO_EVO" | awk '{printf "%d", $1 * 100}')
if [ "$CO_EVO_CHECK" -lt 50 ] 2>/dev/null; then
    T2_WARNINGS="${T2_WARNINGS}\"T2-COEVO-LOW: co_evo=${CO_EVO} < 0.5\","
    T2_COUNT=$((T2_COUNT + 1))
fi

# T2-NO-SCORING: scoring_tools = 0
if [ "$SCORING_TOOLS" -eq 0 ] 2>/dev/null; then
    T2_WARNINGS="${T2_WARNINGS}\"T2-NO-SCORING: 0 scoring tools\","
    T2_COUNT=$((T2_COUNT + 1))
fi

# T2-DENSITY-LOW: surface_density < 5‰
if [ "$TOTAL_FILES" -gt 0 ] && [ "$SURFACE_COUNT" -gt 0 ]; then
    SURF_DENS_CHECK=$((SURFACE_COUNT * 1000 / TOTAL_FILES))
    if [ "$SURF_DENS_CHECK" -lt 5 ]; then
        T2_WARNINGS="${T2_WARNINGS}\"T2-DENSITY-LOW: ${SURF_DENS_CHECK} permille < 5\","
        T2_COUNT=$((T2_COUNT + 1))
    fi
fi

# T2-NO-REVIEW: no reviewing-code-locally skill or make review target (DS-21, L102)
HAS_REVIEW_SKILL="no"
for scan_file in "$DIR/pre-scan/PRE_SCAN.md" "$DIR/pre-scan-log.txt" "$DIR/pre-scan/AI_SURFACES_FULL.md"; do
    if [ -f "$scan_file" ] 2>/dev/null; then
        if grep -qiE "reviewing-code-locally|code.review" "$scan_file" 2>/dev/null; then
            HAS_REVIEW_SKILL="yes"
            break
        fi
    fi
done
if [ "$HAS_REVIEW_SKILL" = "no" ]; then
    T2_WARNINGS="${T2_WARNINGS}\"T2-NO-REVIEW: no code review skill detected (L102)\","
    T2_COUNT=$((T2_COUNT + 1))
fi

# T2-NO-CRITIC: no adversarial critic agent or skill
HAS_CRITIC="no"
for scan_file in "$DIR/pre-scan/PRE_SCAN.md" "$DIR/pre-scan-log.txt" "$DIR/pre-scan/AI_SURFACES_FULL.md"; do
    if [ -f "$scan_file" ] 2>/dev/null; then
        if grep -qiE "critic|adversarial.*review|skeptic" "$scan_file" 2>/dev/null; then
            HAS_CRITIC="yes"
            break
        fi
    fi
done
if [ "$HAS_CRITIC" = "no" ]; then
    T2_WARNINGS="${T2_WARNINGS}\"T2-NO-CRITIC: no adversarial critic detected (L29)\","
    T2_COUNT=$((T2_COUNT + 1))
fi

# T2-THEATER: automation theater detected (DS-21) — capabilities exist but aren't used
# Only run if detect-automation-theater.sh exists (it's a companion tool)
THEATER_SCRIPT="$(cd "$(dirname "$0")" && pwd)/detect-automation-theater.sh"
if [ -f "$THEATER_SCRIPT" ]; then
    # Run theater detection on the original repo (infer from pre-scan-log.txt path references)
    REPO_PATH=""
    if [ -f "$DIR/maturity.txt" ]; then
        REPO_PATH=$(grep "^Path:" "$DIR/maturity.txt" | head -1 | sed 's/^Path: *//' | sed 's/ *$//')
    fi
    if [ -n "$REPO_PATH" ] && [ -d "$REPO_PATH" ]; then
        THEATER_SIGNALS=$(bash "$THEATER_SCRIPT" "$REPO_PATH" 2>/dev/null | grep "THEATER SIGNALS:" | grep -oE '[0-9]+' | head -1) || THEATER_SIGNALS=0
        if [ -z "$THEATER_SIGNALS" ]; then THEATER_SIGNALS=0; fi
        if [ "$THEATER_SIGNALS" -ge 2 ]; then
            T2_WARNINGS="${T2_WARNINGS}\"T2-THEATER: $THEATER_SIGNALS automation theater signals detected (DS-21, L102)\","
            T2_COUNT=$((T2_COUNT + 1))
        fi
    fi
fi

# T2-STALE-CONTENT: Content staleness detected (DS-31)
# Fail-closed: if detector script errors, count as warning (no stderr suppression)
STALENESS_SCRIPT="$(cd "$(dirname "$0")" && pwd)/detect-content-staleness.sh"
if [ -f "$STALENESS_SCRIPT" ]; then
    REPO_PATH_CS=""
    if [ -f "$DIR/maturity.txt" ]; then
        REPO_PATH_CS=$(grep "^Path:" "$DIR/maturity.txt" | head -1 | sed 's/^Path: *//' | sed 's/ *$//')
    fi
    if [ -n "$REPO_PATH_CS" ] && [ -d "$REPO_PATH_CS" ]; then
        STALENESS_OUTPUT=$(bash "$STALENESS_SCRIPT" "$REPO_PATH_CS" 2>&1) || true
        STALENESS_EXIT=$?
        STALE_COUNT=$(echo "$STALENESS_OUTPUT" | grep -oE 'FAIL: ([0-9]+)' | grep -oE '[0-9]+' | head -1) || true
        if [ -z "$STALE_COUNT" ]; then
            # Try alternate format: "FAIL (N stale"
            STALE_COUNT=$(echo "$STALENESS_OUTPUT" | grep -oE 'FAIL \([0-9]+' | grep -oE '[0-9]+' | head -1) || true
        fi
        if [ -z "$STALE_COUNT" ]; then STALE_COUNT=0; fi
        if [ "$STALENESS_EXIT" -ne 0 ] && [ "$STALE_COUNT" -eq 0 ]; then
            # Detector itself failed — fail closed (per C1 HIGH)
            T2_WARNINGS="${T2_WARNINGS}\"T2-STALE-CONTENT: detector error (exit $STALENESS_EXIT)\","
            T2_COUNT=$((T2_COUNT + 1))
        elif [ "$STALE_COUNT" -gt 0 ]; then
            T2_WARNINGS="${T2_WARNINGS}\"T2-STALE-CONTENT: ${STALE_COUNT} stale content assertions (DS-31)\","
            T2_COUNT=$((T2_COUNT + 1))
        fi
    fi
fi

# Remove trailing comma from warnings
T2_WARNINGS=$(echo "$T2_WARNINGS" | sed 's/,$//')

# --- Write score receipts ---
CONTEXT_MANIFEST_FILE="${CONTEXT_SCORE_MANIFEST:-$DIR/CONTEXT_SCORE_MANIFEST.json}"
CONTEXT_MANIFEST_BASENAME="$(basename "$CONTEXT_MANIFEST_FILE")"
AUDIT_CONTEXT_ID="${AUDIT_CONTEXT_ID:-standard}"
COMPARE_ORACLE_VERSION="${COMPARE_ORACLE_VERSION:-1.0.0}"
COUNT_RECON_NOTE_JSON=$(python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$COUNT_RECON_NOTE")

cat > "$DIR/SCORECARD_RECEIPTS.json" << EOF
{
  "meta": {
    "receipt_version": "1.0.0",
    "audit_context_id": "$AUDIT_CONTEXT_ID",
    "context_manifest": "$CONTEXT_MANIFEST_BASENAME",
    "compare_oracle_version": "$COMPARE_ORACLE_VERSION",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "count_reconciliation": {
    "status": "$COUNT_RECON_STATUS",
    "authoritative_total_files": $TOTAL_FILES,
    "pre_scan_total_files": $PRE_SCAN_TOTAL_FILES,
    "maturity_total_files": $MATURITY_TOTAL_FILES,
    "dna_total_files": $DNA_TOTAL_FILES,
    "note": $COUNT_RECON_NOTE_JSON,
    "denominator_semantics": {
      "name": "auditor_pruned_analysis_scorecard_denominator",
      "authoritative_total_files_meaning": "Files counted on the auditor-pruned analysis and scorecard surface.",
      "source": "pre-scan Total files, reconciled with maturity.txt and dna.txt totals",
      "count_behavior": "metadata-only; existing count behavior is preserved"
    },
    "excluded_path_classes": {
      "default_pruned_directories": [
        ".git",
        ".venv",
        "venv",
        "node_modules",
        ".tox",
        ".mypy_cache",
        "__pycache__",
        "vendor",
        ".eggs"
      ],
      "default_excluded_files": [
        ".DS_Store"
      ],
      "auditorignore": {
        "active": $AUDITORIGNORE_ACTIVE,
        "entry_count": $AUDITORIGNORE_ENTRY_COUNT,
        "entry_count_status": "$AUDITORIGNORE_ENTRY_COUNT_STATUS",
        "entries_emitted": false,
        "entry_values_source": "CONTEXT_SCORE_MANIFEST.json auditorignore.entries when that artifact is retained"
      }
    }
  },
  "dimensions": {
    "D3_skill_maturity": {
      "score": $D3,
      "fields": {
        "skill_count": {
          "raw": $SKILL_COUNT,
          "points": $D3_COUNT,
          "bands": ">=20 => 5, >=10 => 4, >=5 => 3, >=1 => 1"
        },
        "density": {
          "raw": $DNA_K_INT,
          "inputs": {
            "skill_count": $SKILL_COUNT,
            "total_files": $DNA_TOTAL_FILES
          },
          "points": $D3_DENSITY,
          "bands": ">=50 => 5, >=20 => 4, >=10 => 3, >=1 => 1"
        },
        "velocity": {
          "raw": $(echo "$DNA_KV" | awk '{printf "%.2f", $1 + 0}'),
          "points": $D3_VEL,
          "bands": ">=1.0 => 5, >=0.5 => 3, >=0.1 => 1"
        },
        "organicity": {
          "raw": $(echo "$DNA_AO" | awk '{printf "%.2f", $1 + 0}'),
          "points": $D3_ORG,
          "bands": ">=0.8 => 5, >=0.5 => 3, >=0.1 => 1"
        }
      }
    },
    "D4_measurement": {
      "score": $D4,
      "fields": {
        "scoring_tools": {
          "raw": $SCORING_TOOLS,
          "points": $D4_SCORE,
          "bands": ">=20 => 5, >=10 => 4, >=5 => 3, >=1 => 1"
        },
        "scoring_layers": {
          "raw": $DNA_SC_INT,
          "points": $D4_SC,
          "bands": "direct value capped at 5"
        },
        "audit_depth": {
          "raw": $DNA_AD_INT,
          "points": $D4_AD,
          "bands": "direct value capped at 5"
        },
        "abstraction": {
          "raw": $DNA_AB_INT,
          "points": $D4_AB,
          "bands": "direct value capped at 5"
        }
      }
    },
    "D5_self_improvement": {
      "score": $D5,
      "fields": {
        "stall_risk": {
          "raw": $STALL_SCORE,
          "points": $D5_STALL,
          "formula": "floor((100 - stall_risk) * 8 / 100)"
        },
        "trajectory": {
          "raw": $DNA_TRAJECTORY_INT,
          "points": $D5_TRAJ,
          "formula": "floor(trajectory * 6 / 100)"
        },
        "plan_infra": {
          "raw": $DNA_PI_INT,
          "points": $D5_PI,
          "formula": "floor(plan_infra * 3 / 2)"
        },
        "spec_bonus": {
          "raw": $D5_SPEC,
          "inputs": {
            "spec_md_count": $SPEC_MD_COUNT
          },
          "points": $D5_SPEC,
          "bands": ">=5 spec.md => 3, >=3 => 2, >=1 => 1"
        }
      }
    }
  },
  "receipt_integrity": {
    "status": "$([ "$COUNT_RECON_STATUS" = "aligned" ] && echo "pass" || echo "warning")",
    "required_terms_present": [
      "D3.skill_count",
      "D3.density",
      "D3.velocity",
      "D3.organicity",
      "D4.scoring_tools",
      "D4.scoring_layers",
      "D4.audit_depth",
      "D4.abstraction",
      "D5.stall_risk",
      "D5.trajectory",
      "D5.plan_infra",
      "D5.spec_bonus"
    ],
    "missing_terms": []
  }
}
EOF

# --- Write SCORECARD.json ---
cat > "$DIR/SCORECARD.json" << EOF
{
  "dimensions": {
    "D1_governance": { "score": $D1, "max": 20, "components": { "gov_count": $GOV_COUNT, "dna_G": $DNA_G_INT } },
    "D2_surface_health": { "score": $D2, "max": 20, "components": { "surfaces": $SURFACE_COUNT, "total_files": $TOTAL_FILES, "co_evo": $(echo "$CO_EVO" | awk '{printf "%.2f", $1 + 0}'), "drift_pct": $DRIFT_PCT_RAW } },
    "D3_skill_maturity": { "score": $D3, "max": 20, "components": { "skill_count": $SKILL_COUNT, "density": $DNA_K_INT, "velocity": $(echo "$DNA_KV" | awk '{printf "%.2f", $1 + 0}'), "organicity": $(echo "$DNA_AO" | awk '{printf "%.2f", $1 + 0}') } },
    "D4_measurement": { "score": $D4, "max": 20, "components": { "scoring_tools": $SCORING_TOOLS, "scoring_layers": $DNA_SC_INT, "audit_depth": $DNA_AD_INT, "abstraction": $DNA_AB_INT } },
    "D5_self_improvement": { "score": $D5, "max": 20, "components": { "stall_risk": $STALL_SCORE, "trajectory": $DNA_TRAJECTORY_INT, "plan_infra": $DNA_PI_INT, "spec_bonus": $D5_SPEC, "spec_md_count": $SPEC_MD_COUNT } }
  },
  "composite": $COMPOSITE,
  "max_composite": 100,
  "receipts": {
    "file": "SCORECARD_RECEIPTS.json",
    "version": "1.0.0",
    "count_reconciliation_status": "$COUNT_RECON_STATUS"
  },
  "tier1_checks": {
    "total": $T1_TOTAL,
    "passed": $T1_PASSED,
    "failed": $T1_FAILED,
    "failures": [${T1_FAILURES}]
  },
  "tier2_warnings": {
    "count": $T2_COUNT,
    "warnings": [${T2_WARNINGS}]
  },
  "meta": {
    "phase": "$(grep "^PHASE:" "$DIR/maturity.txt" 2>/dev/null | head -1 | sed 's/PHASE: *//' || echo "unknown")",
    "maturity_score": $DNA_MATURITY_INT,
    "agents": $AGENT_COUNT,
    "skills": $SKILL_COUNT,
    "context_id": "$AUDIT_CONTEXT_ID",
    "context_manifest": "$CONTEXT_MANIFEST_BASENAME",
    "compare_oracle_version": "$COMPARE_ORACLE_VERSION",
    "auditor_version": "2.2",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF

python3 - "$DIR/SCORECARD.json" "$DIR/SCORECARD_RECEIPTS.json" << 'PY'
import json
import sys

scorecard_path, receipts_path = sys.argv[1], sys.argv[2]
scorecard = json.load(open(scorecard_path))
receipts = json.load(open(receipts_path))

assert scorecard["dimensions"]["D5_self_improvement"]["components"]["spec_bonus"] >= 0
assert scorecard["dimensions"]["D5_self_improvement"]["components"]["spec_md_count"] >= 0
assert scorecard["meta"]["context_manifest"]
assert scorecard["receipts"]["file"] == "SCORECARD_RECEIPTS.json"

required_fields = {
    "D3_skill_maturity": ["skill_count", "density", "velocity", "organicity"],
    "D4_measurement": ["scoring_tools", "scoring_layers", "audit_depth", "abstraction"],
    "D5_self_improvement": ["stall_risk", "trajectory", "plan_infra", "spec_bonus"],
}
for dim, fields in required_fields.items():
    present = receipts["dimensions"][dim]["fields"]
    for field in fields:
        assert field in present, f"missing receipt field: {dim}.{field}"

assert receipts["count_reconciliation"]["authoritative_total_files"] >= 0
assert receipts["count_reconciliation"]["maturity_total_files"] >= 0
assert receipts["count_reconciliation"]["dna_total_files"] >= 0
recon = receipts["count_reconciliation"]
assert recon["denominator_semantics"]["name"] == "auditor_pruned_analysis_scorecard_denominator"
classes = recon["excluded_path_classes"]
for required_dir in [".git", ".venv", "venv", "node_modules", ".tox", ".mypy_cache", "__pycache__", "vendor", ".eggs"]:
    assert required_dir in classes["default_pruned_directories"]
assert ".DS_Store" in classes["default_excluded_files"]
assert isinstance(classes["auditorignore"]["active"], bool)
assert classes["auditorignore"]["entries_emitted"] is False
PY

# --- Print summary to stdout ---
echo "================================================================"
echo "Audit Dimension Scorecard"
echo "================================================================"
echo ""
echo "  D1 Governance:       $D1/20"
echo "  D2 Surface Health:   $D2/20"
echo "  D3 Skill Maturity:   $D3/20"
echo "  D4 Measurement:      $D4/20"
echo "  D5 Self-Improvement: $D5/20"
echo "  ─────────────────────────"
echo "  COMPOSITE:           $COMPOSITE/100"
echo ""
echo "  Tier 1 (blocking):   $T1_PASSED/$T1_TOTAL passed"
if [ "$T1_FAILED" -gt 0 ]; then
    echo "  ⚠️  T1 failures:     $T1_FAILURES"
fi
echo "  Tier 2 (warnings):   $T2_COUNT"
if [ "$T2_COUNT" -gt 0 ]; then
    echo "  📋 T2 warnings:     $T2_WARNINGS"
fi
echo ""
echo "  Written: $DIR/SCORECARD.json"
echo "  Receipts: $DIR/SCORECARD_RECEIPTS.json"
echo "================================================================"
