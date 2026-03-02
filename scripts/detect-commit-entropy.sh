#!/usr/bin/env bash
# detect-commit-entropy.sh — DS-40: Commit message entropy detection
# Fires when no commit convention evidence exists.
# Without .git: checks for convention config, hooks, docs.
# Prevention tier: T3 (advisory)
set -euo pipefail
REPO="${1:?Usage: detect-commit-entropy.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired="false"
has_git="false"
conventional_pct=0
trailer_pct=0
issue_ref_pct=0
evidence=""

if [ -d "$REPO/.git" ]; then
    has_git="true"
    total=$(git -C "$REPO" log --oneline -50 2>/dev/null | wc -l | tr -d ' ') || total=0
    if [ "$total" -gt 0 ]; then
        conventional=$(git -C "$REPO" log --oneline -50 2>/dev/null | \
            grep -cE '^[0-9a-f]+ (feat|fix|chore|docs|style|refactor|test|build|ci|perf|revert)(\(.+\))?:' 2>/dev/null) || conventional=0
        conventional_pct=$((conventional * 100 / total))
        trailer=$(git -C "$REPO" log --format='%B' -50 2>/dev/null | \
            grep -cE '^[A-Z][a-zA-Z-]+: ' 2>/dev/null) || trailer=0
        trailer_pct=$((trailer * 100 / total))
        issue_ref=$(git -C "$REPO" log --oneline -50 2>/dev/null | \
            grep -cE '#[0-9]+' 2>/dev/null) || issue_ref=0
        issue_ref_pct=$((issue_ref * 100 / total))
        if [ "$conventional_pct" -lt 10 ] && [ "$trailer_pct" -lt 10 ] && [ "$issue_ref_pct" -lt 10 ]; then
            fired="true"
            evidence="${total} commits: ${conventional_pct}% conventional, ${trailer_pct}% trailers, ${issue_ref_pct}% issue refs"
        fi
    fi
else
    # No git — check for convention evidence in repo files
    has_convention="false"
    [ -f "$REPO/scripts/commit-msg-hook.sh" ] && has_convention="true"
    [ -f "$REPO/.commitlintrc" ] || [ -f "$REPO/.commitlintrc.js" ] || [ -f "$REPO/commitlint.config.js" ] && has_convention="true"
    [ -f "$REPO/.husky/commit-msg" ] && has_convention="true"
    if [ -f "$REPO/Makefile" ]; then
        grep -qE 'commit-msg|install-hooks' "$REPO/Makefile" 2>/dev/null && has_convention="true"
    fi
    for f in CONTRIBUTING.md CHANGELOG.md; do
        [ -f "$REPO/$f" ] && grep -qiE 'conventional|commit.*format|feat:|fix:' "$REPO/$f" 2>/dev/null && has_convention="true"
    done
    # Check for Spec-ID or similar trailers in any committed docs
    if grep -rqE 'Spec-ID:|Spec-Exempt:|Signed-off-by:' "$REPO" --include='*.md' 2>/dev/null; then
        has_convention="true"
    fi
    if [ "$has_convention" = "false" ]; then
        fired="true"
        evidence="No .git; no commit convention config/hooks/docs found"
    fi
fi

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-40","name":"Commit message entropy","severity":"LOW","prevention_tier":"T3"}' \
    "fired=$fired" "has_git=$has_git" "conventional_pct=$conventional_pct" \
    "trailer_pct=$trailer_pct" "issue_ref_pct=$issue_ref_pct" "evidence=$evidence"
