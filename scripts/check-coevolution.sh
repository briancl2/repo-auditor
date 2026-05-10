#!/usr/bin/env bash
# Validate that governed surface edits co-evolve with test or fixture changes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CHANGED_PATHS_FILE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --changed-paths-file)
            CHANGED_PATHS_FILE="${2:-}"
            shift 2
            ;;
        *)
            echo "usage: bash scripts/check-coevolution.sh [--changed-paths-file <path>]" >&2
            exit 2
            ;;
    esac
done

is_governed_surface() {
    case "$1" in
        .agents/*|.github/agents/*|scripts/detect-*.sh|schemas/*.json)
            return 0
            ;;
    esac
    return 1
}

is_pairing_change() {
    case "$1" in
        tests/*|fixtures/*|*/fixtures/*)
            return 0
            ;;
    esac
    return 1
}

collect_changed_paths() {
    if [ -n "$CHANGED_PATHS_FILE" ]; then
        if [ ! -f "$CHANGED_PATHS_FILE" ]; then
            echo "changed paths file not found: $CHANGED_PATHS_FILE" >&2
            exit 2
        fi
        cat "$CHANGED_PATHS_FILE"
        return
    fi

    if ! git diff --cached --quiet --diff-filter=ACMR --; then
        git diff --cached --name-only --diff-filter=ACMR --
        return
    fi

    if git rev-parse --verify HEAD^ > /dev/null 2>&1; then
        git diff --name-only --diff-filter=ACMR HEAD^ HEAD --
    fi
}

CHANGED_PATHS="$(collect_changed_paths)"
SURFACE_CHANGES=""
HAS_PAIRING_CHANGE=0

while IFS= read -r path; do
    [ -n "$path" ] || continue
    if is_governed_surface "$path"; then
        SURFACE_CHANGES="${SURFACE_CHANGES}${path}"'
'
    fi
    if is_pairing_change "$path"; then
        HAS_PAIRING_CHANGE=1
    fi
done <<EOF
$CHANGED_PATHS
EOF

if [ -z "$SURFACE_CHANGES" ]; then
    echo "  PASS: co-evolution guard (no governed surface edits)"
    exit 0
fi

if [ "$HAS_PAIRING_CHANGE" -eq 1 ]; then
    echo "  PASS: co-evolution guard (surface edits paired with tests/fixtures)"
    exit 0
fi

echo "  FAIL: governed surface edits require a paired tests/ or fixtures/ delta"
printf '%s' "$SURFACE_CHANGES" | sed 's/^/    - /'
exit 1
