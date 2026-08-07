#!/usr/bin/env bash
# test-audit-deep-activation.sh — Prove the advertised deep caller without paid execution.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/repo-auditor-deep-activation.XXXXXX")

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

create_fixture_repo() {
    local repo_path="$1"

    mkdir -p "$repo_path/.agents/skills/reviewing-code-locally" \
        "$repo_path/.github/workflows" "$repo_path/specs/001-sample" \
        "$repo_path/scripts" "$repo_path/tests"

    cat > "$repo_path/AGENTS.md" <<'EOF'
# Fixture Agents

Use reviewing-code-locally before large changes.
EOF
    cat > "$repo_path/LEARNINGS.md" <<'EOF'
# Fixture Learnings

| ID | Learning | Source |
|---|---|---|
| L1 | Keep receipts machine-readable. | fixture |
EOF
    cat > "$repo_path/HYPOTHESES.md" <<'EOF'
# Fixture Hypotheses
EOF
    cat > "$repo_path/.agents/skills/reviewing-code-locally/SKILL.md" <<'EOF'
# reviewing-code-locally
EOF
    cat > "$repo_path/.github/workflows/ci.yml" <<'EOF'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
EOF
    cat > "$repo_path/specs/001-sample/spec.md" <<'EOF'
# Sample Spec
EOF
    cat > "$repo_path/scripts/score-demo.sh" <<'EOF'
#!/usr/bin/env bash
echo score
EOF
    cat > "$repo_path/tests/test-demo.sh" <<'EOF'
#!/usr/bin/env bash
echo test
EOF
    cat > "$repo_path/Makefile" <<'EOF'
review:
	@echo review
EOF
    chmod +x "$repo_path/scripts/score-demo.sh" "$repo_path/tests/test-demo.sh"

    (
        cd "$repo_path"
        git init -q
        git config user.name fixture
        git config user.email fixture@example.com
        git add .
        git commit -qm "fixture"
    )
}

write_stubs() {
    local bin_dir="$1"

    mkdir -p "$bin_dir"
    cat > "$bin_dir/timeout" <<'EOF'
#!/usr/bin/env bash
set -u

if [ "$#" -lt 2 ] || [ "$2" != "copilot" ]; then
    # The deep-caller fixture does not retest the independently covered
    # deterministic signature sweep that precedes deep dispatch.
    printf '{"ds_id":"fixture","fired":false}\n'
    exit 0
fi

limit="$1"
shift
printf 'timeout\t%s\t%s\n' "$limit" "$1" >> "$COPILOT_STUB_LOG"
"$@"
EOF
    cat > "$bin_dir/copilot" <<'EOF'
#!/usr/bin/env bash
set -u

model=""
prompt=""
allow_all="false"
no_ask_user="false"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --model)
            model="$2"
            shift 2
            ;;
        -p)
            prompt="$2"
            shift 2
            ;;
        --allow-all)
            allow_all="true"
            shift
            ;;
        --no-ask-user)
            no_ask_user="true"
            shift
            ;;
        *)
            echo "unexpected copilot argument: $1" >&2
            exit 64
            ;;
    esac
done

if IFS= read -r inherited_stdin; then
    echo "copilot inherited readable stdin: $inherited_stdin" >&2
    exit 91
fi

printf 'copilot\t%s\t%s\t%s\t%s\t%s\n' \
    "$model" "$prompt" "$allow_all" "$no_ask_user" "$PWD" >> "$COPILOT_STUB_LOG"

for domain in governance surface skill measurement improvement theater; do
    case "$prompt" in
        "Read .agents/${domain}-auditor.agent.md"*)
            if [ "${COPILOT_FAIL_DOMAIN:-}" = "$domain" ]; then
                exit 23
            fi
            printf '| severity | finding |\n|---|---|\n| LOW | %s fixture |\n' "$domain"
            exit 0
            ;;
    esac
done

case "$prompt" in
    "Read .agents/audit-synthesis.agent.md"*)
        if [ -n "${COPILOT_SYNTHESIS_OUTPUT+x}" ]; then
            printf '%s\n' "$COPILOT_SYNTHESIS_OUTPUT"
        else
            printf '{"total_findings":6,"findings_by_severity":{"HIGH":0}}\n'
        fi
        exit 0
        ;;
esac

echo "unexpected copilot prompt: $prompt" >&2
exit 65
EOF
    chmod +x "$bin_dir/timeout" "$bin_dir/copilot"
}

