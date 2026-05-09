#!/usr/bin/env bash
# detect-as-phase-attribution-alias-gap.sh - AS-23: phase attribution alias gap
set -euo pipefail
REPO="${1:?Usage: detect-as-phase-attribution-alias-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-23" "$REPO"
