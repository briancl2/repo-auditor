#!/usr/bin/env bash
# detect-as-external-closure-coupling.sh -- AS-56
set -euo pipefail

REPO="${1:?Usage: detect-as-external-closure-coupling.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-56" "$REPO"
