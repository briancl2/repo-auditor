#!/usr/bin/env bash
# detect-as-missing-repo-anthropology-surface.sh — AS-52

set -euo pipefail

REPO="${1:?Usage: detect-as-missing-repo-anthropology-surface.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-52" "$REPO"
