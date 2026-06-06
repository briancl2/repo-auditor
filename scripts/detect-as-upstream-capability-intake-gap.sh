#!/usr/bin/env bash
# detect-as-upstream-capability-intake-gap.sh — AS-35 upstream capability intake gap
set -euo pipefail
REPO="${1:?Usage: detect-as-upstream-capability-intake-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" AS-35 "$REPO"
