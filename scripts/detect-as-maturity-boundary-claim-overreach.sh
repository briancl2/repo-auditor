#!/usr/bin/env bash
# detect-as-maturity-boundary-claim-overreach.sh — AS-53

set -euo pipefail

REPO="${1:?Usage: detect-as-maturity-boundary-claim-overreach.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-53" "$REPO"
