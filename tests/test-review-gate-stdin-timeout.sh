#!/usr/bin/env bash
# test-review-gate-stdin-timeout.sh — fail-closed local review hang regression.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/.agents/skills/reviewing-code-locally/scripts/local_review.sh"
TEST_ROOT="$REPO_ROOT/work/test-review-gate-stdin-timeout-$$"
FIXTURE_REPO="$TEST_ROOT/fixture"
FAKE_COPILOT="$TEST_ROOT/fake-copilot.sh"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

write_lines() {
    local target="$1"
    shift
    printf '%s\n' "$@" > "$target"
}

mkdir -p "$FIXTURE_REPO" "$TEST_ROOT/runtime"

write_lines "$FAKE_COPILOT" \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'if IFS= read -r -t 1 inherited_stdin; then' \
    '    echo "FAIL: fake copilot inherited readable stdin: ${inherited_stdin}" >&2' \
    '    exit 73' \
    'fi' \
    'case "${FAKE_COPILOT_MODE:-success}" in' \
    '    success)' \
    '        echo "LOW: fake review completed"' \
    '        exit 0' \
    '        ;;' \
    '    sleep)' \
    '        sleep 5' \
    '        echo "No findings."' \
    '        exit 0' \
    '        ;;' \
    '    *)' \
    '        echo "unknown fake mode" >&2' \
    '        exit 2' \
    '        ;;' \
    'esac'
chmod +x "$FAKE_COPILOT"

(
    cd "$FIXTURE_REPO"
    git init -q
    git config user.name "Fixture"
    git config user.email "fixture@example.com"
    write_lines sample.txt "before"
    git add sample.txt
    git commit -qm "fixture"
    write_lines sample.txt "after"
    git add sample.txt
)

write_lines "$TEST_ROOT/stdin-payload.txt" "stdin that must not reach copilot"

if ! (
    cd "$FIXTURE_REPO"
    COPILOT_BIN="$FAKE_COPILOT" \
        REVIEW_RUNTIME_DIR="$TEST_ROOT/runtime" \
        bash "$SCRIPT" < "$TEST_ROOT/stdin-payload.txt" > "$TEST_ROOT/stdin.out" 2>&1
); then
    cat "$TEST_ROOT/stdin.out" >&2
    fail "review should complete when parent stdin is readable because copilot stdin is suppressed"
fi
grep -q "LOW: fake review completed" "$TEST_ROOT/stdin.out" || fail "review should print fake copilot output"
if grep -q "inherited readable stdin" "$TEST_ROOT/stdin.out"; then
    cat "$TEST_ROOT/stdin.out" >&2
    fail "copilot child inherited readable stdin"
fi

set +e
(
    cd "$FIXTURE_REPO"
    COPILOT_BIN="$FAKE_COPILOT" \
        FAKE_COPILOT_MODE=sleep \
        REVIEW_RUNTIME_DIR="$TEST_ROOT/runtime" \
        REVIEW_TIMEOUT_SECONDS=1 \
        REVIEW_POLL_SECONDS=1 \
        bash "$SCRIPT" > "$TEST_ROOT/timeout.out" 2>&1
)
TIMEOUT_STATUS=$?
set -e

[ "$TIMEOUT_STATUS" -eq 124 ] || {
    cat "$TEST_ROOT/timeout.out" >&2
    fail "review timeout should exit 124, got $TIMEOUT_STATUS"
}
grep -q "ERROR: review timed out after 1s; failing closed." "$TEST_ROOT/timeout.out" || {
    cat "$TEST_ROOT/timeout.out" >&2
    fail "timeout output should name fail-closed review timeout"
}
if grep -q "Review complete." "$TEST_ROOT/timeout.out"; then
    cat "$TEST_ROOT/timeout.out" >&2
    fail "timeout path must not print success-shaped completion"
fi

echo "review gate stdin + timeout regression: PASS"
