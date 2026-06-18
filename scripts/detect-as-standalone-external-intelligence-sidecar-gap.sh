#!/usr/bin/env bash
# detect-as-standalone-external-intelligence-sidecar-gap.sh - AS-48: Standalone external intelligence sidecar gap
set -euo pipefail
REPO="${1:?Usage: detect-as-standalone-external-intelligence-sidecar-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-48" "$REPO"
