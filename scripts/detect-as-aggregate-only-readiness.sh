#!/usr/bin/env bash
# detect-as-aggregate-only-readiness.sh - AS-16: aggregate-only readiness
set -euo pipefail

REPO="${1:?Usage: detect-as-aggregate-only-readiness.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-16" "$REPO"
