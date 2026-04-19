#!/usr/bin/env bash
# detect-as-instruction-root-drift.sh — AS-01: instruction-root drift
set -euo pipefail

REPO="${1:?Usage: detect-as-instruction-root-drift.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-01" "$REPO"
