#!/usr/bin/env bash
# detect-as-missing-operating-model-alignment-anchor.sh — AS-51: missing operating-model alignment anchor

set -euo pipefail

REPO="${1:?Usage: detect-as-missing-operating-model-alignment-anchor.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-51" "$REPO"
