#!/usr/bin/env bash
# detect-as-cost-model-mismatch.sh — AS-10: selected/current/modelMetrics mismatch
set -euo pipefail

REPO="${1:?Usage: detect-as-cost-model-mismatch.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-10" "$REPO"
