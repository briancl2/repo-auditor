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

if [ "${1:-}" = "--kill-after=1s" ]; then
    shift
fi
limit="${1%s}"
shift

if [ "$#" -ge 4 ] && [ "$1" = "bash" ] && [ "$2" = "-c" ] && \
    [ "$4" = "repo-auditor-copilot-child" ]; then
    printf 'timeout\t%s\tcopilot\n' "$limit" >> "$COPILOT_STUB_LOG"
    "$@"
    exit $?
fi

if [ "$#" -lt 1 ] || [ "$1" != "copilot" ]; then
    # The deep-caller fixture does not retest the independently covered
    # deterministic signature sweep that precedes deep dispatch.
    if [ -n "${STUB_PREDEEP_DELAY:-}" ] && \
        [ ! -e "${STUB_PREDEEP_DELAY_FILE:?}" ]; then
        : > "$STUB_PREDEEP_DELAY_FILE"
        sleep "$STUB_PREDEEP_DELAY"
    fi
    printf '{"ds_id":"fixture","fired":false}\n'
    exit 0
fi

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
            if [ "${COPILOT_SLEEP_DOMAIN:-}" = "$domain" ]; then
                sleep "${COPILOT_SLEEP_SECONDS:-10}"
            fi
            printf '| severity | finding |\n|---|---|\n| LOW | %s fixture |\n' "$domain"
            exit 0
            ;;
    esac
done

case "$prompt" in
    "Read .agents/audit-synthesis.agent.md"*)
        if [ -n "${COPILOT_SLEEP_SYNTHESIS:-}" ]; then
            sleep "${COPILOT_SLEEP_SECONDS:-10}"
        fi
        payload_dir="${prompt#*domain audit payloads in }"
        payload_dir="${payload_dir%% into a unified deep audit summary.*}"
        contract="$PWD/.agents/audit-synthesis.agent.md"
        read_count=0
        while IFS= read -r filename; do
            payload="$payload_dir/$filename"
            if [ ! -s "$payload" ]; then
                echo "synthesis contract input missing: $filename" >&2
                exit 66
            fi
            domain="${filename%-auditor.md}"
            if ! grep -q "| LOW | $domain fixture |" "$payload"; then
                echo "synthesis contract input invalid: $filename" >&2
                exit 67
            fi
            printf 'synthesis-read\t%s\n' "$filename" >> "$COPILOT_STUB_LOG"
            read_count=$((read_count + 1))
        done < <(sed -n 's/^- \([a-z-]*-auditor\.md\)$/\1/p' "$contract")
        if [ "$read_count" -ne 6 ]; then
            echo "synthesis contract named $read_count payloads instead of 6" >&2
            exit 68
        fi
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
reads = [row[1] for row in rows if row[0] == "synthesis-read"]
domains = ["governance", "surface", "skill", "measurement", "improvement", "theater"]

assert len(timeouts) == 7, timeouts
assert all(row[1:] == ["17", "copilot"] for row in timeouts), timeouts
assert len(calls) == 7, calls
assert reads == [f"{domain}-auditor.md" for domain in domains], reads

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
STANDARD_OUT="$TEST_ROOT/standard-reuse-output"
DEADLINE_OUT="$TEST_ROOT/deadline-output"
DOMAIN_DEADLINE_OUT="$TEST_ROOT/domain-deadline-output"
SYNTHESIS_DEADLINE_OUT="$TEST_ROOT/synthesis-deadline-output"
BAD_DEEP_TIMEOUT_OUT="$TEST_ROOT/bad-deep-timeout-output"
CLEANUP_STALL_OUT="$TEST_ROOT/cleanup-stall-output"
SUCCESS_LOG="$TEST_ROOT/success-calls.tsv"
FAIL_LOG="$TEST_ROOT/fail-calls.tsv"
INVALID_LOG="$TEST_ROOT/invalid-synthesis-calls.tsv"
MISSING_TIMEOUT_LOG="$TEST_ROOT/missing-timeout-calls.tsv"
DEADLINE_LOG="$TEST_ROOT/deadline-calls.tsv"
DOMAIN_DEADLINE_LOG="$TEST_ROOT/domain-deadline-calls.tsv"
SYNTHESIS_DEADLINE_LOG="$TEST_ROOT/synthesis-deadline-calls.tsv"
BAD_DEEP_TIMEOUT_LOG="$TEST_ROOT/bad-deep-timeout-calls.tsv"
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