assert_success_calls() {
    local log_path="$1" target_path="$2" output_path="$3"

    python3 - "$log_path" "$target_path" "$output_path" "$REPO_ROOT" <<'PY'
import pathlib
import sys

log_path, target_path, output_path, repo_root = sys.argv[1:5]
rows = [line.split("\t") for line in pathlib.Path(log_path).read_text().splitlines()]
timeouts = [row for row in rows if row[0] == "timeout"]
calls = [row for row in rows if row[0] == "copilot"]
domains = ["governance", "surface", "skill", "measurement", "improvement", "theater"]

assert len(timeouts) == 7, timeouts
assert all(row[1:] == ["17", "copilot"] for row in timeouts), timeouts
assert len(calls) == 7, calls

for row, domain in zip(calls[:6], domains):
    expected_prompt = (
        f"Read .agents/{domain}-auditor.agent.md for instructions. "
        f"Audit the target repo at {target_path}. Write all findings to stdout "
        "in markdown table format."
    )
    assert row == [
        "copilot",
        "claude-sonnet-4.6",
        expected_prompt,
        "true",
        "true",
        repo_root,
    ], row

expected_synthesis = (
    "Read .agents/audit-synthesis.agent.md for instructions. Combine all domain "
    f"audit payloads in {output_path}/payloads/ into a unified deep audit summary. "
    "Write a JSON summary to stdout with total_findings and findings_by_severity."
)
assert calls[6] == [
    "copilot",
    "claude-opus-4.7",
    expected_synthesis,
    "true",
    "true",
    repo_root,
], calls[6]
PY
}

assert_receipt() {
    local output_path="$1" expected_status="$2" expected_exit="$3"
    local expected_failed_tool="${4:-}"

    python3 - "$output_path" "$expected_status" "$expected_exit" "$expected_failed_tool" <<'PY'
import json
import pathlib
import sys

output_path = pathlib.Path(sys.argv[1])
receipt = json.loads((output_path / "AUDIT_RUN_RECEIPT.json").read_text())
assert receipt["status"] == sys.argv[2], receipt
assert receipt["exit_code"] == int(sys.argv[3]), receipt
if sys.argv[4]:
    assert sys.argv[4] in receipt["failed_tools"], receipt
PY
}

TARGET="$TEST_ROOT/target"
STUB_BIN="$TEST_ROOT/bin"
SUCCESS_OUT="$TEST_ROOT/success-output"
FAIL_OUT="$TEST_ROOT/fail-output"
INVALID_OUT="$TEST_ROOT/invalid-synthesis-output"
MISSING_TIMEOUT_OUT="$TEST_ROOT/missing-timeout-output"
STALE_OUT="$TEST_ROOT/stale-output"
SUCCESS_LOG="$TEST_ROOT/success-calls.tsv"
FAIL_LOG="$TEST_ROOT/fail-calls.tsv"
INVALID_LOG="$TEST_ROOT/invalid-synthesis-calls.tsv"
MISSING_TIMEOUT_LOG="$TEST_ROOT/missing-timeout-calls.tsv"
STDIN_PAYLOAD="$TEST_ROOT/stdin-payload.txt"

create_fixture_repo "$TARGET"
write_stubs "$STUB_BIN"
printf 'stdin must not reach copilot\n' > "$STDIN_PAYLOAD"

set +e
theater_output=$(bash "$REPO_ROOT/scripts/detect-automation-theater.sh" "$TARGET" 2>&1)
set -e
if printf '%s\n' "$theater_output" | grep -q 'syntax error in expression'; then
    fail "zero-match theater count produced a multiline arithmetic error"
fi
printf '%s\n' "$theater_output" | grep -q 'in_log=0$' || \
    fail "zero-match theater count did not resolve to one numeric zero"

standard_dry=$(make -s -n -C "$REPO_ROOT" audit TARGET="$TARGET" OUTPUT_DIR="$TEST_ROOT/dry-standard")
deep_dry=$(make -s -n -C "$REPO_ROOT" audit-deep TARGET="$TARGET" OUTPUT_DIR="$TEST_ROOT/dry-deep")
if printf '%s\n' "$standard_dry" | grep -q -- '--mode deep'; then
    fail "standard target unexpectedly selects deep mode"
fi
printf '%s\n' "$deep_dry" | grep -q -- '--mode deep' || fail "deep target omits --mode deep"

mkdir -p "$STALE_OUT/payloads"
printf 'stale\n' > "$STALE_OUT/DEEP_FINDINGS.json"
for domain in governance surface skill measurement improvement theater; do
    printf 'stale\n' > "$STALE_OUT/payloads/${domain}.md"
done
set +e
bash "$REPO_ROOT/scripts/repo-auditor.sh" "$TEST_ROOT/missing-target" "$STALE_OUT" \
    --mode deep > "$TEST_ROOT/stale.out" 2>&1
stale_code=$?
set -e
if [ "$stale_code" -ne 2 ]; then
    fail "missing target returned $stale_code instead of 2"
fi
if [ -e "$STALE_OUT/DEEP_FINDINGS.json" ]; then
    fail "early failure left a stale synthesis receipt"
fi
for domain in governance surface skill measurement improvement theater; do
    if [ -e "$STALE_OUT/payloads/${domain}.md" ]; then
        fail "early failure left stale ${domain} payload"
    fi
done
assert_receipt "$STALE_OUT" "failed" "2" "target"

