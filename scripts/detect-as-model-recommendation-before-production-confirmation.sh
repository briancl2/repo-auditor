#!/usr/bin/env bash
# detect-as-model-recommendation-before-production-confirmation.sh - AS-22: model recommendation before production confirmation
set -euo pipefail

REPO="${1:?Usage: detect-as-model-recommendation-before-production-confirmation.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-22" "$REPO"
