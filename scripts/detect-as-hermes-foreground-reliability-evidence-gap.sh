#!/usr/bin/env bash
# detect-as-hermes-foreground-reliability-evidence-gap.sh — AS-44: Hermes foreground reliability evidence gap
set -euo pipefail
REPO="${1:?Usage: detect-as-hermes-foreground-reliability-evidence-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-44" "$REPO"
