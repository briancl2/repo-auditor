#!/usr/bin/env bash
# detect-as-copied-evidence-boundary-gap.sh — AS-13: copied evidence boundary gap
set -euo pipefail

REPO="${1:?Usage: detect-as-copied-evidence-boundary-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-13" "$REPO"
