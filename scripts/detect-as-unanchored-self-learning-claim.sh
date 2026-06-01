#!/usr/bin/env bash
# detect-as-unanchored-self-learning-claim.sh — AS-32: unanchored self-learning claim

set -euo pipefail

REPO="${1:?Usage: detect-as-unanchored-self-learning-claim.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-32" "$REPO"