COPILOT_STUB_LOG="$SUCCESS_LOG" DEEP_TIMEOUT=17 PATH="$STUB_BIN:$PATH" \
    make -s -C "$REPO_ROOT" audit-deep TARGET="$TARGET" OUTPUT_DIR="$SUCCESS_OUT" \
    < "$STDIN_PAYLOAD" > "$TEST_ROOT/success.out" 2>&1

assert_success_calls "$SUCCESS_LOG" "$TARGET" "$SUCCESS_OUT"
assert_receipt "$SUCCESS_OUT" "completed" "0"
test -s "$SUCCESS_OUT/DEEP_FINDINGS.json" || fail "successful synthesis receipt is missing"
grep -q '## Deep Semantic Analysis' "$SUCCESS_OUT/AUDIT_REPORT.md" || \
    fail "deep summary is missing from report"

mkdir -p "$STALE_OUT/payloads"
printf 'stale\n' > "$STALE_OUT/DEEP_FINDINGS.json"
for domain in governance surface skill measurement improvement theater; do
    printf 'stale\n' > "$STALE_OUT/payloads/${domain}.md"
    printf 'stale\n' > "$STALE_OUT/payloads/${domain}-auditor.md"
done
printf 'preserve\n' > "$STALE_OUT/payloads/owner-note.md"
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
    test ! -e "$STALE_OUT/payloads/${domain}.md" || \
        fail "early failure left stale legacy ${domain} payload"
    test ! -e "$STALE_OUT/payloads/${domain}-auditor.md" || \
        fail "early failure left stale canonical ${domain} payload"
done
test -e "$STALE_OUT/payloads/owner-note.md" || \
    fail "deep cleanup deleted unrelated owner output"
assert_receipt "$STALE_OUT" "failed" "2" "target"

mkdir -p "$STANDARD_OUT/payloads"
printf 'stale\n' > "$STANDARD_OUT/DEEP_FINDINGS.json"
for domain in governance surface skill measurement improvement theater; do
    printf 'stale\n' > "$STANDARD_OUT/payloads/${domain}.md"
    printf 'stale\n' > "$STANDARD_OUT/payloads/${domain}-auditor.md"
done
printf 'preserve\n' > "$STANDARD_OUT/payloads/owner-note.md"
PATH="$STUB_BIN:$PATH" make -s -C "$REPO_ROOT" audit \
    TARGET="$TARGET" OUTPUT_DIR="$STANDARD_OUT" > "$TEST_ROOT/standard.out" 2>&1
test ! -e "$STANDARD_OUT/DEEP_FINDINGS.json" || \
    fail "standard reuse left a stale synthesis artifact"
for domain in governance surface skill measurement improvement theater; do
    test ! -e "$STANDARD_OUT/payloads/${domain}.md" || \
        fail "standard reuse left stale legacy ${domain} payload"
    test ! -e "$STANDARD_OUT/payloads/${domain}-auditor.md" || \
        fail "standard reuse left stale canonical ${domain} payload"
done
test -e "$STANDARD_OUT/payloads/owner-note.md" || \
    fail "standard cleanup deleted unrelated owner output"
assert_receipt "$STANDARD_OUT" "completed" "0"

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

set +e
COPILOT_STUB_LOG="$DEADLINE_LOG" AUDIT_RUN_TIMEOUT=1 DEEP_TIMEOUT=17 \
    REPO_AUDITOR_DEADLINE_CHILD=1 \
    AUDIT_RUN_STARTED_AT=2099-01-01T00:00:00Z \
    AUDIT_RUN_STARTED_EPOCH=4102444800 \
    STUB_PREDEEP_DELAY=2 STUB_PREDEEP_DELAY_FILE="$TEST_ROOT/predeep-delay" \
    PATH="$STUB_BIN:$PATH" make -s -C "$REPO_ROOT" audit-deep \
    TARGET="$TARGET" OUTPUT_DIR="$DEADLINE_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/deadline.out" 2>&1
deadline_code=$?
set -e

if [ "$deadline_code" -eq 0 ]; then
    fail "expired whole-run deadline unexpectedly produced a successful deep audit"
fi
if [ -f "$DEADLINE_LOG" ] && grep -q $'^copilot\t' "$DEADLINE_LOG"; then
    fail "copilot ran after the whole-run deadline expired"
fi
grep -q 'whole-run deadline' "$TEST_ROOT/deadline.out" || \
    fail "whole-run deadline failure was not reported"
assert_receipt "$DEADLINE_OUT" "failed" "3" "deep-run-timeout"

