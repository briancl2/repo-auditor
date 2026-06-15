#!/usr/bin/env bash
# detect-as-scheduled-evidence-boundary-gap.sh — AS-39: Scheduled workflow evidence boundary gap

set -euo pipefail

REPO="${1:?Usage: detect-as-scheduled-evidence-boundary-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-39" "$REPO"
