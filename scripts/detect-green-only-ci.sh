#!/usr/bin/env bash
# detect-green-only-ci.sh — DS-36: Green-only CI detection
# Fires when CI exists but has no failure handling or test commands.
# Prevention tier: T3 (advisory)
set -euo pipefail
REPO="${1:?Usage: detect-green-only-ci.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired="false"
has_ci="false"
ci_type="none"
failure_handling=0
test_commands=0
evidence=""

if [ -d "$REPO/.github/workflows" ]; then
    has_ci="true"; ci_type="github-actions"
elif [ -f "$REPO/.gitlab-ci.yml" ]; then
    has_ci="true"; ci_type="gitlab-ci"
elif [ -f "$REPO/.circleci/config.yml" ]; then
    has_ci="true"; ci_type="circleci"
fi

if [ "$has_ci" = "true" ]; then
    ci_dir="$REPO/.github/workflows"
    [ "$ci_type" = "gitlab-ci" ] && ci_dir="$REPO"
    [ "$ci_type" = "circleci" ] && ci_dir="$REPO/.circleci"

    failure_handling=$(grep -rE 'failure\(\)|on_failure|when: on_failure|if: failure|continue-on-error|allow_failure|fail-fast: false' \
        "$ci_dir" --include='*.yml' --include='*.yaml' 2>/dev/null | wc -l | tr -d ' ') || failure_handling=0

    test_commands=$(grep -rE 'pytest|npm test|make test|go test|cargo test|rspec|jest|mocha|unittest' \
        "$ci_dir" --include='*.yml' --include='*.yaml' 2>/dev/null | wc -l | tr -d ' ') || test_commands=0

    if [ "$failure_handling" -eq 0 ] && [ "$test_commands" -eq 0 ]; then
        fired="true"
        evidence="CI ($ci_type) with 0 failure handlers and 0 test commands"
    elif [ "$failure_handling" -eq 0 ]; then
        fired="true"
        evidence="CI ($ci_type) has test commands but 0 failure handlers"
    fi
fi

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-36","name":"Green-only CI","severity":"MEDIUM","prevention_tier":"T3"}' \
    "fired=$fired" "has_ci=$has_ci" "ci_type=$ci_type" \
    "failure_handling=$failure_handling" "test_commands=$test_commands" "evidence=$evidence"
