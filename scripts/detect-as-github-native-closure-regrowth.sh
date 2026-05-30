#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?Usage: detect-as-github-native-closure-regrowth.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-22" "$REPO"
