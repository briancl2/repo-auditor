#!/usr/bin/env bash
# detect-as-cost-without-token-fields.sh — AS-09: cost estimate without token fields
set -euo pipefail

REPO="${1:?Usage: detect-as-cost-without-token-fields.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-09" "$REPO"
