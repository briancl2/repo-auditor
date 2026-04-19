#!/usr/bin/env bash
# detect-as-memory-authority-confusion.sh — AS-05: memory authority confusion
set -euo pipefail

REPO="${1:?Usage: detect-as-memory-authority-confusion.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-05" "$REPO"
