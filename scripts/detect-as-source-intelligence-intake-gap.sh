#!/usr/bin/env bash
# detect-as-source-intelligence-intake-gap.sh — AS-19 source-intelligence intake gap
set -euo pipefail
REPO="${1:?Usage: detect-as-source-intelligence-intake-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" AS-19 "$REPO"
