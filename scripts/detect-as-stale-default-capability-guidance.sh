#!/usr/bin/env bash
# detect-as-stale-default-capability-guidance.sh — AS-28: stale/default capability guidance

set -euo pipefail

REPO="${1:?Usage: detect-as-stale-default-capability-guidance.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-28" "$REPO"
