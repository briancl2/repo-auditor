#!/usr/bin/env bash
# detect-as-reactive-self-healing-loop.sh — AS-26: reactive self-healing loop

set -euo pipefail

REPO="${1:?Usage: detect-as-reactive-self-healing-loop.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-26" "$REPO"
