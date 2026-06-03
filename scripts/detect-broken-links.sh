#!/usr/bin/env bash
# detect-broken-links.sh — DS-42: Broken internal link detection
# Fires when markdown files link to non-existent files.
# Prevention tier: T1 (make check integration)
set -euo pipefail
REPO="${1:?Usage: detect-broken-links.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

total_links=0
broken_count=0
evidence=""

# Find markdown files (limit to 200 for performance)
md_files=$(find "$REPO" -name "*.md" \
    -not -path "*/node_modules/*" -not -path "*/.git/*" \
    -not -path "*/vendor/*" -not -path "*/.venv/*" \
    -type f 2>/dev/null | head -200) || true

while IFS= read -r md_file; do
    [ -z "$md_file" ] && continue
    [ ! -f "$md_file" ] && continue
    md_dir=$(dirname "$md_file")

    # Extract [text](path) links, exclude URLs/anchors/mailto
    links=$(awk '
        /^[[:space:]]*```/ || /^[[:space:]]*~~~/ { in_fence = !in_fence; next }
        !in_fence { print }
    ' "$md_file" 2>/dev/null | grep -oE '\]\([^)]+\)' | \
        sed 's/^\]//' | sed 's/^(//' | sed 's/)$//' | \
        grep -v '^http' | grep -v '^#' | grep -v '^mailto:' | \
        grep -v '^ *$' | sed 's/#.*//' | sed 's/?.*$//' | sort -u) || true

    while IFS= read -r link; do
        [ -z "$link" ] && continue
        # Skip image URLs and data URIs
        case "$link" in data:*|javascript:*) continue ;; esac

        total_links=$((total_links + 1))

        # Try relative to md file dir, then relative to repo root
        target1="$md_dir/$link"
        target2="$REPO/$link"

        if [ ! -f "$target1" ] && [ ! -d "$target1" ] && \
           [ ! -f "$target2" ] && [ ! -d "$target2" ]; then
            broken_count=$((broken_count + 1))
            if [ "$broken_count" -le 5 ]; then
                short_md=$(echo "$md_file" | sed "s|$REPO/||")
                evidence="${evidence}${short_md} -> ${link}; "
            fi
        fi
    done <<< "$links"
done <<< "$md_files"

fired="false"
[ "$broken_count" -gt 0 ] && fired="true"

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-42","name":"Broken internal links","severity":"HIGH","prevention_tier":"T1"}' \
    "fired=$fired" "total_links=$total_links" "broken_count=$broken_count" "evidence=$evidence"
