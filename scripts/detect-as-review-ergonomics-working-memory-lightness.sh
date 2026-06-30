#!/usr/bin/env bash
# detect-as-review-ergonomics-working-memory-lightness.sh — AS-55

set -euo pipefail

REPO="${1:?Usage: detect-as-review-ergonomics-working-memory-lightness.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-55" "$REPO"
