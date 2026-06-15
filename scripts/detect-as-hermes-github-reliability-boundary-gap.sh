#!/usr/bin/env bash
# detect-as-hermes-github-reliability-boundary-gap.sh — AS-40: Hermes/GitHub reliability boundary gap
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${1:?Usage: detect-as-hermes-github-reliability-boundary-gap.sh <repo_path>}"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-40" "$REPO"
