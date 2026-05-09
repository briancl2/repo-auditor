#!/usr/bin/env bash
# detect-as-promotion-without-control-noise-floor.sh - AS-21: promotion without control noise floor
set -euo pipefail

REPO="${1:?Usage: detect-as-promotion-without-control-noise-floor.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-21" "$REPO"
