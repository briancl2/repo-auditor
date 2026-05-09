#!/usr/bin/env bash
# detect-as-stale-direct-token-evidence.sh - AS-17: stale direct-token evidence
set -euo pipefail

REPO="${1:?Usage: detect-as-stale-direct-token-evidence.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-17" "$REPO"
