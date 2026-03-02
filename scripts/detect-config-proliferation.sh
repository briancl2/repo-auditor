#!/usr/bin/env bash
# detect-config-proliferation.sh — DS-38: Config format proliferation
# Fires when >2 distinct config file formats coexist in the repo.
# Prevention tier: T3 (advisory)
set -euo pipefail
REPO="${1:?Usage: detect-config-proliferation.sh <repo_path>}"
THRESHOLD="${2:-2}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

formats_found=0
formats_list=""
EXCLUDE="-not -path */node_modules/* -not -path */.git/* -not -path */vendor/* -not -path */.venv/* -not -path */venv/* -not -path */archive/*"

check_fmt() {
    local label="$1"; shift
    local cnt
    cnt=$(find "$REPO" "$@" \
        -not -path "*/node_modules/*" -not -path "*/.git/*" \
        -not -path "*/vendor/*" -not -path "*/.venv/*" \
        -not -path "*/archive/*" -type f 2>/dev/null | wc -l | tr -d ' ') || cnt=0
    if [ "$cnt" -gt 0 ]; then
        formats_found=$((formats_found + 1))
        [ -n "$formats_list" ] && formats_list="$formats_list, "
        formats_list="${formats_list}${label}(${cnt})"
    fi
}

check_fmt "json" -name "*.json"

yaml_count=$(find "$REPO" \( -name "*.yaml" -o -name "*.yml" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" \
    -not -path "*/vendor/*" -not -path "*/.venv/*" \
    -not -path "*/archive/*" -type f 2>/dev/null | wc -l | tr -d ' ') || yaml_count=0
if [ "$yaml_count" -gt 0 ]; then
    formats_found=$((formats_found + 1))
    [ -n "$formats_list" ] && formats_list="$formats_list, "
    formats_list="${formats_list}yaml(${yaml_count})"
fi

check_fmt "toml" -name "*.toml"
check_fmt "env" -name "*.env"
check_fmt "ini" -name "*.ini"
check_fmt "cfg" -name "*.cfg"
check_fmt "conf" -name "*.conf"

fired="false"
[ "$formats_found" -gt "$THRESHOLD" ] && fired="true"

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-38","name":"Config format proliferation","severity":"LOW","prevention_tier":"T3"}' \
    "fired=$fired" "formats_found=$formats_found" "threshold=$THRESHOLD" \
    "evidence=formats: $formats_list"
