#!/usr/bin/env bash
# detect-as-route-changing-learning-propagation-gap.sh — AS-42: route-changing learning propagation gap
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${1:?Usage: detect-as-route-changing-learning-propagation-gap.sh <repo_path>}"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-42" "$REPO"
