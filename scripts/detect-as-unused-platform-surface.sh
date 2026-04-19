#!/usr/bin/env bash
# detect-as-unused-platform-surface.sh — AS-07: unused platform surface
set -euo pipefail

REPO="${1:?Usage: detect-as-unused-platform-surface.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-07" "$REPO"