COPILOT_STUB_LOG="$SUCCESS_LOG" DEEP_TIMEOUT=17 PATH="$STUB_BIN:$PATH" \
    make -s -C "$REPO_ROOT" audit-deep TARGET="$TARGET" OUTPUT_DIR="$SUCCESS_OUT" \
    < "$STDIN_PAYLOAD" > "$TEST_ROOT/success.out" 2>&1

assert_success_calls "$SUCCESS_LOG" "$TARGET" "$SUCCESS_OUT"
assert_receipt "$SUCCESS_OUT" "completed" "0"
test -s "$SUCCESS_OUT/DEEP_FINDINGS.json" || fail "successful synthesis receipt is missing"
grep -q '## Deep Semantic Analysis' "$SUCCESS_OUT/AUDIT_REPORT.md" || \
    fail "deep summary is missing from report"

set +e
COPILOT_STUB_LOG="$FAIL_LOG" COPILOT_FAIL_DOMAIN=measurement \
    DEEP_TIMEOUT=17 PATH="$STUB_BIN:$PATH" make -s -C "$REPO_ROOT" audit-deep \
    TARGET="$TARGET" OUTPUT_DIR="$FAIL_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/fail.out" 2>&1
fail_code=$?
set -e

if [ "$fail_code" -eq 0 ]; then
    fail "domain failure unexpectedly produced a successful deep audit"
fi
if [ -e "$FAIL_OUT/DEEP_FINDINGS.json" ]; then
    fail "domain failure left a synthesis receipt"
fi
if grep -q $'^copilot\tclaude-opus-4.7\t' "$FAIL_LOG"; then
    fail "synthesis ran after a domain failure"
fi
grep -q 'synthesis] SKIPPED' "$TEST_ROOT/fail.out" || \
    fail "domain failure did not report fail-closed synthesis skip"
assert_receipt "$FAIL_OUT" "failed" "3" "deep-domain-measurement"

set +e
COPILOT_STUB_LOG="$INVALID_LOG" COPILOT_SYNTHESIS_OUTPUT='not-json' \
    DEEP_TIMEOUT=17 PATH="$STUB_BIN:$PATH" make -s -C "$REPO_ROOT" audit-deep \
    TARGET="$TARGET" OUTPUT_DIR="$INVALID_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/invalid-synthesis.out" 2>&1
invalid_code=$?
set -e

if [ "$invalid_code" -eq 0 ]; then
    fail "malformed synthesis output unexpectedly produced a successful deep audit"
fi
if [ -e "$INVALID_OUT/DEEP_FINDINGS.json" ]; then
    fail "malformed synthesis output left a synthesis receipt"
fi
grep -q $'^copilot\tclaude-opus-4.7\t' "$INVALID_LOG" || \
    fail "malformed synthesis regression did not reach synthesis"
grep -q 'synthesis] FAILED' "$TEST_ROOT/invalid-synthesis.out" || \
    fail "malformed synthesis output was not reported as failed"
assert_receipt "$INVALID_OUT" "failed" "3" "deep-synthesis"

set +e
(
    # Exported into repo-auditor.sh and invoked there via command -v.
    # shellcheck disable=SC2329
    command() {
        if [ "${0##*/}" = "repo-auditor.sh" ] && [ "${1:-}" = "-v" ] && \
            { [ "${2:-}" = "timeout" ] || [ "${2:-}" = "gtimeout" ]; }; then
            return 1
        fi
        builtin command "$@"
    }
    export -f command
    COPILOT_STUB_LOG="$MISSING_TIMEOUT_LOG" DEEP_TIMEOUT=17 PATH="$STUB_BIN:$PATH" \
        bash "$REPO_ROOT/scripts/repo-auditor.sh" "$TARGET" "$MISSING_TIMEOUT_OUT" \
        --mode deep < "$STDIN_PAYLOAD" > "$TEST_ROOT/missing-timeout.out" 2>&1
)
missing_timeout_code=$?
set -e

if [ "$missing_timeout_code" -eq 0 ]; then
    fail "missing timeout utility unexpectedly produced a successful deep audit"
fi
if [ -e "$MISSING_TIMEOUT_OUT/DEEP_FINDINGS.json" ]; then
    fail "missing timeout utility left a synthesis receipt"
fi
if [ -s "$MISSING_TIMEOUT_LOG" ]; then
    fail "copilot ran without an available timeout utility"
fi
grep -q 'deep mode requires timeout or gtimeout' "$TEST_ROOT/missing-timeout.out" || \
    fail "missing timeout utility did not report the fail-closed requirement"
assert_receipt "$MISSING_TIMEOUT_OUT" "failed" "3" "deep-timeout"

git -C "$TARGET" diff --quiet || fail "deep audit mutated the target worktree"
test -z "$(git -C "$TARGET" status --short)" || fail "deep audit dirtied the target worktree"

echo "PASS: audit-deep activation, caller controls, strict synthesis, timeout enforcement, stale cleanup, and fail-closed propagation"
