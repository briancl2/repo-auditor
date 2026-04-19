#!/usr/bin/env bash
# detect-as-missing-runtime-heartbeat.sh — AS-03: missing runtime heartbeat
set -euo pipefail

REPO="${1:?Usage: detect-as-missing-runtime-heartbeat.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-03" "$REPO"
