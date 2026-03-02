#!/usr/bin/env bash
# detect-unused-deps.sh — DS-35: Unused dependency detection
# Fires when dependency manifest entries aren't imported in source.
# Prevention tier: T2 (skill — auto-prune)
set -euo pipefail
REPO="${1:?Usage: detect-unused-deps.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired="false"
total_deps=0
unused_count=0
evidence=""
manifest_type="none"

# Check requirements.txt
if [ -f "$REPO/requirements.txt" ]; then
    manifest_type="requirements.txt"
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/#.*//' | tr -d '[:space:]')
        [ -z "$line" ] && continue
        pkg=$(echo "$line" | sed 's/[><=!~].*//' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
        [ -z "$pkg" ] && continue
        total_deps=$((total_deps + 1))
        found=$(grep -rlE "import ${pkg}|from ${pkg}" "$REPO" \
            --include='*.py' --exclude-dir='.venv' --exclude-dir='venv' \
            --exclude-dir='node_modules' --exclude-dir='.git' 2>/dev/null | head -1) || true
        if [ -z "$found" ]; then
            unused_count=$((unused_count + 1))
            evidence="${evidence}${pkg} not imported; "
        fi
    done < "$REPO/requirements.txt"
fi

# Check package.json
if [ -f "$REPO/package.json" ] && [ "$manifest_type" = "none" ]; then
    manifest_type="package.json"
    deps=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        p = json.load(f)
    for s in ['dependencies','devDependencies']:
        for k in p.get(s,{}): print(k)
except: pass
" "$REPO/package.json" 2>/dev/null) || true
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        total_deps=$((total_deps + 1))
        found=$(grep -rlE "require\(['\"]${pkg}['\"]\)|from ['\"]${pkg}" "$REPO" \
            --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' \
            --exclude-dir='node_modules' --exclude-dir='.git' 2>/dev/null | head -1) || true
        if [ -z "$found" ]; then
            unused_count=$((unused_count + 1))
            evidence="${evidence}${pkg} not imported; "
        fi
    done <<< "$deps"
fi

[ "$total_deps" -gt 0 ] && [ "$unused_count" -gt 0 ] && fired="true"

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-35","name":"Unused dependencies","severity":"MEDIUM","prevention_tier":"T2"}' \
    "fired=$fired" "total_deps=$total_deps" "unused_count=$unused_count" \
    "manifest_type=$manifest_type" "evidence=$evidence"
