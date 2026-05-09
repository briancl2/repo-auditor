#!/bin/bash
# local_review.sh — Review staged git changes via Copilot CLI
#
# Usage: bash .agents/skills/reviewing-code-locally/scripts/local_review.sh
#   or:  make review
#
# Reads staged diff, gathers full file context, substitutes into the review
# prompt template, and passes to copilot -p for review.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_TEMPLATE="$SKILL_DIR/references/review-prompt.md"
COPILOT_BIN="${COPILOT_BIN:-/opt/homebrew/bin/copilot}"
REVIEW_TIMEOUT_SECONDS="${REVIEW_TIMEOUT_SECONDS:-900}"
REVIEW_POLL_SECONDS="${REVIEW_POLL_SECONDS:-1}"

if [ ! -x "$COPILOT_BIN" ]; then
    COPILOT_BIN="$(command -v copilot || true)"
fi

if [ -z "$COPILOT_BIN" ]; then
    echo "ERROR: copilot executable not found. Set COPILOT_BIN to the full path."
    exit 1
fi

case "$REVIEW_TIMEOUT_SECONDS" in
    ''|*[!0-9]*)
        echo "ERROR: REVIEW_TIMEOUT_SECONDS must be a positive integer."
        exit 1
        ;;
esac

if [ "$REVIEW_TIMEOUT_SECONDS" -lt 1 ]; then
    echo "ERROR: REVIEW_TIMEOUT_SECONDS must be at least 1."
    exit 1
fi

case "$REVIEW_POLL_SECONDS" in
    ''|*[!0-9]*)
        echo "ERROR: REVIEW_POLL_SECONDS must be a positive integer."
        exit 1
        ;;
esac

if [ "$REVIEW_POLL_SECONDS" -lt 1 ]; then
    echo "ERROR: REVIEW_POLL_SECONDS must be at least 1."
    exit 1
fi

# Verify prompt template exists
if [ ! -f "$PROMPT_TEMPLATE" ]; then
    echo "ERROR: Review prompt template not found at $PROMPT_TEMPLATE"
    exit 1
fi

# Get staged diff
DIFF=$(git diff --cached)

if [ -z "$DIFF" ]; then
    echo "Nothing staged. Run 'git add <files>' first."
    exit 1
fi

# Gather full file context for each changed file (up to 500 lines each)
FILE_CONTEXT=""
while IFS= read -r file; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file" | tr -d ' ')
        if [ "$LINES" -le 500 ]; then
            FILE_CONTEXT="${FILE_CONTEXT}

### ${file}

\`\`\`
$(cat "$file")
\`\`\`
"
        else
            FILE_CONTEXT="${FILE_CONTEXT}

### ${file} (${LINES} lines — skipped, exceeds 500-line limit)
"
        fi
    fi
done < <(git diff --cached --name-only)

# Build the prompt by reading template and replacing placeholders
# We split the template at the placeholders and concatenate with actual content
PROMPT_BEFORE_DIFF=$(sed -n '1,/{{DIFF}}/p' "$PROMPT_TEMPLATE" | sed '$d')
PROMPT_BETWEEN=$(sed -n '/{{DIFF}}/,/{{FILE_CONTEXT}}/p' "$PROMPT_TEMPLATE" | sed '1d;$d')
PROMPT_AFTER=$(sed -n '/{{FILE_CONTEXT}}/,$p' "$PROMPT_TEMPLATE" | sed '1d')

PROMPT="${PROMPT_BEFORE_DIFF}
${DIFF}
${PROMPT_BETWEEN}
${FILE_CONTEXT}
${PROMPT_AFTER}"

# Check prompt size (macOS ARG_MAX is ~1MB)
PROMPT_SIZE=${#PROMPT}
if [ "$PROMPT_SIZE" -gt 500000 ]; then
    echo "WARNING: Prompt is ${PROMPT_SIZE} bytes (>500KB). May exceed ARG_MAX."
    echo "Consider staging fewer files or reviewing in batches."
    exit 1
fi

review_process_state() {
    local pid="$1"
    ps -p "$pid" -o state= 2>/dev/null | tr -d ' ' || true
}

collect_review_pids() {
    local root_pid="$1"
    local child_pid

    if command -v pgrep > /dev/null 2>&1; then
        for child_pid in $(pgrep -P "$root_pid" 2>/dev/null || true); do
            collect_review_pids "$child_pid"
        done
    fi
    echo "$root_pid"
}

kill_review_tree() {
    local signal="$1"
    local root_pid="$2"
    local pids

    pids=$(collect_review_pids "$root_pid" | sort -rn | tr '\n' ' ')
    if [ -n "$pids" ]; then
        # shellcheck disable=SC2086
        kill "-$signal" $pids 2>/dev/null || true
    fi
}

run_copilot_review() {
    local runtime_dir output_file pid start_ts now_ts elapsed state status

    runtime_dir="${REVIEW_RUNTIME_DIR:-work/local-review-runtime}"
    mkdir -p "$runtime_dir"
    output_file="$runtime_dir/review-output-$$.txt"
    : > "$output_file"

    "$COPILOT_BIN" -p "$PROMPT" --no-color -s < /dev/null > "$output_file" 2>&1 &
    pid=$!
    start_ts=$(date +%s)

    while :; do
        state=$(review_process_state "$pid")
        case "$state" in
            ""|*Z*) break ;;
        esac

        now_ts=$(date +%s)
        elapsed=$((now_ts - start_ts))
        if [ "$elapsed" -ge "$REVIEW_TIMEOUT_SECONDS" ]; then
            kill_review_tree TERM "$pid"
            sleep 1
            state=$(review_process_state "$pid")
            case "$state" in
                ""|*Z*) ;;
                *) kill_review_tree KILL "$pid" ;;
            esac
            wait "$pid" 2>/dev/null || true
            cat "$output_file"
            rm -f "$output_file"
            echo "ERROR: review timed out after ${REVIEW_TIMEOUT_SECONDS}s; failing closed." >&2
            return 124
        fi

        sleep "$REVIEW_POLL_SECONDS"
    done

    set +e
    wait "$pid"
    status=$?
    set -e
    cat "$output_file"
    rm -f "$output_file"
    return "$status"
}

# Run review
echo "Reviewing $(git diff --cached --name-only | wc -l | tr -d ' ') staged file(s)..."
echo ""

run_copilot_review

echo ""
echo "Review complete."
