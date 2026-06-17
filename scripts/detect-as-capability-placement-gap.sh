#!/usr/bin/env bash
# detect-as-capability-placement-gap.sh — AS-43: capability placement preview gap
set -euo pipefail
REPO="${1:?Usage: detect-as-capability-placement-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-43" "$REPO"
