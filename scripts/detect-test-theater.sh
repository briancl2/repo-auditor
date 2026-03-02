#!/usr/bin/env bash
# detect-test-theater.sh — DS-41: Test theater detection
# Fires when test files exist but no test runner in CI or Makefile.
# Prevention tier: T2 (CI fix skill)
set -euo pipefail
REPO="${1:?Usage: detect-test-theater.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired="false"
has_tests="false"
has_runner_ci="false"
has_runner_make="false"
test_file_count=0
evidence=""

test_files=$(find "$REPO" \( -path "*/tests/*" -o -path "*/test/*" -o -path "*/spec/*" \) \
    -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \
    -o -name "*.rb" -o -name "*.go" -o -name "*_test.*" -o -name "test_*" \
    -o -name "*_spec.*" -o -name "*.test.*" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" \
    2>/dev/null) || true

if [ -n "$test_files" ]; then
    test_file_count=$(echo "$test_files" | wc -l | tr -d ' ')
    [ "$test_file_count" -gt 0 ] && has_tests="true"
fi

# Check CI for test runner
if [ -d "$REPO/.github/workflows" ]; then
    ci_tests=$(grep -rlE 'pytest|npm test|make test|go test|cargo test|rspec|jest|mocha|unittest|phpunit' \
        "$REPO/.github/workflows/" 2>/dev/null | wc -l | tr -d ' ') || ci_tests=0
    [ "$ci_tests" -gt 0 ] && has_runner_ci="true"
elif [ -f "$REPO/.gitlab-ci.yml" ]; then
    grep -qE 'pytest|npm test|make test|go test' "$REPO/.gitlab-ci.yml" 2>/dev/null && has_runner_ci="true"
fi

# Check Makefile for test target
if [ -f "$REPO/Makefile" ]; then
    grep -qE '^test[[:space:]]*:|^test-|^check[[:space:]]*:' "$REPO/Makefile" 2>/dev/null && has_runner_make="true"
fi

if [ "$has_tests" = "true" ] && [ "$has_runner_ci" = "false" ] && [ "$has_runner_make" = "false" ]; then
    fired="true"
    evidence="$test_file_count test files but no runner in CI or Makefile"
fi

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-41","name":"Test theater","severity":"HIGH","prevention_tier":"T2"}' \
    "fired=$fired" "has_tests=$has_tests" "test_file_count=$test_file_count" \
    "has_runner_ci=$has_runner_ci" "has_runner_make=$has_runner_make" "evidence=$evidence"
