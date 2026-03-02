#!/usr/bin/env bash
# detect-stale-todos.sh — DS-34: Stale TODO/FIXME detection
# Fires when >10 TODO/FIXME markers exist in source files.
# Prevention tier: T3 (advisory)
set -euo pipefail
REPO="${1:?Usage: detect-stale-todos.sh <repo_path>}"
THRESHOLD="${2:-10}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

count=0
evidence=""
if [ -d "$REPO" ]; then
    results=$(grep -rn 'TODO\|FIXME' "$REPO" \
        --include='*.sh' --include='*.py' --include='*.js' --include='*.ts' \
        --include='*.rb' --include='*.go' --include='*.java' \
        --include='*.md' --include='*.yaml' --include='*.yml' \
        --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git \
        --exclude-dir=__pycache__ --exclude-dir='.venv' --exclude-dir='venv' \
        2>/dev/null) || true
    count=$(echo "$results" | grep -c . 2>/dev/null) || count=0
    if [ "$count" -gt 0 ]; then
        evidence=$(echo "$results" | head -5 | cut -c1-100 | tr '\n' '|' | head -c 400)
    fi
fi

fired="false"
[ "$count" -gt "$THRESHOLD" ] && fired="true"

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-34","name":"Stale TODO/FIXME","severity":"LOW","prevention_tier":"T3"}' \
    "fired=$fired" "count=$count" "threshold=$THRESHOLD" "evidence=$evidence"
