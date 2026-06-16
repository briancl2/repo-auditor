#!/usr/bin/env bash
# detect-as-campaign-sync-completed-track-gap.sh — AS-41: Campaign Sync completed-track readback gap
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${1:?Usage: detect-as-campaign-sync-completed-track-gap.sh <repo_path>}"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-41" "$REPO"
