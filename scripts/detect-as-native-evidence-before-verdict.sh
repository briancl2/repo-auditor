#!/usr/bin/env bash
# detect-as-native-evidence-before-verdict.sh -- AS-57
set -euo pipefail

REPO="${1:?Usage: detect-as-native-evidence-before-verdict.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-57" "$REPO"
