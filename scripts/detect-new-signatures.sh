#!/usr/bin/env bash
# detect-new-signatures.sh — Unified runner for DS-34+
# Runs the extended post-DS-33 signatures and outputs a combined JSON report.
# Usage: bash scripts/detect-new-signatures.sh <repo_path> [output_dir]
set -euo pipefail
REPO="${1:?Usage: detect-new-signatures.sh <repo_path> [output_dir]}"
OUTPUT_DIR="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$REPO" ]; then
    echo "ERROR: $REPO not a directory" >&2
    exit 1
fi

TMPDIR_DS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_DS"' EXIT

echo "=== DS-34+: $(basename "$REPO") ===" >&2

scripts=(
    "detect-stale-todos.sh"
    "detect-unused-deps.sh"
    "detect-green-only-ci.sh"
    "detect-readme-drift.sh"
    "detect-config-proliferation.sh"
    "detect-silent-errors.sh"
    "detect-commit-entropy.sh"
    "detect-test-theater.sh"
    "detect-broken-links.sh"
    "detect-velocity-bypass.sh"
    "detect-closeout-control-drift.sh"
    "detect-workflow-contract-drift.sh"
    "detect-llm-validation-gap.sh"
    "detect-summary-source-parity-gap.sh"
)

idx=0
for script in "${scripts[@]}"; do
    echo "  $script..." >&2
    bash "$SCRIPT_DIR/$script" "$REPO" > "$TMPDIR_DS/ds_${idx}.json" 2>/dev/null || \
        echo '{"ds_id":"unknown","fired":false,"error":"script failed"}' > "$TMPDIR_DS/ds_${idx}.json"
    idx=$((idx + 1))
done

# Assemble via python3 (no heredocs — uses separate .py file)
python3 "$SCRIPT_DIR/assemble_ds_results.py" "$TMPDIR_DS" "$(basename "$REPO")" "$REPO" "$OUTPUT_DIR"

echo "=== Done ===" >&2
