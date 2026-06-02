#!/usr/bin/env bash
# detect-as-foreground-failure-guidance-gap.sh — AS-33: Foreground failure guidance gap

set -euo pipefail

REPO="${1:?Usage: detect-as-foreground-failure-guidance-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-33" "$REPO"
