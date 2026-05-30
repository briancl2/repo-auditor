#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?Usage: detect-as-owner-surface-ambiguity.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-23" "$REPO"
