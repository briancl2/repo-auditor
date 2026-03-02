#!/usr/bin/env bash
# detect-velocity-bypass.sh — DS-43: Autonomous velocity bypass detection
# Fires when a repo has evidence of code-change work contracts with 0 review/critique artifacts.
# Pattern: agent skips review/critique/hypothesis gates when given velocity-scoped instructions.
# Detectable: work/ dirs with code files staged + no review-receipt.json + unfilled hypothesis in WORK.md.
# Prevention tier: T2 (agent-enforced via flywheel agent rules)
# Source: L323 (v132 RCA), backtest: v129-v131 had latent P7 VIOLATE in 4 contracts.
set -euo pipefail
REPO="${1:?Usage: detect-velocity-bypass.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired="false"
bypass_count=0
total_work_contracts=0
evidence=""

# DS-43 requires work/ directory (repo-agent operating model pattern)
if [ ! -d "$REPO/work" ]; then
    # No work contracts — DS not applicable
    python3 "$SCRIPT_DIR/ds_json_helper.py" \
        '{"ds_id":"DS-43","name":"Autonomous velocity bypass","severity":"HIGH","prevention_tier":"T2"}' \
        "fired=false" "bypass_count=0" "total_work_contracts=0" \
        "evidence=No work/ directory found - DS not applicable"
    exit 0
fi

# Scan work directories for velocity bypass pattern
for work_dir in "$REPO"/work/*/; do
    [ -d "$work_dir" ] || continue
    [ -f "$work_dir/WORK.md" ] || continue
    total_work_contracts=$((total_work_contracts + 1))

    # Check if this is a code-change work contract
    is_code_change="false"

    # Method 1: WORK.md declares work type
    if grep -qiE 'work type.*code-change|work type.*cross-repo|work type.*bug-fix' "$work_dir/WORK.md" 2>/dev/null; then
        is_code_change="true"
    fi

    # Method 2: Evidence of code files in git log since contract opened
    # (check if .sh/.py/.js/.ts files are mentioned in WORK.md or associated commits)
    if grep -rqlE '\.(sh|py|js|ts)' "$work_dir" --include='*.md' 2>/dev/null; then
        is_code_change="true"
    fi

    # Method 3: Check ser-summary.json for work_type
    if [ -f "$work_dir/ser-summary.json" ]; then
        wt=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('work_type',''))" "$work_dir/ser-summary.json" 2>/dev/null) || wt=""
        case "$wt" in
            code-change|cross-repo|bug-fix) is_code_change="true" ;;
        esac
    fi

    if [ "$is_code_change" = "false" ]; then
        continue
    fi

    # Check for review evidence
    has_review="false"
    [ -f "$work_dir/review-receipt.json" ] && has_review="true"
    # Also check commit messages for Review-Status
    if grep -qE 'Review-Status:|make review' "$work_dir/WORK.md" 2>/dev/null; then
        has_review="true"
    fi

    # Check for critique evidence
    has_critique="false"
    for f in "$work_dir"/critique-*.txt "$work_dir"/critique-*.md; do
        [ -f "$f" ] && has_critique="true" && break
    done

    # Check for filled hypothesis
    has_hypothesis="true"
    if grep -qE '\{what you expect|Prediction.*\{|PASS.*\{|FAIL.*\{' "$work_dir/WORK.md" 2>/dev/null; then
        has_hypothesis="false"
    fi

    # Velocity bypass: code-change + missing review + missing critique + unfilled hypothesis
    # Fire if ANY two of three are missing
    missing=0
    [ "$has_review" = "false" ] && missing=$((missing + 1))
    [ "$has_critique" = "false" ] && missing=$((missing + 1))
    [ "$has_hypothesis" = "false" ] && missing=$((missing + 1))

    if [ "$missing" -ge 2 ]; then
        bypass_count=$((bypass_count + 1))
        dir_name=$(basename "$work_dir")
        evidence="${evidence}${dir_name}: review=${has_review} critique=${has_critique} hypothesis=${has_hypothesis}; "
    fi
done

if [ "$bypass_count" -gt 0 ]; then
    fired="true"
    evidence="$bypass_count/$total_work_contracts code-change contracts with velocity bypass: ${evidence}"
fi

# Truncate evidence to 500 chars for JSON safety
evidence="${evidence:0:500}"

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-43","name":"Autonomous velocity bypass","severity":"HIGH","prevention_tier":"T2"}' \
    "fired=$fired" "bypass_count=$bypass_count" \
    "total_work_contracts=$total_work_contracts" \
    "evidence=$evidence"
