#!/usr/bin/env bash
# detect-as-gbrain-instruction-distribution-overclaim.sh - AS-36: GBrain instruction distribution overclaim
set -euo pipefail
REPO="${1:?Usage: detect-as-gbrain-instruction-distribution-overclaim.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" AS-36 "$REPO"
