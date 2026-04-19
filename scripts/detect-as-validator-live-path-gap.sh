#!/usr/bin/env bash
# detect-as-validator-live-path-gap.sh — AS-04: validator live-path gap
set -euo pipefail

REPO="${1:?Usage: detect-as-validator-live-path-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-04" "$REPO"
