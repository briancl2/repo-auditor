#!/usr/bin/env bash
# detect-as-scheduled-readback-owner-proof-gap.sh - AS-49: Scheduled readback owner proof gap
set -euo pipefail
REPO="${1:?Usage: detect-as-scheduled-readback-owner-proof-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-49" "$REPO"
