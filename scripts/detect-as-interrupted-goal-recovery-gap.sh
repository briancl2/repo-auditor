#!/usr/bin/env bash
# detect-as-interrupted-goal-recovery-gap.sh — AS-30: interrupted Goal recovery gap
set -euo pipefail

REPO="${1:?Usage: detect-as-interrupted-goal-recovery-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-30" "$REPO"
