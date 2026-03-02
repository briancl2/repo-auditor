#!/usr/bin/env bash
# detect-readme-drift.sh — DS-37: README capability drift detection
# Fires when README references files/targets that don't exist.
# Prevention tier: T3 (advisory)
set -euo pipefail
REPO="${1:?Usage: detect-readme-drift.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired="false"
total_claims=0
broken_claims=0
evidence=""

if [ ! -f "$REPO/README.md" ]; then
    python3 "$SCRIPT_DIR/ds_json_helper.py" \
        '{"ds_id":"DS-37","name":"README capability drift","severity":"MEDIUM","prevention_tier":"T3"}' \
        "fired=false" "total_claims=0" "broken_claims=0" "evidence=No README.md"
    exit 0
fi

# Check Makefile target references
if [ -f "$REPO/Makefile" ]; then
    readme_targets=$(grep -oE 'make [a-zA-Z_-]+' "$REPO/README.md" 2>/dev/null | sed 's/make //' | sort -u) || true
    actual_targets=$(grep -oE '^[a-zA-Z_-]+:' "$REPO/Makefile" 2>/dev/null | sed 's/://' | sort -u) || true
    while IFS= read -r target; do
        [ -z "$target" ] && continue
        total_claims=$((total_claims + 1))
        if ! echo "$actual_targets" | grep -qx "$target" 2>/dev/null; then
            broken_claims=$((broken_claims + 1))
            evidence="${evidence}make $target missing; "
        fi
    done <<< "$readme_targets"
fi

# Check script path references
script_refs=$(grep -oE '(scripts|bin)/[a-zA-Z0-9_./-]+\.(sh|py|js|ts)' "$REPO/README.md" 2>/dev/null | sort -u) || true
while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    total_claims=$((total_claims + 1))
    if [ ! -f "$REPO/$ref" ]; then
        broken_claims=$((broken_claims + 1))
        evidence="${evidence}${ref} missing; "
    fi
done <<< "$script_refs"

# Fire if >=2 broken AND >=20% broken
if [ "$total_claims" -gt 0 ] && [ "$broken_claims" -ge 2 ]; then
    pct=$((broken_claims * 100 / total_claims))
    [ "$pct" -ge 20 ] && fired="true"
fi

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-37","name":"README capability drift","severity":"MEDIUM","prevention_tier":"T3"}' \
    "fired=$fired" "total_claims=$total_claims" "broken_claims=$broken_claims" "evidence=$evidence"
