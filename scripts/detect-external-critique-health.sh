#!/usr/bin/env bash
# detect-external-critique-health.sh — AS-08: external critique health
set -euo pipefail

REPO="${1:?Usage: detect-external-critique-health.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-08" "$REPO"
