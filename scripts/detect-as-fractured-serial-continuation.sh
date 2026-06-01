#!/usr/bin/env bash
# detect-as-fractured-serial-continuation.sh — AS-31: fractured serial continuation
set -euo pipefail

REPO="${1:?Usage: detect-as-fractured-serial-continuation.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-31" "$REPO"
