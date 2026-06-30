#!/usr/bin/env bash
# detect-as-closure-signal-integrity.sh — AS-54

set -euo pipefail

REPO="${1:?Usage: detect-as-closure-signal-integrity.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-54" "$REPO"
