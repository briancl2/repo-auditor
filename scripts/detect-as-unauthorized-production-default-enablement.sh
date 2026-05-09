#!/usr/bin/env bash
# detect-as-unauthorized-production-default-enablement.sh - AS-14: unauthorized production default enablement
set -euo pipefail

REPO="${1:?Usage: detect-as-unauthorized-production-default-enablement.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-14" "$REPO"
