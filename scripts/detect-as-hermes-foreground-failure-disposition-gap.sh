#!/usr/bin/env bash
# detect-as-hermes-foreground-failure-disposition-gap.sh — AS-50: Hermes foreground failure disposition gap
set -euo pipefail
REPO="${1:?Usage: detect-as-hermes-foreground-failure-disposition-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-50" "$REPO"
