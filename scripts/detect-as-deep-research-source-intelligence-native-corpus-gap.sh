#!/usr/bin/env bash
# detect-as-deep-research-source-intelligence-native-corpus-gap.sh — AS-46: Deep Research source-intelligence native corpus evidence gap
set -euo pipefail
REPO="${1:?Usage: detect-as-deep-research-source-intelligence-native-corpus-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-46" "$REPO"
