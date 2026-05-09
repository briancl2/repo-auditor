#!/usr/bin/env bash
# detect-as-missing-rollback-control-proof.sh - AS-15: missing rollback/control proof
set -euo pipefail

REPO="${1:?Usage: detect-as-missing-rollback-control-proof.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-15" "$REPO"