ESCALATION_BIN="$TEST_ROOT/escalation-bin"
ESCALATION_OUT="$TEST_ROOT/escalation-output"
ESCALATION_LOG="$TEST_ROOT/escalation-calls.tsv"
ESCALATION_PID_FILE="$TEST_ROOT/term-ignoring-descendant.pid"
REAL_GIT="$(command -v git)"
mkdir -p "$ESCALATION_BIN"
ln -s "$STUB_BIN/copilot" "$ESCALATION_BIN/copilot"
cat > "$ESCALATION_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -u

if [ -n "${STUB_TERM_IGNORING_PID_FILE:-}" ] && \
    [ ! -e "${STUB_TERM_IGNORING_PID_FILE}.started" ]; then
    : > "${STUB_TERM_IGNORING_PID_FILE}.started"
    python3 - "$STUB_TERM_IGNORING_PID_FILE" <<'PY'
import os
import pathlib
import signal
import sys
import time

signal.signal(signal.SIGTERM, signal.SIG_IGN)
pathlib.Path(sys.argv[1]).write_text(f"{os.getpid()}\n")
while True:
    time.sleep(1)
PY
fi
exec "$STUB_REAL_GIT" "$@"
EOF
chmod +x "$ESCALATION_BIN/git"

set +e
COPILOT_STUB_LOG="$ESCALATION_LOG" AUDIT_RUN_TIMEOUT=10 \
    STUB_REAL_GIT="$REAL_GIT" \
    STUB_TERM_IGNORING_PID_FILE="$ESCALATION_PID_FILE" \
    PATH="$ESCALATION_BIN:$PATH" make -s -C "$REPO_ROOT" audit-deep \
    TARGET="$TARGET" OUTPUT_DIR="$ESCALATION_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/escalation.out" 2>&1
escalation_code=$?
set -e

if [ "$escalation_code" -eq 0 ]; then
    fail "TERM-ignoring descendant escaped the production whole-run deadline"
fi
test -s "$ESCALATION_PID_FILE" || \
    fail "TERM-ignoring descendant regression did not start its descendant"
escalation_pid="$(cat "$ESCALATION_PID_FILE")"
if kill -0 "$escalation_pid" 2>/dev/null; then
    fail "production timeout returned before reaping TERM-ignoring descendant $escalation_pid"
fi
assert_receipt "$ESCALATION_OUT" "failed" "3" "deep-run-timeout"

CLEANUP_STALL_BIN="$TEST_ROOT/cleanup-stall-bin"
mkdir -p "$CLEANUP_STALL_BIN"
cat > "$CLEANUP_STALL_BIN/ps" <<'EOF'
#!/usr/bin/env bash
sleep 5
exec /bin/ps "$@"
EOF
chmod +x "$CLEANUP_STALL_BIN/ps"

cleanup_stall_started="$(date '+%s')"
set +e
COPILOT_STUB_LOG="$TEST_ROOT/cleanup-stall-calls.tsv" AUDIT_RUN_TIMEOUT=1 \
    DEEP_TIMEOUT=17 STUB_PREDEEP_DELAY=5 \
    STUB_PREDEEP_DELAY_FILE="$TEST_ROOT/cleanup-stall-predeep-delay" \
    PATH="$CLEANUP_STALL_BIN:$STUB_BIN:$PATH" \
    make -s -C "$REPO_ROOT" audit-deep TARGET="$TARGET" \
    OUTPUT_DIR="$CLEANUP_STALL_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/cleanup-stall.out" 2>&1
cleanup_stall_code=$?
set -e
cleanup_stall_elapsed=$(( $(date '+%s') - cleanup_stall_started ))

if [ "$cleanup_stall_code" -eq 0 ]; then
    fail "stalled cleanup inspection unexpectedly produced a successful deep audit"
fi
if [ "$cleanup_stall_elapsed" -gt 3 ]; then
    fail "stalled cleanup inspection exceeded the bounded whole-run deadline"
fi
grep -q 'could not verify zero descendants' "$TEST_ROOT/cleanup-stall.out" || \
    fail "stalled cleanup inspection did not report its distinct failure"
assert_receipt "$CLEANUP_STALL_OUT" "failed" "3" \
    "deep-run-timeout-cleanup"

