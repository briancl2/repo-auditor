#!/usr/bin/env bash
# detect-as-closure-run-identity-gap.sh — AS-34: Closure-run identity gap
set -euo pipefail
REPO="${1:?Usage: detect-as-closure-run-identity-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-34" "$REPO"
