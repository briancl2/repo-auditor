#!/usr/bin/env bash
# detect-as-hermes-foreground-receipt-adoption-gap.sh — AS-29: Hermes foreground receipt adoption gap

set -euo pipefail

REPO="${1:?Usage: detect-as-hermes-foreground-receipt-adoption-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-29" "$REPO"
