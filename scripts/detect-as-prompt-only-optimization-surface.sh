#!/usr/bin/env bash
# detect-as-prompt-only-optimization-surface.sh — AS-06: prompt-only optimization surface
set -euo pipefail

REPO="${1:?Usage: detect-as-prompt-only-optimization-surface.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-06" "$REPO"
