#!/usr/bin/env bash
# detect-as-goal-runtime-evidence-gap.sh — AS-25: Goal-mode runtime evidence gap

set -euo pipefail

REPO="${1:?Usage: detect-as-goal-runtime-evidence-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-25" "$REPO"
