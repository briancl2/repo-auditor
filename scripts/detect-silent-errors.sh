#!/usr/bin/env bash
# detect-silent-errors.sh — DS-39: Silent error handling detection
# Fires when >5 error suppression patterns in non-test source files.
# Prevention tier: T3 (advisory)
set -euo pipefail
REPO="${1:?Usage: detect-silent-errors.sh <repo_path>}"
THRESHOLD="${2:-5}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

count=0
evidence=""

# Count matches first (avoid storing massive results in variable)
# Note: 2>/dev/null excluded from patterns — too many false positives in shell scripts (E1 fix)
PATTERNS='catch\s*(\([^)]*\))?\s*\{\s*\}|except:\s*pass|\|\|\s*true|\|\|\s*:\s*$|rescue\s*=>\s*nil'
count=$(grep -rnE "$PATTERNS" "$REPO" \
    --include='*.sh' --include='*.py' --include='*.js' --include='*.ts' \
    --include='*.rb' --include='*.go' --include='*.java' \
    --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git \
    --exclude-dir='__pycache__' --exclude-dir='.venv' --exclude-dir='venv' \
    --exclude-dir='test' --exclude-dir='tests' --exclude-dir='spec' \
    2>/dev/null | wc -l | tr -d ' ') || count=0

# Only grab evidence if needed (small sample)
if [ "$count" -gt 0 ]; then
    evidence=$(grep -rnE "$PATTERNS" "$REPO" \
        --include='*.sh' --include='*.py' --include='*.js' --include='*.ts' \
        --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git \
        --exclude-dir='__pycache__' --exclude-dir='.venv' --exclude-dir='venv' \
        --exclude-dir='test' --exclude-dir='tests' --exclude-dir='spec' \
        2>/dev/null | head -3 | cut -c1-80 | tr '\n' '|' | head -c 250) || evidence=""
fi

fired="false"
[ "$count" -gt "$THRESHOLD" ] && fired="true"

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-39","name":"Silent error handling","severity":"MEDIUM","prevention_tier":"T3"}' \
    "fired=$fired" "count=$count" "threshold=$THRESHOLD" "evidence=$evidence"