set +e
COPILOT_STUB_LOG="$DOMAIN_DEADLINE_LOG" AUDIT_RUN_TIMEOUT=10 DEEP_TIMEOUT=17 \
    COPILOT_SLEEP_DOMAIN=governance COPILOT_SLEEP_SECONDS=20 PATH="$STUB_BIN:$PATH" \
    make -s -C "$REPO_ROOT" audit-deep TARGET="$TARGET" \
    OUTPUT_DIR="$DOMAIN_DEADLINE_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/domain-deadline.out" 2>&1
domain_deadline_code=$?
set -e

if [ "$domain_deadline_code" -eq 0 ]; then
    fail "in-flight domain call escaped the whole-run deadline"
fi
grep -q $'^copilot\tclaude-sonnet-4.6\t' "$DOMAIN_DEADLINE_LOG" || \
    fail "domain deadline regression did not reach a domain call"
test ! -e "$DOMAIN_DEADLINE_OUT/DEEP_FINDINGS.json" || \
    fail "domain deadline left a synthesis artifact"
assert_receipt "$DOMAIN_DEADLINE_OUT" "failed" "3" "deep-run-timeout"

set +e
COPILOT_STUB_LOG="$SYNTHESIS_DEADLINE_LOG" AUDIT_RUN_TIMEOUT=20 DEEP_TIMEOUT=17 \
    COPILOT_SLEEP_SYNTHESIS=1 COPILOT_SLEEP_SECONDS=30 PATH="$STUB_BIN:$PATH" \
    make -s -C "$REPO_ROOT" audit-deep TARGET="$TARGET" \
    OUTPUT_DIR="$SYNTHESIS_DEADLINE_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/synthesis-deadline.out" 2>&1
synthesis_deadline_code=$?
set -e

if [ "$synthesis_deadline_code" -eq 0 ]; then
    fail "in-flight synthesis call escaped the whole-run deadline"
fi
if ! grep -q $'^copilot\tclaude-opus-4.7\t' "$SYNTHESIS_DEADLINE_LOG"; then
    sed -n '1,160p' "$TEST_ROOT/synthesis-deadline.out" >&2
    fail "synthesis deadline regression did not reach synthesis"
fi
test ! -e "$SYNTHESIS_DEADLINE_OUT/DEEP_FINDINGS.json" || \
    fail "synthesis deadline left a synthesis artifact"
assert_receipt "$SYNTHESIS_DEADLINE_OUT" "failed" "3" "deep-run-timeout"

set +e
COPILOT_STUB_LOG="$BAD_DEEP_TIMEOUT_LOG" DEEP_TIMEOUT=99999999999999999999 \
    PATH="$STUB_BIN:$PATH" make -s -C "$REPO_ROOT" audit-deep \
    TARGET="$TARGET" OUTPUT_DIR="$BAD_DEEP_TIMEOUT_OUT" < "$STDIN_PAYLOAD" \
    > "$TEST_ROOT/bad-deep-timeout.out" 2>&1
bad_deep_timeout_code=$?
set -e

if [ "$bad_deep_timeout_code" -eq 0 ]; then
    fail "oversized DEEP_TIMEOUT unexpectedly produced a successful deep audit"
fi
if [ -f "$BAD_DEEP_TIMEOUT_LOG" ] && \
    grep -q $'^copilot\t' "$BAD_DEEP_TIMEOUT_LOG"; then
    fail "copilot ran with an oversized DEEP_TIMEOUT"
fi
assert_receipt "$BAD_DEEP_TIMEOUT_OUT" "failed" "3" "deep-timeout"

set +e
AUDIT_RUN_TIMEOUT=99999999999999999999 PATH="$STUB_BIN:$PATH" \
    bash "$REPO_ROOT/scripts/repo-auditor.sh" "$TARGET" \
    "$TEST_ROOT/bad-run-timeout-output" --mode deep \
    > "$TEST_ROOT/bad-run-timeout.out" 2>&1
bad_run_timeout_code=$?
set -e
if [ "$bad_run_timeout_code" -eq 0 ]; then
    fail "oversized AUDIT_RUN_TIMEOUT unexpectedly passed validation"
fi
grep -q 'AUDIT_RUN_TIMEOUT must be an integer from 1 to 900' \
    "$TEST_ROOT/bad-run-timeout.out" || \
    fail "oversized AUDIT_RUN_TIMEOUT did not fail closed before arithmetic"

git -C "$TARGET" diff --quiet || fail "deep audit mutated the target worktree"
test -z "$(git -C "$TARGET" status --short)" || fail "deep audit dirtied the target worktree"

echo "PASS: audit-deep activation, caller controls, strict synthesis, timeout enforcement, stale cleanup, and fail-closed propagation"
