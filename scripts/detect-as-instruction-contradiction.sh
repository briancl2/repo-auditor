#!/usr/bin/env bash
# detect-as-instruction-contradiction.sh -- AS-58
set -euo pipefail

REPO="${1:?Usage: detect-as-instruction-contradiction.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-58" "$REPO"
