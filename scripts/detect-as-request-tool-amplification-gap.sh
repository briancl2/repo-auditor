#!/usr/bin/env bash
# detect-as-request-tool-amplification-gap.sh — AS-11: request/tool amplification gap
set -euo pipefail

REPO="${1:?Usage: detect-as-request-tool-amplification-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-11" "$REPO"
